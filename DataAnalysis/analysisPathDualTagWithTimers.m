%%
%Authors:
%Lucas Wassénius
%Oscar Johansson
%
%Script for data analysis from path measurements
%
% Args:
%           measurements:   Matrix with Columns[X1,Y1,X2,Y2, X1f, Y1f, X2f, Y2f]
%                           Each Row is another measurement
%                           The numbers represent the indexed tag, and f
%                           represents the filtered values
%           
%           truePos:        The true position in vector [X1,Y1,0;X2,Y2,0...]
%                           Where X1,Y1 represents the starting point and
%                           continues to X2, Y2 and X3, Y3 and onward...
%
%           anchorPos:      The anchor positions in vector [X1,X2,X3,Y1,Y2,Y3]
%
%           trueTimes:      Timevector with the times where the robot is
%                           turning. Given by: 
%                           [Start, First Stop, First Start, Second Stop, Second Start, End]
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
    

    %Timers
    cumTime = measurements(:,9)./1000;
    %simMeasurements = 48;  %Simulation Times(Matrix not corresponding to actual simulation times)
    %cumTime = linspace(0,simMeasurements/4,simMeasurements);
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
    orientationError = find_orientation_error(orientation,trueOrientation, cumTime, trueTimes);
    orientationErrorFiltered = find_orientation_error(orientationFiltered,trueOrientation, cumTime, trueTimes);
    
    %Mean Error in distance
    meanPositionError = sqrt(meanErrorX^2+meanErrorY^2);
    meanPositionErrorFiltered = sqrt(meanErrorXFiltered^2+meanErrorYFiltered^2);
    
    %Mean Error in distance
    meanDistanceError = mean(distanceError);
    meanDistanceFiltered = mean(distanceErrorFiltered);
    
    %Mean Error in Orientation
    absoluteMeanOrientError = mean(abs(orientationError));
    absoluteMeanOrientErrorFiltered = mean(abs(orientationErrorFiltered));

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
    orientMSE = sum(orientationError.^2)/length(orientationError);
    orientMSEFiltered = sum(orientationErrorFiltered.^2)/length(orientationErrorFiltered);
    
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

    T1 = table(Mean_Distance_Error,MSE,Absolute_Mean_Orient,'RowNames',Method);

    uitable('Data',T1{:,:},'ColumnName',ColumnNames,...
        'RowName',T1.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1],...
        'FontSize',16);



    set(gcf, 'Position',  [100, 650, 600, 100])
    set(gcf, 'Color', [102/255 204/255 255/255], 'name', 'Error Measurements')

    %% Plot Constants
    fontSize = 15;
    binWidthDistance = 0.02;
    binWidthOrient = 0.1;
    legendLocation = 'NE';
    positionDistHist =          [100, 800, 500, 500];
    positionOrientHist =        [600, 800, 500, 500];
    positionECDFDist =          [1100, 800, 500, 500];
    positionECDFOrient =        [1600, 800, 500, 500];
    positionOrientPlot =        [100, 50, 500, 500];
    positionPositionPlot =      [600, 50, 500, 500];
    positionPositionLivePlot =  [50, 50, 2450, 1300];
    
     %% Histogram Distance Error
    HistDistanceFig = figure;
    
    subplot(2,1,1);
    histogram(distanceError,'BinWidth', binWidthDistance);
    title('Measured','Fontsize', fontSize);
    xlabel('Distance Error[m]', 'Fontsize', fontSize);
    ylabel('Measurements', 'Fontsize', fontSize);
    xlim([0 max(max([distanceError,distanceErrorFiltered]))+binWidthDistance]);
    
    subplot(2,1,2);
    histogram(distanceErrorFiltered,'BinWidth', binWidthDistance);
    title('Filtered','Fontsize', fontSize); 
    xlabel('Distance Error[m]', 'Fontsize', fontSize);
    ylabel('Measurements', 'Fontsize', fontSize);
    
    xlim([0 max(max([distanceError,distanceErrorFiltered]))+binWidthDistance]);
    set(gcf, 'Position',  positionDistHist);
    
    %% Histogram Orientation Error
    HistOrientationFig = figure;
    
    subplot(2,1,1);
    histogram(abs(orientationError),'BinWidth', binWidthOrient);
    title('Measured','Fontsize', fontSize);
    xlabel('Absolute Orientation Error[m]', 'Fontsize', fontSize);
    ylabel('Measurements', 'Fontsize', fontSize);
    xlim([0 max(max([abs(orientationError),abs(orientationErrorFiltered)]))+binWidthOrient]);
    
    subplot(2,1,2);
    histogram(abs(orientationErrorFiltered),'BinWidth', binWidthOrient);
    title('Filtered','Fontsize', fontSize); 
    xlabel('Absolute Orientation Error[m]', 'Fontsize', fontSize);
    ylabel('Measurements', 'Fontsize', fontSize);
    xlim([0 max(max([abs(orientationError),abs(orientationErrorFiltered)]))+binWidthOrient]);
    
    set(gcf, 'Position',  positionOrientHist);
    
    
    %% ECDF Position
    ECDFDistanceFig = figure;
    [ECDFdistanceErrorY,ECDFdistanceErrorX] = ecdf(distanceError);
    [ECDFdistanceErrorYFiltered,ECDFdistanceErrorXFiltered] = ecdf(distanceErrorFiltered);
    
    hold on;
    plot(ECDFdistanceErrorX,ECDFdistanceErrorY)
    plot(ECDFdistanceErrorXFiltered,ECDFdistanceErrorYFiltered)
    plot([-1 10], [1 1],'--', 'Color', 'black')
    
    xlabel('Distance Error[m]', 'Fontsize', fontSize);
    ylabel('Cumulative Probability', 'Fontsize', fontSize);
    
    legend('Measured ECDF', 'Filtered ECDF', 'Location', legendLocation);
    set(gcf, 'Position',  positionECDFDist);
    axis([0 max(max([ECDFdistanceErrorX, ECDFdistanceErrorXFiltered])) ...
            0 max(max([ECDFdistanceErrorY, ECDFdistanceErrorYFiltered]))+0.2]);
    
    %% ECDF Orientation
    ECDFOrientationFig = figure;
    [ECDForientationErrorY,ECDForientationErrorX] = ecdf(abs(orientationError));
    [ECDForientationErrorYFiltered,ECDForientationErrorXFiltered] = ecdf(abs(orientationErrorFiltered));
    
    hold on;
    plot(ECDForientationErrorX,ECDForientationErrorY)
    plot(ECDForientationErrorXFiltered,ECDForientationErrorYFiltered)
    plot([-1 10], [1 1],'--', 'Color', 'black')
    
    xlabel('Absolute Orientation Error[rad]', 'Fontsize', fontSize);
    ylabel('Cumulative Probability', 'Fontsize', fontSize);
    
    legend('Measured ECDF', 'Filtered ECDF','Location', legendLocation);
    set(gcf, 'Position',  positionECDFOrient);
    axis([0 max(max([ECDForientationErrorX, ECDForientationErrorXFiltered])) ...
        0 max(max([ECDForientationErrorY, ECDForientationErrorYFiltered]))+0.2]);
    
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
    
    legend('Orientation ','Filtered Orientation','True Orientation','Location', legendLocation);
    set(orientationFig, 'Position',  positionOrientPlot);
    %set(orientationFig, 'Color',  [102/255 204/255 255/255], 'name', 'Orientation Plot');
     
    axis([-0.3 max(trueTimes)+0.3 -pi-0.3 pi+0.3]);
    xlabel('Time[s]', 'Fontsize', fontSize);
    ylabel('Orientation[rad]', 'Fontsize', fontSize);
    yticks([-pi -pi/2 0 pi/2 pi]);
    yticklabels({'-\pi',join(['-\pi','/2']),'0',join(['\pi','/2']),'\pi'})
     
    %%  Plotting the data Path
    positionFig = figure();
    hold on;

    measuredPositionPlot = scatter(middlePos(:,1), middlePos(:,2),30);
    filteredPositionPlot= scatter(middlePosFiltered(:,1), middlePosFiltered(:,2),30);
    
    anchorPlot = scatter(anchorX, anchorY,60,'s');
    plot(truePath(:,1),truePath(:,2),'Color','black' );

    axis([-0.5 anchorX(2)+0.5 -0.5 anchorY(3)+0.5])

    measuredPositionPlot.MarkerFaceColor = [0 0 1];
    measuredPositionPlot.MarkerEdgeColor = [0 0 1];
    
    filteredPositionPlot.MarkerFaceColor = [1 102/255 0];
    filteredPositionPlot.MarkerEdgeColor = [1 102/255 0];
    
    anchorPlot.MarkerFaceColor = 'red';
    anchorPlot.MarkerEdgeColor = 'red';

    
    set(gcf, 'Position',  positionPositionPlot)
    %set(gcf, 'Color',  [102/255 204/255 255/255], 'name', 'Live Graph')
    legend('Measured Positions','Filtered Positions' , 'Anchor Positions','True Position','Location', legendLocation);
    xlabel('x[m]', 'Fontsize', fontSize);
    ylabel('y[m]', 'Fontsize', fontSize);
    
    print(positionFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\positionFig','-dpdf');
    axis([min(middlePos(:,1))-0.15 max(middlePos(:,1))+0.15 min(middlePos(:,2))-0.15 max(middlePos(:,2))+0.15])
    
    %% Saving the Figures
    
    writetable(T1,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\TableMoving.xlsx')
    print(HistDistanceFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\HistDistanceFig','-dpdf');
    print(HistOrientationFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\HistOrientationFig','-dpdf');
    print(ECDFDistanceFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\ECDFDistanceFig','-dpdf');
    print(ECDFOrientationFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\ECDFOrientationFig','-dpdf');
    print(orientationFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\orientationFig','-dpdf');
    print(positionFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\ZoomedPositionFig','-dpdf');
    
    %%  Plotting the data LIVE Path
    %{
    waitforbuttonpress;
    
    dataFig = figure();
    hold on;

    measuredPositionPlot = scatter(middlePos(1,1), middlePos(1,2),30);
    filteredPositionPlot= scatter(middlePosFiltered(1,1), middlePosFiltered(1,2),30);
    
    anchorPlot = scatter(anchorX, anchorY,60,'s');
    plot(truePath(:,1),truePath(:,2) );

    axis([-0.5 anchorX(2)+0.5 -0.5 anchorY(3)+0.5])
    
    measuredPositionPlot.MarkerFaceColor = [0 0 1];
    measuredPositionPlot.MarkerEdgeColor = [0 0 1];

    
    filteredPositionPlot.MarkerFaceColor = [1 102/255 0];
    filteredPositionPlot.MarkerEdgeColor = [1 102/255 0];

    
    anchorPlot.MarkerFaceColor = 'red';
    anchorPlot.MarkerEdgeColor = 'red';

    
    set(gcf, 'Position',  positionPositionLivePlot)
    %set(gcf, 'Color',  [102/255 204/255 255/255], 'name', 'Live Graph')
    legend('Measured Positions','Filtered Positions' , 'Anchor Positions','True Position','Location', legendLocation);
    xlabel('x[m]', 'Fontsize', fontSize);
    ylabel('y[m]', 'Fontsize', fontSize);

    for i = 2:(length(deltaTime))
        if ~ishghandle(dataFig)
            break
        end
        set(measuredPositionPlot,'XData',middlePos(i,1),'YData',middlePos(i,2)) ;
        set(filteredPositionPlot,'XData',middlePosFiltered(i,1),'YData',middlePosFiltered(i,2));
        drawnow
        pause(deltaTime(i-1))
    end
%}
end

