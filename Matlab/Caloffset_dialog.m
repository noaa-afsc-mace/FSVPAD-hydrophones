function Caloffin = Caloffset_dialog()
% Author: C. Bassett
% Last Modified: 12 April 2018
% Dialog for the calibration offset 
% due to atmospheric conditions
% Applies to GRAS 42AA or 42AC pistonphones
% This offset is read from the barometer
% in the pistonphone case

defaultoffset = {'0.0'}; % Default of 0 dB for ~ 101.1 kPa

prompt = 'Enter calibration offset due to atmospheric pressure in dB';

Caloffin = inputdlg(prompt,'Calibration offset (dB)',...
                    [1 40],defaultoffset); 

Caloffin = str2double(Caloffin); 
if isempty(Caloffin)
    Caloffin = 0.0;     % If closed with no input set offset to 0
end

