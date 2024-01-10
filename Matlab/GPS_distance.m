function [d,b] = GPS_distance(dlat,dlon,slat,slon)
% last edited: 9 Apr. 2018
% Takes GPS strings and calculates distance between
% the ship and drifter
% dlat = drifter latitude
% dlong = drifter longtitude
% slat = ship latitude
% slon = ship longitude

req = 6378.137; % Earth's equitorial radius 
rpol = 6356.7523; % Earth's polar radius

slat = deg2rad(slat);       % convert to radians
dlat = deg2rad(dlat);       % convert to radians
slon = deg2rad(slon);       % convert to radians
dlon = deg2rad(dlon);       % convert to radians

% range in meters
r = sqrt( [(req.^2.*cos(slat)).^2+(rpol.^2.*sin(slat)).^2]./...
          [(req.*cos(slat)).^2+(rpol.*sin(slat)).^2] ); 

Dlat = slat - dlat;     % differential latitude
Dlon = slon - dlon;     % differential longtiude

a = sin(Dlat./2).^2 + cos(dlat).*cos(slat).*sin(Dlon./2).^2;
d = 2 .* r .* atan2(sqrt(a),sqrt(1-a))*1000;    % range in m

Dlon = dlon - slon;
x = sin(Dlon) .* cos(dlat);
y = (cos(slat) .* sin(dlat)) - (sin(slat).*cos(dlat).*cos(Dlon));
b = atan2(x,y);
b = rem((rad2deg(b)+360),360); % bearing
end
