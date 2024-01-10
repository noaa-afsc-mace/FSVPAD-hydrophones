function [tmp] = uAural_read(fn)
% Author: Chris Bassett
% Last Modifications: 13 Feb. 2018 
% Script to read audio data (.wav) from the uAural
% fn is the input file name, including the filepath
% format of fn: Directory\Filename.wav

[tempy, tempfs] = audioread(fn,'native'); % Read native audio
temptype = whos('tempy');                 % get info about audio signal (e.g., bits)
tmp.y = tempy;                            % temporary audio signal
tmp.fs = tempfs;                          % temporary sampling frequency
tmp.type = temptype.class;                % temporary bit depth

end
