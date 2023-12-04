classdef Titan<handle
% Class for interfacing with the Titan using the Interacoustics Research
% Platform. Use doc('Titan') for a list of available methods and syntax
% help for specific methods, and Titan=Titan(fs) to initiate an object
% with sampling rate fs.
    properties(Access=private)
        i3;
        conf;
        lh event.listener;
        fs;
        iLogPres; % Total number of logged pressures.
        blockLength; % Block length for the present nLog;
        nLog; % Counter for each time StartLogging() or LogResponses() is invoked.
    end
    properties(Access=public)
        pressureAll; % Contains all pressure call-backs since initializing object.
        pressure; % Cell array containing the averaged pressure call-backs for each block n, obj.response{nLog}(:,n). Each time StartLogging or LogResponses is invoked, nLog=nLog+1.
        response; % Cell array containing the microphone responses for each block n, obj.response{nLog}(:,n). Each time StartLogging or LogResponses is invoked, nLog=nLog+1.
    end
    methods(Access=public)
        %% Constructor
        function self=Titan(fs)
            % Constructor for the object with sampling rate fs.
            %
            % obj=Titan(fs);
            self.i3=I3('Titan');
            self.fs=fs;
            
            blockLengthInit=256*fs/22050; % Set initial blockLength to 512 for fs=22050 and 1024 for fs=44100
            self.conf=Titan.Conf.Data();
            self.conf.system.fs=self.fs;
            self.conf.input.blockLength=blockLengthInit;
            self.i3.instrument.SetStimuli(zeros(blockLengthInit,1),1);
            self.i3.instrument.Configure(self.conf);
            self.i3.instrument.Run();
            
            pause(0.1)
            
            self.lh(1)=self.i3.instrument.addlistener('Pressure',@self.LogPressure);
            self.lh(2)=self.i3.instrument.addlistener('Response',@self.LogResponse);
            
            self.lh(1).Enabled=true;
            self.lh(2).Enabled=false;
            
            self.pressureAll=[];
            self.pressure{1}=[];
            self.response{1}=[];
            self.nLog=1;
        end
        
        %% Response methods
        function StartStimulation(self,stimulus,channels,blockLength)
            % Start playback of stimuli.
            %
            % StartStimulation(stimulus,channels,blockLength);
            %
            % Setting blockLength enables block lengths and response call-backs different from the stimulus length.
            if ~exist('blockLength','var')
                blockLength=length(stimulus);
            end
            if mod(length(stimulus),blockLength)~=0 && mod(blockLength,length(stimulus))~=0
                StopInstrument(self);
                error('length(stimulus) must be an integer multiple or fraction of blockLength.')
            end
            self.i3.instrument.SetStimuli(stimulus,channels);
            self.blockLength=blockLength;
            self.conf.input.blockLength=blockLength;
            self.i3.instrument.Configure(self.conf);
            self.i3.instrument.Update();
            self.response{self.nLog}=[];
        end
        
        function StartLogging(self)
            % Initiate response call-backs to start logging responses.
            %
            % StartLogging();
            self.response{self.nLog}=[];
            self.lh(2).Enabled=true;
            while isempty(self.response{self.nLog})
                pause(eps)
            end
        end
        
        function StopLogging(self)
            % Stop logging of responses.
            %
            % StopLogging();
            self.lh(2).Enabled=false;
            self.nLog=self.nLog+1;
        end
        
        function LogResponses(self,Nresp)
            % Log a predefines number of responses.
            %
            % LogResponses(Nresp);
            self.response{self.nLog}=[];
            self.lh(2).Enabled=true;
            while size(self.response{self.nLog}(:,:),2)<Nresp
                pause(eps)
            end
            self.lh(2).Enabled=false;
            self.nLog=self.nLog+1;
        end
        
        function StopInstrument(self)
            % Stop playback, logging, and exit instrument PC mode.
            %
            % StopInstrument();
            self.i3.instrument.Stop();
            while (self.i3.instrument.isRunning)
                pause(0.01)
            end
        end
        
        %% Pressure methods
        function InitializePressure(self)
            % Initialize the pressure for an ambient measurement by pumping slowly to ambient pressure.
            %
            % InitializePressure();
            pumpSpeed='Slow';tolerance=2;
            self.i3.instrument.SetPressure(0,pumpSpeed,tolerance)
            BlockExecution(self,0,0,0)
            pause(0.5)
        end
        
        function EqualizePressure(self)
            % Quickly equalize the pressure to ambient after a pressurized measurement.
            %
            % EqualizePressure();
            pumpSpeed='Fast';tolerance=10;
            self.i3.instrument.SetPressure(0,pumpSpeed,tolerance)
            BlockExecution(self,0,tolerance,0)
        end
        
        function SetPressure(self,targetPressure,pumpSpeed,tolerance,strict)
            % Pump pressure to targetPressure with pumpSpeed and tolerance while blocking script execution.
            %
            % SetPressure(targetPressure,pumpSpeed,tolerance,strict);
            %
            % Available pumpSpeed values are 'Veryslow', 'Slow', 'Medium',
            % and 'Fast'. If strict=1, script execution is interrupted if
            % the pressure cannot be reached. If strict=0, a warning is
            % displayed and script execution continues.
            self.i3.instrument.SetPressure(targetPressure,pumpSpeed,tolerance)
            BlockExecution(self,targetPressure,tolerance,strict)
        end
        
        function SweepPressure(self,targetPressure,pumpSpeed,tolerance)
            % Sweep pressure to specified targetPressure with pumpSpeed and tolerance while continuing script execution.
            %
            % SweepPressure(targetPressure,pumpSpeed,tolerance);
            %
            % Available pumpSpeed values are 'Veryslow', 'Slow', 'Medium',
            % and 'Fast'.
            self.i3.instrument.SetPressure(targetPressure,pumpSpeed,tolerance)
        end
    end
    methods(Access=private)
        %% Utility methods
        function BlockExecution(self,targetPressure,tolerance,strict)
            % Function for blocking script execution during pressure operations.
            blockTimer=tic;
            pumpTimeout=0;
            pause(eps)
            while length(self.pressureAll)<3
                pause(eps)
            end
            pause(eps)
            while abs(self.pressureAll(end)-targetPressure)>tolerance
                pause(eps)
                if toc(blockTimer)>2
                    pressureChange=peak2peak(self.pressureAll(end-19:end));
                    if pressureChange<5 && ~pumpTimeout
                        mark=toc(blockTimer);
                        pumpTimeout=1;
                    end
                    if pumpTimeout && toc(blockTimer)>mark+2
                        if strict
                            self.i3.instrument.SetPressure(0,'Fast',20)
                            self.StopInstrument();
                            error('Pump timeout!')
                        else
                            self.i3.instrument.SetPressure(self.pressureAll(end),'Fast',20)
                            disp('Warning: Pump timeout!')
                            break
                        end
                    end
                end
            end
        end
            
            %function runningBool=IsRunning(self)
            %    runningBool=self.i3.instrument.isRunning;
            %end
            
        %% Call-back functions
        function LogPressure(self,src,data)
            % Call-back for logging pressure.
            if isempty(self.pressureAll)
                self.pressureAll=data.data;
            else
                self.pressureAll(end+1)=data.data;
            end
        end
        
        function LogResponse(self,src,data)
            % Call-back for logging responses. For each logged block, the pressures logged during that block are averaged.
            if isempty(self.response{self.nLog})
                self.response{self.nLog}(:,1)=data.data;
                self.pressure{self.nLog}(1)=mean(self.pressureAll((end-round(self.blockLength/(0.0121*self.fs))):end));
            else
                self.response{self.nLog}(:,end+1)=data.data;
                self.pressure{self.nLog}(end+1)=mean(self.pressureAll(self.iLogPres+1:end));
            end
            self.iLogPres=length(self.pressureAll);
        end
    end
end