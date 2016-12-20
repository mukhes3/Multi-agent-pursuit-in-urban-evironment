function [ h ] = my_bar3( x, y, Z )
%MY_BAR3 Summary of this function goes here
%   Detailed explanation goes here
h = bar3(x,Z);
width = min(diff(y));
n = length(h);
zMax = max(max(Z));
zMin = min(min(Z));
for i = 1:n
  set(h(i), 'XData', width*(get(h(i),'XData') - i) + y(i));
  % Use a gradient of colors
%   r = (i-1)/(n-1)*ones(length(x),1);
%   if i == n
%     g = zeros(length(x), 1);
%   else
%     g = 1 - ((i-1)/(n-1):(n-i)/((n-1)*(length(x)-1)):1)';
%   end
%   b = (0:1/(length(x)-1):1)';
  r = max(0, min(1, 4*(Z(:,i)-zMin)/(zMax-zMin) - 2));
  g = max(0, min(1, -abs(4*(Z(:,i)-zMin)/(zMax-zMin) - 2) + 2));
  b = max(0, min(1, 4*(zMax - Z(:,i))/(zMax-zMin) - 2));
  o = ones(6,4);
  cdata = cat(3, kron(r,o), kron(g,o), kron(b,o));
  set(h(i), 'CData', cdata);
  set(h(i), 'CDataMapping', 'direct')
end
xlim([y(1)-0.4*width, y(end)+0.4*width]);
set(gca(),'XTick', y);
end

