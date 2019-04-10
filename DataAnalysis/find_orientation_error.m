%Function calculates the orientation error in each point with regard to
%the true orientation in that point of time.
%
% oriError - Vector with the errors in orientation(Except during the 
%            turning phase)
% oriWithoutTurns - A vector with the orientation values(Except during the
%                   turning phase)
%
function oriError = find_orientation_error(orientation,trueOrientation, times, trueTimes)
    counter = 1;
    for(i = 1:length(orientation))
        [index,turnFlag] = find_time_index(times(i),trueTimes);
        if(turnFlag == 0)
            %oriWithoutTurns(counter) = orientation(i);
            oriError(counter) = trueOrientation(index-1)-orientation(i);
            counter = counter+1;
        end
    end 
    oriError = min_orient_error(oriError')';
end
