% SL plots.m
% code to make plots after running SL calcluations
% Written by Chris Bassett and Alex De Robertis
%Last edits: 3 Jan, 2024

%% Get SNR flags for plots  

% flag TOBs with SNRs >3 dB on at least 1 hydrophone
SNRflagbad = find(isnan(SL.TOL_SNR_3dB)==1);

% flag TOBs with SNRs > 6 dB on all hydrphones (good enough)
SNRflaggood = find(SL.index_all_hyds_SNR6dB);

% flag TOBs with SNRs 3 dB < SNR < 6 dB, or 1 or more hydrophones excluded (acceptable; not great)
SNRflagok = setdiff(1:length(SL.fTOL),[SNRflagbad;SNRflaggood ]);

%% Load in the curves for the noise quieted vessel standard
% NL includes a frequency vector and narrowband radiated noise level (at
% 1 m). When plotting against this we need to convert to 1 Hz bands.
NL = ICES_spec;


%% Figure: Radiated noise compared to ICES Spec (stoplight version)
% displays the 'raw data' in red, and the SNR-corrected data in orange and
% green
% two lines to used to set the max on the y-axis
maxtl = max( SL.TOL_raw); % find max
maxtl = ceil(maxtl./10)*10 +10; % Divide by ten and round up
% then multiply by 10 and add 10. Makes max on y-axis at most 20 dB above
% maximum TOL
% Now do similar for the minimum
mintl = min( SL.TOL_raw); 
mintl = floor(mintl./10)*10 -10;

figure(1)
myfiguresize = [2,0.5, 3.2, 2.7];
set(gcf,'color','w','units','inches','position',myfiguresize)
hold on
h1=plot(NL.f,NL.SPL,'color',[0.5 0.5 0.5],'linewidth',2)


if ~isempty('SNRflagbad')
h2=plot(SL.fTOL(SNRflagbad), SL.TOL_raw(SNRflagbad)-...
     10.*log10(SL.TOLbw(SNRflagbad)),'s','markerfacecolor','r','color','r')
end
if ~isempty('SNRflagok')
h3=plot(SL.fTOL(SNRflagok), SL.TOL_raw(SNRflagok)-...
    10.*log10(SL.TOLbw(SNRflagok)),'s' ,'markerfacecolor',[230 159 0]./256, 'color',[230 159 0]/256)
end
if ~isempty('SNRflaggood')
h4=plot(SL.fTOL(SNRflaggood), SL.TOL_SNR_3dB(SNRflaggood)-...
    10.*log10(SL.TOLbw(SNRflaggood)), 's', 'markerfacecolor',[0 0.5 0],'color',[0 0.5 0])
end

axis([9 10^5 90 maxtl])
box on
set(gca,'xscale','log','linewidth',2)
set(gca,'xtick',[10 100 1000 10000 100000])
xlabel('Frequency (Hz)','fontweight','bold')
ylabel({'Radiated Noise'; '[dB re 1\muPa/Hz at 1 m]'},'fontweight','bold')
legend([h1 h2 h3 h4],'ICES Spec','<3 dB','>3 dB','>6 dB','location','Northeast')
figname = [resultspath '\RadiatedNoise_vs_ICES_Spec.png']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)

%% Figure: Radiate noise compared to ICES Spec (plotting only SNR>3 dB)
figure(11)
myfiguresize = [2,0.5, 3.2, 2.7];
set(gcf,'color','w','units','inches','position',myfiguresize)
hold on
h1=plot(NL.f,NL.SPL,'color',[0.5 0.5 0.5],'linewidth',2)
%h2=plot(SL.fTOL(SNRflaggood), SL.TOL_SNR_3dB(SNRflaggood)-10.*log10(SL.TOLbw(SNRflaggood)),'k','linewidth',2)
h2=plot(SL.fTOL, SL.TOL_SNR_3dB-10.*log10(SL.TOLbw),'k','linewidth',2)

axis([9 10^5 90 maxtl])
box on
set(gca,'xscale','log','linewidth',2)
set(gca,'xtick',[10 100 1000 10000 100000])
xlabel('Frequency (Hz)','fontweight','bold')
ylabel({'Radiated Noise'; '[dB re 1\muPa/Hz at 1 m]'},'fontweight','bold')
legend([h1 h2],'ICES Spec','Valid data','location','Northeast')
figname = [resultspath '\FORMAL_RadiatedNoise_vs_ICES_Spec.png']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)





