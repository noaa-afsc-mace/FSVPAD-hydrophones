clc; clear all; close all
%%% Code for combining processed GPS and hydrophone data for vessel  
%%% noise tests. This code first asks the user to lead in the 
%%% processed GPS data and select the data points assocaited
%%% with the closest points of approach of the vessel during 
%%% radiated noise tests. The user then selects the processed 
%%% hydrophone data for all three hydrophones. GPS and hydrophone
%%% data are then used to match the time stamps and the sound
%%% pressure levels during the relevant tests are matched. Finally,
%%% the slant distance between the vessel and hydrophones are used to
%%% correct for the radiated noise levels and averages are performed
%%% according to the vessel noise standard to calculate the final,
%%% representative radiated noise level for the vessel. 


% corrected couple of bugs with plotting for bad passes 10/18/22 ADR
% data stored in S=shallow, M=middle, D=deep,
% added pass by pass third octave band statistics

% 10/24/23 ADR added ambient computation at each hydrophone
% previous version only used the shallow hyrophone to compute SNR
% but this varies by hydrophone (noise is higher in shallow water)
%
% 1/3/24 ADR updated to exclude data with SNR<3 in third octave averages
% If some but not all hydrophones have SNR>3, only the ones with SNR>3 are
% used
% see SL structure for a summary of final results

% add path for Matlab functions
parentpath = uigetdir('title',...
    'Select Matlab Processing Scripts Directory');
addpath(parentpath); 
clear parentpath

resultspath = uigetdir('title',...
    'Select Path for Results Figures');

FileNames = uipickfiles('Prompt','Select Processed GPS Data',...
                        'Type',{'*.mat','.matfiles'});
