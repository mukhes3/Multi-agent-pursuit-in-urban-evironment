function isend=edge_detect(xpos,ypos)
global edge_matrix

[imax jmax]=size(edge_matrix);
clear jmax
temp=[xpos*ones(imax,1),ypos*ones(imax,1)];
temp2=temp==edge_matrix;
M=max(temp2);

if norm(M)>0
    isend=1;
else
    isend=0;
end
