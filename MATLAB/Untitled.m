classdef Untitled < handle
  %UNTITLED Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    value
  end
  
  methods
    function obj = Untitled()
      obj.set_the_value(5);
    end
    
    function set_the_value(obj,val)
      obj.value = val;
    end
    
    function delete(obj)
      disp('DELETED')
    end
  end
  
end