%% Figure SL at 1 m (formal version) - with no ICES curve
figure(22)
myfiguresize = [2,0.5, 3.2, 2.5];
set(gcf,'color','w','units','inches','position',myfiguresize)
hold on
plot(SL.fTOL, SL.TOL_SNR_3dB,'k','linewidth',2)
axis([9 10^5 mintl maxtl]), box on
set(gca,'xscale','log','linewidth',2)
set(gca,'xtick',[10 100 1000 10000 100000])
xlabel('Frequency (Hz)','fontweight','bold')
ylabel({'Radiated Noise'; '[dB re 1\muPa at 1 m]'},'fontweight','bold')
set(findall(gcf,'-property','FontSize'),'FontSize',10)

figname = [resultspath '\FORMAL_Radiated_Noise.png']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)


%% Figure of SNR by TOL for hydrophone depths (stoplight version)
minSNR = ceil(min([SL.SNRS;SL.SNRM; SL.SNRD])./10)*10-10;
maxSNR = ceil(max([SL.SNRS;SL.SNRM; SL.SNRD])./10)*10+5;

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
legend([h1 h2 h3],'Shallow','Mid','Deep','location','southeast')
axis([9 10^5 minSNR maxSNR])
set(gca,'xtick',[10 100 1000 10000 100000]), box on
set(gca,'xscale','log','linewidth',2)
xlabel('Frequency (Hz)','fontweight','bold')
ylabel('SNR [dB]','fontweight','bold')
set(findall(gcf,'-property','FontSize'),'FontSize',10)
set(gca, 'Layer', 'Top');
figname = [resultspath '\Noise_Test_SNRs.png']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)


%% Figure of SNR by TOL for hydrophone depths (formal version)

figure(33)
myfiguresize = [2,0.5, 3.2, 2.8];
set(gcf,'color','w','units','inches','position',myfiguresize)
hold on
h1=plot(SL.fTOL, SL.SNRS,'k','linewidth',2)
h2=plot(SL.fTOL, SL.SNRM,'color',[0.5 0.5 0.5],'linewidth',2)
h3=plot(SL.fTOL, SL.SNRD,'b','linewidth',2)
legend([h1 h2 h3],'Shallow','Mid','Deep','location','northwest')
axis([9 10^5 minSNR maxSNR])
set(gca,'xtick',[10 100 1000 10000 100000]), box on
set(gca,'xscale','log','linewidth',2)
xlabel('Frequency (Hz)','fontweight','bold')
ylabel('SNR [dB]','fontweight','bold')
set(findall(gcf,'-property','FontSize'),'FontSize',10)
set(gca, 'Layer', 'Top');
figname = [resultspath '\FORMAL_Noise_Test_SNRs.png']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)


%% Figure of range (TOLmax-TOLmin) for different hydrophone depths

maxrange = ceil(max([S.SL.TOLRange; M.SL.TOLRange; D.SL.TOLRange])./...
                10)*10;
            
figure(4)
myfiguresize = [2,0.5, 3.2, 2.5];
set(gcf,'color','w','units','inches','position',myfiguresize)
hold on
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
figname =[resultspath '\Range_of_Noise.png']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)




%% Figure w/ radiated noise plots (all passes) for all hydrophones
figure(5)
fns = fields(DWT);

myfiguresize = [2,0.5, 3.2, 4.5];
set(gcf,'color','w','units','inches','position',myfiguresize)

subplot(311)
hold on
for j = 1:length(fns)
h1=plot(SL.fTOL, S.(fns{j}).SL_TOL,'k','linewidth',2)
end
axis([9 10^5 mintl maxtl]), box on
set(gca,'xscale','log','linewidth',2,'xtick',...
[10 100 1000 10000 100000],'xticklabel','')
title('Shallow Hydrophone')

subplot(312)
hold on
for j = 1:length(fns)
h1=plot(SL.fTOL, M.(fns{j}).SL_TOL,'k','linewidth',2)
end
axis([9 10^5 mintl maxtl]), box on
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
figname = [resultspath '\RadiatedNoise_All_Passes']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)


%% Figure - plot an example of ambient vs radiated at CPA for all passes
 
