classdef RoadNetwork < handle
  %ROADNETWORK Defines a set of interconnected roads
  %   Detailed explanation goes here
  
  properties
    % Array of intersections composing the network
    intersections = Intersection.empty(); 
    roads = Road.empty(); % Array of roads composing the network 
    roadColor; % Color used to draw road
    dr;        % Angle step size for plotting curves connecting roads
  end
  
  methods
    % Consturctor
    function obj = RoadNetwork(varargin)
      % Handle optional parameters
      [obj.dr, obj.roadColor] = ...
        optionalparams(varargin, ...
        'AngleStepSize', pi/12,...
        'RoadColor', [0.2 0.2 0.3]);
    end
    
    % Create a grid network of streets
    function CreateGrid(obj, nBlocksWide, nBlocksLong, bat_time, varargin)
      % Handle optional parameters
      [blockLength, nForwardLanes, nBackwardLanes, laneWidth,...
        shoulderWidth, intRad, speedLimit, maxCarLength, oneWay] = ...
        optionalparams(varargin, ...
        'BlockLength', 50,...
        'NumberOfForwardLanes', 1,...
        'NumberOfBackwardLanes', 1,...
        'LaneWidth', 3,...
        'ShoulderWidth', 1.5,...
        'IntersectionRadius', 12,...
        'SpeedLimit', 50,...
        'MaxCarLength', 4,...
        'OneWay', false);
      
      % Parameters to be passed to Roads
      roadParams = ...
        {'NumberOfForwardLanes', nForwardLanes,...
        'NumberOfBackwardLanes', nBackwardLanes,...
        'LaneWidth', laneWidth,...
        'ShoulderWidth', shoulderWidth,...
        'SpeedLimit', speedLimit,...
        'MaxCarLength', maxCarLength,...
        'RoadColor', obj.roadColor};
      
      % Start defining the intersections
      h = nBlocksLong + 1; % Height of intersection array, for convenience
      w = nBlocksWide + 1; % Width of intersection array, for convenience
      
      % Preallocate intersection and road array
      obj.intersections(h,w) = Intersection();
      nRoads = (h-1)*w + ... Number of vertical roads
                h*(w-1);   % Number of horizontal roads
      obj.roads(nRoads,1) = Road();
              
      for r = 1:h
        for c = 1:w
          % Calculate center position of intersection
          pos = ([c;r] - 1)*(intRad + blockLength);
          % Set desired properties of intersection
          obj.intersections(r,c).initialize(pos, 'Radius', intRad, ...
            'AngleStepSize', obj.dr, 'RoadColor', obj.roadColor);
          obj.intersections(r,c).add_sensor(Sensor(obj,obj.intersections(r,c),bat_time));
        end
      end
      iroad = 1; % index of the current unassigned road
      for r = 1:h
        for c = 1:w 
          % Create roads
          if c < w
            % Create road to the right of the intersection
            if oneWay && mod(r,2) == 1
              % Direction of road alternates from street to street
              obj.roads(iroad).initialize(obj.intersections(r,c+1), ...
                obj.intersections(r,c), roadParams{:});
            else
              obj.roads(iroad).initialize(obj.intersections(r,c), ...
                obj.intersections(r,c+1), roadParams{:});
            end
            iroad = iroad + 1;
          end
          
          if r < h
            if oneWay && mod(c,2) == 0
              Direction of road alternates from street to street
              obj.roads(iroad).initialize(obj.intersections(r+1,c), ...
                obj.intersections(r,c), roadParams{:});
            else
              obj.roads(iroad).initialize(obj.intersections(r,c), ...
                obj.intersections(r+1,c), roadParams{:});
            end
            iroad = iroad + 1;
          end
        end
      end
      
      % Create a list of neighboring sensors on each sensor
      for i=1:length(obj.intersections(:))
          obj.intersections(i).sensors.neighbors = ...
            [obj.intersections(i).neighbors.sensors];
      end
    end
    
    function [road, slot, lane, dir] = get_random_empty_slot(obj)
      found_empty_slot = false;
      while ~found_empty_slot
        road = obj.roads(randi(length(obj.roads)));
        if road.nLanes(1) == 0
          dir = 2;
        elseif road.nLanes(2) == 0
          dir = 1;
        else
          dir = randi(2);
        end
        slot = randi(road.nSlots);
        lane = randi(road.nLanes(dir));
        found_empty_slot = isempty(road.slots{dir}{slot, lane});
      end
    end
    
    function draw(obj, simple)
      if nargin < 2 || ~simple
        arrayfun(@(x) x.draw(), obj.intersections);
        arrayfun(@(x) x.draw(), obj.roads);
      else
        obj.draw_simple();
      end
    end
    
    function draw_simple(obj)
      arrayfun(@(x) x.draw_simple(), obj.roads);
    end
    
    function delete(obj)
      for int = obj.intersections
        if isvalid(int)
          int.delete();
        end
      end
      for r = obj.roads
        if isvalid(r)
          r.delete();
        end
      end
      obj.intersections = [];
      obj.roads = [];
    end
  end
end

