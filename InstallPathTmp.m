% Run script to temporarily reset the MATLAB search path and add the
% required folders for the Interacoustics Research Platform for the current
% MATLAB session only.
restoredefaultpath
addpath(genpath([pwd '\i3']))
addpath(genpath([pwd '\Functions']))
addpath(genpath([pwd '\Stimuli']))
clear all