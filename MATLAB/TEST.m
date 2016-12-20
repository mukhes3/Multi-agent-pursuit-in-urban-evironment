close all;
clear classes; 
addpath 'utils'
RN = RoadNetwork(); 
RN.CreateGrid(2,2,'NumberOfForwardLanes', 2, 'NumberOfBackwardLanes', 3,...
  'IntersectionRadius', 15)
figure(1); hold on; 
RN.draw()
c = Car(RN, RN.roads(1), 1, 1, 1, RN.intersections(3,3));
c.draw()
axis equal

try
  for i = 1:100
    tic
    c.step()
    c.draw()
    pause(0.5-toc)
    drawnow
  end
catch err
  delete(RN)
  delete(c)
  rethrow(err)
end