function bands = uAural_TOBs()
%Author: Chris Bassett
% Last Modified: 14 Feb. 2018
% Creates of table of 1/3-octave band center frequencies
% and passes it back to the processing code
bands = [10 12.5 16 20 25 31.5 40 50 63 80 100,...
         125 160 200 250 315 400 500 630 800 1000,...
         1250 1600 2000 2500 3150 4000 5000,...
         6300 8000 10000 12500 16000 20000 25000 31500];
end