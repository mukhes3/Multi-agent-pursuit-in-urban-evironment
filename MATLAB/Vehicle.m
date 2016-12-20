classdef Vehicle < handle & matlab.mixin.Heterogeneous
  %VEHICLE Generic class defining vehicles that travel on a RoadNetwork
  %   Detailed explanation goes here
  
  properties
    velocity
    time = 0           % Current time index of simulation
    lastActionTime = 0 % Time index of last action performed
    actionList         % Global ordered list of objects and their 
                       %   update times
    actionListItemsPos = 0 % Used by the actionList for efficiency
    waitTime = 25      % time steps to wait between performing actions
    
    RN % RoadNetwork that the vehicle is on
    % Index of current road vehicle is on
    road
    roadSlot
    roadLane
    roadDirection % 1 if traveling in the forward direction, 
                  % 2 if traveling in the backward direction
                  
    points
    color
    markerSize = 5;
    plt
    plt_simple
  end
  
  properties (SetAccess = private)
    pos_history
    time_history
  end
  
  properties (Dependent)
    pos
    orientation
    otherSlot % Slot at same location as roadSlot in other direction
    otherDirection % 2 if roadDirection is 1, and vice versa
    nextIntersection % upcoming intersection
    prevIntersection % previous intersection
  end
  
  methods (Abstract)
    action(obj)
    choose_next_road(obj)
  end
  
  methods
    % Constructor
    function obj = Vehicle(RN, road, roadSlot, roadLane, roadDirection,...
        wait_time)
      obj.RN = RN;
      obj.road = road;
      obj.roadSlot = roadSlot;
      obj.roadLane = roadLane;
      obj.roadDirection = roadDirection;
      obj.waitTime = wait_time;
      if ~isempty(obj.road.slots{obj.roadDirection}...
          {obj.roadSlot, obj.roadLane})
        error('Slot for vehicle is not empty.')
      end
      obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane} = obj;
      obj.pos_history = DynArray(obj.pos);
      obj.time_history = DynArray(obj.time);
    end
    
    % This function prepares the same vehicles to be used in another
    % simulation
    function reset(obj, road, roadSlot, roadLane, roadDirection)
      % Remove from former slot
      if ~isempty(obj.road)
        obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane} = [];
      end
      % Update location information
      obj.road = road;
      obj.roadSlot = roadSlot;
      obj.roadLane = roadLane;
      obj.roadDirection = roadDirection;
      % Place car at its location on the road
      obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane} = obj;
      
      % Update simulation properties
      obj.time = 0;
      obj.lastActionTime = 0;
    end
    
    % Get functions
    function value = get.pos(obj)
      value = ...
        obj.road.slotPos{obj.roadDirection}{obj.roadSlot, obj.roadLane};
    end
    function value = get.orientation(obj)
      if obj.roadDirection == 1
        value = obj.road.orientation;
      else
        value= -obj.road.orientation;
      end
    end
    function value = get.otherDirection(obj)
      if obj.roadDirection == 1
        value = 2;
      else
        value = 1;
      end
    end
    function value = get.otherSlot(obj)
      value = obj.road.nSlots - obj.roadSlot + 1;
    end
    function value = get.nextIntersection(obj)
      if obj.roadDirection == 1
        value = obj.road.intersections(2);
      else
        value = obj.road.intersections(1);
      end
    end
    function value = get.prevIntersection(obj)
      value = obj.road.intersections(obj.roadDirection);
    end
    
    function intersection = at_intersection(obj)
      % See if car is in the last slot, and return appropriate
      % intersection index
      if (obj.roadSlot == obj.road.nSlots)
        % Return intersection 2 if in direction 1, and vice versa
        intersection = obj.nextIntersection;
      else
        % If not at an intersection, return an empty intersection
        intersection = Intersection.empty();
      end
    end
    
    function car = car_in_front(obj)
      % If you're at an intersection no car is in front
      if isempty(obj.at_intersection())
        car = {};
      else % If you're not at an intersection, look at the slot ahead
        car = ...
          obj.road.slots{obj.roadDirection}{obj.roadSlot+1,obj.roadLane};
      end
    end
    
    function car = car_behind(obj)
      % If you are in the first slot, ie behind you in the intersection
      if obj.roadSlot == 1
        car = {};
      else % If you're not in the first slot, look at the slot behind
        car = ...
          obj.road.slots{obj.roadDirection}{obj.roadSlot-1,obj.roadLane};
      end
    end
    
    function car = car_to_left(obj)
      if obj.in_leftmost_lane() 
        if obj.road.nLanes(obj.otherDirection) == 0
          car = {}; % No lanes to left, return empty value
        else
          car = obj.road.slots{obj.otherDirection}...
            {obj.otherSlot, obj.road.nLanes(obj.otherDirection)};
        end
      else
        car = obj.road.slots{obj.roadDirection}...
          {obj.roadSlot, obj.roadLane+1};
      end
    end
    
    function car = car_to_right(obj)
      if obj.in_rightmost_lane() 
        car = {}; % No lanes to left, return empty value
      else
        car = obj.road.slots{obj.roadDirection}...
          {obj.roadSlot, obj.roadLane-1};
      end
    end
    
    function bool = in_leftmost_lane(obj)
      bool = (obj.roadLane == obj.road.nLanes(obj.roadDirection));
    end
    
    function bool = in_rightmost_lane(obj)
      bool = (obj.roadLane == 1);
    end
        
    function success = move_forward(obj)
      success = false;
      % If at an intersection, call decision funciton to determine where to
      % go, and move there if a slot is open
      intersection = obj.at_intersection(); % Get intersection
      if ~isempty(intersection)
        next_road = obj.choose_next_road(intersection);
        
        free = cellfun(@isempty, intersection.get_exit_slots(next_road));
        if any(free)
          % Remove this car from its current slot
          obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane}...
            = [];
          % And add it to the next slot
          obj.road = next_road;
          obj.roadSlot = 1;
          obj.roadLane = find(free,1);
          obj.roadDirection = obj.road.get_direction(intersection);
          obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane}...
            = obj;
          obj.lastActionTime = obj.time;
          success = true;
        end
      else
        slot = ...
          obj.road.slots{obj.roadDirection}{obj.roadSlot+1, obj.roadLane};
        if isempty(slot)
          % Remove the car from the current slot
          obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane}...
            = [];
          % And add it to the next slot
          obj.roadSlot = obj.roadSlot + 1;
          obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane}...
            = obj;
          obj.lastActionTime = obj.time;
          success = true;
        end
      end
    end
    
