%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Authors: Andrew Winn, Sumit Mukherjee, Soumya Chakraborty
%
% Description: This script runs the MATLAB simulation for "Multiple Agent
% Pursuit in an Urban Environment." 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Clean Up
clean_up % Convenience script, needs to be changed if object vars change

%% Add Utility Function Path
addpath 'utils'
javaaddpath('.')

%% Parameters
% Simulation Parameters
fps = 24;                 % Frames per second
Ts = 1/fps;               % Time step
SHOW_SIMULATION = true;
MAXIMIZE_FIGURE = false;%true;
SHOW_TOOLBAR = true;
DRAW_SIMPLE = true;
RECORD_GLOBAL_VIDEO = false;
RECORD_LOCAL_VIDEO = false; % Not yet implemented

% Road Network Parameters
nBlocksWide = 11;
nBlocksLong = 15;

blockLength = 50;         % m, Length of block in meters
nLanes = 2;               % Number of lanes per segment of road
laneWidth = 3;
shoulderWidth = 1.5;
speedLimit = 50;          % kph, metric system in use
garageDensity = 0.1;      % Percentage of blocks containing a garage
carGenerationRate = 1/5;  % cars/second rate at which cars leave a 
car_time = 25;
pursuer_time = 15;
evader_time = 15;
carLength = 4;
bat_time = evader_time * floor(blockLength/carLength);

% Car Parameters
nCars = 10;

% Pursuer Parameters
nPursuers = 5;

% Evader Parameters

% Sensor Parameters

% Video Parameters
video_save_folder = 'videos';
filename_prefix = 'DSSN_project';
FrameRate = 10;
Quality = 30;



%% Create Objects
RN = RoadNetwork();
RN.CreateGrid(nBlocksWide, nBlocksLong, bat_time, ...
  'BlockLength', blockLength, 'LaneWidth', laneWidth, ...
  'ShoulderWidth', shoulderWidth, 'SpeedLimit', speedLimit);

sensors = [RN.intersections.sensors];
for s = 1:numel(sensors)
  sensors(s).ID = s;
end

% nGarages = ceil(nBlocksWide*nBlocksLong*garageDensity);
% for i = nGarages:-1:1
%   garages(i) = Garage(RN, 'RandomGridBlock', true, ...
%     'CarGenerationRage', carGenerationRate);
% end

% Create Cars
cars = cell(1,nCars);%Car.empty();
for i = 1:nCars
  [road, slot, lane, direction] = RN.get_random_empty_slot();
  randomIntersection = RN.intersections(randi(numel(RN.intersections)));
  cars{i} = Car(RN, road, slot, lane, direction, car_time, ...
    randomIntersection);
end
cars = [cars{:}];

% Create Evader
[road, slot, lane, direction] = RN.get_random_empty_slot();
evader = Evader(RN, road, slot, lane, direction, evader_time);

% Create Pursuers
pursuers = cell(1,nPursuers);
for i = 1:nPursuers
  [road, slot, lane, direction] = RN.get_random_empty_slot();
  pursuers{i} = ...
    Pursuer(RN, road, slot, lane, direction, pursuer_time, bat_time, i);
  pursuers{i}.algorithm = 2; % path plan quick improved
  %pursuers{i}.color = [(nPursuers-i)/nPursuers,0,i/nPursuers];
end
pursuers = [pursuers{:}];

vehicles = [evader pursuers cars];

% Pick Leader
dists = vec_norms([pursuers.pos] - evader.pos*ones(1,length(pursuers)));
[~,idx] = min(dists);
leader = pursuers(idx);

if RECORD_GLOBAL_VIDEO
  filename = [filename_prefix '__' datestr(now,'yyyy-mm-dd__HH-MM-SS')];
  vid = VideoWriter([video_save_folder filesep filename], ...
    'Motion JPEG AVI');
  
  vid.FrameRate = FrameRate;
  vid.Quality = Quality;
end

