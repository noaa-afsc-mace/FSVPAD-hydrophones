clc; clear all; close all
%%% Code for combining processed GPS and hydrophone data for vessel noise 
%%% tests. This code first asks the user to lead in the processed GPS data
%%% and select the data points assocaited with the closest points of 
%%% approach of the vessel during radiated noise tests. The user then
%%% selects the processed hydrophone data for all three hydrophones. GPS
%%% and hydrophone data are then used to match the time stamps and the
%%% sound pressure levels during the relevant tests are matched. Finally,
%%% the slant distance between the vessel and hydrophones are used to
%%% correct for the radiated noise levels and averages are performed
%%% according to the vessel noise standard to calculate the final,
%%% representative radiated noise level for the vessel. 
%%% Written by Chris Bassett
%%% Last edits: 22 Feb 2019

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
S.depth = 27; %hydrophone depth for shallow = 27 m; 
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
load(GPSpath)

[~,Tmin] = min(abs(S.time - min(GPS.time))) 
[~,Tmax] = min(abs(S.time - max(GPS.time))) 

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

figname = [resultspath '\CPA_and_TOL.png']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)

uiwait(msgbox({'Select a 2-min. when vessel was quiet';...
        'and far from ship (see deck log)'}));
    
[x,y] = ginput(2);          % select and input two data points
pause(1)
close all 

[~, minind] = min(abs(x(1) - S.time)); 
[~, maxind] = min(abs(x(2) - S.time));

Ambient.TOL = 10.*log10(nanmean(10.^(S.TOL(:,minind:maxind)./10),2));
Ambient.tminind = minind; clear minind
Ambient.tmaxind = maxind; clear maxmin

%% Process Shallow Passes
Spasses = Process_Pass(S,DWT,alpha,Ambient);
fns = fields(Spasses); 
S.SL.BB = 0;
S.SL.TOL = zeros(length(Spasses.(fns{1}).TOL(:,1)),1);
S.SL.SNR = zeros(length(Spasses.(fns{1}).SNR(:,1)),1);

for i = 1:length(fns)
    S.(fns{i}) = Spasses.(fns{i});
    S.SL.BB = S.SL.BB + 10.^(S.(fns{i}).SL_BB./10);
    S.SL.TOL = S.SL.TOL + 10.^(S.(fns{i}).SL_TOL./10);
    S.SL.SNR = S.SL.SNR + 10.^(S.(fns{i}).SNR./10);
    TOLarray(:,i) = S.(fns{i}).SL_TOL;
end
S.SL.BB = 10.*log10(S.SL.BB./length(fns));
S.SL.TOL = 10.*log10(S.SL.TOL./length(fns)); 
S.SL.SNR = 10.*log10(S.SL.SNR./length(fns)); 
S.SL.TOLmin = min(TOLarray,[],2);
S.SL.TOLmax = max(TOLarray,[],2);
S.SL.TOLRange = S.SL.TOLmax - S.SL.TOLmin;

clear Spasses fns TOLarray
     
%% Now, load in mid-water hydrophone data and process
FileNames = uipickfiles('Prompt',...
                'Select Mid-Water Hydrophone Processed Data',...
                'Type',{'*TOL.mat','.matfiles'});
