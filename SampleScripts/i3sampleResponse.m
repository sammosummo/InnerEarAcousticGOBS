i3clear

fs=44100;
Titan=Titan(fs);

figure;
hPresPlot=plot(1,'linewidth',2);
grid

ch=2;
level=750;
blockLength=512;
stimulus=[1;zeros(blockLength-1,1)];

Titan.StartStimulation(level*stimulus,ch,blockLength);
Titan.InitializePressure();
Titan.StartLogging();

try
    while 1
        set(hPresPlot,'xdata',1:length(Titan.response{:}(:,end)),'ydata',Titan.response{:}(:,end))
        drawnow
        pause(eps)
    end
catch
    Titan.StopInstrument();
end