%%
%Authors:
%Lucas Wassénius
%Oscar Johansson
%
%Script for data analysis in positioning
%%

function analysisStationaryDualTag(measurements,truePos,trueOrientation,radians,anchorPos)

    %Store first row as true position
    trueX = truePos(1);
    trueY = truePos(2);

    %Anchor positions[A0, A1, A2]
    anchorX = anchorPos(1,:);
    anchorY = anchorPos(2,:);

    %Fetch unfiltered measurements
    posFrontTag = measurements(:,1:2);
    posBackTag = measurements(:,3:4);

    %Fetch Filtered filtered measurements
    posFrontTagFiltered = measurements(:,5:6);
    posBackTagFiltered = measurements(:,7:8);

    %Timers
    cumTime = measurements(:,9)./1000;
    for i = 1 : length(cumTime)-1
        deltaTime(i) = cumTime(i+1)-cumTime(i);
    end

    %Orientation
    trueOrientationVec = wrapToPi(linspace(trueOrientation, trueOrientation+radians, length(cumTime)));
    
    orientation = atan2((posFrontTag(:,2)-posBackTag(:,2)),(posFrontTag(:,1)-posBackTag(:,1)));
    orientationFiltered = atan2((posFrontTagFiltered(:,2)-posBackTagFiltered(:,2)),(posFrontTagFiltered(:,1)-posBackTagFiltered(:,1)));
    
    %% Mean Error
    
    %Measured middle position of the robot
    middlePos = (posFrontTag+posBackTag)./2;
    middlePosFiltered = (posFrontTagFiltered+posBackTagFiltered)./2;
    
    %Calculate mean positions
    meanX = mean(middlePos(:,1));
    meanY = mean(middlePos(:,2));
    meanXFiltered = mean(middlePosFiltered(:,1));
    meanYFiltered = mean(middlePosFiltered(:,2));
    
    meanOrient = mean(orientation);
    meanOrientFiltered = mean (orientationFiltered);

    %Errors between measured position and true position(and true orientation and calculated orientation)
    errorX = trueX - middlePos(:,1);
    errorY = trueY - middlePos(:,2);
    errorXFiltered = trueX - middlePosFiltered(:,1);
    errorYFiltered = trueY - middlePosFiltered(:,2);
    
    errorOrient0 = trueOrientation - orientation;
    errorOrient = min_orient_error(errorOrient0);
    
    errorOrientFiltered0 = trueOrientation - orientationFiltered;
    errorOrientFiltered = min_orient_error(errorOrientFiltered0);
    
    %Mean Errors X,Y
    meanErrorX = mean(errorX);
    meanErrorY = mean(errorY);
    meanErrorXFiltered = mean(errorXFiltered);
    meanErrorYFiltered = mean(errorYFiltered);
    
    %Mean Position Error
    meanPositionError = sqrt(meanErrorX.^2 + meanErrorY.^2);
    meanPositionErrorFiltered = sqrt(meanErrorXFiltered.^2 + meanErrorYFiltered.^2);
    
    %Distance Error between measured position and true position
    distanceError = sqrt(errorX.^2 + errorY.^2);
    distanceErrorFiltered = sqrt(errorXFiltered.^2 + errorYFiltered.^2);

    %Mean Error in distance and orientation
    meanDistanceError = mean(distanceError);
    meanDistanceErrorFiltered = mean(distanceErrorFiltered);
    
    meanOrientError = mean(errorOrient);
    meanOrientErrorFiltered = mean(errorOrientFiltered);
    
    %Eucledian distance of Standard Deviation
    positionSTD_Dist =  sqrt((middlePos(:,1)-meanX).^2 + (middlePos(:,2)-meanY).^2);
    positionSTD_DistFiltered = sqrt((middlePosFiltered(:,1)-meanXFiltered).^2 + (middlePosFiltered(:,2)-meanYFiltered).^2);
    

    %Standard Deviation in distance
    positionSTD = sqrt(sum(positionSTD_Dist.^2)/(length(positionSTD_Dist(:,1))-1));
    positionSTDFiltered = sqrt(sum(positionSTD_DistFiltered.^2)/(length(positionSTD_DistFiltered(:,1))-1));

    %Standard Deviation in Orientation
    orientSTD = sqrt(sum((errorOrient-meanOrientError).^2)/(length(errorOrient)-1));
    orientSTDFiltered = sqrt(sum((errorOrientFiltered-meanOrientErrorFiltered).^2)/(length(errorOrientFiltered)-1));
    
    %MSE Distance
    pathMSE = sum(distanceError.^2)/length(distanceError);
    pathMSEFiltered = sum(distanceErrorFiltered.^2)/length(distanceErrorFiltered);
    
    %MSE Orientation
    %orientMSE = sum(absoluteErrorOrient.^2)/length(absoluteErrorOrient);
    %orientMSEFiltered = sum(absoluteErrorOrientFiltered.^2)/length(absoluteErrorOrientFiltered);
    
    %% Table of values
    ColumnNames = {'Mean Position Error';'STD Position';'Mean Orient. Error';'STD Orient.'};
    Method = {'Unfiltered';'Filtered'};
    Mean_Distance_Error =[meanDistanceError;meanDistanceErrorFiltered];
    Mean_Position_Error =[meanPositionError;meanPositionErrorFiltered];
    STD = [positionSTD;positionSTDFiltered];
    MSE = [pathMSE;pathMSEFiltered];
    %MSEOrient = [orientMSE;orientMSEFiltered];
    Abolute_Mean_Orient = [meanOrientError;meanOrientErrorFiltered];
    STD_Orient = [orientSTD;orientSTDFiltered];
    
    T = table(Mean_Position_Error,STD,Abolute_Mean_Orient,STD_Orient,'RowNames',Method);

    uitable('Data',T{:,:},'ColumnName',ColumnNames,...
        'RowName',T.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1],...
        'FontSize',16);



    set(gcf, 'Position',  [200, 1000, 600, 200])

    %%  Plotting Orientation
     
    orientationFig = figure();
    hold on;
    
    orientPlot = scatter(cumTime,orientation);
    orientFilterPlot = scatter(cumTime,orientationFiltered);
    plot(cumTime,trueOrientationVec,'black')
    
    orientPlot.MarkerFaceColor = [0 0 1];
    orientPlot.MarkerEdgeColor = [0 0 1];
   
    orientFilterPlot.MarkerFaceColor = [1 102/255 0];
    orientFilterPlot.MarkerEdgeColor = [1 102/255 0];
     
    legend('Orientation ','Filtered Orientation','True Orientation');
    set(orientationFig, 'Position',  [200, 200, 600, 500]);
    set(orientationFig, 'Color',  [102/255 204/255 255/255], 'name', 'Orientation Plot');
     
    axis([-0.5 max(cumTime)+0.5 -pi-0.5 pi+0.5]);
    xlabel('Time[s]');
    ylabel('Orientation[rad]');
    yticks([-pi -pi/2 0 pi/2 pi]);
    yticklabels({'-\pi',join(['-\pi','/2']),'0',join(['\pi','/2']),'\pi'})
     
     
  %%  Plotting the stationary data
    figure();
    hold on;

    frontTagPlot = scatter(posFrontTag(:,1), posFrontTag(:,2),30,'filled');
    backTagPlot = scatter(posBackTag(:,1), posBackTag(:,2),30,'filled');
    frontTagFilteredPlot= scatter(posFrontTagFiltered(:,1), posFrontTagFiltered(:,2),30,'filled');
    backTagFilteredPlot= scatter(posBackTagFiltered(:,1), posBackTagFiltered(:,2),30,'filled');
    
    anchorPlot = scatter(anchorX, anchorY,60,'s');
    truePlot = scatter(trueX, trueY,20,'s');

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
    truePlot.MarkerFaceColor = 'black';
    truePlot.MarkerEdgeColor = 'black';

    
    set(gcf, 'Position',  [1000, 800, 1000, 500])
    set(gcf, 'Color',  [102/255 204/255 255/255], 'name', 'Live Graph')
    legend('Front Tag Positions','Back Tag Positions', 'Front Tag Filtered Positions','Back Tag Filtered Positions' , 'Anchor Positions','True Position');
    xlabel('x[m]');
    ylabel('y[m]');

 %%  Plotting the stationary data LIVE
    dataFig = figure();
    hold on;

    frontTagPlot = scatter(posFrontTag(1,1), posFrontTag(1,2),30,'filled');
    backTagPlot = scatter(posBackTag(1,1), posBackTag(1,1),30,'filled');
    frontTagFilteredPlot= scatter(posFrontTagFiltered(1,1), posFrontTagFiltered(1,2),30,'filled');
    backTagFilteredPlot= scatter(posBackTagFiltered(1,1), posBackTagFiltered(1,2),30,'filled');
    
    anchorPlot = scatter(anchorX, anchorY,60,'s');
    truePlot = scatter(trueX, trueY,20,'s');

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
    truePlot.MarkerFaceColor = 'black';
    truePlot.MarkerEdgeColor = 'black';

    
    set(gcf, 'Position',  [1000, 200, 1000, 500])
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
        pause(deltaTime(i))
    end
    
end

