function [ array ] = squarearray( array, val )
%SQUAREARRAY makes ARRAY a square array by padding array with VAL
%      VAL is set to zero by default. if ARRAY is more than two dimensions,
%      it makes the array square with respect to the first two dimensions
if nargin < 2
  val = 0;
end

sz = size(array);
diff = abs(sz(1) - sz(2)); % Difference in dimension sizes

pre = zeros(size(sz)); % Padding in front of array in each dimension
post = pre;            % Padding in back of array in each dimension
% Pad is smaller dimension by half the difference before an after
% If the difference is odd, pad the back by the extra row
pre(1:2) = (sz(1:2) < sz(2:-1:1)) * floor(diff/2);
post(1:2) = (sz(1:2) < sz(2:-1:1)) * ceil(diff/2);

array = padarray(array, pre, val, 'pre');
array = padarray(array, post, val, 'post');


end

