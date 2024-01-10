function [NL] = ICES_spec()
% Author: Chris Bassett
% Last Modifications: 13 Feb. 2018 

% ICES Recommendations for radiated noise from research vessels
% Mitson, R.B., (1995). Underwater Noise of Research Vessel. ICES Coop.
% Research Report No. 209. 

% Ship noise curves
% 135 - 1.66 log(f in Hz) from 1-1000Hz
% 130-22log(f in kHz) from 1-100 kHz

% when called in use to get outputs ICES.f and ICES.SPL

NL.f = [10:10:1000 2000:1000:40000]; % frequency vector in Hz

low_inds = find(NL.f <= 1000); % indices for low-freq portion of curve
high_inds = find(NL.f > 1000); % indices for high-freq portion of the curve

n1 = 135 - 1.66.*log10(NL.f(low_inds));     % SPL for low-freq 
n2 = 130-22.*log10(NL.f(high_inds)./1000);  % SPL for high-freq

NL.SPL = [n1';n2'];                         % make one curve for SPLs

% Uncomment and run code to view
%figure
%semilogx(NL.f,NL.SPL,'k','linewidth',2)
%xlabel('Frequency [Hz]','fontweight','bold')
%ylabel('SPL [dB re 1\muPa]','fontweight','bold')
%box on, set(gca,'linewidth',2)
end