[path, name, ext] = fileparts(FileNames{1});
load([path '\' name])
M = TOL;
M.depth = 58;                   %hydrophone depth for shallow = 58 m
clear path name ext FilesNames TOL

Mpasses = Process_Pass(M,DWT,alpha,Ambient);
fns = fields(Mpasses); 
M.SL.BB = 0;
M.SL.TOL = zeros(length(Mpasses.(fns{1}).TOL(:,1)),1);
M.SL.SNR = zeros(length(Mpasses.(fns{1}).SNR(:,1)),1);

for i = 1:length(fns)
    M.(fns{i}) = Mpasses.(fns{i});
    M.SL.BB = M.SL.BB + 10.^(M.(fns{i}).SL_BB./10);
    M.SL.TOL = M.SL.TOL + 10.^(M.(fns{i}).SL_TOL./10);
    M.SL.SNR = M.SL.SNR + 10.^(M.(fns{i}).SNR./10);
    TOLarray(:,i) = M.(fns{i}).SL_TOL;

end
M.SL.BB = 10.*log10(M.SL.BB./length(fns));
M.SL.TOL = 10.*log10(M.SL.TOL./length(fns)); 
M.SL.SNR = 10.*log10(M.SL.SNR./length(fns)); 
M.SL.TOLmin = min(TOLarray,[],2);
M.SL.TOLmax = max(TOLarray,[],2);
M.SL.TOLRange = M.SL.TOLmax - M.SL.TOLmin;

clear Mpasses fns TOLarray
 
%% Now, load in deep hydrophone data and process
FileNames = uipickfiles('Prompt',...
                        'Select Deep Hydrophone Processed Data',...
                        'Type',{'*TOL.mat','.matfiles'});
[path, name, ext] = fileparts(FileNames{1});
load([path '\' name])
D = TOL;
D.depth = 100;                  %hydrophone depth for shallow = 100 m
clear path name ext FilesNames TOL

Dpasses = Process_Pass(D,DWT,alpha,Ambient);
fns = fields(Dpasses); 
D.SL.BB = 0;
D.SL.TOL = zeros(length(Dpasses.(fns{1}).TOL(:,1)),1);
D.SL.SNR = zeros(length(Dpasses.(fns{1}).SNR(:,1)),1);
for i = 1:length(fns)
    D.(fns{i}) = Dpasses.(fns{i});
    D.SL.BB = D.SL.BB + 10.^(D.(fns{i}).SL_BB./10);
    D.SL.TOL = D.SL.TOL + 10.^(D.(fns{i}).SL_TOL./10);
    D.SL.SNR = D.SL.SNR + 10.^(D.(fns{i}).SNR./10);
    TOLarray(:,i) = D.(fns{i}).SL_TOL;

end
D.SL.BB = 10.*log10(D.SL.BB./length(fns));
D.SL.TOL = 10.*log10(D.SL.TOL./length(fns)); 
D.SL.SNR = 10.*log10(D.SL.SNR./length(fns)); 
D.SL.TOLmin = min(TOLarray,[],2);
D.SL.TOLmax = max(TOLarray,[],2);
D.SL.TOLRange = D.SL.TOLmax - D.SL.TOLmin;

clear Dpasses fns

%% Get SNR flags for plots
fns =  fields(DWT); 
SNRflagbad = [];
for i = 1:length(fns)
SNRflagbad = [SNRflagbad; find(S.(fns{i}).SNR < 3);... 
     find(M.(fns{i}).SNR < 3); find(D.(fns{i}).SNR < 3)];
end    
SNRflagbad = unique(SNRflagbad);

SNRflagok = [];
for i = 1:length(fns)
SNRflagok = [SNRflagok; find(S.(fns{i}).SNR < 6);... 
     find(M.(fns{i}).SNR < 6); find(D.(fns{i}).SNR < 6)];
end    
SNRflagok = unique(SNRflagok);


%% Now average data from all passes and all depths
SL.BB = 10.*log10( (10.^(S.SL.BB./10) +...
                    10.^(M.SL.BB./10) + 10.^(D.SL.BB./10))./3);
SL.TOL = 10.*log10((10.^(S.SL.TOL./10) +...
                    10.^(M.SL.TOL./10) + 10.^(D.SL.TOL./10))./3);
SL.fTOL = S.fTOL';
SL.SNRS = S.SL.SNR; 
SL.SNRM = M.SL.SNR; 
SL.SNRD = D.SL.SNR; 
SL.RangeS = S.SL.TOLRange;
SL.RangeM = M.SL.TOLRange;
SL.RangeD = D.SL.TOLRange;

% create array with the bandwith of each 1/3 octave band. These will be
% used for comparisons to the ICES standard
SL.TOLbw = (SL.fTOL.*2^(1/6)) - (SL.fTOL./(2^(1/6)));  

%% Load in the curves for the noise quieted vessel standard
% NL includes a frequency vector and narrowband radiated noise level (at
% 1 m). When plotting against this we need to convert to 1 Hz bands.
NL = ICES_spec;

%%
% two lines to used to set the max on the y-axis
maxtl = max( SL.TOL); % find max
maxtl = ceil(maxtl./10)*10 +10; % Divide by ten and round up
% then multiply by 10 and add 10. Makes max on y-axis at most 20 dB above
% maximum TOL
% Now do similar for the minimum
mintl = min( SL.TOL); 
mintl = floor(mintl./10)*10 -10;



figure(1)
myfiguresize = [2,0.5, 3.2, 2.7];
set(gcf,'color','w','units','inches','position',myfiguresize)
hold on
h1=plot(NL.f,NL.SPL,'color',[0.5 0.5 0.5],'linewidth',2)
h2=plot(SL.fTOL, SL.TOL-10.*log10(SL.TOLbw),'k','linewidth',5)
plot(SL.fTOL, SL.TOL-10.*log10(SL.TOLbw),'color',[0 0.5 0],'linewidth',2)
if ~isempty('SNRflagok')
plot(SL.fTOL(SNRflagok), SL.TOL(SNRflagok)-...
    10.*log10(SL.TOLbw(SNRflagbad)),...
    'color',[230 159 0]./256,'linewidth',2)
end
if ~isempty('SNRflagbad')
plot(SL.fTOL(SNRflagbad), SL.TOL(SNRflagbad)-...
     10.*log10(SL.TOLbw(SNRflagbad)),'r','linewidth',2)
end
axis([9 10^5 90 maxtl])
box on
set(gca,'xscale','log','linewidth',2)
set(gca,'xtick',[10 100 1000 10000 100000])
xlabel('Frequency (Hz)','fontweight','bold')
ylabel({'Radiated Noise'; '[dB re 1\muPa/Hz at 1 m]'},'fontweight','bold')
legend([h1 h2],'ICES Spec','Data','location','Northeast')
figname = [resultspath '\RadiatedNoise_vs_ICES_Spec.png']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)


figure(2)
myfiguresize = [2,0.5, 3.2, 2.7];
set(gcf,'color','w','units','inches','position',myfiguresize)
hold on
plot(SL.fTOL, SL.TOL,'k','linewidth',4)
h1=plot(SL.fTOL, SL.TOL,'color',[0 0.5 0],'linewidth',2)
if ~isempty('SNRflagok')
h2=plot(SL.fTOL(SNRflagok), SL.TOL(SNRflagok),...
    'color',[230 159 0]./256,'linewidth',2)
end

if ~isempty('SNRflagbad')
h3=plot(SL.fTOL(SNRflagbad), SL.TOL(SNRflagbad),'r','linewidth',2)
end

axis([9 10^5 mintl maxtl])
box on
set(gca,'xscale','log','linewidth',2)
set(gca,'xtick',[10 100 1000 10000 100000])

xlabel('Frequency (Hz)','fontweight','bold')
ylabel({'Radiated Noise'; '[dB re 1\muPa at 1 m]'},'fontweight','bold')
set(findall(gcf,'-property','FontSize'),'FontSize',10)
legend([h1 h2 h3],'SNR > 3 dB','3 dB < SNR < 6 dB',...
       'SNR < 3 dB','location','southwest')
figname = [resultspath '\Radiated_Noise.png']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)

%%
minSNR = ceil(min([SL.SNRS;SL.SNRM; SL.SNRD])./10)*10-10;
maxSNR = ceil(max([SL.SNRS;SL.SNRM; SL.SNRD])./10)*10+10;
 figure(3)
 myfiguresize = [2,0.5, 3.2, 2.8];
set(gcf,'color','w','units','inches','position',myfiguresize)

 hold on
patch([7 97000 9100000 7 7],[3 3 -100 -100 3],...
       'r','facealpha',0.3,'edgecolor','none')
patch([7 97000 9100000 7 7],[6 6 3 3 6],...
       'r','facecolor',[230 159 0]./256,'facealpha',0.3,'edgecolor','none')   
patch([7 97000 9100000 7 7],[100 100 6 6 100],...
       'r','facecolor',[0 0.5 0],'facealpha',0.3,'edgecolor','none')   
      
h1=plot(SL.fTOL, SL.SNRS,'k','linewidth',2)
h2=plot(SL.fTOL, SL.SNRM,'color',[0.5 0.5 0.5],'linewidth',2)
h3=plot(SL.fTOL, SL.SNRD,'b','linewidth',2)
legend([h1 h2 h3],'Shallow','Mid','Deep','location','northwest')
 axis([9 10^5 minSNR maxSNR])
 set(gca,'xtick',[10 100 1000 10000 100000])
 box on
 set(gca,'xscale','log','linewidth',2)
 xlabel('Frequency (Hz)','fontweight','bold')
 ylabel('SNR [dB]','fontweight','bold')
set(findall(gcf,'-property','FontSize'),'FontSize',10)
set(gca, 'Layer', 'Top');
figname = [resultspath '\Noise_Test_SNRs.png']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)


%%


maxrange = ceil(max([S.SL.TOLRange; M.SL.TOLRange; D.SL.TOLRange])./...
                10)*10;

figure(4)
myfiguresize = [2,0.5, 3.2, 2.5];
set(gcf,'color','w','units','inches','position',myfiguresize)

 hold on
%patch([7 97000 9100000 7 7],[3 3 -100 -100 3],'r','facealpha',0.3,'edgecolor','none')
plot([1 100000],[3 3],'--k','linewidth',1)
h1=plot(SL.fTOL, S.SL.TOLRange,'k','linewidth',2)
h2=plot(SL.fTOL, M.SL.TOLRange,'color',[0.5 0.5 0.5],'linewidth',2)
h3=plot(SL.fTOL, D.SL.TOLRange,'b','linewidth',2)
legend([h1 h2 h3],'Shallow','Mid','Deep','location','northwest')
 axis([9 10^5 0 maxrange])
 box on
 set(gca,'xtick',[10 100 1000 10000 100000])

 set(gca,'xscale','log','linewidth',2)
 xlabel('Frequency (Hz)','fontweight','bold')
 ylabel('TOL_{max} - TOL_{min} [dB]','fontweight','bold')
set(findall(gcf,'-property','FontSize'),'FontSize',10)
set(gca, 'Layer', 'Top');
figname = [resultspath '\Range_of_Radiated_Noise_Measurements_by_Depth.png']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)

