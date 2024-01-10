function [ftmp, psdtmp] = uAural_band_merge(ft,psd)
% Author: Chris Bassett
% Last Modified: 10 April 2018

% The raw (1 Hz) sound pressure spectra, when processed for an entire
% deployment in a second intervals produce too much data to be reasonably
% stored and processed later (e.g., about 1 GB per hour). Given that this
% data is only a by-product of processing variable band merging is applied
% to considerably reduce the data volume.

% The band merging
% 1 Hz bands from 10 Hz - 100 Hz
% 3 Hz bands from 100 Hz - 500 Hz
% 6 Hz bands from 500 Hz - 1000 Hz
% 10 Hz bands from 1000 - 10000 Hz
% 20 Hz bands from 10000 - max(freq)
% Note all

% variables in: f - frequency array in 1 Hz bands
%               psd - pressure spectrum 
% variables out: psdtmp - the band merged spectra
%                f - band merged frequency array

% create temporary variables
psdtmp = psd';
ftmp = ft;

% remove values above 100 Hz since no band merging is applied 
% below 100 Hz the frequency resolution is still 1 dB
psdtmp(101:end) = [];
ftmp(101:end) = [];

cnt = 100;
for j = 101:3:499
    cnt = cnt+1;
    psdtmp(cnt,1) = 10.*log10(nanmean(10.^(psd(j:j+2)./10))); 
    ftmp = [ftmp; j+1]; 
end
for j = 502:6:999
    cnt = cnt+1;
    psdtmp(cnt,1) = 10.*log10(nanmean(10.^(psd(j:j+5)./10)));
    ftmp = [ftmp; j+2]; 
end
for j = 1001:10:9999
    cnt = cnt+1;
    psdtmp(cnt,1) = 10.*log10(nanmean(10.^(psd(j:j+9)./10)));
    ftmp = [ftmp; j+4]; 
end
for j = 10001:20:floor(max(ft)./20)*20
    cnt = cnt+1;
    psdtmp(cnt,1) = 10.*log10(nanmean(10.^(psd(j:j+19)./10)));
    ftmp = [ftmp; j+9]; 
end

% Remove points below 10 Hz from freq. and pressure arrays
ftmp(1:9) = [];
psdtmp(1:9,:) = [];
end



