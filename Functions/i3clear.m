% Script to clear MATLAB workspace and stop Titan instrument to avoid
% deleting the Titan object of a running instrument. Can be used in place
% of clear all for scripts interfacing the with Interacoustics Research
% Platform.
if exist('Titan')==1
    Titan.StopInstrument();
end
clear all