figure(90)
myfiguresize = [2,0.5, 3.2*4, 2.3];
set(gcf,'color','w','units','inches','position',myfiguresize)

subplot(1,3,1)
plot(SL.fTOL,AmbientS.TOL,'k','linewidth',2), hold on
for i=1:size(S.TOLarray,2)
plot(SL.fTOL,S.P1.TOL(:,i),'color',...
    [0.5 0.5 0.5],'linewidth',2)
end
axis([9 10^5 60 120])
set(gca,'xscale','log','linewidth',2,'xtick',[10 100 1000 10000 100000])
set(gca,'ytick',[50:20:130])
xlabel('Frequency (Hz)','fontweight','bold')
ylabel('TOL (dB re 1\muPa)','fontweight','bold')
legend('Ambient','CPA','location','southwest')
title('Shallow hydrophone')

subplot(1,3,2)
plot(SL.fTOL,AmbientM.TOL,'k','linewidth',2), hold on
for i=1:size(M.TOLarray,2)
plot(SL.fTOL,M.P1.TOL(:,i),'color',...
    [0.5 0.5 0.5],'linewidth',2)
end
axis([9 10^5 60 120])
set(gca,'xscale','log','linewidth',2,'xtick',[10 100 1000 10000 100000])
set(gca,'ytick',[50:20:130])
xlabel('Frequency (Hz)','fontweight','bold')
ylabel('TOL (dB re 1\muPa)','fontweight','bold')
legend('Ambient','CPA','location','southwest')
title('Middle hydrophone')

subplot(1,3,3)
plot(SL.fTOL,AmbientD.TOL,'k','linewidth',2), hold on
for i=1:size(D.TOLarray,2)
plot(SL.fTOL,D.P1.TOL(:,i),'color',...
    [0.5 0.5 0.5],'linewidth',2)
end
axis([9 10^5 60 120])
set(gca,'xscale','log','linewidth',2,'xtick',[10 100 1000 10000 100000])
set(gca,'ytick',[50:20:130])
xlabel('Frequency (Hz)','fontweight','bold')
ylabel('TOL (dB re 1\muPa)','fontweight','bold')
legend('Ambient','CPA','location','southwest')
title('Deep hydrophone')

set(findall(gcf,'-property','FontSize'),'FontSize',10)
figname = [resultspath '\Ambient_vs_CPA']
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)

%% Overview plot showing final results filtered for SNR
% data with SNR >3 at at least some hydrophones showin in orange
% data with SNR >6 on all hydrophones shown in green
% data from indvidual passes shown as dots
 
figname=[resultspath '\Result_overview_vs_ICES_SPEC']
figure
myfiguresize = [2,0.5, 3.2, 2.7]*1.75;
set(gcf,'color','w','units','inches','position',myfiguresize)
hold on

ind=SL.index_all_hyds_SNR6dB>0; % index for highest quality data
%plot the figure
plot(NL.f,NL.SPL,'color',[0.5 0.5 0.5],'linewidth',2) % ICES 209
plot(SL.fTOL,SL.TOL_SNR_3dB-10*log10(SL.TOLbw),'color',[230 159 0]./256,'linewidth',2) % One third octave band result
plot(SL.fTOL(ind),SL.TOL_SNR_3dB(ind)-10*log10(SL.TOLbw(ind)),'color',[0 0.5 0],'linewidth',2) % 2023 OTO result
%plot(SL.fTOL,SL.TOL-10*log10(SL.TOLbw),'g') % 2023 raw data
plot(SL.fTOL, SL.TOL_by_pass_SNR3dB-10*log10(SL.TOLbw),'.k') % individual data points
legend("ICES 209", "> 3dB SNR", ">6 dB SNR","ind. pass")

% now set all the plot options
axis([9 10^5 90 140])
grid on
box on
set(gca,'xscale','log','linewidth',2)
set(gca,'xtick',[10 100 1000 10000 100000])
xlabel('Frequency (Hz)','fontweight','bold','fontsize',14)
ylabel({'Radiated Noise'; '[dB re 1\muPa/Hz at 1 m]'},'fontweight','bold','fontsize',14)
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)

%% Write to command line to tell user it is the code is done
disp('The code finished running.')
disp('Check the Source Level Results directory for figures.')