% Initialize sensors to start with evader info (can implement search and
% broadcast later, if desired)
for s = sensors
  s.update_info(evader.nextIntersection.pos, 1);
end

%% Initialize Plot
if SHOW_SIMULATION || RECORD_GLOBAL_VIDEO 
  % Create figure to show simulation, make it full screen
  if SHOW_TOOLBAR; toolbar_op = 'auto'; else toolbar_op = 'none'; end
  if SHOW_SIMULATION; visible = 'on'; else visible = 'off'; end
  fig = figure('Toolbar', toolbar_op, 'Renderer', 'OpenGL', ...
    'Visible', visible);
  if MAXIMIZE_FIGURE; maxfig(fig,1); end;
  hold on;

  RN.draw(DRAW_SIMPLE);
  evader.draw(DRAW_SIMPLE)
  for p = pursuers %#ok<*UNRCH>
    p.draw(DRAW_SIMPLE)
  end
  for c = cars
    c.draw(DRAW_SIMPLE)
  end
    
  axis tight
  axis equal
  
  %
  %[pc, ~, alpha_dat] = imread('pics/police-car.png');
  %image('CData', pc, 'AlphaData', alpha_dat, 'XData', [-3,0], 'YData', [-6,-4]);
  
  drawnow;
  
  % Write Initial Frame
  if RECORD_GLOBAL_VIDEO
    open(vid)
    vid.writeVideo(getframe(get(fig,'Children')));
  end
end

%% Run Simulation

% Initialize ActionList to update everything at the first time step
actionList = PriorityQueue(length(sensors) + length(vehicles));
for s = sensors
  s.actionList = actionList;
  actionList.add(1,s);
end
for v = vehicles(randperm(length(vehicles)))
  v.actionList = actionList;
  actionList.add(1,v);
end

iter = 0;
while ~evader.is_pinned() && iter < 100000
  iter = iter + 1;
  
  % Examine objects ordered by the update time, and update if needed
  [updateTime, obj] = actionList.poll();
  while ~isempty(updateTime) && updateTime <= iter
    obj.step(iter);
    [updateTime, obj] = actionList.poll();
  end
  % add on the last object that does not yet need to be updated
  if ~isempty(updateTime)
    actionList.add(updateTime, obj);
  end
  
%   % Update each vehicle in a random order
%   for i = randperm(length(vehicles))
%     vehicles(i).step()
%   end
%   for s = sensors
%     s.step()
%   end
  
  % Only update plots every time the cars are expected to move
  if (SHOW_SIMULATION || RECORD_GLOBAL_VIDEO) && mod(iter,car_time) == 0
    % Update Vehicle images
    evader.draw(DRAW_SIMPLE)
    for p = pursuers %#ok<*UNRCH>
      p.draw(DRAW_SIMPLE)
    end
    for c = cars
      c.draw(DRAW_SIMPLE)
    end

    drawnow;

    % Write Intermediate Frames
    if RECORD_GLOBAL_VIDEO
      vid.writeVideo(getframe(get(fig,'Children')));
    end
  end
end

% Write Final Frame
if RECORD_GLOBAL_VIDEO
  vid.writeVideo(getframe(get(fig,'Children')));
end

%% Generate and Process Results
% Plot of Communication Intensity
figure(); hold on;
maxTrans = max([sensors.nTransmissions]);
for s = sensors
  pctTrans = s.nTransmissions/maxTrans;
  plot(s.pos(1), s.pos(2), 'o', ...
    'MarkerEdgeColor', [pctTrans, 0, 0], ...
    'MarkerFaceColor', [pctTrans, 0, 0], ...
    'MarkerSize', 9 * pctTrans + 1);
end
for p = pursuers
  [pts, ~] = p.get_history();
  plot(pts(1,:), pts(2,:), '-', 'Color', p.color)
end
pts = evader.get_history();
plot(pts(1,:), pts(2,:), '--', 'Color', evader.color, 'LineWidth', 2)



%% Clean Up
if RECORD_GLOBAL_VIDEO
  close(vid)
end

