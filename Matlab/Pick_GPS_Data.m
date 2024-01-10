function varargout = Pick_GPS_Data(varargin)
% Author: Chris Bassett
% Last Modified: 24 Feb 2018
% Created by GUIDE v2.5 15-Feb-2018 13:29:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn' , @Pick_GPS_Data_OpeningFcn, ...
                   'gui_OutputFcn',  @Pick_GPS_Data_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


function Pick_GPS_Data_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for Pick_GPS_Data
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Pick_GPS_Data wait for user response (see UIRESUME)
% uiwait(handles.figure1);


function varargout = Pick_GPS_Data_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;


% --- Executes on button press in button_plot.
function button_plot_Callback(hObject, eventdata, handles)
% need to evalin the GPS offsets

% Query used to get first pass information (port or starboard)
% This is used later to account for the GPS location offset
ps = '';
cnt = 0;
while isempty(ps)
    if cnt == 0
        ps = questdlg(['Was the first pass on the port' sprintf('\n') 'or starboard side of the vessel?'], ...
            'Pass 1: Port or Starboard', ...
            'Port','Starboard','Port');
    else
        ps = questdlg(['Was the first pass on the port' sprintf('\n') 'or starboard side of the vessel?' sprintf('\n') 'You must select one'], ...
            'Pass 1: Port or Starboard', ...
            'Port','Starboard','Port');
    end
    cnt = cnt+1;
end
clear cnt
handles.aspect = ps; % save the aspect of the first pass, it is
                     % used to calculate the distances
% create a Boolean for handle aspect where value 1 = Starboard
if strfind(handles.aspect,'Starboard')
    handles.aspectbool = 1;
else
    handles.aspectbool = 0;
end
% load in GPS offsets and assign them to hand for future
% distance calculations
gpsoffset = evalin('base','GPS_offset');
handles.xoffset = gpsoffset.along;
handles.yoffset = gpsoffset.cross;
                     
% bring in GPS data from workspace
x=evalin('base','GPS.time');
y=evalin('base','GPS.range');
handles.dmaxplot = ceil(max(y)./1000)*1000;

time = x;
%time = datenum(2018,1,30,1,0.25.*[1:length(x)]./(24),0);
%x = [1:1000];
%y = 10.*sin(x);
axes(handles.plot_axes);
plot(time,y,'k','linewidth',2)
ylabel('Distance [m]','fontweight','bold')
xlabel('Time','fontweight','bold')
datetick
box on
set(gca,'linewidth',2)
set(gca,'ylim',[0 handles.dmaxplot])
handles.x = time;
handles.y = y;

guidata(hObject, handles);

% --- Executes on button press in button_pass1.
function button_pass1_Callback(hObject, eventdata, handles)

guidata(hObject,handles)
uiwait(msgbox('Select data before, then after, the 1st CPA'))


[x1,y1,button,ax]=ginputax(handles.plot_axes,2);

xinds = find(and(handles.x > x1(1), handles.x < x1(2))); 
yminind = find(min(handles.y(xinds)) == handles.y );
ymin = handles.y(yminind);      % Distance at CPA
xmin = handles.x(yminind);      % Time at CPA

% calculate the new distances for the pass based on the
% GPS offsets 
dcpatmp = ymin;                    % distance at CPA w/o offsets
xgps = handles.xoffset;         % x offset from GPS GUI
ygps = handles.yoffset          % y offset from GPS GUI

% to calculate distance, must break distance into it's contituents
% based on the y-value at CPA;      
x2 = sqrt(handles.y.^2 - dcpatmp.^2);     % placeholder x values where 
                                       % x2 = sqrt(d^2 - d_cpa^2)
                                       
% conditional statements for GPS location and which side
% calculate distance with offsets; variable name = y
% x3 is along-ship distance with GPS offset
% y3 is cross-ship distance with GPS offset
% aspectbool = 1 if starboard side, 0 if port
if and(handles.aspectbool == 1, xgps >= 0)
   x3 = x2 - xgps;
   y3 = dcpatmp + ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 1, xgps <= 0)
   x3 = x2 + xgps;
   y3 = dcpatmp + ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 0, xgps >= 0)
   x3 = x2 - xgps;
   y3 = dcpatmp - ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 0, xgps <= 0)
   x3 = x2 + xgps;
   y3 = dcpatmp - ygps;
   d = sqrt(x3.^2 + y3.^2); 
