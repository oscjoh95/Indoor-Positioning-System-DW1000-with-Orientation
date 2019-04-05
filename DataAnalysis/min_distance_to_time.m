
%Euclidean distance from measurement point to true point with timestamps
%


function [distanceError, errorX,errorY] = min_distance_to_time(pt,truePath, time, trueTimes)
    [index,turnFlag] = find_time_index(time,trueTimes);
    if(turnFlag==0)
        deltaT = trueTimes(index*2-2)-trueTimes(index*2-3);
        timeFactor = ((time-trueTimes(index*2-3))/deltaT);
        deltaX = (truePath(index,1)-truePath(index-1,1))*timeFactor;
        deltaY = (truePath(index,2)-truePath(index-1,2))*timeFactor;
        estPosX = truePath(index-1,1) + deltaX;
        estPosY = truePath(index-1,2) + deltaY;
        distanceError  = sqrt((estPosX-pt(1)).^2 + (estPosY-pt(2)).^2);
        errorX = estPosX-pt(1);
        errorY = estPosY-pt(2);
    else
        distanceError = -1;
        
    end
    
end

