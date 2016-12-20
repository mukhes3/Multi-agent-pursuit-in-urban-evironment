classdef Pursuer < handle & Vehicle
  %PURSUER Summary of this class goes here
  %   Detailed explanation goes here
  % CATCH THE BATMAN!!!!
  
  properties
    ID
    request_status = 0;
    request_time = 0;
    response_time = [];
    bat_rad; %radius of batman where it can start implementing a
    %distributed control algorithm
    
    bat_pos = [0;0]; %position of the interestion batman is headed towards
    tbat = -Inf;
    del_bat; %shortest time taken by batman to cross a block
    sensor = Sensor.empty(); % Sensor node pursuer is connected to
    algorithm = 1;
  end
  
  methods    
    % Constructor
    function obj = Pursuer(RN, road, roadSlot, roadLane, roadDirection, ...
        wait_time, del_bat, ID)
      obj = obj@Vehicle(RN, road, roadSlot, roadLane, roadDirection,...
        wait_time);
      obj.del_bat = del_bat;
      
      obj.points = [1.5 1.5 -1.5 -1.5; -0.5 0.5 1 -1];
      obj.color = 'b';
      obj.markerSize = 7;
      obj.ID = ID;
    end
    
    % This function prepares the same vehicles to be used in another
    % simulation
    function reset(obj, road, roadSlot, roadLane, roadDirection)
      reset@Vehicle(obj, road, roadSlot, roadLane, roadDirection);
      obj.request_status = 0;
      obj.request_time = 0;
      obj.response_time = [];
      obj.sensor = Sensor.empty();
      obj.bat_pos = [0;0];
      obj.tbat = -Inf;
    end
    
    function action(obj)
      obj.communicate();
      obj.move_forward();
    end
    
    function next_road = choose_next_road(obj, intersection)
      switch obj.algorithm;
        case 1 % path plan quick
          next_road = obj.path_plan_quick(intersection, false);
        case 2 % path plan quick improved
          next_road = obj.path_plan_quick(intersection, true);
      end
    end
    
    function [] = communicate(obj)
      if (obj.time - obj.tbat) > obj.del_bat && obj.request_status == 0
        %this portion needs to be modified but the idea is to use
        %search for the closest sensor
        obj.sensor = obj.nextIntersection.sensors;
        if obj.request_status == 0
          %calls the service request class
          obj.sensor.service_request(obj, obj.time);
          obj.request_status = 1;
          obj.request_time = obj.time;
        end
      end
    end
    
    function receive_data(obj, tbat, bat_pos, time)
      obj.tbat = tbat;
      obj.bat_pos = bat_pos;
      obj.request_status = 0;
      obj.response_time = [obj.response_time, time - obj.request_time];
      obj.request_time = 0;
      obj.sensor = Sensor.empty();
      %disp(obj.bat_pos) 
      %disp(obj.ID)
    end
    
    %the following function causes the dumbest possible path planning
    %i.e. the pursuer will always try to track batman via the shortest
    %possible path. In case of multiple possible paths, it will pick the
    %one with the least congestion after reaching a intersection.
    function [next_road] = path_plan_quick(obj, intersection, IMPROVED)
      % Get the roads that the pursuer is not on at the current
      % intersection
      other_roads = (intersection.roads ~= obj.road);
      roads = intersection.roads(other_roads);
      
      % Avoid roads with other pursuers, if possible
      if IMPROVED
        without_pursuers = arrayfun(@(r,dir) ~r.has_a('Pursuer',dir), ...
          intersection.roads, intersection.exitIndex');
        other_roads_without_pursuers = other_roads & without_pursuers;
        if any(other_roads_without_pursuers)
          other_roads = other_roads_without_pursuers;
          roads = intersection.roads(other_roads);
        else
          without_evader = arrayfun(@(r,dir) ~r.has_a('Evader',dir),...
            intersection.roads, intersection.exitIndex');
          other_roads_without_evader = other_roads & without_evader;
          if any(other_roads_without_evader)
            other_roads = other_roads_without_evader;
            roads = intersection.roads(other_roads);
          end
        end
      end
      
      % Choose road with evader, if there is one
      has_evader = arrayfun(@(r) r.has_a('Evader'), roads);
      if any(has_evader)
        next_road = roads(has_evader);
      else
        
        % Get the orientations for each road
        exitIndex = intersection.exitIndex(other_roads);
        exitIndex(exitIndex == 2) = -1;
        orientations = [roads.orientation] .* (ones(2,1)*exitIndex);
        
        % Dot product the orientation vector with the normalized desired
        % direction vector. Positive values correspond to roads heading
        % towards the desired intersection
        dirQuality = normc(obj.bat_pos - obj.pos)' * orientations;
        
        % Picks the road with the least congestion among the possible
        % path choices. The choices are however limited by the fact
        % that it can go in only one of two ways and not 4.
        congestion = intersection.get_congestion();
        congestion = congestion(other_roads);
        
        % Choose the available roads are in the direction of the evader,
        % then choose the one with least congestion. If no roads are in the
        % direction of the evader, then choose the closest ones
        best_roads = dirQuality > 0.2;
        if ~any(best_roads)
          % Use a small value > 0 above to exclude perpendicular choices
          best_roads = (dirQuality >= max(dirQuality) - 0.2);
        end
        roads = roads(best_roads);
        if length(roads) > 1
          % If there are more than one choice, choose the one with the
          % least congestion
          [~, idx] = min(congestion(best_roads));
          next_road = roads(idx);
        else
          next_road = roads;
        end
      end
    end

%     % The following function results in a path planning strategy similar
%     % to what humans do in such situations.
%     
%     function [next_road] = path_plan_human(obj, intersection)
%       
%         if norm(obj.bat_pos-intersection.pos,-Inf) > obj.bat_rad
%           next_road = path_plan_quick(obj, intersection);
%         else
%           % Calls a function of the Sensor class which returns the
%           % congestion information. It also returns the other pursuers in 
%           % the range of batman. 
%           
%           [congestion_info,pursuers_inrange]= obj.sensor.get_range_info();
%           
%           %Calculate shortest distance between batman and each of the
%           %agents in the range (including itself).
%           min_dist=[];
%           for i=1:length(pursuers_inrange) 
% %               This part will estimate the present coordinate of the
% %               pursuer(i) based on the congestion in the road it is on.
% %               Assuming the present estimated position gets stored in 
% %               variable pos.
%                 min_dist(i)=norm(obj.batpos-obj.pos);
%           end
%           %The agent with the least distance from batman is considered the
%           %leader. The next part checks if this agent is the present leader. 
%           [min,Index]=min(min_dist);
%           if pursuer_inrange(Index)==obj.ID
% %               In that case, this agent is the leader. 
%              next_road = path_plan_quick(obj, intersection);
%           else
% %               This part will find an alternate route for the agent in
% %               case it is not the leader. 
% 
%          
% 
%         end
%       end
    
% The following function will try to catch batman on the basis of
% communication between the pursuing agents and their leader. 

function [next_road]=path_plan_leader(obj)
end    




    function draw(obj, simple)
      if nargin < 2 || ~simple
        obj.draw_poly();
      else
        obj.draw_simple();
      end
    end
    
    function delete(obj)
      if ~isempty(obj.sensor)
        if isvalid(obj.sensor)
          obj.sensor.pursuers = [];
        end
        obj.sensor = [];
      end
    end
  end
end
    