end

% rewrite ymin based on distance at CPA after offsets
% first check to see if there is a new index for the minimum
yminind = find(min(d(xinds)) == d );
ymin = d(yminind);

xinds = [yminind-45:yminind];% new xinds for finding times for DWL
             % go 45 inds below CPA (seconds at 1 Hz)
             % If ship SOG = 11 knots, it travels 250 m in 45 sec.

% DWT = (2*d_{cpa}*tand(30))/2 ~= 58 where d_{cpa} = 100 m
% therefore range to drifter for beginning/end of DWT 
% is therefore the hypotenuse with legs d_{cpa} + DWT/2;
% See vessel noise standard for additional information

y_dwl = sqrt(ymin^2+(2*100*tand(30)).^2); %distance at start DWT


[~,xnew1ind]=min(abs(d(xinds) - y_dwl));
xnew1ind = yminind - length(xinds) + xnew1ind
xdwt(1) = handles.x(xnew1ind);
ydwt(1) = d(xnew1ind);
%handles.y(xnewind1)
xinds = [yminind:yminind+45];
[~,xnew1ind]=min(abs(d(xinds) - y_dwl));
xnew1ind = yminind + xnew1ind;

xdwt(2) = handles.x(xnew1ind);
ydwt(2) = d(xnew1ind);
pinds = find(and(handles.x >= xdwt(1), handles.x <= xdwt(2)));
ptimes = handles.x(pinds);
dtimes = d(pinds);

ymaxplot = ceil(max(handles.y)./1000)*1000;

axes(handles.plot_axes);
hold on

%hl = plot([xmin xmin],[0 10000],'r')
%uistack(hl, 'bottom');
%hl = patch([xdwt(1) xdwt(2) xdwt(2) xdwt(1) xdwt(1)],...
   %        [10000 10000 0 0 10000],'r','FaceColor',[0.5 0.5 0.5])
%uistack(hl, 'bottom');
       
scatter(xdwt(1),ydwt(1),30,'r','filled','MarkerEdgeColor',[0 0 0 ])
scatter(xdwt(2),ydwt(2),30,'r','filled','MarkerEdgeColor',[0 0 0])
scatter(xmin,ymin,20,'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor',[0 0 0])

% Print CPA/DWT output to GUI
set(handles.text_P1start,'String',datestr(xdwt(1),13)) % start time DWT
set(handles.text_P1end,'String',datestr(xdwt(2),13))   % end time DWT
set(handles.text_cpa1,'String',num2str(ymin,'%-.0f'))  % CPA [in m]

% create data in handles for output
handles.P1.ts = xdwt(1);          % start time for DWT on pass 1
handles.P1.te = xdwt(2);          % end time for DWT on pass 1
handles.P1.t = ptimes;            % times within 30 degress
handles.P1.CPA = ymin;            % CPA Pass 1
handles.P1.DWT_ds = ydwt(1);      % Range at P1 DWT start
handles.P1.DWT_de = ydwt(2);      % Range at P1 DWT start
handles.P1.d = dtimes;            % time series of range within 30 deg
handles.P1.aspect = handles.aspect; % Note aspect in handle
% delete once debugging complete

assignin('base','handles',handles);
assignin('base','d',d);

set(handles.button_pass1, 'enable', 'off')

guidata(hObject, handles);


% For details about the processing see comments in button_Pass1_Callback
% The processing for each seperate button is the same except that the
% boolean operator for the vessel aspect (starboard vs port) gets switched
% each iteration.

function button_pass2_Callback(hObject, eventdata, handles)
switch(handles.aspect)
    case 'Starboard'
        handles.aspect = 'Port';
        handles.aspectbool == 0;
    case 'Port'
        handles.aspect = 'Starboard';
        handles.aspectbool == 1;
end

guidata(hObject,handles)
uiwait(msgbox('Select data before, then after, the 2nd CPA'))

