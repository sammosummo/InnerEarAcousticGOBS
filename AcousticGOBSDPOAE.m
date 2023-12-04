if exist('Titan')==1
    Titan.StopInstrument();
end
clearvars -except fname subjectID ear

files=dir('Calibration/AcousticGOBSCal_*.mat');
load(['Calibration/' files(end).name])
load('TransducerCalIOWA')

fs=44100;
Titan=Titan(fs);

%% Settings
ch=[1 2];
blockLength=4096;
filterCutOff=250;
filterOrder=2;

dBtargetLevel=[65 55];
dBmaxSweepNoise=55;
dBOAEpassSNR=15;
fRatio=1.22;

desiredf2s=[2000 3000 4000 5000 6000 8000 9000 10000 11000 12500 14000 16000 18000];
minSweeps=20;
maxSweeps=60;

%% Initialize
t=(0:blockLength-1).'/fs;
freq =(0:blockLength/2-1).'*fs/blockLength;
fftScale=2/(sqrt(2)*blockLength);
micSens=ppval(pp.micSens,freq);

levelStart=[3 3]*sqrt(2);
pTargetLevel=20e-6*10.^(dBtargetLevel/20);

[bFilter,aFilter]=butter(filterOrder,filterCutOff*2/fs,'high');
Hfilter=freqz(bFilter,aFilter,blockLength/2,fs);

NlogFreqs=length(desiredf2s);

for i=1:NlogFreqs
    [~,ix]=min(abs(freq-desiredf2s(i)));
    if2(i)=ix;
end
f2meas=freq(if2);
if1=round(if2/fRatio);
for i=1:NlogFreqs
    [~,ix]=min(abs(freq-f2meas(i)/fRatio));
    if1(i)=ix;
end
idp=2*if1-if2;

f2meas=freq(if2);
f1meas=freq(if1);
fdp=freq(idp);

%% Plots
figure('units','normalized','outerposition',[0.3 0.1 0.4 0.9])
hTitle=subplot(4,1,1);
hSpectrum=semilogx(1,'linewidth',2);hold all
hDPmarker=semilogx(1,'.','markersize',20);
xlim([1500 25000]);ylim([-40 80])
title(hTitle,['0 / ' num2str(maxSweeps) ' sweeps'])
ylabel('dB SPL')
grid

subplot(4,1,2)
hDPgramNoise=semilogx(0,'.-','markersize',20,'linewidth',2);hold all
hDPgram=semilogx(0,'.-','markersize',20,'linewidth',2);
xlim([1500 25000]);ylim([-40 40])
ylabel('dB SPL')
legend('Noise','DPOAE')
grid

subplot(4,1,3)
f1plot=loglog(0,'.-','markersize',20,'linewidth',2);hold all
f2plot=loglog(0,'.-','markersize',20,'linewidth',2);
xlim([1500 25000]);ylim([0.2 200])
xlabel('Frequency [Hz]');ylabel('Level Adj')
legend('f1','f2')
grid

subplot(4,1,4)
SNRgram=semilogx(0,'.-','markersize',20,'linewidth',2);
xlim([1500 25000]);ylim([-10 60])
ylabel('SNR [dB]')
grid
drawnow

%% Measurement
%pause(20);

