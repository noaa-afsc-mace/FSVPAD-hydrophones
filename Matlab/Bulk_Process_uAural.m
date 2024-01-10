%%% Code for processing of uAural data
%%% Written by Chris Bassett
%%% Last edits: 1 Jan 2024
%
% ADR 13 Oct 2023
% % 2023 wav files from uAural are read in as 'single', which is scaled from
% -1 to +1 rather than bit depth
% altered code to accomodate this.  see L83
% 
% 1 Jan 2024 - Note that made decision not to adjust gains by hydrophone
% pistonphone calibration. We went back and forth on this and ultimately
% decided that the pistophone is better left as a 'system check'.  Results
% for Dyson were very close (for averaged hdrophones within 0.7 dB), so
% really not an important decision.

clear all; close all; clc;
parentpath = uigetdir('title',...
    'Select Matlab Processing Scripts Directory');
addpath(parentpath);
clear parentpath
global proc_para SPL % Define these global variables
% proc_para is for processing parameters
% SPL is for processed sound pressure levels

%% Loop to get all data for further processing

% All files to be processed must be in a single directory
FileNames = uipickfiles('Prompt',...
    'Select Files in Chronological Order',...
    'Type',{'*.wav','WAVfiles'});
files = []; paths = [];             % Initialize these variables
close all                           % close existing windows

% Iterate over file names to get the appropriate files/paths
for ii = 1:length(FileNames)
    [path, name, ext] = fileparts(FileNames{ii});
    files = [files; sprintf('%s',FileNames{ii})];
    paths = [paths; path];
end

% Get hydrophone serial number from the path lengths
Hydrophone_SN = paths(1,end-5:end);
clear name ext path