[x1,y1,button,ax]=ginputax(handles.plot_axes,2);

xinds = find(and(handles.x > x1(1), handles.x < x1(2))); 
yminind = find(min(handles.y(xinds)) == handles.y );
ymin = handles.y(yminind);      % Distance at CPA
xmin = handles.x(yminind);      % Time at CPA

dcpatmp = ymin;                    % distance at CPA w/o offsets
xgps = handles.xoffset;         % x offset from GPS GUI
ygps = handles.yoffset          % y offset from GPS GUI
 
x2 = sqrt(handles.y.^2 - dcpatmp.^2);     % placeholder x values where 
                                          % x2 = sqrt(d^2 - d_cpa^2)
                                       
if and(handles.aspectbool == 1, xgps >= 0)
   x3 = x2 - xgps;
   y3 = dcpatmp + ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 1, xgps <= 0)
   x3 = x2 + xgps;
   y3 = dcpatmp + ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 0, xgps >= 0)
   x3 = x2 - xgps;
   y3 = dcpatmp - ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 0, xgps <= 0)
   x3 = x2 + xgps;
   y3 = dcpatmp - ygps;
   d = sqrt(x3.^2 + y3.^2); 
end

yminind = find(min(d(xinds)) == d );
ymin = d(yminind);

xinds = [yminind-45:yminind];% new xinds for finding times for DWL
y_dwl = sqrt(ymin^2+(2*100*tand(30)).^2); %distance at start DWT


[~,xnew1ind]=min(abs(d(xinds) - y_dwl));
xnew1ind = yminind - length(xinds) + xnew1ind
xdwt(1) = handles.x(xnew1ind);
ydwt(1) = d(xnew1ind);
xinds = [yminind:yminind+45];
[~,xnew1ind]=min(abs(d(xinds) - y_dwl));
xnew1ind = yminind + xnew1ind;

xdwt(2) = handles.x(xnew1ind);
ydwt(2) = d(xnew1ind);
pinds = find(and(handles.x >= xdwt(1), handles.x <= xdwt(2)));
ptimes = handles.x(pinds);
dtimes = d(pinds);

ymaxplot = ceil(max(handles.y)./1000)*1000;

axes(handles.plot_axes);
hold on

scatter(xdwt(1),ydwt(1),30,'r','filled','MarkerEdgeColor',[0 0 0 ])
scatter(xdwt(2),ydwt(2),30,'r','filled','MarkerEdgeColor',[0 0 0])
scatter(xmin,ymin,20,'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor',[0 0 0])

set(handles.text_P2start,'String',datestr(xdwt(1),13)) % start time DWT
set(handles.text_P2end,'String',datestr(xdwt(2),13))   % end time DWT
set(handles.text_cpa2,'String',num2str(ymin,'%-.0f'))  % CPA [in m]

handles.P2.ts = xdwt(1);          % start time for DWT on pass 2
handles.P2.te = xdwt(2);          % end time for DWT on pass 2
handles.P2.t = ptimes;            % times within 30 degress
handles.P2.CPA = ymin;            % CPA Pass 2
handles.P2.DWT_ds = ydwt(1);      % Range at P2 DWT start
handles.P2.DWT_de = ydwt(2);      % Range at P2 DWT start
handles.P2.d = dtimes;            % time series of range within 30 deg
handles.P2.aspect = handles.aspect; % Note aspect in handle

assignin('base','handles',handles);
assignin('base','d',d);

set(handles.button_pass2, 'enable', 'off')
guidata(hObject,handles)


function button_pass3_Callback(hObject, eventdata, handles)
switch(handles.aspect)
    case 'Starboard'
        handles.aspect = 'Port';
        handles.aspectbool == 0;
    case 'Port'
        handles.aspect = 'Starboard';
        handles.aspectbool == 1;
end

guidata(hObject,handles)
uiwait(msgbox('Select data before, then after, the 3rd CPA'))


[x1,y1,button,ax]=ginputax(handles.plot_axes,2);