%% 
figure(5)
fns = fields(DWT)

myfiguresize = [2,0.5, 3.2, 4.5];
set(gcf,'color','w','units','inches','position',myfiguresize)

subplot(311)
hold on
for j = 1:length(fns)
h1=plot(SL.fTOL, S.(fns{j}).SL_TOL,'k','linewidth',2)
end
axis([9 10^5 mintl maxtl])
box on
set(gca,'xscale','log','linewidth',2,'xtick',...
    [10 100 1000 10000 100000],'xticklabel','')
title('Shallow Hydrophone')
%xlabel('Frequency (Hz)','fontweight','bold')
%ylabel('Radiated Noise [dB re 1\muPa at 1 m]','fontweight','bold')

subplot(312)
hold on
for j = 1:length(fns)
h1=plot(SL.fTOL, M.(fns{j}).SL_TOL,'k','linewidth',2)
end
axis([9 10^5 mintl maxtl])
box on
set(gca,'xscale','log','linewidth',2,'xtick',...
    [10 100 1000 10000 100000],'xticklabel','')
ylabel('Radiated Noise [dB re 1\muPa at 1 m]','fontweight','bold')
title('Mid-Water Hydrophone')


subplot(313)
hold on
for j = 1:length(fns)
h1=plot(SL.fTOL, D.(fns{j}).SL_TOL,'k','linewidth',2)
end
axis([9 10^5 mintl maxtl])
box on
set(gca,'xscale','log','linewidth',2,'xtick',[10 100 1000 10000 100000])
xlabel('Frequency (Hz)','fontweight','bold')
title('Deep Hydrophone')

set(findall(gcf,'-property','FontSize'),'FontSize',10)

figname = [resultspath '\RadiatedNoise_All_Passes_And_Depths']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)

%%

