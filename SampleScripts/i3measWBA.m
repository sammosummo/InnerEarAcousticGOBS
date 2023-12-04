i3clear

files=dir('Calibration/wbtCal_*.mat');
load(['Calibration/' files(end).name])

Titan=Titan(fs);

%% Settings
Nblocks=64;
Z0=rho*c/(0.00375^2*pi);

%% Initialize plot
figure
hPlot=semilogx(1,'linewidth',2);
xlim([100 10000]);ylim([0 1])
xlabel('Frequency [Hz]');ylabel('Absorbance')
grid

%% Measure
%pause(20);
Titan.StartStimulation(level*stimulus,ch);
Titan.InitializePressure();
Titan.StartLogging();
for nBlock=1:Nblocks
    pause(eps)
    while size(Titan.response{:},2)<nBlock
        pause(eps)
    end
    
    fftResponse=dft(Titan.response{:}(:,end).*timeWindow);
    Z=Zs.*fftResponse./(Ps-fftResponse);
    R=(Z-Z0)./(Z+Z0);
    A=1-abs(R).^2;
    
    set(hPlot,'xdata',freq,'ydata',A);
    drawnow
end

meanResponse=mean(Titan.response{:}.*timeWindow,2);
fftResponse=dft(meanResponse);
Z=Zs.*fftResponse./(Ps-fftResponse);
[R,Z0,L]=CompRefl(Z,freq,8000);
A=1-abs(R).^2;

set(hPlot,'xdata',freq,'ydata',A);
drawnow

Titan.StopLogging();
Titan.StopInstrument();

%% Save
measStr=['wbaMeas_' datestr(now,'yymmdd_HHMMSS')];
save(['Measurement/' measStr],...
    'Z','R','A','Z0','L',...
    'Zs','Ps',...
    'meanResponse','fftResponse','stimulus','fftStimulus',...
    'fs','blockLength','freq','timeWindow','ch','level',...
    'temperatureCal','pressureCal','rho','c','calStr')