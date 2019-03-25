
%Euclidean distance from measurement point to true point with timestamps
%  


function d = min_distance_to_time(pt,truePath, time, trueTimes)
    
    [index,turnFlag] = find_time_index(time,trueTimes);
    if(turnFlag==0)
        deltaT = trueTimes(index)-trueTimes(index-1);
        estPosX = (truePath(index,1)-truePath(index-1,1))*(time/deltaT);
        estPosY = (truePath(index,2)-truePath(index-1,2))*(time/deltaT);
        
        d  = sqrt((estPosX-pt(1)).^2 + (estPosY-pt(2)).^2);
    else
        d = -1;
    end
    
end

