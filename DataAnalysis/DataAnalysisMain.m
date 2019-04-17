%%
%Authors:
%Lucas Wassénius
%Oscar Johansson
%
%Script to run the data analysis for different paths and stationary
%measurements.
%
%%
clear;
close all;

filename = 'SimPi40';
delimiterIn = ' ';
headerlinesIn = 0;
measurements = importdata(filename, delimiterIn, headerlinesIn);

%Anchor positions[A0, A1, A2]
anchorPos = [0, 10, 5 ;  0, 0, 10];

%%Linear Measurements
%{ 
x1 = linspace(1,2,100)';
y1 = ones(100,1);

x2 = linspace(1,3,100)';
y2 = ones(100,1)*2;

x1f = ones(100,1)*4;
y1f = ones(100,1)*4;

x2f = ones(100,1)*3;
y2f = ones(100,1)*3;

times = linspace(1,5,100)';
%}

%%Sinus Measurements
%{ 
x2 = ones(100,1)*2;
y2 = ones(100,1)*2;


theta = linspace(0,2*pi,100)';
x1 = cos(theta)+2;
y1 = sin(theta)+2;


x2f = ones(100,1)*3;
y2f = ones(100,1)*3;s
x1f = cos(theta+pi/2)+3;
y1f = sin(theta+pi/2)+3;

%}

%measurements = [x1, y1, x2, y2, x1f, y1f, x2f, y2f, times];

%True Path[X,Y,0]
origin = [1,1,0];
point1 = [4,1,0];

piPoint1 = [1,4,0];
piPoint2 = [4,4,0];
piPoint3 = [4,1,0];

trueStraightPath = [origin; point1;];
truePiPath = [origin; piPoint1;piPoint2;piPoint3];

trueTimes = [0;4.3;4.79;9;9.5;13.86];

trueStationary = [3, 3, 0];
trueOrient     = 0;
radians        = 4*pi;

%analysisStationaryDualTag(measurements,trueStationary,trueOrient,radians,anchorPos);
analysisPathDualTagWithTimers(measurements,truePiPath,anchorPos,trueTimes);

