% this function returns the array of distances from the present point of
% the mobile node to each of the sensors. 
function [norm_array]=cal_norm(xpos,ypos,matpos)
%should we make matpos global ? 
[rows, coloumns] = size(matpos);
temp=zeros(1,rows);
clear coloumns
for i=1:rows
    xdiff=xpos-matpos(i,1);
    ydiff=ypos-matpos(i,2);
    temp(i)=norm([xdiff ydiff]);
end
clear xdiff ydiff
norm_array=temp;