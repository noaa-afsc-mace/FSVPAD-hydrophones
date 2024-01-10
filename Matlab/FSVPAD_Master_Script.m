%FSVPAD_Master_Script
% Run this line by line following the instructions in the tech memo
% to process FSVPAD data

%% Add path for Matlab processing scripts
parentpath = uigetdir('title',...
    'Select Matlab Processing Scripts Directory');
addpath(parentpath); 
clear parent path

%%  this makes all of the subdirectories for the test
Make_Test_Directories

%% Perform pistonphone calibrations on each hydrophone
uAural_Calibration % Calibrate hydrophone 1 
uAural_Calibration % Calibrate hydrophone 2 
uAural_Calibration % Calibrate hydrophone 3 
% dependencies - uAural_Check_DAQ_Gain, uAural_gainu, Aural_read, 
% Caloffset_dialog, uAural_Cal_SelectData, Cal_Gain_GUI
 
%% Bulk Processing of GPS Data (raw text files -> .mat file)
% GPS is 7.65m ahead of halfway point between prop and engines
% [be sure to slect the Arduino files for the drifter]
Create_GPS_Distances 
% dependencies - GPS_parse, GPS_interp, GPS_distance

%% Process data - [each hydrophone is processed individually, so repeat 3 times, once for each hydrophone]
Bulk_Process_uAural % process hydrophone 1
Bulk_Process_uAural % process hydrophone 2
Bulk_Process_uAural % process hydrophone 3
 % dependencies - uAural_Processing_para, uAural_read, uAural_gain,
 % uAural_Spec, uAural_TOBs, uAural_YN_dialog,
 %uAural_band_merge, Processing_GUI, hydrophone_info,oct3dsgn, oct3bankFc
 
%% .match GPS data to CPA information and calculate TOL and SNR
SL_Calculations 
% dependencies - GPS_location_GUI, Pick_GPS_Data,ginputax, alpha_sea,
% sw_svel,Process_Pass, ICES_spec, wait_for_existence
% the matlab structures at the end of the process are saved as \results\FSVPAD_processing_results.mat
% in case they are needed later
 
%% Make figures are write them out to the \results directory
SL_plots
 
%% Output text files to the \results directory
SL_text_output

%% Dyson-specific calcuations and reporting  [commented out here, but take a look if desired]
% edit Dyson_2308_FSVPAD_Calcs