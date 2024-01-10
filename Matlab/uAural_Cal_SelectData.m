function xin = uAuralCal_SelectData(t,y,yfil)
% Author: C. Bassett
% Last Modified: 11 April 2018

% This code is used to plot and select a time series 
% associated with pistonphone measurements

myfiguresize = [1 1 8 6];
figure(1)
fsize = 14;     % font size
set(0, 'DefaultAxesFontSize', fsize)
set(gcf,'color','w','units','inches','position',myfiguresize)
plot(t,yfil,'k')
xlabel('Time (sec)','fontweight','bold')
ylabel('Pres. (Pa)','fontweight','bold')
title({'Select a 10 sec. (or longer) portion of the signal', ...
       'over which the signal is loud and flat (no transients).',...
       '                                                       ',...
       'Select points in chronological order.',...
       'After selecting points press "Enter" on the keyboard.'}) 

maxy = ceil(max(abs(yfil))./100).*100;   
%set(gca,'ylim',[-maxy maxy])  

[xin,yin] = ginput;
xin = floor(xin);

close 