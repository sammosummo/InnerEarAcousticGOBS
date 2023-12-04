i3clear

fs=44100;
Titan=Titan(fs);

figure;
hPresPlot=plot(1,'linewidth',2);
ylim([-400 300])
grid

Titan.InitializePressure();
Titan.SweepPressure(-300,'Fast',5);
Titan.StartLogging();

tic
while toc<4
    set(hPresPlot,'xdata',1:length(Titan.pressureAll),'ydata',Titan.pressureAll)
    drawnow
end

Titan.SweepPressure(200,'Veryslow',5);

while toc<14
    set(hPresPlot,'xdata',1:length(Titan.pressureAll),'ydata',Titan.pressureAll)
    drawnow
end

Titan.SetPressure(-300,'Fast',5,0);

while toc<20
    set(hPresPlot,'xdata',1:length(Titan.pressureAll),'ydata',Titan.pressureAll)
    drawnow
end

Titan.EqualizePressure();
pause(1)
Titan.StopInstrument();

set(hPresPlot,'xdata',1:length(Titan.pressureAll),'ydata',Titan.pressureAll)
drawnow