i3clear

load('TEOAEclicksIOWA')
load('TransducerCalIOWA')

fs=44100;
Titan=Titan(fs);

%% Settings
protocol='TEOAE';
%protocol='2CEOAE';

ch=[1 2];
blockLength=1024;
filterOrder=2;
windowStart=0.0025;
windowRamp=0.0015;

dBppSPL=83;
dBmaxSweepNoise=40;
dBSNRbandPass=10;
NpassBands=2;

minSweeps=25;
maxSweeps=300;
bandCenterFreqs=10.^(log10(1000):log10(sqrt(2)):log10(4000));

%% Initialize
t=(0:blockLength-1).'/fs;
freq=(0:blockLength/2-1).'*fs/blockLength;
micSens=ppval(pp.micSens,freq);
micSensAvg=mean(abs(micSens(freq>100 & freq<10000)));
Ppp=sqrt(2)*2e-5*10^(dBppSPL/20);

rampWindow=blackman(2*round(windowRamp*fs));
timeWindow=[zeros(round(windowStart*fs),1);rampWindow(1:round(windowRamp*fs));ones(blockLength-round(windowStart*fs)-round(windowRamp*fs),1)];
cutOffFreq=[bandCenterFreqs(1)*(bandCenterFreqs(1)/bandCenterFreqs(2)) bandCenterFreqs(end)*(bandCenterFreqs(end)/bandCenterFreqs(end-1))];

[bFilter,aFilter]=butter(filterOrder,cutOffFreq*2/fs,'bandpass');
Hfilter=freqz(bFilter,aFilter,blockLength/2,fs);
filterDelay=grpdelay(bFilter,aFilter);
filterDelay=ceil(mean(filterDelay(freq>cutOffFreq(1) & freq<cutOffFreq(2))));

stimulus1=[click1;zeros(blockLength+filterDelay+clickDelay-length(click1),1)];
stimulus2=[click2;zeros(blockLength+filterDelay+clickDelay-length(click2),1)];
noStimulus=zeros(blockLength+filterDelay+clickDelay,1);

if strcmp(protocol,'TEOAE')
    stimulus=[stimulus1 noStimulus;stimulus1 noStimulus;stimulus1 noStimulus;3*stimulus1 noStimulus];
elseif strcmp(protocol,'2CEOAE')
    stimulus=[stimulus1 noStimulus;noStimulus stimulus2;stimulus1 stimulus2];
end
Nblocks=length(stimulus)/length(stimulus1);

stimulus=circshift(stimulus,-clickDelay);

%% Plot
figure('units','normalized','outerposition',[0.3 0.1 0.4 0.8])
subplot(3,3,1)
clickPlot(1)=plot(1,'linewidth',2);hold all
clickPlot(2)=plot(1,'linewidth',2);
ylim([-0.5 0.5])
xlim([0 0.004])
xlabel('Time [s]');ylabel('Pressure [Pa]')
grid

subplot(3,3,[2 3])
residualAplot=plot(1,'linewidth',2);hold all
residualBplot=plot(1,'linewidth',2);
noisePlot=plot(1);
ylim([-0.4 0.4])
xlim([t(1) t(end)])
xlabel('Time [s]');ylabel('Pressure [mPa]')
grid

hTitle=subplot(3,3,4:9);
fftResidualOctBndPlot=bar(1,'basevalue',-20);hold all
fftNoiseOctBndPlot=bar(1,'basevalue',-20);
legend('OAE','Noise')
ylim([-20 40])
xlim(log10(bandCenterFreqs([1 end]).*[sqrt(sqrt(0.5)) sqrt(sqrt(2))]))
set(gca,'xtick',log10(bandCenterFreqs),'xticklabel',bandCenterFreqs)
title(hTitle,['0 / ' num2str(maxSweeps) ' sweeps'])
xlabel('Frequency [Hz]');ylabel('dB SPL')
grid
drawnow

%% Level adjust
levelStart=[45 45];
Titan.StartStimulation(levelStart.*stimulus,ch);
Titan.InitializePressure();
Titan.LogResponses(2);
[~,filterInit]=filter(bFilter,aFilter,Titan.response{end}(:,1));
responseFiltAdj=filter(bFilter,aFilter,Titan.response{end}(:,2),filterInit);
for nAdj=find(~all(stimulus==0))
    PppAdj=peak2peak(responseFiltAdj((1:blockLength)+((nAdj-1)*(blockLength)))/micSensAvg);
    level(nAdj)=levelStart(nAdj)*Ppp/PppAdj;
end

%% Measurement
Titan.StartStimulation(level.*stimulus,ch);
Titan.StartLogging();

nSeq=1;
nSweep=1;
while 1
    while size(Titan.response{end},2)<nSeq
        pause(eps)
    end
    if nSeq==1
        [~,filterInit]=filter(bFilter,aFilter,Titan.response{end}(:,nSeq));
    else
        [responseFiltTmp(:,mod(nSeq,2)+1),filterInit]=filter(bFilter,aFilter,Titan.response{end}(:,nSeq),filterInit);
        if mod(nSeq,2)
            rmsSweepNoise=rms(diff(responseFiltTmp,1,2)./sqrt(2))/micSensAvg;
            if dbspl(rmsSweepNoise)>dBmaxSweepNoise
                nSeq=nSeq+1;
                continue
            end
            
            for nBlock=1:Nblocks
                blockSign=1-2*(nBlock==Nblocks);
                iSeq=(blockLength*(nBlock-1)+1:blockLength*nBlock)+(nBlock-1)*(filterDelay+clickDelay);
                seqA(:,nBlock,nSweep)=responseFiltTmp(iSeq,1)*blockSign;
                seqB(:,nBlock,nSweep)=responseFiltTmp(iSeq,2)*blockSign;
            end
            
            meanSeqA=sum(mean(seqA,3),2)/(Nblocks-2).*timeWindow;
            meanSeqB=sum(mean(seqB,3),2)/(Nblocks-2).*timeWindow;
            
            OAE=mean([meanSeqA meanSeqB],2);
            noise=mean([meanSeqA -meanSeqB],2);
            
            fftOAEoctBnd=octbndsum(dft(OAE)./(Hfilter.*micSens),freq,bandCenterFreqs);
            fftNoiseOctBnd=octbndsum(dft(noise)./(Hfilter.*micSens),freq,bandCenterFreqs);
            
            for nClick=find(~all(stimulus==0))
                set(clickPlot(nClick),'xdata',t,'ydata',seqA(:,nClick,nSweep)/micSensAvg)
            end
            set(residualAplot,'xdata',t,'ydata',meanSeqA*1e3/micSensAvg);
            set(residualBplot,'xdata',t,'ydata',meanSeqB*1e3/micSensAvg);
            set(fftResidualOctBndPlot,'xdata',log10(bandCenterFreqs),'ydata',dbspl(fftOAEoctBnd))
            set(fftNoiseOctBndPlot,'xdata',log10(bandCenterFreqs),'ydata',dbspl(fftNoiseOctBnd))
            title(hTitle,[num2str(nSweep) ' / ' num2str(maxSweeps) ' sweeps'])
            drawnow
            
            if (length(find(dbspl(fftOAEoctBnd)-dbspl(fftNoiseOctBnd)>dBSNRbandPass))>=NpassBands  &&...
                nSweep>=minSweeps) || nSweep>=maxSweeps
                break
            end
            nSweep=nSweep+1;
        end
    end
    nSeq=nSeq+1;
    pause(eps)
end
Titan.StopLogging();
Titan.StopInstrument();