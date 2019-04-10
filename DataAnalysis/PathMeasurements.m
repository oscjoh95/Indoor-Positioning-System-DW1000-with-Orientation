%%
%Authors:
%Lucas Wassénius
%Oscar Johansson
%
%Script to run the data analysis with True Path and True timestamps
%
%%
clear;
close all;

filename = 'test';
delimiterIn = ' ';
headerlinesIn = 0;
measurements = importdata(filename, delimiterIn, headerlinesIn);

%Anchor positions[A0, A1, A2]
anchorPos = [0, 4.37, 1.3 ;  0, 0, 6.9];

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
y2f = ones(100,1)*3;

x1f = cos(theta+pi/2)+3;
y1f = sin(theta+pi/2)+3;

%}

%measurements = [x1, y1, x2, y2, x1f, y1f, x2f, y2f, times];


%True Path[X,Y,0]
origin = [2.15,2,0];
point1 = [4.15,2,0];
point2 = [0,0,0];
point3 = [0,0,0];

truePath = [origin; point1;];
trueTimes = [0; 1.786];

trueStationary = [5, 4, 0];
trueOrient     = -pi;
radians        = 0;

%analysisStationaryDualTag(measurements,trueStationary,trueOrient,radians,anchorPos);
analysisPathDualTagWithTimers(measurements,truePath,anchorPos,trueTimes);


