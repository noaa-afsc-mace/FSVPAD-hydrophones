% This script includes some Dyson 2308 specific checks and calculations
% used in the report
% provided here so that users can see what kinds of additional calculations
% users may
% want to do when processing the data


%clear
% load up the data

fname=[resultspath '\FSVPAD_processing_results'] % load up data from last run
load(fname)

% load up the historical results as DY_history
fname2="DY_radiated_noise_11knots_history_from_reports.mat"
load(fname2)
% create array with the bandwith of each 1/3 octave band. 
DY_history.OTObw = (DY_history.fOTO.*2^(1/6)) - (DY_history.fOTO./(2^(1/6)));  

NL = ICES_spec;

% Calculate SNR by hydrophone (include only 2 hyds if  both are > 3 dB] and
% make addtional graphs and make data summary table
%% FIGURE 2 compare Dyson data with history
 % setup
figname=[resultspath '\DY_11knot_radiated_noise_comparison']
figure
myfiguresize = [2,0.5, 3.2, 2.7]*1.75;
set(gcf,'color','w','units','inches','position',myfiguresize)
hold on

% make the figure
 plot(NL.f,NL.SPL,'color',[0.5 0.5 0.5],'linewidth',2) % ICES 209
 plot(SL.fTOL,SL.TOL_SNR_3dB-10*log10(SL.TOLbw),'k','linewidth',2) % 2023 result
 plot(DY_history.fOTO,DY_history.OTO_2011_93RPM- 10*log10(DY_history.OTObw)) % 2011
 plot(DY_history.fOTO,DY_history.OTO_2010_93RPM- 10*log10(DY_history.OTObw)) % 2010
 plot(DY_history.fOTO,DY_history.OTO_2007_93RPM- 10*log10(DY_history.OTObw)) % 2007
 plot(DY_history.fOTO,DY_history.OTO_2006_93RPM- 10*log10(DY_history.OTObw)) % 2006
 plot(DY_history.fOTO,DY_history.OTO_2004_96RPM- 10*log10(DY_history.OTObw)) % 2004
 legend('ICES 209','2023, 86 RPM', '2011, 93 RPM', '2010, 93 RPM', '2007, 93 RPM', '2006, 93 RPM','2004, 96 RPM', 'location','Northeast')

% now set all the plot options
axis([9 10^5 75 155])
grid on
box on
set(gca,'xscale','log','linewidth',2)
set(gca,'xtick',[10 100 1000 10000 100000])
xlabel('Frequency (Hz)','fontweight','bold','fontsize',14)
ylabel({'Radiated Noise'; '[dB re 1\muPa/Hz at 1 m]'},'fontweight','bold','fontsize',14)
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)

%%  %% FIGURE  compare Dyson data with 2010  noise
 % setup
figname=[resultspath '\DY_2023_and_2010_shaft_noise_comparison']
figure
myfiguresize = [2,0.5, 3.2, 2.7]*1.75;
set(gcf,'color','w','units','inches','position',myfiguresize)
hold on
% make the figure
plot(NL.f,NL.SPL,'color',[0.5 0.5 0.5],'linewidth',2) % ICES 209
plot(SL.fTOL,SL.TOL_SNR_3dB-10*log10(SL.TOLbw),'k','linewidth',2) % 2023 result
plot(DY_history.fOTO,DY_history.OTO_2010_93RPM_shaft_noise- 10*log10(DY_history.OTObw),'b') % 2011 with shaft noise
legend('ICES 209','2023, 86 RPM', '2010, 93 RPM with shaft noise','location','Northeast')

% now set all the plot options
axis([9 10^5 75 155])
grid on
box on
set(gca,'xscale','log','linewidth',2)
set(gca,'xtick',[10 100 1000 10000 100000])
xlabel('Frequency (Hz)','fontweight','bold','fontsize',14)
ylabel({'Radiated Noise'; '[dB re 1\muPa/Hz at 1 m]'},'fontweight','bold','fontsize',14)
set(gcf, 'PaperPosition', myfiguresize);
print('-dpng', '-r300', figname)

