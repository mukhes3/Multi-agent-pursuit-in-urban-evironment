classdef Garage < handle
  %GARAGE Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    roadNetwork;
    points;
    carGenerationRate; % cars/second (Poisson Dist) that leave the garage
    accessRoadIndex;
    color;
  end
  
  methods
    % Constructor
    function obj = Garage(roadNetwork, varargin)
      % Handle optional parameters
      [randomGridBlock, obj.carGenerationRate] = ...
        optionalparams(varargin,...
        'RandomGridBlock', false,...
        'CarGenerationRate', 1/5);
      
      obj.roadNetwork = roadNetwork;
      
    end
    
    
    function Draw(obj)
      fill(obj.points(1,:), obj.points(2,:), obj.color)
    end
    
    
    function run(obj, time)
      
    end
  end
  
end

