classdef Evader < handle & Vehicle
  %EVADER Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
  end
  
  methods
    % Contsructor
    function obj = Evader(RN, road, roadSlot, roadLane, roadDirection,...
        wait_time)
      obj = obj@Vehicle(RN, road, roadSlot, roadLane, roadDirection,...
        wait_time);
      obj.points = [1.5 1.5 -1.5 -1.5; -0.5 0.5 1 -1];
      obj.color = [0,0.5,0];
      obj.markerSize = 7;
    end
    
    function action(obj)
      if ~obj.is_pinned()
        if obj.pursuer_in_front()
          obj.u_turn();
        else
          was_at_intersection = ~isempty(obj.at_intersection());
          moved_forward = obj.move_forward();
          if was_at_intersection && moved_forward
            obj.prevIntersection.sensors.update_info(...
              obj.nextIntersection.pos, obj.time);
          end
        end
      end
    end
    
    function next_road = choose_next_road(obj, intersection)
      has_pursuer = arrayfun(@(r) r.has_a('Pursuer'), intersection.roads);
      congestion = intersection.get_congestion();
      if ~all(has_pursuer)
        roads = intersection.roads(~has_pursuer);
        congestion = congestion(~has_pursuer);
        if length(roads) > 1
          forward_roads = (roads ~= obj.road);
          roads = roads(forward_roads);
          congestion = congestion(forward_roads);
        end
      else
        roads = intersection.roads;
      end
      % Randomize order of roads, so no direction gets a preference in case
      % of ties
      rand_idxs = randperm(length(congestion));
      % Choose road with minimum congestion
      [~,roadIndex] = min(congestion(rand_idxs));
      next_road = roads(rand_idxs(roadIndex));
    end
    
    function bool = pursuer_in_front(obj)
      my_side = any(any(cellfun(@(x) isa(x, 'Pursuer'), ...
        obj.road.slots{obj.roadDirection}(obj.roadSlot+1:end, :))));
      other_side = any(any(cellfun(@(x) isa(x, 'Pursuer'), ...
        obj.road.slots{obj.otherDirection}(1:obj.otherSlot-1, :))));
      int_cond = false;
      int = obj.at_intersection();
      if ~isempty(int)
        for r = 1:length(int.roads)
          if any(cellfun(@(x) isa(x, 'Pursuer'), ...
              int.roads(r).slots{int.exitIndex(r)}(1,:)));
            int_cond = true;
          end
        end
      end
      bool = (my_side || other_side || int_cond);
    end
    
    function bool = pursuer_behind(obj)
      my_side = any(any(cellfun(@(x) isa(x, 'Pursuer'), ...
        obj.road.slots{obj.roadDirection}(1:obj.roadSlot-1, :))));
      other_side = any(any(cellfun(@(x) isa(x, 'Pursuer'), ...
        obj.road.slots{obj.otherDirection}(obj.otherSlot+1:end, :))));
      bool = (my_side || other_side);
    end
    
    % If there is a Pursuer both in front and behind the evader, it is
    % pinned
    function bool = is_pinned(obj)
      bool = (obj.pursuer_in_front() && obj.pursuer_behind());
    end
    
    function draw(obj, simple)
      if nargin < 2 || ~simple
        obj.draw_poly();
      else
        obj.draw_simple();
      end
    end
  end
  
end

