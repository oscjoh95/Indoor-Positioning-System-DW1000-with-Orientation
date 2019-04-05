%Finds the index corresponding to within which span the point resides
%
%The index refers to the largest boundery point in truePath
%Eg. If truePath is [0,0,0; 0,2,0] and index is 2, it means that the point
%is between [0,0,0] and [0,2,0]
function [index,turnFlag] = find_time_index(time,trueTimes)
    i=2;
    index = 2;
    turnFlag = 0;
    trueTimes = trueTimes-trueTimes(1);
    while( time>trueTimes(i))
        if time<trueTimes(i+1)
            turnFlag = 1;
            time = 0;
        end
        index = index+1;
        i=i+2;
    end
end