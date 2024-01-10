function varargout = GPS_location_GUI(varargin)
% Author: Chris Bassett
% Last Modified: 20 Feb. 2018
% Last Modified by GUIDE v2.5 25-Feb-2019 14:34:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GPS_location_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @GPS_location_GUI_OutputFcn, ...
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

% --- Executes just before GPS_location_GUI is made visible.
function GPS_location_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);
uiwait(handles.figure1);

% --- Executes on button press in returnbutton.
function returnbutton_Callback(hObject, eventdata, handles)
% placeholder GPSoffsets read from GUI
% .along is along-ship dimension, positive being forward of screw
% .cross is cross-ship dimension, positive being starboard of screw
uiresume(handles.figure1); 

GPSoffset.along = str2double(get(handles.along,'string'));
GPSoffset.cross = str2double(get(handles.cross,'string'));

% interate over distance fields to find NaNs 
% replace any NaN (lack of input or otherwise) with 0s
field = fieldnames(GPSoffset)
for fn=field'
    if isnan(GPSoffset.(fn{1}))
       GPSoffset.(fn{1}) = 0; 
    end
end

% get units from GUI: Value 1 = m, 2 = ft
if get(handles.units,'Value') == 1
    GPSoffset.units = 'm';
else
    GPSoffset.units = 'ft';
end

% pass user input back through dialog box
outstr = sprintf('%.1f %s forward and %.1f %s starboard of amidships',...
                 GPSoffset.along, GPSoffset.units, GPSoffset.cross, GPSoffset.units);
h = msgbox(outstr);

% for calculations we need units of m
% if units are in feet, convert to units before passing
if strfind('ft',GPSoffset.units)
    % 1 ft = 0.3048 m
    GPSoffset.along = GPSoffset.along * 0.3048;
    GPSoffset.cross = GPSoffset.cross * 0.3048;
    GPSoffset.units = 'm';
end

% pass GUI data to workspace after conversion
assignin('base','GPS_offset',GPSoffset);

% close dialog box and GUI after a short pause
pause(2)
%close(h)
close(gcf)
return

% --- Executes on button press in cancelbutton.
function cancelbutton_Callback(hObject, eventdata, handles)
% if cancel button is pressed then by default then
% distance are set to 0 and units to meters
uiresume(handles.figure1); 
GPSoffset.along = 0;
GPSoffset.cross = 0;
GPSoffset.units = 'm';
assignin('base','GPS_offset',GPSoffset);

h = msgbox('You pressed cancel - Default values will be used');
pause(2) % pause for 2 seconds
%close(h)
close(gcf)
return

function cross_Callback(hObject, eventdata, handles)
% hObject    handle to cross (see GCBO)
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function cross_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Outputs from this function are returned to the command line.
function varargout = GPS_location_GUI_OutputFcn(hObject, eventdata, handles) 
%varargout{1} = handles.output;

function along_Callback(hObject, eventdata, handles)
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function along_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function crossedit_Callback(hObject, eventdata, handles)
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function crossedit_CreateFcn(hObject, eventdata, handles)
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in units.
function units_Callback(hObject, eventdata, handles)
% handles    structure with handles and user data (see GUIDATA)

function units_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
