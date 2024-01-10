function [p,f] = oct3bankFc(x,Fs,dBref,Fc) 
% OCT3BANKFC Simple one-third-octave filter bank from defined central freqs
%    [p,f] = oct3bank3(x,Fs,Pref,Fc)
%    computes one-third-octave power spectra of signal vector x. 
%    Implementation based on ANSI S1.11-1986 Order-3 filters. 
%    Sampling frequency Fs [Hz]. Restricted one-third-octave-band 
%    range (from 20 Hz to 20000 Hz). RMS power is computed in each band 
%    and expressed in dB with <dBref> as reference level. 
%
%    [P,F] = oct3bank3(x,Fs,dBref,Fc) returns two length-F row-vectors with 
%    the RMS power (in dB) in P and the corresponding preferred labeling 
%    frequencies (ANSI S1.6-1984) in F. 
%
%    x              -->  time signal     
%    Fs             -->  Sampling Frequency [Hz]
%    dBref          -->  Reference level for dB scale. 
%    Fc             -->  one third octave labels
%
%    See also OCT3DSGN, OCT3SPEC, OCTDSGN, OCTSPEC.

% Author: Christophe Couvreur, Faculte Polytechnique de Mons (Belgium)
%         couvreur@thor.fpms.ac.be
% Last modification: Aug. 23, 1997, 10:30pm.

% References: 
%    [1] ANSI S1.1-1986 (ASA 65-1986): Specifications for
%        Octave-Band and Fractional-Octave-Band Analog and
%        Digital Filters, 1993.
%    [2] S. J. Orfanidis, Introduction to Signal Processing, 
%        Prentice Hall, Englewood Cliffs, 1996.
%
% Revised by Fabio G. Ferraz
% fgferraz@ig.com.br
% Rev.00 06-Jan-2011
% Rev.01 30-Mar-2011
%

%%

%F =[20 25 31.5 40 50 63 80 100 125 160 200 250 315 400 500 630 800 1000 1250, ... 
%i-> 1  2  3    4  5  6  7  8   9   10  11  12  13  14  15  16  17  18   19     
%	 1600 2000 2500 3150 4000 5000 6350 8000 10000 12500 16000 20000]; % Preferred labeling freq. 
%i-> 20   21   22   23   24   25   26   27   28    29    30    31
global proc_para
N = 3; 					% Order of analysis filters. 

%F = [20 25 31.5 40 50 63 80 100 125 160 200 250 315 400 500 630 800 1000 1250, ... 
% 	1600 2000 2500 3150 4000 5000 6350 8000 10000 12500 16000 20000]; % Preferred labeling freq. 

