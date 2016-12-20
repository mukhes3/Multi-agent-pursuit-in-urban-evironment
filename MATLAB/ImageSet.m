classdef ImageSet < handle
  %IMAGESET Generates and stores a set of rotations of an image
  %   Detailed explanation goes here
  
  properties(SetAccess = private)
    im = {};          % Cell array of rotated images
    alpha = {};       % Cell array of alpha values
    rotationAngle;    % Spacing between rotations in radians
    rotationAngleDeg; % Spacing between rotations in degrees
    nRotations;       % Number of rotations
  end
  
  methods
    % Constructor
    function obj = ImageSet(pic, nRotations, varargin)
      % pic - image to rotate and store
      
      % If pic is a char, then it is a file name, otherwise, assume it is
      % an image
      if ischar(pic)
        % pic is a file name to load
        [pic, ~, imalpha] = imread(pic);
      else
        imalpha = ones(size(pic)); % Set default alpha values to opaque
      end
      
      % Handle optional parameters
      imalpha = optionalparams(varargin, ...
        'AlphaData', imalpha, @(a) isalpha(a,pic));
      
      obj.nRotations = nRotations;
      obj.rotationAngle = 2*pi/obj.nRotations;
      obj.rotationAngleDeg = 360/obj.nRotations;
      obj.im = cell(obj.nRotations,1);
      obj.alpha = cell(obj.nRotations,1);
      
      % Generate Rotations
      obj.im{1} = squarearray(pic);
      obj.alpha{1} = squarearray(imalpha);
      for i = 2:obj.nRotations
        obj.im{i} = ...
          imrotate(obj.im{1}, -(i-1)*obj.rotationAngleDeg, 'bilinear');
        obj.alpha{i} = ...
          imrotate(obj.alpha{1}, -(i-1)*obj.rotationAngleDeg, 'bilinear');
      end
    end
    
  end
  
end

