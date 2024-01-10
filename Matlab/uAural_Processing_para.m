function uAural_Processing_para(samp_f)
% Author: Chris Bassett
% Last Modified: 15 Feb. 2018

% Code sets default processing parameters for uAural data
% proc_para is a pre-existing global variable
% The only input required is the sampling frequency (samp_f) in Hz
% If changes in processing parameters are made when this calls
% the processing parameter GUI, they will be passed back

global proc_para;
proc_para.fs = samp_f;            % sampling frequency [Hz]

proc_para.window_time = [];       % reserved for future use
               % could be used to cut off beginning of file  

% 1/3-octave band default processing parameters
proc_para.oto.fs = samp_f;        % sampling frequency
% lowest 1/3 octave band (center frequency) to calculate
proc_para.oto.f_min = 10;        
% maximum 1/3 octave band (center frequency) to calculate
proc_para.oto.f_max = samp_f/2;      

% SPL spectrum default parameters
% defaults to 1 second of data so freq resolution = 1 Hz
proc_para.spec.NFFT = samp_f;           % total # of points in FFT, N
proc_para.spec.fs = samp_f;             % sampling frequency
proc_para.spec.type = 'Hann';                    % window type
proc_para.spec.win = hann(proc_para.spec.NFFT);  % window Hann default
proc_para.spec.win_cf = sqrt(8/3);      % correction factor (for Hann)
proc_para.spec.overlap = 0;             % overlap fraction of windows 
proc_para.DAQgain = 18;                 % DAQ gain

Processing_GUI;                 % Call the processing parameter GUI

end