Titan.InitializePressure();
for nFreq=1:length(if2)
    stimulus=[cos(2*pi*f1meas(nFreq)*t) cos(2*pi*f2meas(nFreq)*t)];
    iNoise=[round(idp(nFreq).^2./if1(nFreq))+1:idp(nFreq)-1 idp(nFreq)+1:if1(nFreq)-1];

    % Adjust level
    okToMeasure=false;
    Titan.StartStimulation(levelStart.*stimulus,ch);
    Titan.LogResponses(2);

    [~,initFilter]=filter(bFilter,aFilter,Titan.response{end}(:,1));
    [responseAdjust,initFilter]=filter(bFilter,aFilter,Titan.response{end}(:,2),initFilter);
    fftResponseAdjust=fftScale*dft(responseAdjust)./(Hfilter.*micSens);
    level=levelStart.*pTargetLevel./abs(fftResponseAdjust([if1(nFreq) if2(nFreq)])).';
    f1Levels(nFreq)=level(1);
    f2Levels(nFreq)=level(2);

    if max(level)>100
      disp(['f1=' num2str(f1meas(nFreq)) 'Hz,    level=' num2str(level(1))])
      disp(['f2=' num2str(f2meas(nFreq)) 'Hz,    level=' num2str(level(2))])
      disp('Voltage threshold exceeded, restarting.')
      Titan.StopLogging();
      Titan.EqualizePressure();
      Titan.StopInstrument();
      clear Titan
      disp('Trying again.')
      Titan=Titan(fs);
      Titan.StartStimulation(levelStart.*stimulus,ch);
      Titan.LogResponses(10);
      [~,initFilter]=filter(bFilter,aFilter,Titan.response{end}(:,1));
      [responseAdjust,initFilter]=filter(bFilter,aFilter,Titan.response{end}(:,10),initFilter);
      fftResponseAdjust=fftScale*dft(responseAdjust)./(Hfilter.*micSens);
      level=levelStart.*pTargetLevel./abs(fftResponseAdjust([if1(nFreq) if2(nFreq)])).';
      f1Levels(nFreq)=level(1);
      f2Levels(nFreq)=level(2);
    end

    if max(level)>100
      disp(['f1=' num2str(f1meas(nFreq)) 'Hz,    level=' num2str(level(1))])
      disp(['f2=' num2str(f2meas(nFreq)) 'Hz,    level=' num2str(level(2))])
      
      disp('Voltage threshold exceeded again, skipping frequency.')
    else
        okToMeasure=true;
    end

    if okToMeasure
        set(f1plot,'xdata',f1meas(1:nFreq),'ydata',f1Levels(1:nFreq));
        set(f2plot,'xdata',f2meas(1:nFreq),'ydata',f2Levels(1:nFreq));
    
        % Measure DPOAE
        Titan.StartStimulation(level.*stimulus,ch);
        Titan.StartLogging();
    
        nBlock=1;
        nSweep=1;
        while 1
            while size(Titan.response{end},2)<nBlock
                pause(eps)
            end
            if nBlock==1
                [~,initFilter]=filter(bFilter,aFilter,Titan.response{end}(:,nBlock));
            else
                [responseFiltTmp(:,mod(nBlock,2)+1),initFilter]=filter(bFilter,aFilter,Titan.response{end}(:,nBlock),initFilter);
                if mod(nBlock,2)
                    fftResponseNoise=dft(responseFiltTmp);
                    rmsSweepNoise=sqrt(2/blockLength^2*sum(abs(diff(fftResponseNoise(2:end,:),1,2)./sqrt(2)./(micSens(2:end))).^2));
                    if dbspl(rmsSweepNoise)>dBmaxSweepNoise
                        nBlock=nBlock+1;
                        title(hTitle,'Too noisy!')
                        drawnow
                        continue
                    end
    
                    responseFilt{nFreq}(:,nSweep)=mean(responseFiltTmp,2);
                    fftResponse(:,nFreq)=fftScale*dft(mean(responseFilt{nFreq},2))./(Hfilter.*micSens);
    
                    dpResponse(:,nFreq)=fftResponse(idp(nFreq),nFreq);
                    noiseFloor(:,nFreq)=mean(abs(fftResponse(iNoise,nFreq)));
    
                    set(hSpectrum,'xdata',freq,'ydata',dbspl(fftResponse(:,nFreq)));
                    set(hDPmarker,'xdata',freq(idp(nFreq)),'ydata',dbspl(fftResponse(idp(nFreq),nFreq)));
                    set(hDPgram,'xdata',f2meas(1:nFreq),'ydata',dbspl(dpResponse));
                    set(hDPgramNoise,'xdata',f2meas(1:nFreq),'ydata',dbspl(noiseFloor));
                    set(SNRgram,'xdata',f2meas(1:nFreq),'ydata',dbspl(dpResponse)-dbspl(noiseFloor));
                    title(hTitle,[num2str(nSweep) ' / ' num2str(maxSweeps) ' sweeps'])
                    drawnow
    
                    if (dpResponse(:,nFreq)-noiseFloor(:,nFreq)>dBOAEpassSNR && nSweep<=minSweeps) || nSweep>=maxSweeps
                        break
                    end
                    nSweep=nSweep+1;
                end
            end
            nBlock=nBlock+1;
        end
    end
end
Titan.StopLogging();
Titan.StopInstrument();

%% Save
savefig(['Figures/' 'AcousticGOBSDPOAE_' subjectID '_' ear{1} '.fig']);
save(fname,...
    'desiredf2s','dpResponse','ear','f1Levels','f1meas','fdp',...
    'fftResponse','fftResponseAdjust','fftResponseCal','fftResponseAdjust', ...
    'fftScale','noiseFloor')