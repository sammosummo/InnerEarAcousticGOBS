%% This Example shows how to use the example class HelloWorld.
% It set a stimulus and starts logging the mic response.
% Afterwards it start the pump to pump to the desired pressure goal. 
% A pause is used to define a measure time, before the logging and 
% stimulation is stooped.
% in the end the mic and pressure data is plot to be evaluated.


clear; clc; close all;
% Include the i3 folder
addpath([pwd '\i3'])
disp('Start of script')

%% Create test object to work on of the HelloWork class
helloWorld = HelloWorld();

% Start stimuli (frequency[Hz], amplitude[mV], length of stimuli[n])
helloWorld.StartStimulation(226,100,390);

% Start the pump (Pressure target[daPa], speed, Pressure target tolerence[daPa])
helloWorld.SetPressure(300, 'Fast' , 10);

pause(2); % Wait until time is completed.

% Change stimuli (frequency[Hz], amplitude[mV], length of stimuli[n])
helloWorld.ChangeStimulation(452,100,390);

% Start the pump (Pressure target[daPa], speed, Pressure target tolerence[daPa])
helloWorld.SetPressure(0, 'Veryslow', 10);

pause(2); % Wait until time is completed.

helloWorld.StopStimulation(); % Stop the test.
disp('Stimulation Stopped')

%% evaluate the logged data

response = reshape(helloWorld.response.',[],1);
figure(1);
plot(response);
title('Sampled mic signal')
xlabel('Sample Index [n]')
ylabel('mic. signal [mV]')
grid on

figure(2);
plot(helloWorld.pressure);
title('Sampled pressure')
xlabel('Sample Index [n]')
ylabel('Pressure [daPa')
grid on

disp('End of script')