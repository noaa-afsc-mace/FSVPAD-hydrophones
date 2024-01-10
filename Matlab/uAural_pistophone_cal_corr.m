function [cal_corr] = uAural_pistophone_cal_corr(h_sn)
% Author:Alex De Robertis
% Last Modified: 10/24/23

% This script takes finds the correction from a pistophone calibration for
% for the HTI-96min hydrophone given the input hydrophone serial number
% Use uAural_Calibration.m to get the results
% eg.
% GOOD CAL, Hydrophone 382293 (-164.0 dB re 1V/uPa), Pistonphone Signal 145.6 dB re 1 uPa, Expected: 145.9 dB
% gives a correction of 0.4
% Serial numbers
%
% GOOD CAL, Hydrophone 382293 (-164.0 dB re 1V/uPa), Pistonphone Signal 145.6 dB re 1 uPa, Expected: 145.9 dB *** Differed by 0.3 dB ****
%GOOD CAL, Hydrophone 382295 (-164.5 dB re 1V/uPa), Pistonphone Signal 146.0 dB re 1 uPa, Expected: 146.4 dB *** Differed by 0.4 dB ****
%GOOD CAL, Hydrophone 382299 (-164.6 dB re 1V/uPa), Pistonphone Signal 145.2 dB re 1 uPa, Expected: 146.6 dB  Re-calibrated 10/23/23 *** Differed by 1.4 dB ****

h.list = {'382278';'382293';'382295';'382299';'382313';'382314'};

% Manufacturer specified gains
% e.g 0.3 from 

h.cal_corr = [0,0.3,0.4,1.4,0,0]; 

% First check to make sure the serial number is in the table
% If not, exit code and provide instruction
if ~ismember(h.list,h_sn)
    fprintf('\n\n')
    fprintf('Hydrophone serial number does not match list. \n')
    fprintf('Check directory name to ensure it matches the \n')
    fprintf('hydrophone serial number \n\n')
    
    fprintf('Either rename the directory or edit the \n')
    fprintf('uAural_gain script to include the new serial number and gains \n\n\n')

    return
else
    % find index matching the series number
    hind = find(ismember(h.list,h_sn));
end

% pass gain back to the bulk processing script
cal_corr = h.cal_corr(hind);

end