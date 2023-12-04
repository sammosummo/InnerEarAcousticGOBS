% Master script to run inner ear assessments for the Acoustic GOBS study.
% This should be the only script Maery et al. need to run.
i3clear
clear; clc; close all;
disp('---------------------------------------')
disp('Acoustic GOBS Inner-Ear Assessments ...')
disp('---------------------------------------')
disp('Adding paths.')
addpath(genpath([pwd '\i3']))
addpath(genpath([pwd '\Functions']))
addpath(genpath([pwd '\Stimuli']))

disp('Searching for Acoustic GOBS calibration.')
prefix='AcousticGOBS';
cals=dir(['Calibration/' prefix 'Cal_*.mat']);
if isempty(cals)
  disp('No calibration file found. Running calibration first.')
  AcousticGOBSCal
end
disp('Calibration(s) found. Using the most recent.')
disp('---------------------------------------')

subjectID=input('Enter subject ID: ','s');
subjectID2=input('Re-enter subject ID: ','s');
while ~strcmp(subjectID,subjectID2)
  disp('Subject IDs do not match. Please try again.')
  subjectID=input('Enter subject ID: ','s');
  subjectID2=input('Re-enter subject ID: ','s');
end
disp(['About to run inner ear assessments on ' subjectID '.'])

for ear={'right','left'}
  
  % 3DT
  fname=['Measurement/' 'AcousticGOBS3DT_' subjectID '_' ear{1} '.mat'];
  disp(['Looking for' fname '.'])
  if ~exist(fname,'file')
    disp([fname 'does not exist.'])
    disp(['About to run 3DT in the ' ear{1} ' ear.'])
    choice=input(['Insert probe in ' ear{1} ' ear now and press ENTER, or type `skip`'],'s');
    if strcmp(choice,'skip')
      disp('WARNING: Skipping measurement!')
      save(fname,'choice');
    else
      AcousticGOBS3DT
    end
  else
    disp([fname 'exists.'])
  end
  disp('---------------------------------------')
  close all
  
  % WBR
  fname=['Measurement/' 'AcousticGOBSWBR_' subjectID '_' ear{1} '.mat'];
  disp(['Looking for' fname '.'])
  if ~exist(fname,'file')
    disp([fname 'does not exist.'])
    disp(['About to run WBR in the ' ear{1} ' ear.'])
    choice=input(['Insert probe in ' ear{1} ' ear now and press ENTER, or type `skip`'],'s');
    if strcmp(choice,'skip')
      disp('WARNING: Skipping measurement!')
      save(fname,'choice');
    else
      AcousticGOBSWBR
    end
  else
    disp([fname 'exists, skipping.'])
  end
  disp('---------------------------------------')
  close all

  % HPR
  fname=['Measurement/' 'AcousticGOBSHPR_' subjectID '_' ear{1} '.mat'];
  disp(['Looking for' fname '.'])
  if ~exist(fname,'file')
    disp([fname 'does not exist.'])
    disp(['About to run HPR in the ' ear{1} ' ear.'])
    choice=input(['Insert probe in ' ear{1} ' ear now and press ENTER, or type `skip`'],'s');
    if strcmp(choice,'skip')
      disp('WARNING: Skipping measurement!')
      save(fname,'choice');
    else
      AcousticGOBSHPR
    end
  else
    disp([fname 'exists, skipping.'])
  end
  disp('---------------------------------------')
  close all
  
  % DPOAE
  fname=['Measurement/' 'AcousticGOBSDPOAE_' subjectID '_' ear{1} '.mat'];
  disp(['Looking for' fname '.'])
  if ~exist(fname,'file')
    disp([fname 'does not exist.'])
    disp(['About to run DPAOE in the ' ear{1} ' ear.'])
    choice=input(['Insert probe in ' ear{1} ' ear now and press ENTER, or type `skip`'],'s');
    if strcmp(choice,'skip')
      disp('WARNING: Skipping measurement!')
      save(fname,'choice');
    else
      AcousticGOBSDPOAE
    end
  else
    disp([fname 'exists, skipping.'])
  end
  disp('---------------------------------------')
  close all

end

disp('Script completed without errors.')
disp('---------------------------------------')




