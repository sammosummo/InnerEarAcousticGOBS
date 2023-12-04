if exist('Titan')==1
    Titan.StopInstrument();
end
clearvars -except fname subjectID ear
aname=['Measurement/' 'AcousticGOBSWBA_' subjectID '_' ear{1} '.mat'];
if ~exist(aname,'file')
    AcousticGOBSWBA
end
if exist('Titan')==1
    Titan.StopInstrument();
end
clearvars -except fname subjectID ear
files=dir('Calibration/AcousticGOBSCal_*.mat');
load(['Calibration/' files(end).name])
load('TransducerCalIOWA')
load(['Measurement/' 'AcousticGOBSWBA_' subjectID '_' ear{1} '.mat'],'Z0','L');
Titan=Titan(fs);

%% Settings
chActivator=1;
Nseqs=10;
dBSPLactivator=80:5:110;
activatorFreq=1000;

%% Initialize
t=(0:(blockLength*2.5-1)).'/fs;
activatorCal=ppval(pp.activator,activatorFreq);
activatorLevel=2e-5*10.^(dBSPLactivator/20)/activatorCal;
% activator=tukeywin(blockLength*2.5,0.1).*cos(2*pi*activatorFreq*t);

n=length(t);
X=zeros(1,n);
f=linspace(0,fs,n);
rng(1);
X(f>=3000&f<=8000)=randn(1,sum(f>=3000&f<=8000))+1i*randn(1,sum(f>=3000&f<=8000));
X(f>fs/2)=conj(X(fliplr(f<fs/2)));
noise=real(ifft(X,'symmetric'));
noise=noise/sqrt(mean(noise.^2))/sqrt(2);
noise=noise.';
activator=noise;  % this has the same RMS as a pure tone with amp=1

d=zeros(blockLength/2,1);
D=zeros(blockLength,1);

activatorSeq=[D;D;D;activator;d;D;activator;d;D;activator;d;D;activator;d;D;activator;d;D;activator;d;D;D;D;D;D;D;D;D;D;D;D;D;D;D;D;D;D];
stimulusSeq=[D;D;stimulus;D;D;D;stimulus;D;D;D;stimulus;D;D;D;stimulus;D;D;D;stimulus;D;D;D;stimulus;D;D;D;stimulus;D;D;D;D;D;D;D;D;D;D;D;D;D;D;D;D];
iStim=(1:blockLength).'+blockLength*unique(floor(find(stimulusSeq~=0)/blockLength)).';

%% Initialize plot
figure('units','normalized','outerposition',[0.3 0.1 0.4 0.8])

subplot(3,1,1);
for nLevel=1:length(activatorLevel)
    hBaseline(nLevel)=semilogx(1,'linewidth',2);hold all
end
xlim([250 5000]);ylim([0 1])
xlabel('Frequency [Hz]');ylabel('Baseline')
legend(string(num2cell(dBSPLactivator)),'location','northoutside','orientation','horizontal')
grid

subplot(3,1,2);
for nLevel=1:length(activatorLevel)
    hReflex(nLevel)=semilogx(1,'linewidth',2);hold all
end
xlim([250 5000]);ylim([0 1])
xlabel('Frequency [Hz]');ylabel('Reflex')
grid


subplot(3,1,3);
for nLevel=1:length(activatorLevel)
    hDelta(nLevel)=semilogx(1,'linewidth',2);hold all
end
xlim([250 5000]);ylim([-0.2 0.2])
xlabel('Frequency [Hz]');ylabel('\DeltaAbsorbance')
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
        
        set(hBaseline(nLevel),'xdata',freq,'ydata',Abaseline(:,nLevel));
        set(hReflex(nLevel),'xdata',freq,'ydata',Areflex(:,nLevel));
        set(hDelta(nLevel),'xdata',freq,'ydata',Areflex(:,nLevel)-Abaseline(:,nLevel));
        drawnow
    end
    Titan.StopLogging();
end
Titan.EqualizePressure();
Titan.StopInstrument();

%% Save
savefig(['Figures/' 'AcousticGOBSHPR_' subjectID '_' ear{1} '.fig']);
save(fname,...
  'Abaseline','Areflex','c','ear','fftResponseBaseline',...
  'fftResponseCal','fftResponseReflex','fftStimulus','L',...
  'meanResponseCal','meanResponseSeqBaseline','meanResponseSeqReflex',...
  'pressureCal','pressureSeq','Ps','Rbaseline',...
  'responseSeq','rho','Rreflex','stimulus','stimulusSeq',...
  'subjectID','Z0','Zbaseline','Zest','Zref','Zreflex','Zs')