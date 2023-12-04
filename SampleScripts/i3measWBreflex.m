i3measWBA

i3clear

files=dir('Measurement/wbaMeas_*.mat');
load(['Measurement/' files(end).name],'Z0','L')
files=dir('Calibration/wbtCal_*.mat');
load(['Calibration/' files(end).name])
load('Tra nsducerCalIOWA')

Titan=Titan(fs);

%% Settings
chActivator=1;
Nseqs=5;
dBSPLactivator=80:5:105;
activatorFreq=1000;

%% Initialize
t=(0:(blockLength*2.5-1)).'/fs;

activatorCal=ppval(pp.activator,activatorFreq);
activatorLevel=2e-5*10.^(dBSPLactivator/20)/activatorCal;
activator=tukeywin(blockLength*2.5,0.1).*cos(2*pi*activatorFreq*t);
d=zeros(blockLength/2,1);
D=zeros(blockLength,1);

activatorSeq=[D;D;D;activator;d;D;activator;d;D;activator;d;D;activator;d;D;D;D;D;D;D;D;D;D;D;D;D;D;D;D;D;D];
stimulusSeq=[D;D;stimulus;D;D;D;stimulus;D;D;D;stimulus;D;D;D;stimulus;D;D;D;stimulus;D;D;D;D;D;D;D;D;D;D;D;D;D;D;D;D];
iStim=(1:blockLength).'+blockLength*unique(floor(find(stimulusSeq~=0)/blockLength)).';

%% Initialize plot
figure
for nLevel=1:length(activatorLevel)
    hReflex(nLevel)=semilogx(1,'linewidth',2);hold all
end
xlim([100 10000]);ylim([-0.2 0.2])
xlabel('Frequency [Hz]');ylabel('\DeltaAbsorbance')
legend(string(num2cell(dBSPLactivator)),'location','northoutside','orientation','horizontal')
grid

%% Measure
Titan.InitializePressure();
for nLevel=1:length(activatorLevel)
    Titan.StartStimulation([activatorLevel(nLevel)/sqrt(2)*activatorSeq level*stimulusSeq],[chActivator ch]);
    Titan.StartLogging();
    for nSeq=1:Nseqs
        while size(Titan.response{end},2)<nSeq
            pause(eps)
        end
        for nBlock=1:size(iStim,2)
            responseSeq(:,nBlock)=Titan.response{end}(iStim(:,nBlock),nSeq);
        end
        pressureSeq(nLevel,nSeq)=Titan.pressure{end}(nSeq);
        
        meanResponseSeqBaseline{nLevel}(:,nSeq)=mean(responseSeq(:,1),2).*timeWindow;
        fftResponseBaseline(:,nLevel)=dft(mean(meanResponseSeqBaseline{nLevel}(:,:),2));
        Zbaseline(:,nLevel)=Zs.*fftResponseBaseline(:,nLevel)./(Ps-fftResponseBaseline(:,nLevel));
        Rbaseline(:,nLevel)=(Zbaseline(:,nLevel)-2i*pi*freq*L-Z0)./(Zbaseline(:,nLevel)-2i*pi*freq*L+Z0);
        Abaseline(:,nLevel)=1-abs(Rbaseline(:,nLevel)).^2;
        
        meanResponseSeqReflex{nLevel}(:,nSeq)=mean(responseSeq(:,2:end),2).*timeWindow;
        fftResponseReflex(:,nLevel)=dft(mean(meanResponseSeqReflex{nLevel}(:,:),2));
        Zreflex(:,nLevel)=Zs.*fftResponseReflex(:,nLevel)./(Ps-fftResponseReflex(:,nLevel));
        Rreflex(:,nLevel)=(Zreflex(:,nLevel)-2i*pi*freq*L-Z0)./(Zreflex(:,nLevel)-2i*pi*freq*L+Z0);
        Areflex(:,nLevel)=1-abs(Rreflex(:,nLevel)).^2;        
        
        set(hReflex(nLevel),'xdata',freq,'ydata',Areflex(:,nLevel)-Abaseline(:,nLevel));
        drawnow
    end
    Titan.StopLogging();
end
Titan.EqualizePressure();
Titan.StopInstrument();