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