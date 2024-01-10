clear all; close all; clc;
%%
% Author: C. Bassett
% Last modified: 19 Oct 2023
% This code is used as a quality control code to ensure
% that the hydrophone is operating as expected. 
% The user is prompted to select a .wav (audio) file that is 
% associated with pistonphone measurements using the hydrophone.
% It then uses the directory information to deterine the presumed
% sensitivity of the hydrophone. The user is prompted to provide
% an atmospheric pressure offset for the amplitude as read 
% from the barometer shipped with the pistonphone

% The output is an estimated hydrophone sensitivity that is
% written into a CalibrationResults.txt file in the hydrophone
% results directory. Results within a couple dB of the expected
% sensitivity + gain of the system are acceptable.
%
% ADR 18 Oct 2023
% % 2023 wav files from uAural are read in as 'single', which is scaled from
% -1 to +1 rather than bit depth
% altered code to accomodate this.  see L83

% add path for Matlab functions
parentpath = uigetdir('title',...
    'Select Matlab Processing Scripts Directory');
addpath(parentpath); 
clear parentpath

%% 
fn = uipickfiles('Prompt',...
        'Select .wav file with pistonphone measurements',...
        'Type',{'*.wav','WAVfiles'});

% Get path, name, and file extection
[path, name, ext] = fileparts(fn{1});

idsc = strfind(path,'\');         % parse path

% Get path up one directory from the data source
% Write to the Processed_Hydrophone_Data 
resultsdir = [path(1,1:idsc(end)-1) '\Processed_Hydrophone_Data'];

% Check if pre-existing results directory, if not create it
if ~exist(resultsdir)
   mkdir(resultsdir);
end
clear idsc  

% Create Hydrophone serial number string for gain and saving
Hydrophone_SN = path(1,end-5:end);      

%%   
% Voltage factor associated with DAQ. That is, scalar to get 
% from max of +/- 1  for .wav  to +/-5 V associated with DAQ)
Cal.V = 5;                       

% Hydrophone sensitivity from the file's directory
Cal.cal = uAural_gain(Hydrophone_SN);  

% Data Acquisition Gain
Cal.DAQgain = 18;
uAural_Check_DAQ_Gain(Cal.DAQgain);
Cal.DAQgain = g; clear g

% Calibration offset dialog (due to atmospheric conditions)
Cal.Atmos_off = Caloffset_dialog;

% Expected signal amplitude for calibration w/ correction
Cal.Expected = abs(Cal.cal+Cal.DAQgain + Cal.Atmos_off);
% The total without accounting for the atmospheric offset should 
% be 144.2 dB for a GRAS 42AA pistonphone with HTI-96 coupler. This is
% for a typical unit, small deviations exist for specific serial numbers

% Linear factor for time series
Cal.Volts_to_Pa = 1e6.*power(10,(Cal.cal+Cal.DAQgain)./20);   

