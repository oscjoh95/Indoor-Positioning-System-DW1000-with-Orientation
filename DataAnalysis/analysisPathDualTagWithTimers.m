%%
%Authors:
%Lucas Wassénius
%Oscar Johansson
%
%Script for data analysis in positioning
%%
function analysisPathDualTagWithTimers(measurements,truePath,anchorPos,trueTimes)

    %Anchor positions[A0, A1, A2]
    anchorX = anchorPos(1,:);
    anchorY = anchorPos(2,:);

    %Fetch unfiltered measurements[X,Y]
    posFrontTag = measurements(:,1:2);
    posBackTag = measurements(:,3:4);

    %Fetch Filtered filtered measurements[X,Y]
    posFrontTagFiltered = measurements(:,5:6);
    posBackTagFiltered = measurements(:,7:8);
    
    %Fetch Measurement Timestamps
    posFrontTagFiltered = measurements(:,5:6);
    posBackTagFiltered = measurements(:,7:8);

    %Timers
    cumTime = measurements(:,9)./1000;
    for i = 1 : length(cumTime)-1
        deltaTime(i) = cumTime(i+1)-cumTime(i);
    end
        
    %Orientation
    for(i = 1:length(truePath(:,1))-1)
       trueOrientation(i)= atan2((truePath(i+1,2)-truePath(i,2)),(truePath(i+1,1)-truePath(i,1)));
    end
    orientation = atan2((posFrontTag(:,2)-posBackTag(:,2)),(posFrontTag(:,1)-posBackTag(:,1)));
    orientationFiltered = atan2((posFrontTagFiltered(:,2)-posBackTagFiltered(:,2)),(posFrontTagFiltered(:,1)-posBackTagFiltered(:,1)));

    %% Table of Error Measurements
    %Errors between measured position and true path
    loopCounter = 1;
    timeCounter = 1;
    while timeCounter <(length(measurements(:,1)))
        tempPos = [posFrontTag(i,1),posFrontTag(i,2),0];
        tempDist = min_distance_to_time(tempPos, truePath, cumTime(timeCounter), trueTimes);
        timeCounter=timeCounter+1;
        if tempDist >= 0
            distanceError(loopCounter) = tempDist;
            loopCounter = loopCounter +1 ;
        end
    end
    
    %Errors between measured position and true path (Filtered)
    loopCounter = 1;
    timeCounter = 1;
    while timeCounter <(length(measurements(:,1)))
        tempPos = [posFrontTagFiltered(i,1),posFrontTagFiltered(i,2),0];
        tempDist = min_distance_to_time(tempPos, truePath, cumTime(timeCounter), trueTimes);
        timeCounter=timeCounter+1;
        if tempDist >= 0
            distanceErrorFiltered(loopCounter) = tempDist;
            loopCounter = loopCounter +1 ;
        end
    end
    
    %Error between calculated orientation and true orientation
    orientationError = find_orientation_error(orientation,trueOrientation, cumTime, trueTimes);
    orientationErrorFiltered = find_orientation_error(orientationFiltered,trueOrientation, cumTime, trueTimes);
    
    %Mean Error in distance
    meanError = sum(distanceError)/length(distanceError);
    meanErrorFiltered = sum(distanceErrorFiltered)/length(distanceErrorFiltered);
    
    %Mean Error in Orientation
    meanOrientError = mean(orientationError);
    meanOrientErrorFiltered = mean(orientationErrorFiltered);

    %STD in distance from mean error
    pathSTD = sqrt(sum((distanceError-meanError).^2)/(length(distanceError)-1));
    pathSTDFiltered = sqrt(sum((distanceErrorFiltered-meanErrorFiltered).^2)/(length(distanceErrorFiltered)-1));

    %STD in Orientation from mean orientation error
    pathOrientSTD = sqrt(sum((orientationError-meanOrientError).^2)/(length(orientationError)-1));
    pathOrientSTDFiltered = sqrt(sum((orientationErrorFiltered-meanOrientErrorFiltered).^2)/(length(orientationErrorFiltered)-1));
    
    %MSE
    pathMSE = sum(distanceError.^2)/length(distanceError);
    pathMSEFiltered = sum(distanceError.^2)/length(distanceError);
    
    
    %%Table of values
    ColumnNames = {'Mean Error'; 'STD'; 'MSE';'Mean Orient. Error'; 'STD Orient.'};
    Method = {'Unfiltered';'Filtered Filter'};
    Mean_Error =[meanError;meanErrorFiltered];
    STD = [pathSTD;pathSTDFiltered];
    MSE = [pathMSE;pathMSEFiltered];
    Mean_Orient = [meanOrientError;meanOrientErrorFiltered];
    STD_Orient = [pathOrientSTD;pathOrientSTDFiltered];

    T = table(Mean_Error,STD,MSE,Mean_Orient,STD_Orient,'RowNames',Method);

    uitable('Data',T{:,:},'ColumnName',ColumnNames,...
        'RowName',T.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1],...
        'FontSize',16);



    set(gcf, 'Position',  [200, 1000, 600, 200])
    set(gcf, 'Color', [102/255 204/255 255/255], 'name', 'Error Measurements')

    %%  Plotting Orientation
    orientationFig = figure();
    hold on;
    plot(cumTime,orientation)
    plot(cumTime,orientationFiltered)
    
    for(i = 1:2:length(trueTimes)-1)
        plot([trueTimes(i) trueTimes(i+1)], [trueOrientation(i/2+0.5) trueOrientation(i/2+0.5)], ...
        trueTimes(i+1),trueOrientation(i/2+0.5),'*',trueTimes(i),trueOrientation(i/2+0.5),'*','color','black')
    end
    
    legend('Orientation ','Filtered Orientation','True Orientation');
    set(orientationFig, 'Position',  [200, 200, 600, 500]);
    set(orientationFig, 'Color',  [102/255 204/255 255/255], 'name', 'Orientation Plot');
     
    axis([-0.5 max(trueTimes)+0.5 -pi-0.5 pi+0.5]);
    xlabel('Time[s]');
    ylabel('Orientation[rad]');
    yticks([-pi -pi/2 0 pi/2 pi]);
    yticklabels({'-\pi',join(['-\pi','/2']),'0',join(['\pi','/2']),'\pi'})
     
    %%  Plotting the data Path
    dataFig = figure();
    hold on;

    frontTagPlot = scatter(posFrontTag(:,1), posFrontTag(:,2),30);
    backTagPlot = scatter(posBackTag(:,1), posBackTag(:,2),30);
    frontTagFilteredPlot= scatter(posFrontTagFiltered(:,1), posFrontTagFiltered(:,2),30);
    backTagFilteredPlot= scatter(posBackTagFiltered(:,1), posBackTagFiltered(:,2),30);
    
    anchorPlot = scatter(anchorX, anchorY,60,'s');
    plot(truePath(:,1),truePath(:,2) );

    axis([-0.5 anchorX(2)+0.5 -0.5 anchorY(3)+0.5])

    frontTagPlot.MarkerFaceColor = [0 0 1];
    frontTagPlot.MarkerEdgeColor = [0 0 1];
    backTagPlot.MarkerFaceColor =  [0 102/255 1];
    backTagPlot.MarkerEdgeColor =  [0 102/255 1];
    
    frontTagFilteredPlot.MarkerFaceColor = [1 102/255 0];
    frontTagFilteredPlot.MarkerEdgeColor = [1 102/255 0];
    backTagFilteredPlot.MarkerFaceColor =  [1 153/255 1/255];
    backTagFilteredPlot.MarkerEdgeColor =  [1 102/255 1/255];
    
    anchorPlot.MarkerFaceColor = 'red';
    anchorPlot.MarkerEdgeColor = 'red';

    
    set(gcf, 'Position',  [1000, 200, 700, 1000])
    set(gcf, 'Color',  [102/255 204/255 255/255], 'name', 'Live Graph')
    legend('Front Tag Positions','Back Tag Positions', 'Front Tag Filtered Positions','Back Tag Filtered Positions' , 'Anchor Positions','True Position');
    xlabel('x[m]');
    ylabel('y[m]');
     
    %%  Plotting the data LIVE Path
    dataFig = figure();
    hold on;

    frontTagPlot = scatter(posFrontTag(1,1), posFrontTag(1,2),30);
    backTagPlot = scatter(posBackTag(1,1), posBackTag(1,2),30);
    frontTagFilteredPlot= scatter(posFrontTagFiltered(1,1), posFrontTagFiltered(1,2),30);
    backTagFilteredPlot= scatter(posBackTagFiltered(1,1), posBackTagFiltered(1,2),30);
    
    anchorPlot = scatter(anchorX, anchorY,60,'s');
    plot(truePath(:,1),truePath(:,2) );

    axis([-0.5 anchorX(2)+0.5 -0.5 anchorY(3)+0.5])
    
    frontTagPlot.MarkerFaceColor = [0 0 1];
    frontTagPlot.MarkerEdgeColor = [0 0 1];
    backTagPlot.MarkerFaceColor =  [0 102/255 1];
    backTagPlot.MarkerEdgeColor =  [0 102/255 1];
    
    frontTagFilteredPlot.MarkerFaceColor = [1 102/255 0];
    frontTagFilteredPlot.MarkerEdgeColor = [1 102/255 0];
    backTagFilteredPlot.MarkerFaceColor =  [1 153/255 1/255];
    backTagFilteredPlot.MarkerEdgeColor =  [1 102/255 1/255];
    
    anchorPlot.MarkerFaceColor = 'red';
    anchorPlot.MarkerEdgeColor = 'red';

    
    set(gcf, 'Position',  [1800, 200, 700, 1000])
    set(gcf, 'Color',  [102/255 204/255 255/255], 'name', 'Live Graph')
    legend('Front Tag Positions','Back Tag Positions', 'Front Tag Filtered Positions','Back Tag Filtered Positions' , 'Anchor Positions','True Position');
    xlabel('x[m]');
    ylabel('y[m]');

    for i = 2:(length(deltaTime))
        if ~ishghandle(dataFig)
            break
        end
        set(frontTagPlot,'XData',posFrontTag(i,1),'YData',posFrontTag(i,2)) ;
        set(backTagPlot,'XData',posBackTag(i,1),'YData',posBackTag(i,2)) ;
        set(frontTagFilteredPlot,'XData',posFrontTagFiltered(i,1),'YData',posFrontTagFiltered(i,2));
        set(backTagFilteredPlot,'XData',posBackTagFiltered(i,1),'YData',posBackTagFiltered(i,2));
        drawnow
        pause(deltaTime(i-1))
    end
     
end

