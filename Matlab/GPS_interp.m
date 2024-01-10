function GPS = GPS_interp(GPS, st, et)
% Author: C Bassett
% Last modified: 9 April 2018
%
% GPS is global GPS variable with all of the data
% st is the datenumber for the start time
% et is the datenumber for the end time
%
% ADR  8/18/23
% having issue where get multiple values per time interval in a few cases
% causing interp to fail
% so adding code to take the unique values (first GPS fix) if multiple per
% second

dt = 1/(24*60*60); % this is 1 second in datenumber time
t_i = st:dt:et; % create array for interpolated data

% add unique versions
[delme,i]=unique(GPS.shiptime)
GPS.shiplat = interp1(GPS.shiptime(i),GPS.shiplat(i),t_i);
GPS.shiplon = interp1(GPS.shiptime(i),GPS.shiplon(i),t_i);
GPS.shipSOG =  interp1(GPS.shiptime(i),GPS.shipSOG(i),t_i);
GPS.shipCOG = interp1(GPS.shiptime(i),GPS.shipCOG(i),t_i);
GPS.shiptime = t_i;

[delme,i]=unique(GPS.driftertime)
GPS.drifterlat = interp1(GPS.driftertime(i),GPS.drifterlat(i),t_i);
GPS.drifterlon = interp1(GPS.driftertime(i),GPS.drifterlon(i),t_i);
GPS.drifterSOG =  interp1(GPS.driftertime(i),GPS.drifterSOG(i),t_i);
GPS.drifterCOG  = interp1(GPS.driftertime(i),GPS.drifterCOG(i),t_i);
GPS.driftertime = t_i;
GPS.time = GPS.shiptime;
end