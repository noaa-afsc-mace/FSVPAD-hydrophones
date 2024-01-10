function [gain] = uAural_gain(h_sn)
% Author: Chris Bassett
% Last Modified: 13 Feb. 2018

% This script takes finds the manufacturer specified gain
% for the HTI-96min hydrophone given the input hydrophone serial number

% Serial numbers
h.list = {'382278';'382293';'382295';'382299';'382313';'382314'};

% Manufacturer specified gains
h.gains = [-164.3,-164.0,-164.5,-164.6,-163.4,-163.8]; 

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
gain = h.gains(hind);

end