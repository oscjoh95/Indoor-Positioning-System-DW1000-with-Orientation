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
    posFrontTag = measurements(:,3:4);
    posBackTag = measurements(:,1:2);

    %Fetch Filtered filtered measurements[X,Y]
    posFrontTagFiltered = measurements(:,7:8);
    posBackTagFiltered = measurements(:,5:6);
    

    %Timers
    cumTime = measurements(:,9)./1000;
    for i = 1 : length(cumTime)-1
        deltaTime(i) = cumTime(i+1)-cumTime(i);
    end
        
    %Orientation
    for i = 1:length(truePath(:,1))-1
       trueOrientation(i)= atan2((truePath(i+1,2)-truePath(i,2)),(truePath(i+1,1)-truePath(i,1)));
    end
    orientation = atan2((posFrontTag(:,2)-posBackTag(:,2)),(posFrontTag(:,1)-posBackTag(:,1)));
    orientationFiltered = atan2((posFrontTagFiltered(:,2)-posBackTagFiltered(:,2)),(posFrontTagFiltered(:,1)-posBackTagFiltered(:,1)));

    %Measured middle of Robot
    middlePos = (posFrontTag+posBackTag)./2;
    middlePosFiltered = (posFrontTagFiltered+posBackTagFiltered)./2;
    
    %% Table of Error Measurements
    %Errors between measured position and true path
    loopCounter = 1;
    timeCounter = 1;
    while timeCounter <(length(measurements(:,1)))
        tempPos = [middlePos(timeCounter,1),middlePos(timeCounter,2),0];
        [tempDist, tempErrorX, tempErrorY] = min_distance_to_time(tempPos, truePath, cumTime(timeCounter), trueTimes);
        timeCounter=timeCounter+1;
        if tempDist >= 0
            distanceError(loopCounter) = tempDist;
            errorX(loopCounter) = tempErrorX;
            errorY(loopCounter) = tempErrorY;
            loopCounter = loopCounter +1 ;
        end
    end
    
    %Errors between measured position and true path (Filtered)
    loopCounter = 1;
    timeCounter = 1;
    while timeCounter <(length(measurements(:,1)))
        tempPos = [middlePosFiltered(timeCounter,1),middlePosFiltered(timeCounter,2),0];
        [tempDist, tempErrorX, tempErrorY] = min_distance_to_time(tempPos, truePath, cumTime(timeCounter), trueTimes);
        timeCounter=timeCounter+1;
        if tempDist >= 0
            distanceErrorFiltered(loopCounter) = tempDist;
            errorXFiltered(loopCounter) = tempErrorX;
            errorYFiltered(loopCounter) = tempErrorY;
            loopCounter = loopCounter +1 ;
        end
    end
    
    %Mean Errors
    meanErrorX = mean(errorX);
    meanErrorY = mean(errorY);
    meanErrorXFiltered = mean(errorXFiltered);
    meanErrorYFiltered = mean(errorYFiltered);
    
    %Error between calculated orientation and true orientation(Absolute)
    orientationAbsoluteError = find_orientation_error(orientation,trueOrientation, cumTime, trueTimes);
    orientationAbsoluteErrorFiltered = find_orientation_error(orientationFiltered,trueOrientation, cumTime, trueTimes);
    
    %Mean Error in distance
    meanPositionError = sqrt(meanErrorX^2+meanErrorY^2);
    meanPositionErrorFiltered = sqrt(meanErrorXFiltered^2+meanErrorYFiltered^2);
    
    %Mean Error in distance
    meanDistanceError = mean(distanceError);
    meanDistanceFiltered = mean(distanceErrorFiltered);
    
    %Mean Error in Orientation
    absoluteMeanOrientError = mean(abs(orientationAbsoluteError));
    absoluteMeanOrientErrorFiltered = mean(abs(orientationAbsoluteErrorFiltered));

    %STD in distance from mean error
    pathSTD = sqrt(sum((distanceError-meanPositionError).^2)/(length(distanceError)-1));
    pathSTDFiltered = sqrt(sum((distanceErrorFiltered-meanPositionErrorFiltered).^2)/(length(distanceErrorFiltered)-1));

    %STD in Orientation from mean orientation error
    %pathOrientSTD = sqrt(sum((orientationError-meanOrientError).^2)/(length(orientationError)-1));
    %pathOrientSTDFiltered = sqrt(sum((orientationErrorFiltered-meanOrientErrorFiltered).^2)/(length(orientationErrorFiltered)-1));
    
    %MSE Distance
    pathMSE = sum(distanceError.^2)/length(distanceError);
    pathMSEFiltered = sum(distanceErrorFiltered.^2)/length(distanceErrorFiltered);
    
    %MSE Orientation
    orientMSE = sum(orientationAbsoluteError.^2)/length(orientationAbsoluteError);
    orientMSEFiltered = sum(orientationAbsoluteErrorFiltered.^2)/length(orientationAbsoluteErrorFiltered);
    
    %% Table of values
    ColumnNames = {'Mean Distance Error';'MSE Distance';'Absolute Mean Orient. Error'};
    Method = {'Unfiltered';'Filtered'};
    Mean_Distance_Error =[meanDistanceError;meanDistanceFiltered];
    Mean_Position_Error =[meanPositionError;meanPositionErrorFiltered];
    STD = [pathSTD;pathSTDFiltered];
    MSE = [pathMSE;pathMSEFiltered];
    MSEOrient = [orientMSE;orientMSEFiltered];
    Absolute_Mean_Orient = [absoluteMeanOrientError;absoluteMeanOrientErrorFiltered];
    %STD_Orient = [pathOrientSTD;pathOrientSTDFiltered];

    T = table(Mean_Distance_Error,MSE,Absolute_Mean_Orient,'RowNames',Method);

    uitable('Data',T{:,:},'ColumnName',ColumnNames,...
        'RowName',T.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1],...
        'FontSize',16);



    set(gcf, 'Position',  [200, 1000, 600, 200])
    set(gcf, 'Color', [102/255 204/255 255/255], 'name', 'Error Measurements')

    %%  Plotting Orientation
    orientationFig = figure();
    hold on;
    orientPlot =scatter(cumTime,orientation);
    orientFilterPlot = scatter(cumTime,orientationFiltered);
    
    orientPlot.MarkerFaceColor = [0 0 1];
    orientPlot.MarkerEdgeColor = [0 0 1];
    
    orientFilterPlot.MarkerFaceColor = [1 102/255 0];
    orientFilterPlot.MarkerEdgeColor = [1 102/255 0];
    
    for i = 1:2:length(trueTimes)-1
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

