 %%% Code for creating the directory structure for
%%% radiated noise tests
%%% Written by Chris Bassett
%%% Last edits: 25 Feb 2019
%%% See document manual for explanation of the
%%% directory structure

clear all; close all; clc;
%%
% get the parent directory for the entire experiment
parentpath = uigetdir('title',...
    'Select Parent Directory for Radiated Noise Test Data');

% base directory for the cruise
testname = inputdlg('Enter the vessel name (no spaces): E.g.- OscarDyson',...
             'FSVPAD - Radiated Noise Test', [1 70]);
testname = testname{1};         

% date of the vessel test
testdate = inputdlg('Enter a Test Date (YYYYMMDD): E.g.- 20180315',...
             'FSVPAD - Radiated Noise Test', [1 70]);
testdate = testdate{1};         

% cruise directory is a combination of vessel name and date
cruisedir = [parentpath '\' testname '_' testdate];
mkdir(cruisedir)

% make raw GPS directories
mkdir([cruisedir '\GPS_Files_YMD_' testdate]);
% Adruino GPS
mkdir([cruisedir '\GPS_Files_YMD_' testdate '\Arduino GPS']);
% Python distance outputs
mkdir([cruisedir '\GPS_Files_YMD_' testdate '\Distance']);
% Python data logger (ship and FSVPAD) files
mkdir([cruisedir '\GPS_Files_YMD_' testdate '\RawGPS']);
% GPS Results directory
mkdir([cruisedir '\GPS_Results']);

% make base hydrophone directory
mkdir([cruisedir '\Hydrophones']);

% make shallow hydrophone directory
ShallowSN = inputdlg('Enter Serial Number for Shallow Hydrophone:',...
             'FSVPAD - Radiated Noise Test', [1 70]);
ShallowSN = ShallowSN {1};  
mkdir([cruisedir '\Hydrophones\' ShallowSN]);

% make mid hydrophone directory
MidSN = inputdlg('Enter Serial Number for Mid Hydrophone:',...
             'FSVPAD - Radiated Noise Test', [1 70]);
MidSN = MidSN {1};  
mkdir([cruisedir '\Hydrophones\' MidSN]);

% make deep hydrophone directory
DeepSN = inputdlg('Enter Serial Number for Deep Hydrophone:',...
             'FSVPAD - Radiated Noise Test', [1 70]);
DeepSN = DeepSN {1};  
mkdir([cruisedir '\Hydrophones\' DeepSN]);

% make source level (final results) directory
mkdir([cruisedir '\' testname '_' testdate '_Source_Level_Results']);
clear all

fprintf('done')