xinds = find(and(handles.x > x1(1), handles.x < x1(2))); 
yminind = find(min(handles.y(xinds)) == handles.y );
ymin = handles.y(yminind);      % Distance at CPA
xmin = handles.x(yminind);      % Time at CPA

dcpatmp = ymin;                    % distance at CPA w/o offsets
xgps = handles.xoffset;         % x offset from GPS GUI
ygps = handles.yoffset          % y offset from GPS GUI

    
x2 = sqrt(handles.y.^2 - dcpatmp.^2);     % placeholder x values where 
                                       
if and(handles.aspectbool == 1, xgps >= 0)
   x3 = x2 - xgps;
   y3 = dcpatmp + ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 1, xgps <= 0)
   x3 = x2 + xgps;
   y3 = dcpatmp + ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 0, xgps >= 0)
   x3 = x2 - xgps;
   y3 = dcpatmp - ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 0, xgps <= 0)
   x3 = x2 + xgps;
   y3 = dcpatmp - ygps;
   d = sqrt(x3.^2 + y3.^2); 
end

yminind = find(min(d(xinds)) == d );
ymin = d(yminind);

xinds = [yminind-45:yminind];% new xinds for finding times for DWL
y_dwl = sqrt(ymin^2+(2*100*tand(30)).^2); %distance at start DWT

[~,xnew1ind]=min(abs(d(xinds) - y_dwl));
xnew1ind = yminind - length(xinds) + xnew1ind
xdwt(1) = handles.x(xnew1ind);
ydwt(1) = d(xnew1ind);
xinds = [yminind:yminind+45];
[~,xnew1ind]=min(abs(d(xinds) - y_dwl));
xnew1ind = yminind + xnew1ind;

xdwt(2) = handles.x(xnew1ind);
ydwt(2) = d(xnew1ind);
pinds = find(and(handles.x >= xdwt(1), handles.x <= xdwt(2)));
ptimes = handles.x(pinds);
dtimes = d(pinds);

ymaxplot = ceil(max(handles.y)./1000)*1000;

axes(handles.plot_axes);
hold on
   
scatter(xdwt(1),ydwt(1),30,'r','filled','MarkerEdgeColor',[0 0 0 ])
scatter(xdwt(2),ydwt(2),30,'r','filled','MarkerEdgeColor',[0 0 0])
scatter(xmin,ymin,20,'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor',[0 0 0])
set(handles.text_P3start,'String',datestr(xdwt(1),13)) % start time DWT
set(handles.text_P3end,'String',datestr(xdwt(2),13))   % end time DWT
set(handles.text_cpa3,'String',num2str(ymin,'%-.0f'))  % CPA [in m]

handles.P3.ts = xdwt(1);          % start time for DWT on pass 3
handles.P3.te = xdwt(2);          % end time for DWT on pass 3
handles.P3.t = ptimes;            % times within 30 degress
handles.P3.CPA = ymin;            % CPA Pass 3
handles.P3.DWT_ds = ydwt(1);      % Range at P3 DWT start
handles.P3.DWT_de = ydwt(2);      % Range at P3 DWT start
handles.P3.d = dtimes;            % time series of range within 30 deg
handles.P3.aspect = handles.aspect; % Note aspect in handle

assignin('base','handles',handles);
assignin('base','d',d);

set(handles.button_pass3, 'enable', 'off')
guidata(hObject,handles)


function button_pass4_Callback(hObject, eventdata, handles)
switch(handles.aspect)
    case 'Starboard'
        handles.aspect = 'Port';
        handles.aspectbool == 0;
    case 'Port'
        handles.aspect = 'Starboard';
        handles.aspectbool == 1;
end

guidata(hObject,handles)
uiwait(msgbox('Select data before, then after, the 4th CPA'))

[x1,y1,button,ax]=ginputax(handles.plot_axes,2);

xinds = find(and(handles.x > x1(1), handles.x < x1(2))); 
yminind = find(min(handles.y(xinds)) == handles.y );
ymin = handles.y(yminind);      % Distance at CPA
xmin = handles.x(yminind);      % Time at CPA

dcpatmp = ymin;                    % distance at CPA w/o offsets
xgps = handles.xoffset;         % x offset from GPS GUI
ygps = handles.yoffset          % y offset from GPS GUI
  
