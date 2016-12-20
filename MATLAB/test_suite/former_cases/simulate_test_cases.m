%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Authors: Andrew Winn, Sumit Mukherjee, Soumya Chakraborty
%
% Description: This script runs the MATLAB simulation for "Multiple Agent
% Pursuit in an Urban Environment" for a variety of parameters, and saves
% the resulting data.
%
% Does not plot results or save video.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Add Utility Function Path
addpath '../utils'
addpath '../'
javaaddpath('../')

%% Clean Up
clean_up % Convenience script, needs to be changed if object vars change

%% Parameters
% Define default parameters, may be changed during iterations below
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

% Simulation parameters
maxIter = 100000;
nTrials = 10;

% File Parameters
filename_prefix = 'pursuers_cars_algs';
filename = [filename_prefix '__' datestr(now,'yyyy-mm-dd__HH-MM-SS')];

%% Create Objects
RN = RoadNetwork();
RN.CreateGrid(nBlocksWide, nBlocksLong, bat_time, ...
  'BlockLength', blockLength, 'LaneWidth', laneWidth, ...
  'ShoulderWidth', shoulderWidth, 'SpeedLimit', speedLimit);

sensors = [RN.intersections.sensors];
for s = 1:numel(sensors)
  sensors(s).ID = s;
end

% Create Evader
[road, slot, lane, direction] = RN.get_random_empty_slot();
evader = Evader(RN, road, slot, lane, direction, evader_time);

% Prepare Pursuers cell array
pursuers = cell(0); % Create dynamically, since their numbers change

% Prepare Cars cell array
cars = cell(0); % Create dynamically, since their numbers change

% Create Action List
actionList = PriorityQueue(2000);


%% Setup for loops for parameter variation
vAlgs = [1 2];
vNPursuers = (3:12);
vNCars = (0:2:18)*100;


%% Run Simulation
% Preallocate results struct
nRuns = length(vAlgs) * length(vNPursuers) * length(vNCars) * nTrials;
results(nRuns).trial = nTrials;
lastrun = '';

run = 0;
for alg = vAlgs;
for nPursuers = vNPursuers
for nCars = vNCars
for trial = 1:nTrials
run = run + 1; % Counter of each run
fprintf('Run: %d\n', run);

%% Setup cars
% Remove extra cars
if length(cars) > nCars
  for i = nCars+1:length(cars)
    cars{i}.delete();
  end
  cars = cars(1:nCars);
end
% Reset existing cars
for i = 1:length(cars)
  [road, slot, lane, direction] = RN.get_random_empty_slot();
  randomIntersection = RN.intersections(randi(numel(RN.intersections)));
  cars{i}.reset(road, slot, lane, direction, randomIntersection);
end
% Add missing cars
nNewCars = nCars - length(cars);
if nNewCars > 0
  cars_to_add = cell(1, nNewCars);
  for i = 1:nNewCars
    [road, slot, lane, direction] = RN.get_random_empty_slot();
    randomIntersection = RN.intersections(randi(numel(RN.intersections)));
    cars_to_add{i} = Car(RN, road, slot, lane, direction, ...
      car_time, randomIntersection);
  end
  cars = [cars cars_to_add]; %#ok<AGROW>
end

%% Setup Pursuers
% Remove extra pursuers
if length(pursuers) > nPursuers
  for i = nPursuers+1:length(pursuers)
    pursuers{i}.delete();
    pursuers = pursuers(1:nPursuers);
  end
end
% Reset existing pursuers
for i = 1:length(pursuers)
  [road, slot, lane, direction] = RN.get_random_empty_slot();
  pursuers{i}.reset(road, slot, lane, direction);
  pursuers{i}.algorithm = alg;
end
% Add missing pursuers
nNewPursuers = nPursuers - length(pursuers);
if nNewPursuers > 0
  pursuers_to_add = cell(1, nNewPursuers);
  for i = 1:nNewPursuers
    [road, slot, lane, direction] = RN.get_random_empty_slot();
    pursuers_to_add{i} = Pursuer(RN, road, slot, lane, direction, ...
      pursuer_time, bat_time, i);
    pursuers_to_add{i}.algorithm = alg;
  end
  pursuers = [pursuers pursuers_to_add]; %#ok<AGROW>
end

p = [pursuers{:}];
pursuer_initial_dists = vec_norms(...
  [p.pos] - evader.pos*ones(1,nPursuers));

%% Reset Evader
[road, slot, lane, direction] = RN.get_random_empty_slot();
evader.reset(road, slot, lane, direction);

vehicles = [evader pursuers{:} cars{:}];

%% Reset sensors
for s = sensors
  s.reset();
  s.update_info(evader.nextIntersection.pos, 1);
end

%% Initialize ActionList to update everything at the first time step
actionList.clear();
for s = sensors
  s.actionList = actionList;
  actionList.add(1,s);
end
for v = vehicles(randperm(length(vehicles)))
  v.actionList = actionList;
  actionList.add(1,v);
end

%% Simulate the system
iter = 0;
while ~evader.is_pinned() && iter < maxIter
  iter = iter + 1;
  if mod(iter,1000) == 0
    fprintf('  Iter: %d\n', iter);
  end
  
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
end

%% Extract and record data
results(run).alg = alg;
results(run).nPursuers = nPursuers;
results(run).nCars = nCars;
results(run).trial = trial;
results(run).final_time = iter;
results(run).converged = evader.is_pinned();
results(run).pursuer_initial_dists = pursuer_initial_dists;
results(run).nTransmissions = [sensors.nTransmissions];
p = [pursuers{:}];
results(run).response_times = [p.response_time];
results(run).evader_pos = evader.pos;


% Save Intermediary results
save(filename, 'results');
% Create file whose filename displays progress
if ~isempty(lastrun)
  delete(lastrun);
end
lastrun = sprintf('run_%d_of_%d', run, nRuns);
f = fopen(lastrun, 'w+');
fclose(f);


end
end
end
end
