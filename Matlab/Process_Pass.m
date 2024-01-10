function [SS] = Process_Pass(S, DWT, alpha,A)
% This codes takes the received (measured) noise levels
% from a given hydrophone, GPS data associated with specific 
% vessels passes, representative attenuation values for center
% frequency bands, and ambient levels and combines them to
% to calculated the radiated noise levels (at 1 m) for the 
% vessel of interest. The code starts by identifying the total
% number of vessel passes and then iterates for them.
%
% Input Variables:
%  - S: The array of relevant acoustic data from a hydrophone
%  - DWT: GPS data, ranges, and times assocated with each 
%         vessel pass 
%  - alpha: a vector of attenuation rates (dB/m) for every
%           1/3 octave band included in the analysis
%  - A: Ambient noise parameters calculated from user input
% 
%  Author: Chris Bassett
%  Last Edited: 28 Feb. 2019 

% Find the number of passes
fns = fields(DWT);

for j = 1:length(fns)
    % Each pass might have a different number of time stamps
    % in its structure. Interate over these. 
    for i = 1:length(DWT.(fns{j}).t)
        % identify all corresponding indices b/w GPS and hydrophone
        %  hydrophone data sets
        [~,minind(i)] = min(abs(DWT.(fns{j}).t(i)-S.time)); 
    end
% Verify no replicates due to repeated time strings
[iTOL,iGPS,~] = unique(minind); 
% Identify all relevant TOLs, times, distances, slant distances
% and calculate the SNRs
% TOLs
SS.(fns{j}).TOL = S.TOL(:,iTOL)
% times
SS.(fns{j}).time = DWT.(fns{j}).t(iGPS);
% horizontal distance
SS.(fns{j}).d = DWT.(fns{j}).d(iGPS);
% slant distance
SS.(fns{j}).slantd = sqrt(SS.(fns{j}).d.^2 + S.depth.^2);
% signal-to-noise ratio
SNR = SS.(fns{j}).TOL - ...
      repmat(A.TOL,1,length(SS.(fns{j}).TOL(1,:)));
SS.(fns{j}).SNR = 10.*log10(nanmean(10.^(SNR./10),2));

%% deal with SNR stuff. 
% first, find indices with insufficient SNRs to 
% attribute to vessel noise
[SNR3x,SNR3y] = find(SNR < 3);
if ~isempty(SNR3x)
SS.(fns{j}).BadTOL = S.fTOL(unique(SNR3x));
else
SS.(fns{j}).BadTOL = NaN;    
end

% now, find 3 dB < SNR < 10 dB; 
% standard says we need to calculate a noise correction
[SNR10x,SNR10y]  = find(and(SNR > 3, SNR > 10));
if ~isempty(SNR10x)
     SS.(fns{j}).TOL(SNR10x,SNR10y) = ...
         10.*log10(10.^(SS.(fns{j}).TOL(SNR10x,SNR10y)./10) - ...
         10.^(SNR(SNR10x,SNR10y)./10));
end

%%
% Now calculate a radiated noise levels based on received TOLs,
% calculated slant distance from vessel to hydrophone, 
% attenuation, and spherical spreading
RL = SS.(fns{j}).TOL + ... 
 20.*log10(repmat( SS.(fns{j}).slantd,length(SS.(fns{j}).TOL(:,1)),1)) +...
 repmat( SS.(fns{j}).slantd,length(SS.(fns{j}).TOL(:,1)),1).*alpha';
SS.(fns{j}).SL_TOL = 10.*log10(nanmean(10.^(RL./10),2 )); 
SS.(fns{j}).SL_BB = 10.*log10(sum(10.^(SS.(fns{j}).SL_TOL./10))); 
clear iTOL iGPS minind RL i
end