x2 = sqrt(handles.y.^2 - dcpatmp.^2);     % placeholder x values where 
                                       
if and(handles.aspectbool == 1, xgps >= 0)
   x3 = x2 - xgps;
   y3 = dcpatmp + ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 1, xgps <= 0)
   x3 = x2 + xgps;
   y3 = dcpatmp + ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 0, xgps >= 0)
   x3 = x2 - xgps;
   y3 = dcpatmp - ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 0, xgps <= 0)
   x3 = x2 + xgps;
   y3 = dcpatmp - ygps;
   d = sqrt(x3.^2 + y3.^2); 
end

yminind = find(min(d(xinds)) == d );
ymin = d(yminind);

xinds = [yminind-45:yminind];% new xinds for finding times for DWL
y_dwl = sqrt(ymin^2+(2*100*tand(30)).^2); %distance at start DWT

[~,xnew1ind]=min(abs(d(xinds) - y_dwl));
xnew1ind = yminind - length(xinds) + xnew1ind
xdwt(1) = handles.x(xnew1ind);
ydwt(1) = d(xnew1ind);
xinds = [yminind:yminind+45];
[~,xnew1ind]=min(abs(d(xinds) - y_dwl));
xnew1ind = yminind + xnew1ind;

xdwt(2) = handles.x(xnew1ind);
ydwt(2) = d(xnew1ind);
pinds = find(and(handles.x >= xdwt(1), handles.x <= xdwt(2)));
ptimes = handles.x(pinds);
dtimes = d(pinds);

ymaxplot = ceil(max(handles.y)./1000)*1000;

axes(handles.plot_axes);
hold on

scatter(xdwt(1),ydwt(1),30,'r','filled','MarkerEdgeColor',[0 0 0 ])
scatter(xdwt(2),ydwt(2),30,'r','filled','MarkerEdgeColor',[0 0 0])
scatter(xmin,ymin,20,'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor',[0 0 0])

set(handles.text_P4start,'String',datestr(xdwt(1),13)) % start time DWT
set(handles.text_P4end,'String',datestr(xdwt(2),13))   % end time DWT
set(handles.text_cpa4,'String',num2str(ymin,'%-.0f'))  % CPA [in m]

handles.P4.ts = xdwt(1);          % start time for DWT on pass 4
handles.P4.te = xdwt(2);          % end time for DWT on pass 4
handles.P4.t = ptimes;            % times within 30 degress
handles.P4.CPA = ymin;            % CPA Pass 4
handles.P4.DWT_ds = ydwt(1);      % Range at P4 DWT start
handles.P4.DWT_de = ydwt(2);      % Range at P4 DWT start
handles.P4.d = dtimes;            % time series of range within 30 deg
handles.P4.aspect = handles.aspect; % Note aspect in handle

assignin('base','handles',handles);
assignin('base','d',d);

set(handles.button_pass4, 'enable', 'off')
guidata(hObject,handles)


function button_pass5_Callback(hObject, eventdata, handles)
switch(handles.aspect)
    case 'Starboard'
        handles.aspect = 'Port';
        handles.aspectbool == 0;
    case 'Port'
        handles.aspect = 'Starboard';
        handles.aspectbool == 1;
end

guidata(hObject,handles)
uiwait(msgbox('Select data before, then after, the 5th CPA'))

[x1,y1,button,ax]=ginputax(handles.plot_axes,2);

xinds = find(and(handles.x > x1(1), handles.x < x1(2))); 
yminind = find(min(handles.y(xinds)) == handles.y );
ymin = handles.y(yminind);      % Distance at CPA
xmin = handles.x(yminind);      % Time at CPA

dcpatmp = ymin;                    % distance at CPA w/o offsets
xgps = handles.xoffset;         % x offset from GPS GUI
ygps = handles.yoffset          % y offset from GPS GUI

x2 = sqrt(handles.y.^2 - dcpatmp.^2);     % placeholder x values where 
                                       
