      function temp = closeby(pos,posref,bat_rad) 
%     This function returns 1 if the pursuer is within a certain number of
%     blocks from batman. Else it returns 0. 
      
      if abs(pos(1)-posref(1))<=bat_rad && abs(pos(2)-posref(2))<=bat_rad
              temp=1;
          else
              temp=0;
      end
          
          