i3clear

files=dir('Calibration/wbtCal_*.mat');
load(['Calibration/' files(end).name])

Titan=Titan(fs);

%% Settings
nFreqPlot=100;
freqLim=[100 10000];
iFreqLim=[find(freq<freqLim(1),1,'last') find(freq>freqLim(2),1,'first')];
iFreqPlot=unique(round(logspace(log10(iFreqLim(1)),log10(iFreqLim(2)),nFreqPlot)));

Z0=rho*c/(0.00375^2*pi);
pumpSpeed='Medium';
sweepLim=[200 -300];
sweepDir=sign(diff(sweepLim));
overshoot=20;

%% Initialize plot
figure
hPlotAbs=surf(zeros(2),'facecolor','interp');
set(gca,'xscale','log')
set(gcf,'renderer','opengl')
xlim(freqLim);ylim(sort(sweepLim));zlim([0 1]);caxis([0 1])
xlabel('Frequency [Hz]');ylabel('Pressure [Pa]');zlabel('Absorbance')
drawnow

%% Measure
Titan.StartStimulation(level*stimulus,ch);
Titan.SetPressure(sweepLim(1)-sweepDir*overshoot,'Fast',5,1);
Titan.SweepPressure(sweepLim(2)+sweepDir*overshoot,pumpSpeed,5);
Titan.StartLogging();

nBlock=1;
while 1
    while sweepDir*Titan.pressure{:}(end)<sweepDir*sweepLim(1)
        nResp=size(Titan.response{:},2);
        pause(eps)
    end
    response(:,nBlock)=Titan.response{:}(:,nResp);
    pressure(nBlock)=Titan.pressure{:}(nResp);
    
    fftResponse(:,nBlock)=dft(response(:,nBlock).*timeWindow);
    
    Z(:,nBlock)=Zs.*fftResponse(:,nBlock)./(Ps-fftResponse(:,nBlock));
    R(:,nBlock)=(Z(:,nBlock)-Z0)./(Z(:,nBlock)+Z0);
    A(:,nBlock)=1-abs(R(:,nBlock)).^2;
    
    try
        [~,Z0est(nBlock),Lest(nBlock)]=CompRefl(Z(:,nBlock),freq,8000);
    catch
        Z0est(nBlock)=0;
        Lest(nBlock)=0;
    end
    
    set(hPlotAbs,'xdata',freq(iFreqPlot),'ydata',pressure,'zdata',(A(iFreqPlot,:).*(A(iFreqPlot,:)>0)).');
    drawnow
    
    if sweepDir*Titan.pressure{:}(end)>sweepDir*sweepLim(2)
        Titan.StopLogging();
        break
    end
    
    while size(Titan.response{:},2)<=nResp
        pause(eps)
    end
    
    nResp=nResp+1;
    nBlock=nBlock+1;
    pause(eps)
end

Z0=mean(Z0est(Z0est>0));
L=mean(Lest(Lest~=0 & Lest<400 & Lest>-200));
R=(Z-2i*pi*freq*L-Z0)./(Z-2i*pi*freq*L+Z0);
A=1-abs(R).^2;

set(hPlotAbs,'xdata',freq(iFreqPlot),'ydata',pressure,'zdata',(A(iFreqPlot,:).*(A(iFreqPlot,:)>0)).');
drawnow

Titan.EqualizePressure();
Titan.StopInstrument();

%% Save
measStr=['3dtMeas_' datestr(now,'yymmdd_HHMMSS')];
save(['Measurement/' measStr],...
    'Z','R','A','Z0','L',...
    'response','fftResponse','stimulus','fftStimulus',...
    'fs','blockLength','freq','iFreqPlot','pressure','timeWindow','ch','level',...
    'temperatureCal','pressureCal','rho','c','calStr')