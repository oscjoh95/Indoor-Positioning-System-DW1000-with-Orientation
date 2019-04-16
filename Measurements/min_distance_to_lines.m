
%Euclidean distance from point to Line
%  
function d = min_distance_to_lines(pt, truePath)
    for i = 1:(length(truePath(:,1))-1)
        lines(i,:) = [linspace(truePath(i,1),truePath(i+1,1),1000),linspace(truePath(i,2),truePath(i+1,2),1000)];  
        distances(i,:) = sqrt((lines(i,1:1000)-pt(1)).^2 + (lines(i,1001:2000)-pt(2)).^2);
    end
        d=min(min(distances));
end

