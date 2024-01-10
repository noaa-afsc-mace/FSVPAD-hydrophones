function uAural_Check_DAQ_Gain(g)
% Author: C. Bassett
% Last Modified: 11 April 2018
% in g: The DAQ gain
% Prompts user if the defauly gain is correct. 
% If yes, it assigns the default to the workspace.
% If no, it calls Cal_Gain_GUI and the user can select
% from the four available gain options

dlgq = sprintf('Is the DAQ Gain %i dB?',g);
DAQgain_answer = questdlg(dlgq, ...
	'DAQ Gain', ...
	'Yes','No','Yes');

% Check if happy with default?
% If no answer is selected than default (18 dB is used)
if strcmp('No',DAQgain_answer)
    Cal_Gain_GUI();                    % Call GUI
else
    assignin('base','g',18);           % assign result to workspace
end

end

