i3clear

load('WBTclickIOWA')

fs=44100;
Titan=Titan(fs);

%% Settings
temperatureCal=23;
pressureCal=101325;

ch=2;
level=450;
Ntubes=4;
Nblocks=128;
blockLength=2048;

%% Initialize
freq=((0:blockLength/2-1)*fs/blockLength).';

stimulusDelay=round((blockLength-length(stimulus)-transientDecay)/2);
stimulus=[zeros(stimulusDelay,1);stimulus;zeros(blockLength-length(stimulus)-stimulusDelay,1)];
fftStimulus=dft(stimulus);

timeWindow=tukeywin(blockLength,2*stimulusDelay/blockLength);

%% Calibration
Titan.StartStimulation(level*stimulus,ch);
for nTube=1:Ntubes
    disp(['Place probe in tube ' num2str(nTube) ' and press any key...'])
    commandwindow
    pause
    
    Titan.InitializePressure();
    Titan.LogResponses(Nblocks);
    
    meanResponseCal(:,nTube)=mean(Titan.response{nTube}.*timeWindow,2);
    fftResponseCal(:,nTube)=dft(meanResponseCal(:,nTube));
end
Titan.StopInstrument();

[Ps,Zs,Zref,Zest,epsilon,rho,c,zeta,L]=CalcWBTcal(fftResponseCal,freq,temperatureCal,pressureCal);

%% Plot
figure('units','normalized','outerposition',[0.5 0.05 0.4 0.92])
blue=[0 0.4470 0.7410];red=[0.8500 0.3250 0.0980];

subplot(3,1,1);
semilogy(freq,abs(Zest),'color',red,'linewidth',2);hold all;
semilogy(freq,abs(Zref),'color',blue,'linewidth',2);
xlim([0 12000]);ylim([1e5 1e10]);set(gca,'ytick',10.^(5:10))
xlabel('Frequency [Hz]');ylabel('Impedance magnitude [Pa\cdots/m^3]');
grid;

subplot(3,1,2);
plot(freq,angleDeg(Zest),'color',red,'linewidth',2);hold all;
plot(freq,angleDeg(Zref),'color',blue,'linewidth',2);
xlim([0 12000]);ylim([-100 100]);set(gca,'ytick',-90:45:90)
xlabel('Frequency [Hz]');ylabel('Impedance phase [Deg.]');
grid;

subplot(3,1,3);
semilogy(freq,epsilon,'linewidth',2);hold all;
xlim([0 12000]);ylim([1e-5 10]);set(gca,'ytick',10.^(-5:1))
xlabel('Frequency [Hz]');ylabel('Relative calibration error');
grid;

%% Save
calStr=['wbtCal_' datestr(now,'yymmdd_HHMMSS')];
save(['Calibration/' calStr],...
    'Ps','Zs','Zest','Zref','epsilon',...
    'meanResponseCal','fftResponseCal','stimulus','fftStimulus',...
    'fs','blockLength','freq','timeWindow','ch','level','Ntubes',...
    'temperatureCal','pressureCal','rho','c','calStr')