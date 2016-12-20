classdef DynArray < handle
  %DYNARRAY Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (SetAccess = private)
    len
    resizeFactor
    nDims
    last
    data
  end
  
  methods
    function obj = DynArray(data, varargin)
      [obj.len, obj.resizeFactor] = optionalparams(varargin, ...
        'InitialSize', 100, 'ResizeFactor', 2);
      [obj.nDims, obj.last] = size(data);
      obj.data = zeros(obj.nDims, obj.len);
      obj.data(:,1:obj.last) = data;
    end
    
    function add(obj, val)
      nNew = size(val, 2);
      if obj.last + nNew > obj.len
        obj.len = ceil(obj.resizeFactor * obj.len);
        temp = obj.data;
        obj.data = zeros(obj.nDims, obj.len);
        obj.data(:,1:obj.last) = temp;
      end
      insert_idx = obj.last + 1;
      obj.last = obj.last + nNew;
      obj.data(:,insert_idx:obj.last) = val;
    end
    
    function value = get(obj)
      value = obj.data(:,1:obj.last);
    end
  end
  
end