%     function success = pull_over(obj)
%       % Not implemented
%     end
    
    function success = change_lane_left(obj)
      if obj.in_leftmost_lane()
        error('In leftmost lane, cannot change lane left.')
      end
      success = false;
      if isempty(obj.car_to_left())
        obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane} = [];
        obj.roadLane = obj.roadLane + 1;
        obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane} ...
          = obj;
        obj.lastActionTime = obj.time;
        success = true;
      end
    end
    
    function success = change_lane_right(obj)
      if obj.in_rightmost_lane()
        error('In rightmost lane, cannot change lane right.')
      end
      success = false;
      if isempty(obj.car_to_right())
        obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane} = [];
        obj.roadLane = obj.roadLane - 1;
        obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane} ...
          = obj;
        obj.lastActionTime = obj.time;
        success = true;
      end
    end
    
    function success = u_turn(obj)
      if obj.road.nLanes(obj.otherDirection) == 0
        error('Cannot perform a u-turn on a one-way street.')
      end
      success = false;
      if obj.in_leftmost_lane()
        if isempty(obj.car_to_left())
         obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane} ...
           = [];
         obj.roadLane = obj.road.nLanes(obj.otherDirection);
         obj.roadDirection = obj.otherDirection;
         obj.roadSlot = obj.otherSlot;
         obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane} ...
           = obj;
         obj.lastActionTime = obj.time;
         success = true;
        end
      else
        obj.change_lane_left()
        obj.lastActionTime = obj.time;
      end
    end
    
%     function success = drive_on_shoulder(obj)
%       % Not implemented
%     end
    
    function [val, t] = get_history(obj)
      val = obj.pos_history.get();
      t = obj.time_history.get();
    end

    function draw_poly(obj)
      if isempty(obj.points) || isempty(obj.color)
        error('%s %s', 'Properties "points" and "color" must', ...
          'be defined before calling draw_poly().')
      end
      angle = atan2(obj.orientation(2), obj.orientation(1));
      p = obj.pos*ones(1,size(obj.points,2)) + ...
        general.R_2D(angle) * obj.points;
      if isempty(obj.plt)
        obj.plt = fill(p(1,:), p(2,:), obj.color);
      else
        set(obj.plt, 'XData', p(1,:));
        set(obj.plt, 'YData', p(2,:));
      end
    end
    
    function draw_simple(obj)
      if isempty(obj.points) || isempty(obj.color)
        error('%s %s', 'Properties "points" and "color" must', ...
          'be defined before calling draw_poly().')
      end
      if isempty(obj.plt_simple)
        obj.plt_simple = plot(obj.pos(1), obj.pos(2), 'o', ...
          'Color', obj.color, 'MarkerFaceColor', obj.color, ...
          'MarkerSize', obj.markerSize);
      else
        set(obj.plt_simple, 'XData', obj.pos(1));
        set(obj.plt_simple, 'YData', obj.pos(2));
      end
    end
    
    function delete(obj)
      obj.RN = [];
      if isvalid(obj.road)
        obj.road.slots{obj.roadDirection}{obj.roadSlot, obj.roadLane} = [];
      end
      obj.road = [];
      obj.actionList = [];
    end
  end
  
  methods (Sealed)
    function step(obj, time)
      obj.time = time;
      obj.action()
      if obj.lastActionTime == obj.time
        obj.pos_history.add(obj.pos);
        obj.time_history.add(obj.time);
        obj.actionList.add(obj.time + obj.waitTime, obj);
      else
        obj.actionList.add(obj.time + 1, obj);
      end
    end
  end
end

