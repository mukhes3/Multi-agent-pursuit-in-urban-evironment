function [ s ] = join( strs, delim )
%JOIN Catenates strings in STRS with DELIM placed in between each string
%   STRS - a cell array of strings to be catenated
%   DELIM - a string that will be catenated between each consecutive pair
%   of strings given in STRS

if nargin < 2
  % No delimiter given, set its default value to ', '
  delim = ', ';
end
  
sc = cell(1, 2*length(strs) - 1,1); % cell array for strs and delim interleaved
sc(1:2:end) = strs(:);
sc(2:2:end) = {delim};
s = [sc{:}];

end

