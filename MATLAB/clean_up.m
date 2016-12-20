close all;
if exist('vehicles','var'); 
  for v = vehicles; 
    if isvalid(v)
      v.delete(); 
    end
  end
end
if exist('sensors','var'); 
  if isvalid(sensors)
    sensors.delete(); 
  end
end
if exist('RN','var'); if isvalid(RN) delete(RN); end; end;
if exist('vid','var'); if isvalid(vid); close(vid); end; end;
if exist('actionList','var'); 
  if isvalid(actionList); 
    delete(actionList); 
  end
end
clear classes;