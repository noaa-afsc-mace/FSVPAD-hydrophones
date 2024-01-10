function m = uAural_YN_dialog()
% Author: C. Bassett
% Last Modified: 12 April 2018

% Calls a dialog to ask the user if they approve of the
% pistonphone time series signal that was selected.
% If not, it circles back and has the user re-select 
% a portion of the time series for processing

options.Default = 'No';
goodstr = 'Are you happy with the selected time series?';
choice = questdlg(goodstr,'Select Yes or No','Yes','No',options.Default);

switch choice
    case 'Yes'
        m = 'Y';
    case 'No'
        m = 'N';
    case ''
        m = 'N';
end
end