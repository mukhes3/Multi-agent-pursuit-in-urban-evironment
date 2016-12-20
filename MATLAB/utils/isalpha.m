function [ valid ] = isalpha( alpha, pic )
%ISALPHA Raises an error if alpha is not a valid alpha array for pic

if (size(alpha) ~= size(pic) && length(alpha) ~= 1) || ~isnumeric(alpha)
  error('AlphaData is not of the appropriate form.')
else
  valid = true;
end


end

