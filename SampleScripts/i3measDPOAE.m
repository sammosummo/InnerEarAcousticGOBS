i3clear

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

freqLim=[750 20000];
NlogFreqs=21;
minSweeps=100;
maxSweeps=150;

%% Initialize
t=(0:blockLength-1).'/fs;
freq =(0:blockLength/2-1).'*fs/blockLength;
fftScale=2/(sqrt(2)*blockLength);
micSens=ppval(pp.micSens,freq);

levelStart=[3 3]*sqrt(2);
pTargetLevel=20e-6*10.^(dBtargetLevel/20);

[bFilter,aFilter]=butter(filterOrder,filterCutOff*2/fs,'high');
Hfilter=freqz(bFilter,aFilter,blockLength/2,fs);

iFreqLim=[find(freq<freqLim(1),1,'last') find(freq>freqLim(2),1,'first')];
if2=unique(round(10.^linspace(log10(iFreqLim(1)),log10(iFreqLim(end)),NlogFreqs))).';
if1=round(if2/fRatio);
idp=2*if1-if2;

f2meas=freq(if2);
f1meas=freq(if1);
fdp=freq(idp);

%% Plots
figure('units','normalized','outerposition',[0.3 0.1 0.4 0.8])
hTitle=subplot(2,1,1);
hSpectrum=semilogx(1,'linewidth',2);hold all
hDPmarker=semilogx(1,'.','markersize',20);
xlim([500 25000]);ylim([-40 80])
title(hTitle,['0 / ' num2str(maxSweeps) ' sweeps'])
xlabel('Frequency [Hz]');ylabel('dB SPL')
grid

subplot(2,1,2)
hDPgramNoise=semilogx(0,'.-','markersize',20,'linewidth',2);hold all
hDPgram=semilogx(0,'.-','markersize',20,'linewidth',2);
xlim([150 25000]);ylim([-40 40])
xlabel('Frequency [Hz]');ylabel('dB SPL')
legend('Noise','DPOAE')
grid
drawnow

%% Measurement
%pause(20);

Titan.InitializePressure();
for nFreq=1:length(if2)
    stimulus=[cos(2*pi*f1meas(nFreq)*t) cos(2*pi*f2meas(nFreq)*t)];
    iNoise=[round(idp(nFreq).^2./if1(nFreq))+1:idp(nFreq)-1 idp(nFreq)+1:if1(nFreq)-1];
    
    % Adjust level
    Titan.StartStimulation(levelStart.*stimulus,ch);
    Titan.LogResponses(2);
    
    [~,initFilter]=filter(bFilter,aFilter,Titan.response{end}(:,1));
    [responseAdjust,initFilter]=filter(bFilter,aFilter,Titan.response{end}(:,2),initFilter);
    fftResponseAdjust=fftScale*dft(responseAdjust)./(Hfilter.*micSens);
    level=levelStart.*pTargetLevel./abs(fftResponseAdjust([if1(nFreq) if2(nFreq)])).';
    if max(level)>100
        error('Voltage threshold exceeded.')
    end
    
    
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
                    continue
                end
                
                responseFilt{nFreq}(:,nSweep)=mean(responseFiltTmp,2);
                fftResponse(:,nFreq)=fftScale*dft(mean(responseFilt{nFreq},2))./(Hfilter.*micSens);
                
                dpResponse(:,nFreq)=fftResponse(idp(nFreq),nFreq);
                noiseFloor(:,nFreq)=mean(abs(fftResponse(iNoise,nFreq)));
                
                set(hSpectrum,'xdata',freq,'ydata',dbspl(fftResponse(:,nFreq)));
                set(hDPmarker,'xdata',freq(idp(nFreq)),'ydata',dbspl(fftResponse(idp(nFreq),nFreq)));
                set(hDPgram,'xdata',f2meas(1:nFreq),'ydata',dbspl(dpResponse))
                set(hDPgramNoise,'xdata',f2meas(1:nFreq),'ydata',dbspl(noiseFloor))
                title(hTitle,[num2str(nSweep) ' / ' num2str(maxSweeps) ' sweeps'])
                drawnow

                dpResponses(nSweep,nFreq)=dpResponse(:,nFreq);
                noiseFloors(nSweep,nFreq)=noiseFloor(:,nFreq);
                
                if (dpResponse(:,nFreq)-noiseFloor(:,nFreq)>dBOAEpassSNR && nSweep<=minSweeps) || nSweep>=maxSweeps
                    break
                end
                nSweep=nSweep+1;
            end
        end
        nBlock=nBlock+1;
    end
end
Titan.StopLogging();
Titan.StopInstrument();

%% Save
measStr=['DpoaeMeas_' datestr(now,'yymmdd_HHMMSS')];
save(['Measurement/' measStr],...
    "noiseFloors","dpResponses","f1meas","fdp","if2","f2meas","if1","dpResponse","noiseFloor")