if and(handles.aspectbool == 1, xgps >= 0)
   x3 = x2 - xgps;
   y3 = dcpatmp + ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 1, xgps <= 0)
   x3 = x2 + xgps;
   y3 = dcpatmp + ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 0, xgps >= 0)
   x3 = x2 - xgps;
   y3 = dcpatmp - ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 0, xgps <= 0)
   x3 = x2 + xgps;
   y3 = dcpatmp - ygps;
   d = sqrt(x3.^2 + y3.^2); 
end

yminind = find(min(d(xinds)) == d );
ymin = d(yminind);

xinds = [yminind-45:yminind];% new xinds for finding times for DWL
y_dwl = sqrt(ymin^2+(2*100*tand(30)).^2); %distance at start DWT

[~,xnew1ind]=min(abs(d(xinds) - y_dwl));
xnew1ind = yminind - length(xinds) + xnew1ind
xdwt(1) = handles.x(xnew1ind);
ydwt(1) = d(xnew1ind);
xinds = [yminind:yminind+45];
[~,xnew1ind]=min(abs(d(xinds) - y_dwl));
xnew1ind = yminind + xnew1ind;

xdwt(2) = handles.x(xnew1ind);
ydwt(2) = d(xnew1ind);
pinds = find(and(handles.x >= xdwt(1), handles.x <= xdwt(2)));
ptimes = handles.x(pinds);
dtimes = d(pinds);

ymaxplot = ceil(max(handles.y)./1000)*1000;

axes(handles.plot_axes);
hold on

scatter(xdwt(1),ydwt(1),30,'r','filled','MarkerEdgeColor',[0 0 0 ])
scatter(xdwt(2),ydwt(2),30,'r','filled','MarkerEdgeColor',[0 0 0])
scatter(xmin,ymin,20,'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor',[0 0 0])

set(handles.text_P5start,'String',datestr(xdwt(1),13)) % start time DWT
set(handles.text_P5end,'String',datestr(xdwt(2),13))   % end time DWT
set(handles.text_cpa5,'String',num2str(ymin,'%-.0f'))  % CPA [in m]

handles.P5.ts = xdwt(1);          % start time for DWT on pass 5
handles.P5.te = xdwt(2);          % end time for DWT on pass 5
handles.P5.t = ptimes;            % times within 30 degress
handles.P5.CPA = ymin;            % CPA Pass 5
handles.P5.DWT_ds = ydwt(1);      % Range at P5 DWT start
handles.P5.DWT_de = ydwt(2);      % Range at P5 DWT start
handles.P5.d = dtimes;            % time series of range within 30 deg
handles.P5.aspect = handles.aspect; % Note aspect in handle

assignin('base','handles',handles);
assignin('base','d',d);

set(handles.button_pass5, 'enable', 'off')
guidata(hObject,handles)


function button_pass6_Callback(hObject, eventdata, handles)
switch(handles.aspect)
    case 'Starboard'
        handles.aspect = 'Port';
        handles.aspectbool == 0;
    case 'Port'
        handles.aspect = 'Starboard';
        handles.aspectbool == 1;
end

guidata(hObject,handles)
uiwait(msgbox('Select data before, then after, the 6th CPA'))


[x1,y1,button,ax]=ginputax(handles.plot_axes,2);

xinds = find(and(handles.x > x1(1), handles.x < x1(2))); 
yminind = find(min(handles.y(xinds)) == handles.y );
ymin = handles.y(yminind);      % Distance at CPA
xmin = handles.x(yminind);      % Time at CPA

dcpatmp = ymin;                    % distance at CPA w/o offsets
xgps = handles.xoffset;         % x offset from GPS GUI
ygps = handles.yoffset          % y offset from GPS GUI
 
x2 = sqrt(handles.y.^2 - dcpatmp.^2);     % placeholder x values where 
                                      
if and(handles.aspectbool == 1, xgps >= 0)
   x3 = x2 - xgps;
   y3 = dcpatmp + ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 1, xgps <= 0)
   x3 = x2 + xgps;
   y3 = dcpatmp + ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 0, xgps >= 0)
   x3 = x2 - xgps;
   y3 = dcpatmp - ygps;
   d = sqrt(x3.^2 + y3.^2); 
