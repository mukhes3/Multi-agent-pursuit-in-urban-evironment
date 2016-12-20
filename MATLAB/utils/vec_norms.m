function [ out_mat ] = vec_norms( mat, norm_type )
% VEC_NORMS  Returns the norms of the column vectors of mat.
%    [out_mat] = VEC_NORMS(mat,norm_type) returns the row vector out_mat
%    whose values are the corresponding norm_type (1, 2, inf) norm of the
%    columns of mat.
%
%    [out_mat] = VEC_NORMS(mat) uses the 2 norm.

if nargin < 2
  norm_type = 2;
end

if norm_type == 1
  out_mat = sum(mat);
  
elseif norm_type == 2
   out_mat = sqrt(sum(bsxfun(@power,mat, 2)));
   
elseif norm_type == inf
  out_mat = max(mat);
  
else
  n_pts = size(mat,2);
  out_mat = zeros(1,n_pts);
  for i = 1:n_pts
    out_mat(i) = norm(mat(:,i), norm_type);
  end
end