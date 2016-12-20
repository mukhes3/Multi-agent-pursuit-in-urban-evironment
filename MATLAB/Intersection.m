classdef Intersection < handle
  %INTERSECTION Defines an intersection in RoadNetwork
  %   Detailed explanation goes here
  
  properties
    dr        % Angle step size for plotting curves connecting roads
    roadColor % Color used to draw road
  end
  
  properties
    radius % corresponds to size of intersection
    pos % 2x1 vector of the location of the intersection
    neighbors = Intersection.empty(); % vector of neighboring intersections
    neighbor_v       % Cell array of vectors from this to each neighbor
    neighbor_v_perp % Cell array of perpendiculars to neighbor_v
    roads = Road.empty(); % vector of intersecting roads
    exitIndex % index of road.slots that contains the lanes of that road 
               % that are leaving that intersection
    leftpoints  % used for plotting
    rightpoints % used for plotting

    sensors = [];%Sensor.empty(); % vector of sensors at an intersection
  end
  
  methods
    % Constructor
    function obj = Intersection(pos, varargin)
      % No parameters -> default construction, ie do nothing. Otherwise,
      % set the appropriate paraeters
      if nargin > 0
        obj.initialize(pos, varargin{:});
      end
    end
    
    % Initialize values for a default instatiation
    function initialize(obj, pos, varargin)
      % Handle optional parameters
      [obj.radius, obj.dr, obj.roadColor] = ...
        optionalparams(varargin, ...
        'Radius', 12,...
        'AngleStepSize', pi/12,...
        'RoadColor', [0.2 0.2 0.3]);
      obj.pos = pos;
    end
    
    % Set functions
    function set.pos(obj, pos)
      if ~isvector(pos) || length(pos) ~= 2
        error('Input "pos" must be a vector of length 2');
      end
      if size(pos,1) == 1
        pos = pos';
      end
      obj.pos = pos;
    end
    
    % Get functions
    function exitSlots = get_exit_slots(obj, road)
      the_road = (obj.roads == road);
      exitSlots = obj.roads(the_road).slots{obj.exitIndex(the_road)}(1,:);
    end
    
    function add_sensor(obj, sensor)
      % Since obj.sensors is typed, will return error if sensor is not of
      % class Sensor
      obj.sensors = [obj.sensors sensor];
    end
    
    function draw(obj)
      % # of neighbors
      nn = length(obj.neighbors);
      
      % Preallocate array of points to plot for intersection
      points = zeros(2, pi/obj.dr*nn);
      
      % Get indexes sorted by angle of neighbor
      k = [(1:nn)' cellfun(@(x) atan2(x(2),x(1)), obj.neighbor_v)'];
      k = sortrows(k,2);
      k = k(:,1);
      
      idx = 1;
      for n = 1:nn
        % use MOD to map 0 to nn, otherwise change nothing
        p1 = obj.leftpoints(:,k(mod(n-2,nn)+1));
        p2 = obj.rightpoints(:,k(n));
        v1 = obj.neighbor_v{k(mod(n-2,nn)+1)};
        v2 = obj.neighbor_v{k(n)};
        % Check if roads are nearly opposite one another, and should be
        % connected by a line rather than an arc.
        if 1 - abs(v1'*v2) > 1e-3 % Not nearly colinear
          p = [v1';v2']\[v1'*p1; v2'*p2];
          th1 = atan2(p1(2)-p(2), p1(1) - p(1));
          th2 = atan2(p2(2)-p(2), p2(1) - p(1));
          % theta 2 must be less than theta 1
          th2 = th2 - 2*pi*fix((th2-th1)/pi); 
          np = floor(abs(th1 - th2)/obj.dr) + 2; % number of points in arc
          
          % Generate points on the arcs
          
          points(:,idx:idx+np-1) = [p*ones(1,np-1) + ...
            norm(p1-p)*[cos(th1:sign(th2-th1)*obj.dr:th2);
            sin(th1:sign(th2-th1)*obj.dr:th2)] p2];
        else
          np = 2;
          points(:,idx:idx+np-1) = [p1 p2];
        end
        idx = idx + np;
      end
      fill(points(1,1:idx-1), points(2,1:idx-1), obj.roadColor);
%       arrayfun(@(x) x.draw(), obj.sensors);
    end
    
    function congestion = get_congestion(obj)
      % Anonymous function to count the number of filled slots in a cell
      % array of car slots for a given direction of a road
      numFilledSlots = ...
        @(slots) sum(sum(cellfun(@(x) ~isempty(x), slots(:))));
      
      % Preallocate vector, and fill it with number of cars on each road in
      % the outgoing direction, in the order they are given by the
      % intersection(index).roads field.
      nRoads = length(obj.roads);
      congestion = zeros(nRoads,1);
      for i = 1:nRoads
        congestion(i) = ...
          numFilledSlots(obj.roads(i).slots{obj.exitIndex(i)});
      end
    end
    
    function delete(obj)
      if isa(obj.sensors, 'Sensor') && isvalid(obj.sensors); 
        obj.sensors.intersection = []; 
      end
      obj.sensors = [];
      obj.neighbors = [];
      for r = 1:length(obj.roads)
        if isvalid(obj.roads(r))
          obj.roads(r).intersections(obj.roads(r).intersections == obj) ...
            = [];
        end
      end
      obj.roads = [];
      obj.neighbors(obj.neighbors == obj) = [];
      obj.neighbors = [];
    end
  end
  
  methods (Access = ?Road)
    % Adds a new road into the intersection
    function add_road(obj, road)
      % Update the list of roads
      obj.roads = [obj.roads; road];
      whichInt = (road.intersections == obj);
      if sum(whichInt) ~= 1
        error('%s %s', 'Cannot add a road to an intersection unless',...
          'that intersection is defined as one of the road''s endpoints')
      end
      
      % Determine whether the first set of lanes are leaving the
      % intersection (if the current intersection is the first) or whether
      % the second set are leaving (the current intersection is the second)
      obj.exitIndex = [obj.exitIndex find(whichInt,1)];
        
      % At the endpoint intersection to the list of neighbors
      obj.neighbors = [obj.neighbors road.intersections(~whichInt)];
      
      % Generate required geometrical information regarding the new road
      obj.neighbor_v = [obj.neighbor_v ...
        {normc(obj.neighbors(end).pos - obj.pos)}];
      obj.neighbor_v_perp = [obj.neighbor_v_perp ...
        { [-obj.neighbor_v{end}(2); obj.neighbor_v{end}(1)] }  ];
      half_width = 0.5*road.width;
      obj.leftpoints = [obj.leftpoints, ...
        obj.pos + half_width .* obj.neighbor_v_perp{end} + ...
        sqrt(obj.radius^2 - half_width.^2) .* obj.neighbor_v{end}];
      obj.rightpoints = [obj.rightpoints, ...
        obj.pos - half_width .* obj.neighbor_v_perp{end} + ...
        sqrt(obj.radius^2 - half_width.^2) .* obj.neighbor_v{end}];
    end
  end
end

