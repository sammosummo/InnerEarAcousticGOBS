% This class is only intended to show how the I3 research system can be used.
% First the properties of the class is defined.
% Then the class is being construct with the desired setup and init parameters. 
%
% the 3 function is defined. SetPressure, StartStimulation,
% StopStimulation, these can be used by user of the class.
%
% In the end of the class the call back functions for the events that the research system has.  


classdef HelloWorld < handle
    properties(Access = private)
        i3;
        conf;
        lh event.listener;        
        fs = 22050;%set the sample frequency [Hz].
    end
    properties(Access = public)
        pressure;
        response;
    end
    %% public methods
    methods
        
        %% Constructor
        function self = HelloWorld()
            % construct superclass                        
            self.i3 = I3('Titan'); % instantiate objects            
            % setup event listner for the pressure log.
            self.lh(1) = self.i3.instrument.addlistener('Pressure', @self.LogPressure);            
            % setup event listner for the mic response log.
            self.lh(2) = self.i3.instrument.addlistener('Response', @self.LogResponse);           
            
            self.pressure=[];
            self.response=[];                        
            self.conf = Titan.Conf.Data(); %load the configuration            
            self.i3.instrument.Configure(self.conf); %set the configuration in the device.
                         
        end
        
        %% Destructor
        function delete(self)
            delete(self.i3);
        end
        
        
        function SetPressure(self, target_p, pump_speed, tolerance ) 
            % Supported pump speeds = Fast - Medium - Slow - Veryslow
            self.i3.instrument.SetPressure( target_p, pump_speed, tolerance )                        
            self.lh(1).Enabled = true; % enable the logging of the pressure.
        end
        
        % Method to setup configuration, stimuli and run
        function StartStimulation(self, freq, amplitude_mV, stimulusLength)
            % setup stimulus
            % i3 support only stimulus length > 256
            
            T=1/self.fs; % Sampling period
            t = (0:stimulusLength-1)*T;        % Time vector
            freqStepSize = self.fs/stimulusLength;
            bin_f = round(freq/(freqStepSize));                        
            
            stim = amplitude_mV*sin(2*pi*bin_f*freqStepSize*t).'; % create the stimulus            
            self.i3.instrument.SetStimuli( stim, 2 ); % Set stimulus in the device configuration
                        
            self.conf.input.blockLength = size(stim,1);% update the configuration by changing the block length.
                                                       % block length is the same for stimilus and response
            
            self.i3.instrument.Configure(self.conf); %set the configuration in the device.
                        
            % kick it all off, by set the device to run with the current configuration
            self.i3.instrument.Run(); % run the device with the current configuration                        
            self.lh(2).Enabled = true; % enable the logging of the mic response.
        end                

        % Method to change setup configuration, stimuli while run is active
        function ChangeStimulation(self, freq, amplitude_mV, stimulusLength)
            self.lh(2).Enabled = false; % disable the logging of the mic response.

            % setup stimulus
            % i3 support only stimulus length > 256

            T=1/self.fs; % Sampling period
            t = (0:stimulusLength-1)*T;        % Time vector
            freqStepSize = self.fs/stimulusLength;
            bin_f = round(freq/(freqStepSize));

            stim = amplitude_mV*sin(2*pi*bin_f*freqStepSize*t).'; % create the stimulus
            self.i3.instrument.SetStimuli( stim, 2 ); % Set stimulus in the device configuration

            self.conf.input.blockLength = size(stim,1);% update the configuration by changing the block length.
                                                       % block length is the same for stimilus and response

            self.i3.instrument.Configure(self.conf); %set the configuration in the device.

            % kick it all off, by set the device to run with the current configuration
            self.i3.instrument.Update(); % update the device with the current configuration
            self.lh(2).Enabled = true; % enable the logging of the mic response.
        end
        
        function StopStimulation(self)            
            self.i3.instrument.Stop(); % Set the device to stop                        
            while ( self.i3.instrument.isRunning ) %  wait until the device has stopped.
                pause(0.01)
            end
        end
        
        %% call back functions for events        
        function LogPressure(self, src, data)            
            if isempty(self.pressure)
                self.pressure=data.data;
            else
                self.pressure(end+1)=data.data;
            end
        end
        
        function LogResponse(self, src, data)            
            if isempty(self.response)
                self.response(1,:)=data.data;
            else
                self.response(end+1,:)=data.data;
            end            
        end  
        
    end
end