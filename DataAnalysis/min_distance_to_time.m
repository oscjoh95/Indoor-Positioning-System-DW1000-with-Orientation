
%Euclidean distance from measurement point to true point with timestamps
%  


function d = min_distance_to_time(pt,truePath, time, trueTimes)
    [index,turnFlag] = find_time_index(time,trueTimes);
    if(turnFlag==0)
        deltaT = trueTimes(index*2-2)-trueTimes(index*2-3);
        deltaX = (truePath(index,1)-truePath(index-1,1))*((time-trueTimes(index*2-3))/deltaT);
        deltaY = (truePath(index,2)-truePath(index-1,2))*((time-trueTimes(index*2-3))/deltaT);
        estPosX = truePath(index-1,1) + deltaX;
        estPosY = truePath(index-1,2) + deltaY;
        d  = sqrt((estPosX-pt(1)).^2 + (estPosY-pt(2)).^2);
    else
        d = -1;
    end
    
end