elseif and(handles.aspectbool == 0, xgps <= 0)
   x3 = x2 + xgps;
   y3 = dcpatmp - ygps;
   d = sqrt(x3.^2 + y3.^2); 
end

yminind = find(min(d(xinds)) == d );
ymin = d(yminind);

xinds = [yminind-45:yminind];% new xinds for finding times for DWL
y_dwl = sqrt(ymin^2+(2*100*tand(30)).^2); %distance at start DWT

[~,xnew1ind]=min(abs(d(xinds) - y_dwl));
xnew1ind = yminind - length(xinds) + xnew1ind
xdwt(1) = handles.x(xnew1ind);
ydwt(1) = d(xnew1ind);
xinds = [yminind:yminind+45];
[~,xnew1ind]=min(abs(d(xinds) - y_dwl));
xnew1ind = yminind + xnew1ind;

xdwt(2) = handles.x(xnew1ind);
ydwt(2) = d(xnew1ind);
pinds = find(and(handles.x >= xdwt(1), handles.x <= xdwt(2)));
ptimes = handles.x(pinds);
dtimes = d(pinds);

ymaxplot = ceil(max(handles.y)./1000)*1000;

axes(handles.plot_axes);
hold on

scatter(xdwt(1),ydwt(1),30,'r','filled','MarkerEdgeColor',[0 0 0 ])
scatter(xdwt(2),ydwt(2),30,'r','filled','MarkerEdgeColor',[0 0 0])
scatter(xmin,ymin,20,'MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor',[0 0 0])

set(handles.text_P6start,'String',datestr(xdwt(1),13)) % start time DWT
set(handles.text_P6end,'String',datestr(xdwt(2),13))   % end time DWT
set(handles.text_cpa6,'String',num2str(ymin,'%-.0f'))  % CPA [in m]

handles.P6.ts = xdwt(1);          % start time for DWT on pass 6
handles.P6.te = xdwt(2);          % end time for DWT on pass 6
handles.P6.t = ptimes;            % times within 30 degress
handles.P6.CPA = ymin;            % CPA Pass 6
handles.P6.DWT_ds = ydwt(1);      % Range at P6 DWT start
handles.P6.DWT_de = ydwt(2);      % Range at P6 DWT start
handles.P6.d = dtimes;            % time series of range within 30 deg
handles.P6.aspect = handles.aspect; % Note aspect in handle

assignin('base','handles',handles);
assignin('base','d',d);

set(handles.button_pass6, 'enable', 'off')
guidata(hObject,handles)


function button_finished_Callback(hObject, eventdata, handles)
% make sure to write a dialog window that makes sure the user is happy 
% dialog box should say happy: yes or no?
% if no is clicked, restart, if yes is clicked restart

% Check to see if user is happy with the results
% Code set to only continue if user clicks yes
% Dialog reopens until user clicks yes or no
yorn = '';
cnt = 0;
while isempty(yorn)
    if cnt == 0
        yorn = questdlg('Do the results look good?', ...
        'Restart Selection?', ...
        'Yes','No','Yes');
    else
       yorn = questdlg('Do the results look good? Must click yes or no.', ...
        'Restart Selection?', ...
        'Yes','No','Yes'); 
    end
    cnt = cnt+1;
end

% If user clicks no restart the entire GUI
if strcmp(yorn,'No')
    close(gcbf) 
    clear handles
    Pick_GPS_Data
    return
end

guidata(hObject,handles)

% get data from handles and create structure to pass to workspace
% first, make sure the pass exists so we don't try to write it
% if it was not created or if there are less than six passes
fields = {'P1','P2','P3','P4','P5','P6'}; % the potential pass fields
for j =  1:length(fields)
    if isfield(handles,fields{j})
        DWT.(fields{j}) = handles.(fields{j});  
    end
end

%DWT.aspect_P1 = ps;
% create dialog to tell user the data have been sent to workspace
uiwait(msgbox('CPA timestamps have been exported'))

assignin('base','DWT',DWT);         % write data out to workspace

close all                           % close figures
pause(1.5)                          % pause to make sure that
                                    % window closes before proceeding
                            
