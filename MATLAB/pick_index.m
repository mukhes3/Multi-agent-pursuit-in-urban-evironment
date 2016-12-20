function Index=pick_index(present,destin,congestion)
diff=destin-present;
% congestion matrix convention 
% 1) Right
% 2) Up 
% 3) Left 
% 4) Down 

if diff(1) <= 0
%     This means that the pursuer has to go down 
      congestion(2)=inf;
else 
    congestion(4)=inf;
end

if diff(2) <=0
    % This means that the pursuer has to go left
    congestion(1)=inf;
else
    congestion(3)=inf;
end
[minm,I]=min(congestion);

if I==1
      Index=[present(1),present(2)+1];
end
if I==2
      Index=[present(1)+1,present(2)];
end
if I==3
      Index=[present(1),present(2)-1];
end
if I==4
      Index=[present(1)-1,present(2)];
end
end
