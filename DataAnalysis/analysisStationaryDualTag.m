%%
%Authors:
%Lucas Wassénius
%Oscar Johansson
%
%Script for data analysis for stationary measurements
%(and for rotating around the center of the robot)
%
% Args:
%           measurements:   Matrix with Columns[X1,Y1,X2,Y2, X1f, Y1f, X2f, Y2f]
%                           Each Row is another measurement
%                           The numbers represent the indexed tag, and f
%                           represents the filtered values
%           
%           truePos:        The true position in vector [X,Y,0]
%           
%           trueOrientation: The true orientation in radians.
%           
%           radians:        Amount of rotation in radians for the rotating
%                           measurements.
%
%           anchorPos:      The anchor positions in vector [X1,X2,X3,Y1,Y2,Y3]
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
    %cumTime = measurements(:,9)./1000;
    simMeasurements = 64;
    cumTime = linspace(0,simMeasurements/4,simMeasurements);
    for i = 1 : length(cumTime)-1
        deltaTime(i) = cumTime(i+1)-cumTime(i);
    end

    
    
    %Orientation
    trueOrientationVec = wrapToPi(linspace(trueOrientation, trueOrientation+radians, length(cumTime)))';
    
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
    
    errorOrient0 = orientation -trueOrientationVec;
    errorOrient = min_orient_error(errorOrient0);
    
    errorOrientFiltered0 = orientationFiltered -  trueOrientationVec;
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
    
    absoluteMeanOrientError = mean(abs(errorOrient));
    absoluteMeanOrientErrorFiltered = mean(abs(errorOrientFiltered));
    
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
    Mean_Position_Error =[meanPositionError;meanPositionErrorFiltered];
    STD = [positionSTD;positionSTDFiltered];
    %MSEOrient = [orientMSE;orientMSEFiltered];
    Mean_Orient = [meanOrientError;meanOrientErrorFiltered];
    STD_Orient = [orientSTD;orientSTDFiltered];
    figure();
    T1 = table(Mean_Position_Error,STD,Mean_Orient,STD_Orient,'RowNames',Method);

    uitable('Data',T1{:,:},'ColumnName',ColumnNames,...
        'RowName',T1.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1],...
        'FontSize',16);



    set(gcf, 'Position',  [100, 650, 600, 100],'name', 'Stationary')
    
    %% Table of values
    ColumnNamesSpin = {'Mean Distance Error';'MSE Distance';'Absolute Mean Orient. Error'};
    Mean_Distance_Error =[meanDistanceError;meanDistanceErrorFiltered];
    MSE = [pathMSE;pathMSEFiltered];
    Absolute_Mean_Orient = [absoluteMeanOrientError;absoluteMeanOrientErrorFiltered];
    figure();
    T2 = table(Mean_Distance_Error,MSE,Absolute_Mean_Orient,'RowNames',Method);

    uitable('Data',T2{:,:},'ColumnName',ColumnNamesSpin,...
        'RowName',T2.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1],...
        'FontSize',16);



    set(gcf, 'Position',  [700, 650, 600, 100])
    set(gcf, 'Color', [102/255 204/255 255/255], 'name', 'Rotating Tags')
    
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
    histogram(distanceError,'BinWidth',binWidthDistance);
    title('Measured','Fontsize', fontSize);
    xlabel('Distance Error[m]', 'Fontsize', fontSize);
    ylabel('Measurements', 'Fontsize', fontSize);
    xlim([0 max(max([distanceError,distanceErrorFiltered]))+binWidthDistance]);
    
    subplot(2,1,2);
    histogram(distanceErrorFiltered,'BinWidth',binWidthDistance);
    title('Filtered','Fontsize', fontSize); 
    xlabel('Distance Error[m]', 'Fontsize', fontSize);
    ylabel('Measurements', 'Fontsize', fontSize);
    xlim([0 max(max([distanceError,distanceErrorFiltered]))+binWidthDistance]);
    set(gcf, 'Position',  positionDistHist);
    
    %% Histogram Orientation Error
    HistOrientationFig = figure;
    
    subplot(2,1,1);
    histogram(abs(errorOrient),'BinWidth',binWidthOrient);
    title('Measured','Fontsize', fontSize);
    xlabel('Absolute Orientation Error[m]', 'Fontsize', fontSize);
    ylabel('Measurements', 'Fontsize', fontSize);
    xlim([0 max(max([abs(errorOrient),abs(errorOrientFiltered)]))+binWidthOrient]);
    
    subplot(2,1,2);
    histogram(abs(errorOrientFiltered),'BinWidth',binWidthOrient);
    title('Filtered','Fontsize', fontSize); 
    xlabel('Absolute Orientation Error[m]', 'Fontsize', fontSize);
    ylabel('Measurements', 'Fontsize', fontSize);
    xlim([0 max(max([abs(errorOrient),abs(errorOrientFiltered)]))+binWidthOrient]);
    set(gcf, 'Position',  positionOrientHist);
    
    %% ECDF Distance Error
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
    [ECDForientationErrorY,ECDForientationErrorX] = ecdf(abs(errorOrient));
    [ECDForientationErrorYFiltered,ECDForientationErrorXFiltered] = ecdf(abs(errorOrientFiltered));
    
    hold on;
    plot(ECDForientationErrorX,ECDForientationErrorY)
    plot(ECDForientationErrorXFiltered,ECDForientationErrorYFiltered)
    plot([-1 10], [1 1],'--', 'Color', 'black')
    
    xlabel('Absolute Orientation Error[rad]', 'Fontsize', fontSize);
    ylabel('Cumulative Probability', 'Fontsize', fontSize);
    
    legend('Measured ECDF', 'Filtered ECDF','Location', legendLocation);
    set(gcf, 'Position', positionECDFOrient);
    axis([0 max(max([ECDForientationErrorX, ECDForientationErrorXFiltered])) ...
        0 max(max([ECDForientationErrorY, ECDForientationErrorYFiltered]))+0.2]);
    
    
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
     
    legend('Orientation ','Filtered Orientation','True Orientation','Location', legendLocation);
    set(orientationFig, 'Position',  positionOrientPlot);
    %set(orientationFig, 'Color',  [102/255 204/255 255/255], 'name', 'Orientation Plot');
     
    axis([-0.3 max(cumTime)+0.3 -pi-0.3 pi+0.3]);
    xlabel('Time[s]', 'Fontsize', fontSize);
    ylabel('Orientation[rad]', 'Fontsize', fontSize);
    yticks([-pi -pi/2 0 pi/2 pi]);
    yticklabels({'-\pi',join(['-\pi','/2']),'0',join(['\pi','/2']),'\pi'})
     
  
  %%  Plotting the stationary data
    positionFig = figure();
    hold on;

    measuredPositionPlot = scatter(middlePos(:,1), middlePos(:,2),30,'filled');
    filteredPositionPlot= scatter(middlePosFiltered(:,1), middlePosFiltered(:,2),30,'filled');
    
    anchorPlot = scatter(anchorX, anchorY,60,'s');
    truePlot = scatter(trueX, trueY,20,'s');

    axis([-0.5 anchorX(2)+0.5 -0.5 anchorY(3)+0.5])
    
    
    measuredPositionPlot.MarkerFaceColor = [0 0 1];
    measuredPositionPlot.MarkerEdgeColor = [0 0 1];
    
    filteredPositionPlot.MarkerFaceColor = [1 102/255 0];
    filteredPositionPlot.MarkerEdgeColor = [1 102/255 0];

    
    anchorPlot.MarkerFaceColor = 'red';
    anchorPlot.MarkerEdgeColor = 'red';
    truePlot.MarkerFaceColor = 'black';
    truePlot.MarkerEdgeColor = 'black';

    
    set(gcf, 'Position', positionPositionPlot)
    %set(gcf, 'Color',  [102/255 204/255 255/255], 'name', 'Live Graph')
    legend('Measured Positions','Filtered Positions' , 'Anchor Positions','True Position','Location', legendLocation);
    xlabel('x[m]', 'Fontsize', fontSize);
    ylabel('y[m]', 'Fontsize', fontSize);
    
    print(positionFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\positionFig','-dpdf');
    axis([min(middlePos(:,1))-0.15 max(middlePos(:,1))+0.15 min(middlePos(:,2))-0.15 max(middlePos(:,2))+0.15])
    
    %% Saving the Figures
    
    writetable(T1,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\TableStationary.xlsx')
    writetable(T2,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\TableRotation.xlsx')
    print(HistDistanceFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\HistDistanceFig','-dpdf');
    print(HistOrientationFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\HistOrientationFig','-dpdf');
    print(ECDFDistanceFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\ECDFDistanceFig','-dpdf');
    print(ECDFOrientationFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\ECDFOrientationFig','-dpdf');
    print(orientationFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\orientationFig','-dpdf');
    print(positionFig,'C:\Users\luwas1\Desktop\Measurements\CurrentFigures\ZoomedPositionFig','-dpdf');
    
 %%  Plotting the stationary data LIVE
 %{
    waitforbuttonpress;
 
    dataFig = figure();
    hold on;
 
    measuredPositionPlot = scatter(middlePos(1,1), middlePos(1,2),30,'filled');
    filteredPositionPlot= scatter(middlePosFiltered(1,1), middlePosFiltered(1,2),30,'filled');
    
    anchorPlot = scatter(anchorX, anchorY,60,'s');
    truePlot = scatter(trueX, trueY,20,'s');

    axis([min(middlePos(:,1))-0.2 max(middlePos(:,1))+0.2 min(middlePos(:,2))-0.2 max(middlePos(:,2))+0.2])

    measuredPositionPlot.MarkerFaceColor = [0 0 1];
    measuredPositionPlot.MarkerEdgeColor = [0 0 1];
    
    filteredPositionPlot.MarkerFaceColor = [1 102/255 0];
    filteredPositionPlot.MarkerEdgeColor = [1 102/255 0];
    
    anchorPlot.MarkerFaceColor = 'red';
    anchorPlot.MarkerEdgeColor = 'red';
    truePlot.MarkerFaceColor = 'black';
    truePlot.MarkerEdgeColor = 'black';

    
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
        pause(deltaTime(i))
    end
    
%}
end