ff = 1000.*2.^([-20:15]./3);  	% Exact center freq. 	
goodTOB = find(and(ff > proc_para.oto.f_min,ff < proc_para.oto.f_max));
F = ff(goodTOB);
FF = [10 12.5 16 20 25 31.5 40 50 63 80 100,...
      125 160 200 250 315 400 500 630 800 1000 1250 1600 2000 2500 3150 4000 5000,...
      6300 8000 10000 12500 16000 20000 25000 31500]; %[1.25 1.6 2 2.5 3.15 4 5 6.3 8 40000 50000 63000 80000 100000


for id=1:length(Fc)
     iF(id)=find(FF==Fc(id)); %#ok<AGROW>

end
ff=ff(iF);

P = zeros(1,length(Fc));
m = length(x); 

% Design filters and compute RMS powers in 1/3-oct. bands
% 20000 Hz band to 1600 Hz band, direct implementation of filters. 
if iF(end)>=24
    for i = iF(end):-1:22
       [B,A] = oct3dsgn(ff(i),Fs,N);
       y = filter(B,A,x); 
       P(i) = sum(y.^2)/m; 
    end
end
%%
if iF(end)>=24
    % 2500 Hz to 20 Hz, multirate filter implementation (see [2]).
    [Bu,Au] = oct3dsgn(ff(24),Fs,N); 	% Upper 1/3-oct. band in last octave. 
    [Bc,Ac] = oct3dsgn(ff(23),Fs,N); 	% Center 1/3-oct. band in last octave. 
    [Bl,Al] = oct3dsgn(ff(22),Fs,N); 	% Lower 1/3-oct. band in last octave. 
    for j = 6:-1:0
       x = decimate(x,2); 
       m = length(x); 
       y = filter(Bu,Au,x); 
       P(j*3+3) = sum(y.^2)/m;    
       y = filter(Bc,Ac,x); 
       P(j*3+2) = sum(y.^2)/m;    
       y = filter(Bl,Al,x); 
       P(j*3+1) = sum(y.^2)/m; 
    end
else
    jj=7:-1:0;
    Mi=[jj; jj*3+3; jj*3+2; jj*3+1];
    [ik,jk]=find(Mi==iF(end));
    if ik ==2
        % multirate filter implementation (see [2]).
        [Bu,Au] = oct3dsgn(ff(Mi(2,jk)),Fs,N); 	% Upper 1/3-oct. band in last octave. 
        [Bc,Ac] = oct3dsgn(ff(Mi(3,jk)),Fs,N); 	% Center 1/3-oct. band in last octave. 
        [Bl,Al] = oct3dsgn(ff(Mi(4,jk)),Fs,N); 	% Lower 1/3-oct. band in last octave. 
        for j = Mi(1,jk):-1:0
           x = decimate(x,2); 
           m = length(x); 
           y = filter(Bu,Au,x); 
           P(j*3+3) = sum(y.^2)/m;    
           y = filter(Bc,Ac,x); 
           P(j*3+2) = sum(y.^2)/m;    
           y = filter(Bl,Al,x); 
           P(j*3+1) = sum(y.^2)/m; 
        end        
    elseif ik == 3                    
        [B,A] = oct3dsgn(ff(Mi(ik,jk)),Fs,N);
        y = filter(B,A,x); 
        P(Mi(ik,jk)) = sum(y.^2)/m; 
        [B,A] = oct3dsgn(ff(Mi(ik+1,jk)),Fs,N);
        y = filter(B,A,x); 
        P(Mi(ik+1,jk)) = sum(y.^2)/m;     
        % multirate filter implementation (see [2]).
        [Bu,Au] = oct3dsgn(ff(Mi(2,jk+1)),Fs,N); 	% Upper 1/3-oct. band in last octave. 
        [Bc,Ac] = oct3dsgn(ff(Mi(3,jk+1)),Fs,N); 	% Center 1/3-oct. band in last octave. 
        [Bl,Al] = oct3dsgn(ff(Mi(4,jk+1)),Fs,N); 	% Lower 1/3-oct. band in last octave. 
        for j = Mi(1,jk+1):-1:0
           x = decimate(x,2); 
           m = length(x); 
           y = filter(Bu,Au,x); 
           P(j*3+3) = sum(y.^2)/m;    
           y = filter(Bc,Ac,x); 
           P(j*3+2) = sum(y.^2)/m;    
           y = filter(Bl,Al,x); 
           P(j*3+1) = sum(y.^2)/m;  
        end
    elseif ik == 4
        [B,A] = oct3dsgn(ff(Mi(ik,jk)),Fs,N);
        y = filter(B,A,x); 
        P(Mi(ik,jk)) = sum(y.^2)/m; 
        % multirate filter implementation (see [2]).
        [Bu,Au] = oct3dsgn(ff(Mi(2,jk+1)),Fs,N); 	% Upper 1/3-oct. band in last octave. 
        [Bc,Ac] = oct3dsgn(ff(Mi(3,jk+1)),Fs,N); 	% Center 1/3-oct. band in last octave. 
        [Bl,Al] = oct3dsgn(ff(Mi(4,jk+1)),Fs,N); 	% Lower 1/3-oct. band in last octave. 
        for j = Mi(1,jk+1):-1:0
           x = decimate(x,2); 
           m = length(x); 
           y = filter(Bu,Au,x); 
           P(j*3+3) = sum(y.^2)/m;    
           y = filter(Bc,Ac,x); 
           P(j*3+2) = sum(y.^2)/m;    
           y = filter(Bl,Al,x); 
           P(j*3+1) = sum(y.^2)/m;                         
        end
    end
    
end
%%
% Convert to decibels. 
%idx = (P>0);
%P(idx) = 20*log10(sqrt(P(idx))/dBref);
%P(~idx) = NaN*ones(sum(~idx),1);

% Generate the plot
if (nargout == 0) 			
  bar(P);
  ax = axis;  
  axis([0 length(Fc)+1 ax(3) ax(4)]) 
  set(gca,'XTick',[2:3:length(Fc)]); 		% Label frequency axis on octaves. 
  set(gca,'XTickLabel',F(2:3:length(Fc)));
  xlabel('Frequency band [Hz]'); ylabel('Power [dB]');
  title('One-third-octave spectrum')
% Set up output parameters
elseif (nargout == 1) 			
  p = P; 
elseif (nargout == 2) 			
  p = P; 
  f = Fc;
end