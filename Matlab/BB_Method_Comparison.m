u = 4000;

BB=TOL.BB(u)
%bbpsd = 10.*log10( nansum((10.^(PSD.PSD(:,u)./10.*diff(PSD.f) )) ))

%bbtol = 10.*log10((10.^(TOL.TOL(:,u)./10)))
%bbpsd = 10.*log10(trapz(PSD.f,10.^(PSD.PSD(:,u)./10)))

%%
%u = 101
%plot(f.f, SPL.PSD(:,u))

for i = 1: length(TOL.time)
bbtol(i) = 10.*log10(sum((10.^(TOL.TOL(:,i)./10))));
bbpsd(i) = 10.*log10(trapz(PSD.f(1:2476),10.^(PSD.PSD(1:2476,i)./10)));
end

subplot(211)
plot(1:length(TOL.time),bbtol,'k'), hold on
plot(1:length(TOL.time),bbpsd,'r')
subplot(212)
plot(1:length(TOL.time),bbpsd-bbtol,'r')