[path, name, ext] = fileparts(FileNames{1});
load([path '\' name])
% save GPS path for later; it will be loaded in again to identify
% an ambient noise dominated period for SNR assessment
GPSpath = [path '\' name];
                    
GPS_location_GUI
Pick_GPS_Data

% This line pauses the execution of the code until the user
% had entered data into the GUI and the variable exists in the workspace
% it times out after 5 minutes and will result in errors
wait_for_existence('DWT','var',1,600);

% Save processed data in case want to view it again later
fnout = [path '\PassNumber_CPA_Time_Data.mat'];
save(fnout, 'DWT')
clear fnout


%% Now, load in processed hydrophone data
FileNames = uipickfiles('Prompt',...
                        'Select Shallow Hydrophone Processed Data',...
                        'Type',{'*TOL.mat','.matfiles'});
[path, name, ext] = fileparts(FileNames{1});
load([path '\' name])
S = TOL;
S.depth = 26.8; %hydrophone depth for shallow = 26.8 m; 
clear path name ext FilesNames TOL

% calculate acoustic attenuation in dB/m
% inputs: depth (m), salinity (psu), temp (C), ph, frequency (kHz)
% below representative values are chosen and associated errors are small
% (~ 0.6 dB or less) over most of the reasonable oceanographic conditions.
% This values accounts for the typical total slant distance used in
% radiated noise levels calculations. At the lowest frequencies these are
% on the order of 0.2 dB or less
alpha = alpha_sea(50, 33, 15, 8, S.fTOL./1000);

%% Need to get ambient noise level
load(GPSpath);  % first load GPS data

% find indices matching the hydrophone time with
% the GPS timestrings
[~,Tmin] = min(abs(S.time - min(GPS.time))); % pass start
[~,Tmax] = min(abs(S.time - max(GPS.time))); % pass end

% Create a figure that plots distance vs time in top panel
% spectrogram in the lower panel. 
figure(10)
myfiguresize = [2,0.5, 6, 4.5];
set(gcf,'color','w','units','inches','position',myfiguresize)

h2=subplot(211)
hold on
plot(GPS.time, GPS.range,'k','linewidth',2)
plot(DWT.P1.t,DWT.P1.d,'r','linewidth',2)
plot(DWT.P2.t,DWT.P2.d,'r','linewidth',2)
plot(DWT.P3.t,DWT.P3.d,'r','linewidth',2)
plot(DWT.P4.t,DWT.P4.d,'r','linewidth',2)
plot(DWT.P5.t,DWT.P5.d,'r','linewidth',2)
plot(DWT.P6.t,DWT.P6.d,'r','linewidth',2)

set(gca,'xticklabel',{})
ylabel('Range (m)','fontweight','bold')
axis([min(GPS.time) max(GPS.time) 0 max(GPS.range)+200])
datetick
box on
set(gca,'linewidth',2)
set(gca, 'Layer', 'Top');

h1=subplot(212)
pcolor(S.time(Tmin:Tmax), S.fTOL,S.TOL(:,Tmin:Tmax)), shading flat
axis([min(GPS.time) max(GPS.time) 10 30000])
set(gca,'yscale','log','clim',[70 120])
ylabel('TOL (dB re 1\muPa)','fontweight','bold')
xlabel('Time','fontweight','bold')
datetick
box on
set(gca,'linewidth',2)
hcb = colorbar('linewidth',2)
ylabel(hcb,'TOL (dB re 1\muPa)','fontweight','bold')
osize = get(h1,'position')

set(findall(gcf,'-property','FontSize'),'FontSize',10)
set(gca, 'Layer', 'Top');

osize = get(h1,'position')
osize2 = get(h2,'position')
set(h2,'position',[osize2(1) osize2(2) osize(3) osize(4)])

% create dialog asking user to select period associated
% with ambient noise measurements/vessel in neutral
uiwait(msgbox({'Select a 2-min. period when the vessel was';...
        'in neutral and far from ship (see deck log)'}));
    
% select and input two data points
[x,y] = ginput(2);         
pause(1)
close all 

% match the selected timestamps to indices
[~, minind] = min(abs(x(1) - S.time)); 
[~, maxind] = min(abs(x(2) - S.time));

% Calculate average ambient noise as a function of
% 1/3 octave bands for the entire period
%Ambient.TOL = 10.*log10(nanmean(10.^(S.TOL(:,minind:maxind)./10),2));
AmbientS.TOL = 10.*log10(nanmean(10.^(S.TOL(:,minind:maxind)./10),2));

% save ambient noise indices
AmbientS.tminind = minind; clear minind
AmbientS.tmaxind = maxind; clear maxmin

close all 

%% Figure - Ambient and CPA figure
% find indices of GPS times for ambient noise periods
% these will be used to highlight ambient noise period in plot
[~, mnd] = min(abs(x(1) - GPS.time)); 
[~, mxd] = min(abs(x(2) - GPS.time));

% recreate and print previous figure with ambient noise
% and CPA periods highlighted in different colors
figure(10)
myfiguresize = [2,0.5, 6, 4.5];
set(gcf,'color','w','units','inches','position',myfiguresize)

h2=subplot(211)
hold on
plot(GPS.time, GPS.range,'k','linewidth',3)
plot(DWT.P1.t,DWT.P1.d,'r','linewidth',3)
plot(DWT.P2.t,DWT.P2.d,'r','linewidth',3)
plot(DWT.P3.t,DWT.P3.d,'r','linewidth',3)
plot(DWT.P4.t,DWT.P4.d,'r','linewidth',3)
plot(DWT.P5.t,DWT.P5.d,'r','linewidth',3)
plot(DWT.P6.t,DWT.P6.d,'r','linewidth',3)
plot(GPS.time(mnd:mxd), GPS.range(mnd:mxd),'color',[0.5 0.5 0.5],'linewidth',3)

set(gca,'xticklabel',{})
ylabel('Range (m)','fontweight','bold')
axis([min(GPS.time) max(GPS.time) 0 max(GPS.range)+200])
datetick
box on
set(gca,'linewidth',2)
set(gca, 'Layer', 'Top');

h1=subplot(212)
pcolor(S.time(Tmin:Tmax), S.fTOL,S.TOL(:,Tmin:Tmax)), shading flat
axis([min(GPS.time) max(GPS.time) 10 30000])
set(gca,'yscale','log','clim',[70 120])
ylabel('Frequency (Hz)','fontweight','bold')
xlabel('Time','fontweight','bold')
datetick
box on
set(gca,'linewidth',2)
hcb = colorbar('linewidth',2)
ylabel(hcb,'TOL (dB re 1\muPa)','fontweight','bold')
osize = get(h1,'position')

set(findall(gcf,'-property','FontSize'),'FontSize',10)
set(gca, 'Layer', 'Top');

osize = get(h1,'position')
osize2 = get(h2,'position')
set(h2,'position',[osize2(1) osize2(2) osize(3) osize(4)])

% export the figure
figname = [resultspath '\CPA_and_TOL.png']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)


%% Process Shallow Passes
% pass hydrophone, CPA, attenuation, and ambient noise
% information along to calculate radiated noise levels
Spasses = Process_Pass(S,DWT,alpha,AmbientS);
% get the number of passes present in the data set
fns = fields(Spasses); 
% preallocated broadband, TOL, and SNR vectors/arrays with 0
S.SL.BB = 0;   
S.SL.TOL = zeros(length(Spasses.(fns{1}).TOL(:,1)),1);
S.SL.SNR = zeros(length(Spasses.(fns{1}).SNR(:,1)),1);

% interate over passes and calculate relevant noise parameters
for i = 1:length(fns)
    S.(fns{i}) = Spasses.(fns{i});
    S.SL.BB = S.SL.BB + 10.^(S.(fns{i}).SL_BB./10);
    S.SL.TOL = S.SL.TOL + 10.^(S.(fns{i}).SL_TOL./10);
    S.SL.SNR = S.SL.SNR + 10.^(S.(fns{i}).SNR./10);
    TOLarray(:,i) = S.(fns{i}).SL_TOL; % store third octave band by pass
    SNRarray(:,i) = S.(fns{i}).SNR; % Store SNR by apss
end
% Calculate averages and store infomation
S.SL.BB = 10.*log10(S.SL.BB./length(fns));
S.SL.TOL = 10.*log10(S.SL.TOL./length(fns)); 
S.SL.SNR = 10.*log10(S.SL.SNR./length(fns)); 
% Calculate min and max values in TOL arrays
S.SL.TOLmin = min(TOLarray,[],2);
S.SL.TOLmax = max(TOLarray,[],2);
% Use these values to calculate the total ranges observed
% in TOLs as a function of frequency
S.SL.TOLRange = S.SL.TOLmax - S.SL.TOLmin;

S.TOLarray=TOLarray; % adding pass by pass TOL 
S.SNRarray=SNRarray % adding pass by pass SNR
clear Spasses fns TOLarray SNRarray
     
%% Now, load in mid-water hydrophone data and process
% Comments in this section are limited since the processing
% is the same as for the previous hydrophone.
FileNames = uipickfiles('Prompt',...
                'Select Mid-Water Hydrophone Processed Data',...
                'Type',{'*TOL.mat','.matfiles'});
[path, name, ext] = fileparts(FileNames{1});
load([path '\' name])
M = TOL;
M.depth = 57.7;             %hydrophone depth for mid = 57.7 m
clear path name ext FilesNames TOL

% Process ambient at this hydrophone
% match the selected timestamps to indices
[~, minind] = min(abs(x(1) - M.time)); 
[~, maxind] = min(abs(x(2) - M.time));
% Calculate average ambient noise as a function of
% 1/3 octave bands for the entire period
AmbientM.TOL = 10.*log10(nanmean(10.^(M.TOL(:,minind:maxind)./10),2));
% save ambient noise indices
AmbientM.tminind = minind; clear minind
AmbientM.tmaxind = maxind; clear maxmin

Mpasses = Process_Pass(M,DWT,alpha,AmbientM);
fns = fields(Mpasses); 
M.SL.BB = 0;
M.SL.TOL = zeros(length(Mpasses.(fns{1}).TOL(:,1)),1);
M.SL.SNR = zeros(length(Mpasses.(fns{1}).SNR(:,1)),1);


for i = 1:length(fns)
    M.(fns{i}) = Mpasses.(fns{i});
    M.SL.BB = M.SL.BB + 10.^(M.(fns{i}).SL_BB./10);
    M.SL.TOL = M.SL.TOL + 10.^(M.(fns{i}).SL_TOL./10);
    M.SL.SNR = M.SL.SNR + 10.^(M.(fns{i}).SNR./10);
    TOLarray(:,i) = M.(fns{i}).SL_TOL; % store third octave band by pass
    SNRarray(:,i) = M.(fns{i}).SNR; % Store SNR by apss
end
M.SL.BB = 10.*log10(M.SL.BB./length(fns));
M.SL.TOL = 10.*log10(M.SL.TOL./length(fns)); 
M.SL.SNR = 10.*log10(M.SL.SNR./length(fns)); 
M.SL.TOLmin = min(TOLarray,[],2);
M.SL.TOLmax = max(TOLarray,[],2);
M.SL.TOLRange = M.SL.TOLmax - M.SL.TOLmin;

M.TOLarray=TOLarray; % adding pass by pass TOL 
M.SNRarray=SNRarray % adding pass by pass SNR

clear Mpasses fns TOLarray SNRarray
close all
%% Now, load in deep hydrophone data and process
% Comments in this section are limited since the processing
% is the same as for the previous hydrophones.
FileNames = uipickfiles('Prompt',...
                        'Select Deep Hydrophone Processed Data',...
                        'Type',{'*TOL.mat','.matfiles'});
[path, name, ext] = fileparts(FileNames{1});
load([path '\' name])
D = TOL;
D.depth = 100;                  %hydrophone depth for deep = 100 m
clear path name ext FilesNames TOL

% Process ambient at this hydrophone
% match the selected timestamps to indices
[~, minind] = min(abs(x(1) - M.time)); 
[~, maxind] = min(abs(x(2) - M.time));
% Calculate average ambient noise as a function of
% 1/3 octave bands for the entire period
AmbientD.TOL = 10.*log10(nanmean(10.^(M.TOL(:,minind:maxind)./10),2));
% save ambient noise indices
AmbientD.tminind = minind; clear minind
AmbientD.tmaxind = maxind; clear maxmin

Dpasses = Process_Pass(D,DWT,alpha,AmbientD);
fns = fields(Dpasses); 
D.SL.BB = 0;
D.SL.TOL = zeros(length(Dpasses.(fns{1}).TOL(:,1)),1);
D.SL.SNR = zeros(length(Dpasses.(fns{1}).SNR(:,1)),1);
for i = 1:length(fns)
    D.(fns{i}) = Dpasses.(fns{i});
    D.SL.BB = D.SL.BB + 10.^(D.(fns{i}).SL_BB./10);
    D.SL.TOL = D.SL.TOL + 10.^(D.(fns{i}).SL_TOL./10);
    D.SL.SNR = D.SL.SNR + 10.^(D.(fns{i}).SNR./10);
    TOLarray(:,i) = D.(fns{i}).SL_TOL; % store third octave band by pass
    SNRarray(:,i) = D.(fns{i}).SNR; % Store SNR by aps
end
D.SL.BB = 10.*log10(D.SL.BB./length(fns));
D.SL.TOL = 10.*log10(D.SL.TOL./length(fns)); 
D.SL.SNR = 10.*log10(D.SL.SNR./length(fns)); 
D.SL.TOLmin = min(TOLarray,[],2);
D.SL.TOLmax = max(TOLarray,[],2);
D.SL.TOLRange = D.SL.TOLmax - D.SL.TOLmin;

D.TOLarray=TOLarray; % adding pass by pass TOL 
D.SNRarray=SNRarray % adding pass by pass SNR

clear Dpasses fns SNRarray TOLarray




%% Now average data from all passes and all depths
% Averages in individual hydrophone structures already
% include calculations of the mean for each pass and the
% average of all passes combined. Now create new averages from
% all of the hydrophones. All results are allocated to a 
% new variable called SL


% Compute alternate average using only hydroyhones with sufficient SNR
% copy data, add nan if data are SNR<3
SL.S.TOL_SNR3dB=S.SL.TOL;% copy TOL data
SL.S.TOL_SNR3dB(S.SL.SNR<3)=NaN; % flag cases where pass average data>3 dB SNR
SL.M.TOL_SNR3dB=M.SL.TOL;% copy TOL data
SL.M.TOL_SNR3dB(M.SL.SNR<3)=NaN; % flag cases where pass average data>3 dB SNR
SL.D.TOL_SNR3dB=D.SL.TOL;% copy TOL data
SL.D.TOL_SNR3dB(D.SL.SNR<3)=NaN; % flag cases where pass average data>3 dB SNR

% average values at each hydrophone

% for raw data (no SNR criteria applied)
SL.TOL_raw=[S.SL.TOL,M.SL.TOL,D.SL.TOL];% compile mean values for each hyd
tmp=10.^(SL.TOL_raw./10);
SL.TOL_raw=10.*log10(mean(tmp,2)); % compute power average over all hydrophones with valid data
% for valid data (exclude data with SNR>3 dB)
SL.TOL_SNR_3dB_by_hyd=[SL.S.TOL_SNR3dB,SL.M.TOL_SNR3dB,SL.D.TOL_SNR3dB]; % compile mean values for each hyd
tmp=10.^(SL.TOL_SNR_3dB_by_hyd./10);
SL.TOL_SNR_3dB=10.*log10(nanmean(tmp,2)); % compute power average over all hydrophones with valid data

% now, let's make a quality flag
tmp=[S.SL.SNR M.SL.SNR D.SL.SNR];
SL.index_all_hyds_SNR6dB=floor(sum(tmp>=6,2)/3); % is 1 if all hydrophones have SNR of 6 dB
SL.index_all_hyds_SNR3dB=floor(sum(tmp>=3,2)/3); % is 1 if all hydrophone shave SNR or 3 dB
SL.num_hyds_SNR3dB=sum((tmp>3),2); % count of valid hydrophones for 3 dB SNR
SL.num_hyds_SNR6dB=sum((tmp>3),2); % count of valid hydrophones for 3 dB SNR

% zero out any cases with only 1 vaild hydrophone
SL.TOL_SNR_3dB(SL.num_hyds_SNR3dB<2)=NaN


% let's do this pass by pass on TOLarray as well so we have pass by pass
% data
SL.S.TOLarray_SNR3dB=S.TOLarray;% copy TOLarray data
SL.S.TOLarray_SNR3dB(S.SL.SNR<3,:)=NaN; % flag cases where pass average data>3 dB SNR as nan
SL.M.TOLarray_SNR3dB=M.TOLarray;% copy TOLarray data
SL.M.TOLarray_SNR3dB(M.SL.SNR<3,:)=NaN; % flag cases where pass average data>3 dB SNR as nan
SL.D.TOLarray_SNR3dB=D.TOLarray;% copy TOLarray data
SL.D.TOLarray_SNR3dB(D.SL.SNR<3,:)=NaN; % flag cases where pass average data>3 dB SNR as na

for i=1:size(SL.S.TOLarray_SNR3dB,2)
    tmp=[SL.S.TOLarray_SNR3dB(:,i) SL.M.TOLarray_SNR3dB(:,i) SL.D.TOLarray_SNR3dB(:,i)];
SL.TOL_by_pass_SNR3dB(:,i)=10*log10(nanmean(10.^(tmp/10),2));
end


% frequency array
SL.fTOL = S.fTOL';
% SNRs by hydrophone (shallow, mid-water, deep)
SL.SNRS = S.SL.SNR; 
SL.SNRM = M.SL.SNR; 
SL.SNRD = D.SL.SNR; 
% Maximum range of TOL passes
SL.RangeS = S.SL.TOLRange;
SL.RangeM = M.SL.TOLRange;
SL.RangeD = D.SL.TOLRange;

% create array with the bandwith of each 1/3 octave band. 
% These are used for comparisons to the ICES standard
SL.TOLbw = (SL.fTOL.*2^(1/6)) - (SL.fTOL./(2^(1/6)));  

 save([resultspath '\FSVPAD_processing_results'])  % save the processing results as a matlab structure so that they are available later