%% Create Results Directory if it doesn't exist
idsc = strfind(paths(1,:),'\');         % parse path
% Move back one directory from the data source
resultsdir = [paths(1,1:idsc(end) - 1) '\Processed_Hydrophone_Data'];

% Check if we have a pre-existing results directory, if not create it
if ~exist(resultsdir)
    mkdir(resultsdir)
end
clear idsc

%%
tmp = uAural_read([files(1,:)]);    % read one file to get sampling rate
uAural_Processing_para(tmp.fs);     % Calls for for processing parameters
clear tmp                           % Default values appear in GUI

%%
% Voltage factor (to get from 1 V for .wav to +/-5 associated with DAQ)
Cal.V = 5;

% Hydrophone Sensitivity in dB re V/uPa
% ~-165 dBV/uPa for the  HTI-96min
Cal.cal = uAural_gain(Hydrophone_SN);

% Data Acquisition Gain
Cal.DAQgain = proc_para.DAQgain;

% Linear factor for time series
Cal.Volts_to_Pa = 1e6.*power(10,(Cal.cal+Cal.DAQgain)./20);  
Cal.G = Cal.cal+Cal.DAQgain; 

TOLs = uAural_TOBs;

% Loop over all files
cnt = 0;


for ii = 1:length(files(:,1))
    data = uAural_read(files(ii,:)); % load data
    if data.type == "int16"
        data.bits = 16;
        data.AtoD = 2^(data.bits)/2; % Analog to digital factor based on bit depth
    elseif data.type == "int32"
        data.bits = 32;
        data.AtoD = 2^(data.bits)/2; % Analog to digital factor based on bit depth
    elseif data.type=="single"
        if data.fs >= 96000
            data.bits = 16;
            data.AtoD = 1; % a to D is -1 to 1 already
        elseif data.fs <96000
            data.bits = 24;
            data.AtoD = 1; % a to D is -1 to 1 already
        end
    end
    
    % New acoustics data time series normalized to +/- 1
    data.y = double(data.y)./data.AtoD;

% Accounts for voltage limits on the DAQ
data.y = data.y .* Cal.V;

% number of points to overlap, default is 0
overlapN = ceil(proc_para.spec.overlap.*proc_para.spec.NFFT);

% create overlapping time series
y = buffer(data.y, proc_para.spec.NFFT, overlapN,'nodelay');

% check if last window was mostly 0-padding
% if it was more than 50% zero padded then get rid of it.
% this only occurs if the last column has been zero-padded
if sum(y(end-proc_para.spec.NFFT/2:end,end)) == 0
    y(:,end) = [];
end

for iii = 1:length(y(1,:))
    cnt = cnt+1;    % counter
    
    [otoraw,TOB] = oct3bankFc(y(:,iii),proc_para.oto.fs,...
        ones(size(TOLs)),TOLs);
    
    % One-third octave band SPLs
    SPL.TOL(:,cnt) = 10.*log10(otoraw) - Cal.G;
    
    % Calculate BB SPL by integrating the one-third octave bands
    SPL.BB(1,cnt) = 10.*log10(sum(10.^(SPL.TOL(:,cnt)./10)));
    
    % Call function to calculate the frequency spectrum
    [tmpS, tmpf, tmpdf] = uAural_Spec(y(:,iii), ...
        proc_para.spec.fs , proc_para.spec.NFFT,...
        proc_para.spec.win, proc_para.spec.win_cf,Cal.G);
    
    %Call band merging script on uAural_Spec output
    [f.f , SPL.PSD(:,cnt)] = uAural_band_merge(tmpf,tmpS');
    
    % Create frequency arrays for saving
    if ii == 1
        f.TOB = TOB;
    end
    
    % exract the filename in order to create time stamps from it
    [path, name, ext] = fileparts(FileNames{ii});
    
    % create a time stamp from the filename
    time.datenum(:,ii) = datenum(str2double(name(8:11)), ...
        str2double(name(12:13)),str2double(name(14:15)),...
        str2double(name(1:2)),str2double(name(3:4)),...
        str2double(name(5:6)));
    
    % create a date string from the MATLAB date number
    time.datestr(:,ii) = datestr(time.datenum(ii));
    
    % create time array for each processed window (1 sec. intervals)
    % adds 1 sec. for each window starting at the beginning of file
    SPL.time(cnt) = time.datenum(ii) + ((iii-1)/(24*60*60));
    
end
clear y tmp S tmpf tmpdf tmpS

% print name of recently finished file
fprintf('Hydrophone %s: %i of %i files have been processed.\n\n',...
    paths(1,end-5:end),ii, length(files(:,1)) ) ;

end

% Print statement when hydrophone processing is complete
fprintf(['PROCESSING OF HYDROPOHONE %s IS COMPLETE:',...
    ' %i of %i files have been processed.\n\n'],...
    paths(1,end-5:end),ii, length(files(:,1)) ) ;

%%
% some variables that are saved and carried through
% to the output files
[depthstr, SN] = hydrophone_info(files(1,:));

hydronum1 = sprintf('Hydrophone_%s_TOL',paths(1,end-5:end))
fn = [resultsdir '\' hydronum1];
TOL.starttime =  time;
TOL.time =  SPL.time;
TOL.fTOL = f.TOB;
TOL.TOL = SPL.TOL;
TOL.SN = SN;
TOL.BB = SPL.BB;
save(fn,'TOL')

PSD.starttime =  time;
PSD.time =  SPL.time;
PSD.f = f.f;
PSD.PSD = SPL.PSD;
PSD.SN = SN;
hydronum2 = sprintf('Hydrophone_%s_PSD',paths(1,end-5:end))
fn = [resultsdir '\' hydronum2];
save(fn,'PSD','-v7.3')
clear hydronum1 hydronumb2

%% Plot TOL Spectrogram and BB SPL time series
fsize = 10;     % font size
figure(11)
set(0, 'DefaultAxesFontSize', fsize)
myfiguresize = [2,2, 6, 4.6];
set(gcf,'color','w','units','inches','position',myfiguresize)
ah1=axes('units','inches','Position',[0.6 2.6 5 1.8])
h1=pcolor(SPL.time,(f.TOB), SPL.TOL), shading flat
set(gca,'YDir','normal','Ylim', [10 40000])
box on, set(gca,'linewidth',2.5)
set(gca,'XTick',[ floor(SPL.time(1)*24*60/60 )/(24*60/60) :1/24/4: ceil(SPL.time(end)*24*60/60 )/(24*60/60)])
set(gca,'XTickLabel',{})
set(ah1,'clim',[70 120])
set(ah1,'yscale','log')
hcb = colorbar
ylabel('Freq [Hz]','fontweight','bold')
ylabel(hcb, 'SPL [dB re 1\muPa]','fontweight','bold','fontsize',fsize)
pos1 = get(ah1,'Position');
datetick('keepticks', 'keeplimits')

set(hcb,'linewidth',2)

ah2=axes('units','inches','Position',[0.6 0.5 5 1.8])
plot(SPL.time, SPL.BB,'k','linewidth',2)
set(gca,'XTick',[ floor(SPL.time(1)*24*60/60 )/(24*60/60) :1/24/4: ceil(SPL.time(end)*24*60/60 )/(24*60/60)])
set(gca,'ylim',[100 150],'ytick',[100:10:150])
ylabel('BB SPL [dB re 1\muPa]','fontweight','bold')
xlabel('Time','fontweight','bold')
datetick('keepticks', 'keeplimits')
box on, set(gca,'linewidth',2)
pos2 = get(ah2,'position')
set(ah2,'Position',[pos2(1) pos2(2) pos1(3) pos2(4)])
ah2.XLim = ah1.XLim;

figout = sprintf('Hydrophone_%s_TOL_BB_TimeSeries',paths(1,end-5:end))
set(gcf, 'PaperPosition', myfiguresize);
printname = sprintf('Hydrophone_%s_TOL_BB_TimeSeries',paths(1,end-5:end))
printname = [resultsdir '\' printname];
print(printname, '-dpng','-r300')
