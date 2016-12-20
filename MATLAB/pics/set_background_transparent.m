% Not actually needed, more for learning about image formats. 
% Keeping this file for reference

pc = imread('police-car-top-view-th.png');
bg = 1 - (pc(:,:,1) ~= 255 & pc(:,:,2) ~= 255 & pc(:,:,3) ~= 255);

w = 3;
bgp = padarray(bg, [3,3], 1);
for xoff = 0:1
  yoff = 1 - xoff;
  for dir = -1:2:1
    for mag = w:-1:1
      xi = w + 1 + dir*xoff*(w+1-mag);
      yi = w + 1 + dir*yoff*(w+1-mag);
      bg = max(bg,mag/w*bgp(xi:end-2*w-1+xi,yi:end-2*w-1+yi));
    end
  end
end
bg = 1 - bg;

figure; hold on;
fill([0,0,120,120],[0,120,120,0],[0,1,0])
h=image(pc);
set(h, 'AlphaData', bg)
imsave(h)

%%
[pc,map,alpha] = imread('police-car-top-view-th.png');
figure; hold on;
fill([0,0,120,120],[0,120,120,0],[1,0,0])
h=image(pc);
set(h, 'AlphaData', alpha)