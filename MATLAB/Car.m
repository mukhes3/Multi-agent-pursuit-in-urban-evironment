classdef Car < handle & Vehicle
  %CAR Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    destination
  end
  
  methods
    % Constructor
    function obj = Car(RN, road, roadSlot, roadLane, roadDirection, ...
        wait_time, destination)
      if ~isa(destination, 'Intersection')
        error('Input "destination" must be of class Intersection.')
      end
      obj = obj@Vehicle(RN, road, roadSlot, roadLane, roadDirection,...
        wait_time);
      obj.destination = destination;
      
      obj.points = [1.5 1.5 -1.5 -1.5; -0.5 0.5 1 -1];
      obj.color = 'r';
    end
    
    % This function prepares the same vehicles to be used in another
    % simulation
    function reset(obj, road, roadSlot, roadLane, roadDirection, ...
        destination)
      reset@Vehicle(obj, road, roadSlot, roadLane, roadDirection);
      obj.destination = destination;
    end
    
    function action(obj)
      if obj.at_intersection() == obj.destination
        % Select a random intersection to be the new destination
        obj.destination = ...
          obj.RN.intersections(randi(numel(obj.RN.intersections)));
      else
        obj.move_forward();
      end
    end
    
    function next_road = choose_next_road(obj, intersection)
      other_roads = (intersection.roads ~= obj.road);
      roads = intersection.roads(other_roads);
      exitIndex = intersection.exitIndex(other_roads);
      exitIndex(exitIndex == 2) = -1;
      orientations = [roads.orientation] .* (ones(2,1)*exitIndex);
      dirQuality = ones(1,length(roads)) + ...
        normc(obj.destination.pos - obj.pos)' * orientations;
      % Determine a road with a probability = quality/sum of qualities
      cdf = cumsum(dirQuality)/sum(dirQuality);
      roadIndex = find(cdf > rand, 1);
      next_road = roads(roadIndex);
    end
   
    function draw(obj, simple)
      if nargin < 2 || ~simple
        obj.draw_poly();
      else
        obj.draw_simple();
      end
    end
    
    function delete(obj)
      obj.destination = [];
    end
  end
end

