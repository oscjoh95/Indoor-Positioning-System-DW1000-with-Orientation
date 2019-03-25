%%
%Authors:
%Lucas Wassénius
%Oscar Johansson
%
%Script for data analysis in positioning
%%
function d = analysisPathOneTag(measurements,truePath,anchorPos)


    %Anchor positions[A0, A1, A2]
    anchorX = anchorPos(1,:);
    anchorY = anchorPos(2,:);
    %Fetch unfiltered measurements
    positionX = measurements(:,1);
    positionY = measurements(:,2);

    %Fetch Filtered filtered measurements
    positionXFiltered = measurements(:,3);
    positionYFiltered = measurements(:,4);

    %Timers
    %deltaTime = measurements(:,5);
    deltaTime = ones(length(positionX)).*0.25;
    cumTime = cumsum(deltaTime);

    %% Table of Error Measurements

    %Errors between measured position and true path
    for i = 1:(length(positionX))
        tempPos = [positionX(i),positionY(i),0];
        distanceError(i) =  min_distance_to_lines(tempPos, truePath);
    end

    %Errors between measured position and true path (Filtered)
    for i = 1:(length(positionX))
        tempPos = [positionXFiltered(i),positionYFiltered(i),0];
        distanceErrorFiltered(i) =  min_distance_to_lines(tempPos,truePath);
    end

    %Mean Error in distance
    meanError = sum(distanceError)/length(distanceError);
    meanErrorFiltered = sum(distanceErrorFiltered)/length(distanceErrorFiltered);

    %STD in distance from path
    pathSTD = sqrt(sum((distanceError-meanError).^2)/(length(distanceError)-1));
    pathSTDFiltered = sqrt(sum((distanceErrorFiltered-meanErrorFiltered).^2)/(length(distanceErrorFiltered)-1));

    %%Table of values
    ColumnNames = {'Mean Error'; 'STD'};
    Method = {'Unfiltered';'Filtered Filter'};
    Mean_Error =[meanError;meanErrorFiltered];
    STD = [pathSTD;pathSTDFiltered];

    T = table(Mean_Error,STD,'RowNames',Method);

    uitable('Data',T{:,:},'ColumnName',ColumnNames,...
        'RowName',T.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1],...
        'FontSize',16);



    set(gcf, 'Position',  [400, 1000, 500, 200])
    set(gcf, 'Color',  [0.8 0.8 0.95], 'name', 'Error Measurements')


    %%  Plotting the data
    %{
    dataFig = figure();
    hold on;

    unfilteredPlot = scatter(positionX, positionY,20);
    FilteredPlot= scatter(positionXFiltered, positionYFiltered,20);
    anchorPlot = scatter(anchorX, anchorY,60,'s');
    %truePlot = scatter(trueX, trueY,'s');

    axis([-0.5 3 -0.5 5])

    unfilteredPlot.MarkerFaceColor = 'blue';
    unfilteredPlot.MarkerEdgeColor = 'blue';
    FilteredPlot.MarkerFaceColor = 'cyan';
    FilteredPlot.MarkerEdgeColor = 'cyan';
    anchorPlot.MarkerFaceColor = 'red';
    anchorPlot.MarkerEdgeColor = 'red';
    %truePlot.MarkerFaceColor = 'black';
    %truePlot.MarkerEdgeColor = 'black';

    legend('Unfiltered Positions', 'Filtered Positions', 'Anchor Positions');
    %}



    %%  Plotting the data LIVE Path
    dataFig = figure();
    hold on;

    unfilteredPlot = scatter(positionX(1), positionY(1),20);
    FilteredPlot= scatter(positionXFiltered(1), positionYFiltered(1),20);
    anchorPlot = scatter(anchorX, anchorY,60,'s');
    trueplot = plot(truePath(:,1),truePath(:,2) );

    axis([-0.5 anchorX(2)+0.5 -0.5 anchorY(3)+0.5])

    unfilteredPlot.MarkerFaceColor = 'blue';
    unfilteredPlot.MarkerEdgeColor = 'blue';
    FilteredPlot.MarkerFaceColor = 'cyan';
    FilteredPlot.MarkerEdgeColor = 'cyan';
    anchorPlot.MarkerFaceColor = 'red';
    anchorPlot.MarkerEdgeColor = 'red';
    truePlot.MarkerFaceColor = 'black';
    truePlot.MarkerEdgeColor = 'black';
    set(gcf, 'Position',  [1000, 200, 1000, 1000])
    set(gcf, 'Color',  [0.8 0.8 0.95], 'name', 'Live Graph')
    legend('Unfiltered Positions', 'Filtered Positions', 'Anchor Positions','True Position');


    for i = 2:(length(deltaTime))
        if ~ishghandle(dataFig)
            break
        end
        set(unfilteredPlot,'XData',positionX(1:i),'YData',positionY(1:i)) ;
        set(FilteredPlot,'XData',positionXFiltered(1:i),'YData',positionYFiltered(1:i));
        drawnow
        pause(deltaTime(i))
    end
    
end
