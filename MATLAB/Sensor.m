
classdef Sensor < handle
  %SENSOR Defines a sensor node and its communication protocols
  %   Detailed explanation goes here
  % TODO: If a node was the target location, but the information has gone
  % out of date, ping the neighbors for updated information
  % Fix node history
  
  properties
    pursuers = Pursuer.empty()
    bat_time
    % list of source nodes that have requested info from this node
    src_objs = Sensor.empty() 
    nRequests = 0;
    RN
    intersection
    time %counter which updates every time_slot
    lastRequestTime = 0
    actionList
    actionListItemsPos = 0 % Used by the actionList for efficiency
    neighbors
    request %main checks every time slot if request of any sensor is 1 then it broadcasts to its neighbour
    request_src = 0
    request_time
    pos
    time_last_update %when was batman last spotted at the intersection.
    last_head_update %which intersection was batman last headed to.
    plt % Stores the plot handle of the sensor
    ID
    node_history = {}
    nTransmissions = 0% Number of transmissions sent
  end
  
  methods
    % Consturctor
    function obj = Sensor(RN, intersection,valid_time,varargin)
      % Handle optional parameters   % ... next line writing.
      %       [] = ...
      %         optionalparams(varargin ...
      %         ); %need to change connectivity....
      %
      obj.RN = RN;
      obj.intersection = intersection;
      obj.pos = intersection.pos;
      obj.bat_time = valid_time;
      obj.time = 1;
      obj.request_time = [];
      obj.request = 0;
    end
    
    % This function prepares the same sensors to be used in another
    % simulation. Assumes RoadNetwork to be unchanged, and the intersection
    % is the same.
    function reset(obj)
      % if bat_time changes, this property needs to be reset manually
      obj.time = 1;
      obj.request_time = [];
      obj.request = 0;
      obj.pursuers = Pursuer.empty();
      obj.src_objs = Sensor.empty();
      obj.nRequests = 0;
      obj.lastRequestTime = 0;
      obj.request_src = 0;
      obj.node_history = {};
      obj.nTransmissions = 0;
    end
    
    function step(obj, time)
      obj.time = time;
      % Iterate through all requests
      if obj.nRequests > 0
        for i = 1:obj.nRequests
          % Only handle requests from previous time steps
          if (obj.time >= obj.request_time(i) + 1)
            % If the current info is valid return it
            if(obj.time - obj.time_last_update <= obj.bat_time)
              % If the current node is the source of the request, return
              % the info to all pursuers who requested it
              if(obj == obj.src_objs(i))
                obj.request_src = 0;
                arrayfun(@(p) p.receive_data(obj.time_last_update,...
                  obj.last_head_update, obj.time), obj.pursuers)
                % Add these transmissions to the counter
                obj.nTransmissions = obj.nTransmissions + ...
                  length(obj.pursuers);
                obj.pursuers = Pursuer.empty();
              else
                % Otherwise, pass it to the next info towards the source
                obj.return_info(i);
              end
            else
              % Our info is out of date, so...
              if(obj == obj.src_objs(i))
                % If we are initiating the request, make a note of it
                obj.request_src = 1;
              end
              if obj.last_head_update == obj.pos
                % If our info is out of date, but we were expected to have
                % the evader pass by us at some point, then the evader must
                % have turned around, and one of our neighbors will have
                % caught this.  Update our info with all of our neighbors,
                % and reinitiate the request
                [max_time, max_idx] = max([obj.neighbors.time_last_update]);
                obj.handle_request(max_time, ...
                  obj.neighbors(max_idx).last_head_update, ...
                  obj.src_objs(i), obj.node_history{i}, obj.time);
              else
                % Our info is out dated, and we are not the last known
                % destindation, so forward towards the last known
                % destination.
                obj.fwd_req_call(i);
              end
            end
            
          end
        end
        % Keep requests made this time step
        to_keep = (obj.request_time == obj.time);
        obj.src_objs = obj.src_objs(to_keep);
        obj.node_history = obj.node_history(to_keep);
        obj.request_time = obj.request_time(to_keep);
        obj.nRequests = sum(to_keep);
      end
    end
    
    % Function call from Pursuer
    function service_request(obj, pursuer, time)
      % Add pursuer to list of pursuers to return info to
      obj.pursuers = [obj.pursuers pursuer];
      % If we are not awaiting info, initiate a new request, otherwise
      % there is no need to do anything
      if(obj.request_src == 0)
        obj.handle_request(pursuer.tbat, pursuer.bat_pos, obj, [], time);
        %fprintf('SERVICE, MYID: %d, YOURID: %d', obj.ID, pursuer.ID)
      end
    end
    
    function [] = fwd_req_call(obj, i) 
      %find which intersection neighbour is on the way to where batman was
      %last headed
      dists = vec_norms([obj.neighbors.pos] - ...
        obj.last_head_update*ones(1,size(obj.neighbors,2)));
      [~,idx] = min(dists);
      obj.neighbors(idx).handle_request(obj.time_last_update, ...
        obj.last_head_update, obj.src_objs(i), obj.node_history{i},...
        obj.time);
      obj.nTransmissions = obj.nTransmissions + 1;
      %fprintf('FORWARD, MYID: %d, YOURID: %d', obj.ID, obj.neighbors(idx).ID)
    end
    
    function [] = return_info(obj, i) %function to return the info to src one hop each time slot.
      dists = vec_norms([obj.neighbors.pos] - ...
        obj.src_objs(i).pos*ones(1,size(obj.neighbors,2)));
      [~,idx] = min(dists);
      obj.neighbors(idx).handle_request(obj.time_last_update, ...
        obj.last_head_update, obj.src_objs(i), obj.node_history{i}, ...
        obj.time);
      obj.nTransmissions = obj.nTransmissions + 1;
      %fprintf('RETURN, MYID: %d, YOURID: %d', obj.ID, obj.neighbors(idx).ID)
    end
    
    function handle_request(obj, time_last_update, last_head_update, ...
        src_obj, node_history, requestTime)
      if (obj.time_last_update < time_last_update) %update its data accordingly
        obj.time_last_update = time_last_update;
        obj.last_head_update = last_head_update;
      end
      obj.src_objs = [obj.src_objs src_obj]; %storing the src node info.
      obj.request_time = [obj.request_time requestTime];
      node_history = [node_history obj.ID];
      obj.node_history = [obj.node_history {node_history}];
      obj.nRequests = obj.nRequests + 1;
      if requestTime > obj.lastRequestTime
        obj.lastRequestTime = requestTime;
        obj.actionList.add(requestTime + 1, obj);
      end
      %obj.ID
    end
    
    function update_info(obj, head_update, time)
      obj.last_head_update = head_update;
      obj.time_last_update = time;
    end
    
    function []=draw(obj,isSimple)
      if isSimple
        if isempty(obj.plt)
          plot(obj.pos(1),obj.pos(2),'s', 'MarkerFaceColor', 'g');
        end
        if obj.request == 0
          set(obj.plt, 'MarkerFaceColor', 'g')
        else
          set(obj.plt, 'MarkerFaceColor', 'r');
        end
      else
        if isempty(obj.plt)
          p = obj.pos*ones(1,4) + [-1 -1 1 1; 1 -1 -1 1];
          fill(p(1,:),p(2,:),'g');
        end
        if obj.request == 0
          set(obj.plt, 'FaceColor', 'g')
        else
          set(obj.plt, 'FaceColor', 'r');
        end
      end
    end
    
    function delete(objs)
      for obj = objs
        for p = 1:length(obj.pursuers)
          if isvalid(obj.pursuers(p))
            obj.pursuers(p).sensor = [];
          end
        end
        obj.pursuers = [];
        if isvalid(obj.intersection)
          obj.intersection.sensors = [];
        end
        obj.intersection = [];
        obj.neighbors(obj.neighbors == obj) = [];
        obj.neighbors = [];
        obj.actionList = [];
      end
    end
    %This following function will return the information stored within the
    %range of batman including the present congestion information and which
    %pursuers are in the range. 
    function [congestion_info,pursuers_inrange]= get_rangeinfo()
    end
  end
end

