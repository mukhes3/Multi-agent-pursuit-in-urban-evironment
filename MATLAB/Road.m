classdef Road < handle
  %ROAD Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    speedLimit
    roadColor

    shoulderWidth
    laneWidth
    nLanes = zeros(2,1); % Two element vector:
    %   element one: Number of lanes connecting intersection 1 to 2
    %   element two: Number of lanes connecting intersection 2 to 1
    width
    % Vector of intersection endpoints
    intersections = Intersection.empty() 
    maxCarLength  % Determines the size of each slot
    roadLength
    nSlots % Number of lengthwise positions a car can occupy on the road
    slotPos % Location of the center of each slot
    orientation % Angle from intersection 1 to intersection 2 in radians
    points  % Corner points used for plotting

    slots  % Cell array of two cell arrays of Vehicles. represents the
           % positions a car can occupy;
           % contains an empty car element if none is there
           % sizes: slots{1}: {nSlots x nLanes(1)},
           %        slots{2}: {nSltos x nLanes(2)}
  end
  
  methods
    % Constructor
    function obj = Road(intersection1, intersection2, varargin)
      % No parameters -> default construction, ie do nothing. Otherwise,
      % set the appropriate paraeters
      if nargin > 0
        obj.initialize(intersection1, intersection2, varargin{:});
      end
    end
    
    function initialize(obj, intersection1, intersection2, varargin)
      % Handle optional parameters
      [obj.nLanes(1), obj.nLanes(2), obj.laneWidth, obj.shoulderWidth, ...
        obj.speedLimit, obj.maxCarLength, obj.roadColor] = ...
        optionalparams(varargin, ...
        'NumberOfForwardLanes', 1,...
        'NumberOfBackwardLanes', 1,...
        'LaneWidth', 3,...
        'ShoulderWidth', 1.5,...
        'SpeedLimit', 50,...
        'MaxCarLength', 4,...
        'RoadColor', [0.2 0.2 0.3]);
      
      % Determine width
      obj.width = sum(obj.nLanes)*obj.laneWidth + 2*obj.shoulderWidth;
      
      % Get intersections at each end set up
      obj.intersections(1,1) = intersection1;
      obj.intersections(2,1) = intersection2;
      obj.intersections(1).add_road(obj)
      obj.intersections(2).add_road(obj)
      obj.orientation = normc(intersection2.pos - intersection1.pos);
      obj.points = ...
        [obj.intersections(1).leftpoints(:,end),...
        obj.intersections(1).rightpoints(:,end),...
        obj.intersections(2).leftpoints(:,end),...
        obj.intersections(2).rightpoints(:,end)];
      
      % Set up slots
      obj.roadLength = norm(obj.points(:,1) - obj.points(:,4));
      obj.nSlots = floor(obj.roadLength/obj.maxCarLength);
      obj.slots = {cell(obj.nSlots, obj.nLanes(1)); ...
        cell(obj.nSlots, obj.nLanes(2))};
      
      % Determine positions of the center of each slot
      % Rightmost lane is the first lane, increases toward center of road
      n_lanes = sum(obj.nLanes); % total # of lanes in both directions
      % Get corner points of each lane at the connection to intersecion 1
      A = obj.intersections(1).rightpoints(:,end)*ones(1,n_lanes+1) + ...
        obj.intersections(1).neighbor_v_perp{end} * ...
        (obj.shoulderWidth + (0:n_lanes)*obj.laneWidth);
      % Get the midpoints of each lane at the connection to intersection 1
      A = 0.5*(A(:,1:end-1) + A(:,2:end));
      A = A(:); % Stack midpoints into vector
      % Get corner points of each lane at the connection to intersecion 1
      B = obj.intersections(2).leftpoints(:,end)*ones(1,n_lanes+1) - ...
        obj.intersections(2).neighbor_v_perp{end} * ...
        (obj.shoulderWidth + (0:n_lanes)*obj.laneWidth);
      % Get the midpoints of each lane at the connection to intersection 1
      B = 0.5*(B(:,1:end-1) + B(:,2:end));
      B = B(:); % Stack midpoints into vector
      % Interpolate between two end to get edges of slots
      C = A*ones(1,obj.nSlots+1) + (B - A)*(0:obj.nSlots)/obj.nSlots;
      % Get midpoints of slots
      C = 0.5*(C(:,1:end-1) + C(:,2:end));
      % Convert into the desired form
      C = mat2cell(C, 2*ones(n_lanes,1), ones(obj.nSlots,1))';
      obj.slotPos = {C(:,1:obj.nLanes(1));...
        rot90(C(:,end-obj.nLanes(2)+1:end), 2)};
    end
    
    function bool = has_a(obj, classname, direction)
      if nargin < 3
        direction = 1:2;
      end
      bool = ...
        any(any(cellfun(@(car) isa(car, classname), [obj.slots{direction}])));
    end
    
    function direction = get_direction(obj, intersection)
      direction = find(obj.intersections == intersection);
      if length(direction) ~= 1
        error('Input "Intersection" must be found only once in road.intersections');
      end
    end
    
    function draw(obj)
      % Fill background
      fill(obj.points(1,:), obj.points(2,:), obj.roadColor)
      
      % Generate lines on the roads. We do this by interpolating the end
      % points along the intersection edges of the roads
      
      % Generate Shoulder Lines
      frac = [obj.shoulderWidth, obj.width-obj.shoulderWidth] / obj.width;
      % Calcualte end points
      ep = obj.get_endpoints(frac);
      % Plot points as a white line
      plot(squeeze(ep(1,:,:))', squeeze(ep(2,:,:))', 'w-')
      
      % Generate Double Yellow Lines
      if all(obj.nLanes ~= 0)
        frac = ...
          (obj.nLanes(2)*obj.laneWidth + obj.shoulderWidth + [-0.2 0.2])...
          / obj.width;
        % Calcualte end points
        ep = obj.get_endpoints(frac);
        % Plot points as a white line
        plot(squeeze(ep(1,:,:))', squeeze(ep(2,:,:))', 'y-')
      end
      
      % Generate Backward Lane Separators
      frac = ...
        ((1:obj.nLanes(2)-1)*obj.laneWidth + ...
        obj.shoulderWidth) / obj.width;
      % Calcualte end points
      ep = obj.get_endpoints(frac);
      
      % Plot points as a white line
      plot(squeeze(ep(1,:,:))', squeeze(ep(2,:,:))', 'w--')
      
      % Generate Forward Lane Separators
      frac = ...
        (obj.width - (1:obj.nLanes(1)-1)*obj.laneWidth - ...
        obj.shoulderWidth) / obj.width;
      % Calcualte end points
      ep = obj.get_endpoints(frac);
      % Plot points as a white line
      plot(squeeze(ep(1,:,:))', squeeze(ep(2,:,:))', 'w--')
      
      % Generate intersection lines
      frac1 = (obj.shoulderWidth + ...
        [0, obj.nLanes(2)*obj.laneWidth]) ...
        / obj.width;
      frac2 = (obj.width - obj.shoulderWidth - ...
        [0, obj.nLanes(1)*obj.laneWidth]) ...
        / obj.width;
      % Calcualte end points
      ep = obj.get_endpoints(frac1, frac2);
      % Plot Intersection Lines
      % Note that there is no transpose, since these lines cross the road
      % rather than run parallel to it
      plot(squeeze(ep(1,:,:)), squeeze(ep(2,:,:)), 'w-');
    end
    
    function draw_simple(obj)
      p = [obj.intersections.pos];
      plot(p(1,:), p(2,:), '-', 'Color', obj.roadColor)
    end
    
    function delete(obj)
      for i = 1:length(obj.intersections)
        if isvalid(obj.intersections(i))
          obj.intersections(i).roads(obj.intersections(i).roads == obj) ...
            = [];
        end
      end
      obj.intersections = [];
      for i = 1:numel(obj.slots{1})
        if isa(obj.slots{1}{i}, 'Vehicle') && isvalid(obj.slots{1}{i})
          obj.slots{1}{i}.road = [];
        end
      end
      for i = 1:numel(obj.slots{2})
        if isa(obj.slots{1}{i}, 'Vehicle') && isvalid(obj.slots{2}{i})
          obj.slots{2}{i}.road = [];
        end
      end
      obj.slots = {};
    end
  end
  
  methods (Access = private)
    function ep = get_endpoints(obj, frac1, frac2)
      % Returns a 3D array that contains endpoints to lines that traverse
      % the length of the road, whose endpoints are given as fractions
      % along the road edges. The form of ep is: 
      % ep(:,:,1) = [leftpoint1 leftpoint2]
      % ep(:,:,2) = [rightpoint1 rightpoint2]
      if nargin < 3
        frac2 = frac1;
      end
      ep = cat(3,...
        obj.points(:,1)*ones(size(frac1)) + ...
        (obj.points(:,2)-obj.points(:,1)) * frac1,...
        obj.points(:,4)*ones(size(frac2)) + ...
        (obj.points(:,3)-obj.points(:,4)) * frac2);
    end
  end
end

