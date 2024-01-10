clear all; close all; clc;
%% 
% Author. C Bassett
% Last Modified: 9 April 2018
%
% This code processes the GPS text files written by the Python scripts that
% manage the acquisition of the ship and drifter location data. The user
% must enter start and end times. The code calls three different Matlab
% functions: GPS_parse, GPS_distance, and GPS_interp
% GPS_parse has the used identify the relevant GPS data files
% GPS_distance calculates the distance and bearing between the data points
% GPS_interp interpolates between data points to get the data into 1-second
             % intervals.
% The code outputs a .mat file with the processed data and will also output
% a single figure with distance between the vessel/drifter as a function of
% time. It also includes the bearing as function of time.
%%
%addpath(genpath('C:\Users\alex.derobertis\Work\projects\FSVPAD_hydrophones\DY2308\Dyson'))
global GPS
GPS = GPS_parse;

%%% NEED TO ENTER START AND END TIMES
% FORMAT: (yyyy,mm,dd,hh,mm,ss)
starttime = datenum(2023,07,14,17,0,0);
endtime =  datenum(2023,07,14,20,0,0);

%% Enter the start time/end time
% Use these times to remove any extra data
diff_t = datenum(0,0,0,0,0,1);
[minv, minind] = min(abs(GPS.shiptime-starttime));
GPS.shiplat(1:minind-1) = [];
GPS.shiplon(1:minind-1) = [];
GPS.shiptime(1:minind-1) = [];
GPS.shipSOG(1:minind-1) = [];
GPS.shipCOG(1:minind-1) = [];

[minv, minind] = min(abs(GPS.shiptime-endtime));
GPS.shiplat(minind:end) = [];
GPS.shiplon(minind:end) = [];
GPS.shiptime(minind:end) = [];
GPS.shipSOG(minind:end) = [];
GPS.shipCOG(minind:end) = [];
%%
% Interpolate to fix any missing data points
GPS = GPS_interp(GPS, starttime, endtime); 
clear endtime dt minind minv 

% Use interpolated data to create distances and bearings
[GPS.range, GPS.bearing] = GPS_distance(GPS.drifterlat,GPS.drifterlon,...
                           GPS.shiplat, GPS.shiplon);

%%
figure(1)
subplot(211)
plot(GPS.time,GPS.range,'k','linewidth',2), hold on
xlabel('Time','fontweight','bold')
ylabel('Range (m)','fontweight','bold')
datetick
set(gca,'linewidth',2,'ylim',[0 2*round(max(GPS.range)./1000,0)*1000])
a.ylim = [0 2*round(max(GPS.range)./1000,0)*1000];
subplot(212)
plot(GPS.time,GPS.bearing,'k','linewidth',2)
xlabel('Time','fontweight','bold')
ylabel('Bearing (deg)','fontweight','bold')
datetick
set(findall(gcf,'-property','FontSize'),'FontSize',11)
set(gca,'linewidth',2)

fout = [GPS.fnpath 'Range_Bearing']; 

%% save data
resultsdir = GPS.fnpath;
idsc = strfind(resultsdir,'\');
resultsdir = [resultsdir(1:idsc(end-2) - 1) '\GPS_Results'];

if exist(resultsdir)
   fout = [resultsdir '\' datestr(starttime,30) '_Processed_GPS.mat'];
   save(fout,'GPS')
   figout = [resultsdir '\' datestr(starttime,30) '_Processed_GPS.png'];
   print(figout,'-r300','-dpng')
else
   mkdir(resultsdir)
   fout = [resultsdir '\' datestr(starttime,30) '_Processed_GPS.mat'];
   save(fout,'GPS')
   figout = [resultsdir '\' datestr(starttime,30) '_Processed_GPS.png'];
   print(figout,'-r300','-dpng')
end
clear starttime