%%
% read uAural data (.wav) file
data = uAural_read([path(1,:) '\' name ext]);

% bit depth for uAural changes based on sampling frequency
% confirm bit depth from the native .wav data
% 2023 wav files from uAural are read in as 'single', which is scaled from
% -1 to +1 rather than bit depth
% altered code to accomodate this.  see L83

if data.type == "int16"
   data.bits = 16;
   data.AtoD = 2^(data.bits)/2-1; % Analog to digital factor based on bit depth
elseif data.type == "int32"
    data.bits = 32;
    data.AtoD = 2^(data.bits)/2-1; % Analog to digital factor based on bit depth
elseif data.type=="single"
      if data.fs >= 96000
         data.bits = 16;
         data.AtoD = 1; % a to D is -1 to 1 already
      elseif data.fs <96000
         data.bits = 24;
         data.AtoD = 1; % a to D is -1 to 1 already
     end
end

% convert .wav data (-1 to 1) based on bit depth
% data.y is variable name for the acoustics data time series
 data.y = double(data.y)./data.AtoD;    

% Accont for DAQ voltage -5 to 5 V instead of -1 to 1 for .wav
data.y = data.y .* Cal.V;         

% Conversion from voltage to pressure based on sensitivity and gain
data.y = data.y ./ Cal.Volts_to_Pa;

% create times vector for pressure time series
data.t = ([1:length(data.y)]-1)'./data.fs; 

% filter the data. Applies 3-pole bandpass, butterworth filter
% with passbands at 100 to 400 Hz. Pistonphone f = 250 Hz
[b,a] = butter(3,[100, 400]/(data.fs/2),'bandpass');
data.yfil = filter(b,a,data.y); clear a b

%%

% Loop to have user identify/input proper portion of 
% pistonphone time series. Runs until user approves
while 1
% Call GUI and prompt user to select the data    
xin = uAural_Cal_SelectData(data.t,data.y,data.yfil); 
% Convert input times to data indices
xin = xin.*data.fs;
% calculate RMS
data.rms = 20.*log10(rms(data.yfil(xin(1):xin(2)))./1e-6);
% Plot limits at least 10 seconds before and after user limits
t.selmin =floor(data.t(xin(1))/10)*10-10;
t.selmax = ceil(data.t(xin(2))/10)*10+10;

% make figure
figure(1)
fsize = 10;     % font size
set(0, 'DefaultAxesFontSize', fsize)
myfiguresize = [1 1 4.25 3.5]*1.5;
set(gcf,'color','w','units','inches','position',myfiguresize)
plot(data.t, data.yfil,'k','linewidth',2), hold on
plot(data.t([xin(1):xin(2)]), data.yfil([xin(1):xin(2)]),...
                    'color',[0.5 0.5 0.5],'linewidth',1)
xlabel('Time (sec)','fontweight','bold')
ylabel('Pres. (Pa)','fontweight','bold')
set(gca,'DefaultAxesFontSize',fsize,'linewidth',2)
axis([t.selmin t.selmax -100 100])
legend('Filtered Signal','Selected Portion of Signal',...
       'location','southoutside')
set(gca,'ytick',[-100 -50 0 50 100],'xtick',[t.selmin:5:t.selmax])
titlestr = sprintf('Pistonphone Signal: %0.1f',data.rms);
hydrostr = sprintf('S/N %s: %0.1f',...
                   Hydrophone_SN, Cal.cal);
offsetstr = sprintf('%0.1f',abs(Cal.Expected)); 
title({[titlestr ' dB re 1\muPa']; ['Expected Signal: ' offsetstr ' dB re 1\muPa'];,...
       [hydrostr ' dB re 1 V/\muPa']})

% call user dialog for approval of the time series
% if approved, break the while loop and close figure
m = uAural_YN_dialog();
if m == 'Y';
    break
end
close 
end

% save figure to the results directory
figname = [resultsdir '\' Hydrophone_SN '_Pistonphone_TimeSeries']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)

%%
% Output of pistonphone time series is written to a .txt file
Cal.fn = [resultsdir '\' 'CalibrationResults.txt'];  % filename
% Calculate difference between measured and expected SPL
Cal.diff = abs(data.rms - Cal.Expected);

% Write output strings to the calibration file. Strings include
% serial number, hydro. sensitivity, & measured and expected SPL
% "Cal" is "good" if the absolute difference is less than 3.5 dB
if Cal.diff < 3.5 
Cal.writeln = sprintf(['GOOD CAL, Hydrophone %s (%0.1f dB re 1V/uPa),',...
              ' Pistonphone Signal %0.1f dB re 1 uPa,',...
              ' Expected: %0.1f dB'],...
              Hydrophone_SN, Cal.cal,data.rms, Cal.Expected);
else
Cal.writeln = sprintf(['BAD CAL, Hydrophone %s (%0.1f dB re 1V/uPa),',...
              ' Pistonphone Signal %0.1f dB re 1 uPa,',...
              ' Expected: %0.1f dB'],...
              Hydrophone_SN, Cal.cal,data.rms, Cal.Expected);    
end

% Check if the output file exists. If so, write to it.
if exist(Cal.fn,'file')
      fid = fopen(Cal.fn,'at')
      fprintf(fid,[Cal.writeln '\n'])
      fclose('all')
else 
% if file does not exist, create it and then write to it
    fid = fopen(Cal.fn,'at')
    fprintf(fid,[Cal.writeln '\n'])
    fclose('all')
end

%close all
% print to command line saying that the code has finished running
disp('The calibration script is done running...');
