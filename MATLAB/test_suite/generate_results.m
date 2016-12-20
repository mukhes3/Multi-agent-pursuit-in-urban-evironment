algorithm = 1;

%% Analyze data
r = total_results;
nPursuers_vars = unique([r.nPursuers]);
nCar_vars = unique([r.nCars]);

% Generate data as a results of nPursuers and nCars
% Initialize arrays
npv = length(nPursuers_vars);
ncv = length(nCar_vars);

plots(1).title = 'Percent of Trials Converged';
plots(2).title = 'Time Steps until Convergence';
plots(3).title = 'Total Number of Messages';
plots(4).title = 'Number of Messages per Time Slot';
plots(5).title = 'Max Messages Sent by a Sensor';
plots(6).title = 'Max Messages Sent per Time Slot';
plots(7).title = 'Idle Time Percentage of Sensors';
plots(8).title = 'Min Idle Time Percentage for a Sensor';
plots(9).title = 'Average Response Time';
plots(10).title = 'Worst Response Time';

[plots.data] = deal(zeros(npv, ncv));
% Populate arrays with data
for p = 1:npv
  for c = 1:ncv
    nCars = nCar_vars(c);
    nPursuers = nPursuers_vars(p);
    subset = ([r.nPursuers] == nPursuers & [r.nCars] == nCars);
    nTrials = sum(subset);
    s = r(subset);
    
    plots(1).data(p,c) = mean([s.converged]);
    plots(2).data(p,c) = mean([s([s.converged]).final_time]);
    
    total_transmissions = zeros(size(s));
    max_transmissions = zeros(size(s));
    for i=1:nTrials
      total_transmissions(i) = sum(s(i).nTransmissions);
      max_transmissions(i) = max(s(i).nTransmissions);
    end
    nSensors = length(s(1).nTransmissions);
    plots(3).data(p,c) = mean(total_transmissions);
    plots(4).data(p,c) = mean(total_transmissions./[s.final_time]);
    plots(5).data(p,c) = mean(max_transmissions);
    plots(6).data(p,c) = mean(max_transmissions./[s.final_time]);
    % plots(4) gives the number of messages in a time slot on average.
    % There are two sensors active per message, yielding the number of
    % sensors active on average per time slot. Dividing by the number of
    % sensors yields the average percentage of time a sensor is active.
    % One minus this value yields the percentage of time a sensor is idle.
    plots(7).data(p,c) = 1 - 2/nSensors*plots(4).data(p,c);
    plots(8).data(p,c) = 1 - 2*plots(6).data(p,c);
    plots(9).data(p,c) = mean([s.response_times]);
    max_response_time = zeros(size(s));
    for i = 1:nTrials
      max_response_time(i) = max(s(i).response_times);
    end
    plots(10).data(p,c) = mean(max_response_time(i));
  end
end

%% Plot and save results
[X,Y] = meshgrid(nCar_vars, nPursuers_vars);
maxPos = [max(nCar_vars), max(nPursuers_vars)];
for i = 1:length(plots)
  p = plots(i);
  p.fig = figure();
  p.plt = surf(X,Y,p.data);
  title(p.title);
  ylabel('Number of Pursuers')
  xlabel('Number of Cars')
  axis tight
  if any(i == [2 7 8])
    cp = campos; campos([-cp(1:2) + maxPos, cp(3)]);
  end
  filename = sprintf('A%d_%s',algorithm, strrep(p.title,' ','_'));
  saveas(p.fig, ['plots/' filename], 'epsc');
  saveas(p.fig, ['plots/' filename], 'png');
end
  



