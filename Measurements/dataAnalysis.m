%%
%Authors:
%Lucas Wassénius
%Oscar Johansson
%
%Script for data analysis in positioning
%%
clear all;
close all;

filename = 'positionMeasurements1';
delimiterIn = ' ';
headerlinesIn = 0;
measurements = importdata(filename, delimiterIn, headerlinesIn);

%Store first row as true position
truePos = measurements(1,1:2); 
trueX = truePos(1);
trueY = truePos(2);

%Remove first values
measurements = measurements(20:length(measurements),:);

%Anchor positions[A0, A1, A2]
anchorX = [0; 2.4; 0.96];
anchorY = [0; 0; 4.80];

%Fetch unfiltered measurements
positionX = measurements(:,1);
positionY = measurements(:,2);

%Fetch Kalman filtered measurements
positionXKalman = measurements(:,3);
positionYKalman = measurements(:,4);


%% Mean Error

%Calculate mean positions
meanX = mean(positionX);
meanY = mean(positionY);
meanXKalman = mean(positionXKalman);
meanYKalman = mean(positionYKalman);

%Errors between measured position and true position
errorX = trueX - positionX;
errorY = trueY - positionY;
errorXKalman = trueX - positionXKalman;
errorYKalman = trueY - positionYKalman;

%Distance Error between measured position and true position
distanceError = sqrt(errorX.^2 + errorY.^2);
distanceErrorKalman = sqrt(errorXKalman.^2 + errorYKalman.^2);

%Mean Error in distance
meanError = sum(distanceError)/length(distanceError);
meanErrorKalman = sum(distanceErrorKalman)/length(distanceErrorKalman);

%Standard Deviation in X/Y direction
positionSTDX = sqrt(sum((positionX-meanX).^2)/(length(positionX)-1));
positionSTDY = sqrt(sum((positionY-meanY).^2)/(length(positionY)-1));
positionSTDXKalman =sqrt(sum((positionXKalman-meanXKalman).^2)/(length(positionXKalman)-1));
positionSTDYKalman =sqrt(sum((positionYKalman-meanYKalman).^2)/(length(positionYKalman)-1));

%Standard Deviation in distance
distanceSTD = sqrt(positionSTDX.^2 + positionSTDY.^2);
distanceSTDKalman = sqrt(positionSTDXKalman.^2 + positionSTDYKalman.^2);

%%Table of values
ColumnNames = {'Mean Error';'STD X';'STD Y';'STD Distance'};
Method = {'Unfiltered';'Kalman Filter'};
Mean_Error =[meanError;meanErrorKalman];
STDx = [positionSTDX;positionSTDXKalman];
STDy = [positionSTDY;positionSTDYKalman];
STD = [distanceSTD;distanceSTDKalman];

T = table(Mean_Error,STDx,STDy,STD,'RowNames',Method);

uitable('Data',T{:,:},'ColumnName',ColumnNames,...
    'RowName',T.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1],...
    'FontSize',16);



set(gcf, 'Position',  [400, 1000, 500, 200])


%%  Plotting the data
dataFig = figure();
hold on;
unfilteredPlot = scatter(positionX, positionY,20);
kalmanPlot= scatter(positionXKalman, positionYKalman,20);
anchorPlot = scatter(anchorX, anchorY,60,'s');
truePlot = scatter(trueX, trueY,60,'s');

axis([-0.5 3 -0.5 5])

unfilteredPlot.MarkerFaceColor = 'blue';
kalmanPlot.MarkerFaceColor = 'cyan';
anchorPlot.MarkerFaceColor = 'red';
truePlot.MarkerFaceColor = 'black';

legend('Unfiltered Positions', 'Filtered Positions', 'Anchor Positions', 'True Position');

