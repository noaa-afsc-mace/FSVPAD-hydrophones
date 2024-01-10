function [S tmpf tmpdf] = uAural_Spec(x, fs, N, win, win_cf)
% Author: Chris Bassett
% Last Modified: 14 Feb. 2018

% Calculates acoustic sound pressure level spectra 
% given a time series and window parameter
% This method assumes the time series has already been converted
% to pressure. Any differences in the calibration/sensitivity as 
% a function of frequency must be accounted for elsewhere.

% Inputs:
% x - time series (already converted to pressure)
      % x may also be an array with multiple time series where 
      % size(x) = [n by m]; each column of the m columns 
      % is the time series with length n
% Bulk_Process_uAural passes single time series data
% and does not average multiple spectra
% fs - sampling rate
% N - number of data points in window
% win - window function (length equals length of x)
% win_cd - window correction factor to account for changes in the 
           % variance of the time series by windowing the data

% Outputs:
% S: sound pressure spectrum in SPL [dB re 1uPa]
% tmpf: frequency vector for spectra
% tmpdf: frequency resolution of spectra [Hz]

% temp. frequency array
tmpf = linspace(0, fs/2, N/2+1)'; tmpf(1) = []; 

% frequency resolution
tmpdf = tmpf(2) - tmpf(1);                   

% remove mean from each window
x = x - nanmean(x);           

% scalar mult. of x and window
x = x.* win;            

% calculate Fourier transform for a 1-sided (real) signal
% also accounts for the window correction factor and proper
% normalization. N = (fs*T) where fs is sampling frequency
% and T is the length (in seconds) of the window
Y = 2 .* win_cf .* abs( fft(x, N)) ./ N ; 

% linear space mean if applicable
Y = nanmean(Y,2);                         

% sound pressure level spectrum based on hydrophone sensitivity
% also remove the negative frequencies for 1-sided spectrum
S = 20 .* log10(Y(2:N/2+1)./1e-6) - 10.*log10(tmpdf);          

end