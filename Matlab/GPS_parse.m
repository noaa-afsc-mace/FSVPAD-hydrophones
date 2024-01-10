function [GPS] = gps_parse(fn1,fn2)
% Author: C Bassett
% Last modified: 9 April 2018
%
% Returns GPS structure with file directories/paths, Latitude, Longitude
% serial datenumbers, speed over ground, and course over ground
% Structures are labeled .ship and .drifter for the respective units

[shipfn, GPS.fnpath] = uigetfile('C:\Users\MACE\Documents\*.txt','Select_ship GPS file - looker under Raw GPS');
%[GPS.shipfn, GPS.shipfnpath] = uigetfile('C:\Users\MACE\Documents\*.txt','Select_ship GPS file');
snames = dir([GPS.fnpath shipfn(1:end-7) '*.txt']);
GPS.shipfn = snames.name;
for i = 1:length(snames)
dnames(i).name = ['Drifter' snames(i).name(5:end)]; % Drifter is same path and name except "Drifter" instead of "Ship"
    [st, nmeat] = textread([GPS.fnpath '\' snames(i).name],'%s %s');
    if i == 1
        shipt = st; shipnmeatmp = nmeat;
    else
        shipt = [shipt; st]; 
        shipnmeatmp = [shipnmeatmp; nmeat];
    end
end
clear snames st nmeat

cnt = 1;
for jj = 1:length(shipnmeatmp)
% check proper string construction 
if shipnmeatmp{1}(1) ~= '$'
    continue
end
    
shipnmea = strsplit(shipnmeatmp{jj},',','CollapseDelimiter',0);

% check for empty fields. If any, then skip to next iteration
if length(shipnmea) < 12
    shipnmea = {shipnmea{1:7}, '0', '0',shipnmea{8:end}};
    continue
end

% get ship latitude and longitude
lat = shipnmea{4};
latdir = shipnmea{5};
GPS.shiplat(cnt) = str2double(lat(1:2)) + str2double(lat(3:end))/60;
    if( latdir == 'S')
        GPS.shiplat(cnt) = -1 * GPS.shiplat(cnt);
    end

lon = shipnmea{6};
londir = shipnmea{7};
GPS.shiplon(cnt) = str2double(lon(1:3)) + str2double(lon(4:end))/60;
    if( londir == 'W')
        GPS.shiplon(cnt) = -1 * GPS.shiplon(cnt);
    end

% calculate Matlab time vector
shiptime = shipnmea{2};
shipdate = shipnmea{10};
GPS.shiptime(cnt) = datenum(2000+str2double(shipdate(5:6)),str2double(shipdate(3:4)),str2double(shipdate(1:2)),...
                   str2double(shiptime(1:2)),str2double(shiptime(3:4)),str2double(shiptime(5:6)));

% Get speed and course
GPS.shipSOG(cnt) = str2double(shipnmea{8});
GPS.shipCOG(cnt) = str2double(shipnmea{9});

cnt = cnt + 1;
end
clear jj

% find and remove bad times
badtimes = find(diff(GPS.shiptime)==0);
if length(badtimes) > 0
    for jj = badtimes
        GPS.shiplat(jj) = [];
        GPS.shiplon(jj) = [];
        GPS.shiptime(jj) = [];
        GPS.shipCOG(jj) = [];
        GPS.shipSOG(jj) = [];
    end
end

%% Calculate important drifter GPS parameteres
[dfn, GPS.drift_fnpath] = uigetfile('C:\Users\MACE\Documents\*.txt','Select first Drifter Arduino GPS file - look under Arduino GPS');

% logic to check if DGPS file
a=dir([GPS.drift_fnpath 'DGPS*.txt']);
a=char(a(1).name);
 if strcmp(a(1:4),'DGPS')
     dnames = dir([GPS.drift_fnpath 'DGPS*.txt']);
 else
     dnames = dir([GPS.drift_fnpath 'DrifterGPS*.txt']);
 end

GPS.drifterfn = dnames;
for i = 1:length(dnames)
    nmeat = textread([GPS.drift_fnpath dnames(i).name],'%s');
    if i == 1
       drifternmeatmp = nmeat;
    else
        drifternmeatmp = [drifternmeatmp; nmeat];
    end
end
clear dnames dt dnmeat


cnt = 1;
for jj = 1:length(drifternmeatmp)
    % make sure NMEA string starts with $. if not, jump to next iteration
if drifternmeatmp{1}(1) ~= '$'
    continue
end

drifternmea = strsplit(drifternmeatmp{jj},',','CollapseDelimiter',0);


% check for empty fields. If any, then skip to next iteration
if length(drifternmea) < 12
    drifternmea = {drifternmea{1:7}, '0', '0',drifternmea{8:end}};
    %continue
end

% get drifter latitude and longitude
lat = drifternmea{4};
latdir = drifternmea{5};
GPS.drifterlat(cnt) = str2double(lat(1:2)) + str2double(lat(3:end))/60;
    if( latdir == 'S')
        GPS.drifterlat(cnt) = -1 * GPS.drifterlat(cnt);
    end

lon = drifternmea{6};
londir = drifternmea{7};
GPS.drifterlon(cnt) = str2double(lon(1:3)) + str2double(lon(4:end))/60;

    if( londir == 'W')
        GPS.drifterlon(cnt) = -1 * GPS.drifterlon(cnt);
    end

% calculate Matlab time vector
driftertime = drifternmea{2};
drifterdate = drifternmea{10};
GPS.driftertime(cnt) = datenum(2000+str2double(drifterdate(5:6)),str2double(drifterdate(3:4)),str2double(drifterdate(1:2)),...
                   str2double(driftertime(1:2)),str2double(driftertime(3:4)),str2double(driftertime(5:6)));

% Get speed and course
GPS.drifterSOG(cnt) = str2double(drifternmea{8});
GPS.drifterCOG(cnt) = str2double(drifternmea{9});

cnt = cnt + 1;
end

badtimes = find(diff(GPS.driftertime)==0);
if length(badtimes) > 0
    for jj = badtimes
        GPS.drifterlat(badtimes) = [];
        GPS.drifterlon(badtimes) = [];
        GPS.driftertime(badtimes) = [];
        GPS.drifterCOG(badtimes) = [];
        GPS.drifterSOG(badtimes) = [];
    end
end


end

