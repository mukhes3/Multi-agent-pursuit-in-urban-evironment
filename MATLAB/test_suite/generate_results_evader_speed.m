for algorithm = 1:2
  
  %% Analyze data
  r = total_results([total_results.alg] == algorithm);
  nPursuers_vars = unique([r.nPursuers]);
  nEvaderTime_vars = unique([r.evader_time]);
  
  % Generate data as a results of nPursuers and nCars
  % Initialize arrays
  npv = length(nPursuers_vars);
  netv = length(nEvaderTime_vars);
  
  plots(1).title = 'Percent of Trials Converged';
  plots(2).title = 'Time Steps until Convergence';
  
  [plots.data] = deal(zeros(npv, netv));
  % Populate arrays with data
  for p = 1:npv
    for et = 1:netv
      evader_time = nEvaderTime_vars(et);
      nPursuers = nPursuers_vars(p);
      subset = ([r.nPursuers] == nPursuers & [r.evader_time] == evader_time);
      nTrials = sum(subset);
      s = r(subset);
      
      plots(1).data(p,et) = mean([s.converged]);
      plots(2).data(p,et) = mean([s([s.converged]).final_time]);
    end
  end
  
  %% Plot and save results
  e2p_rat = 15./nEvaderTime_vars;
  [X,Y] = meshgrid(e2p_rat, nPursuers_vars);
  maxPos = [max(e2p_rat), max(nPursuers_vars)];
  for i = 1:length(plots)
    p = plots(i);
    p.fig = figure();
    p.plt = surf(X,Y,p.data);
    title(p.title);
    ylabel('Number of Pursuers')
    xlabel('Ratio of Evaders Speed to Pursuers Speed')
    axis tight
    if any(i == [2])
      cp = campos; campos([-cp(1:2) + maxPos, cp(3)]);
    end
    filename = sprintf('A%d_evaderspeed_%s',algorithm, strrep(p.title,' ','_'));
    saveas(p.fig, ['plots/' filename], 'epsc');
    saveas(p.fig, ['plots/' filename], 'png');
  end
  
end