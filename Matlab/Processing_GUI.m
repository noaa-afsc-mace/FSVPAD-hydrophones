function varargout = Processing_GUI(varargin)
% Author: Chris Bassett
% Last Modified: 15 Feb. 2018

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Processing_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @Processing_GUI_OutputFcn, ...
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


% --- Executes just before Processing_GUI is made visible.
function Processing_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Processing_GUI (see VARARGIN)

global proc_para;                      % need to call the global variable

%% Take defaults from uAural_Processing_para and
% enter them into the GUI
set(handles.edit_fs,'String',num2str(proc_para.fs));
set(handles.edit_minfreq,'String',num2str(proc_para.oto.f_min));

% following lines find the maximum 1/3 octave band (TOB) that can
% be processed given the sampling rate
TOBc = 1000.*2.^([-20:15]./3);                  % Exact center freq. 	
TOBu = TOBc*(2^(1/6));                          % Upper limit of TOB
TOB = uAural_TOBs;                  % approximate center frequencies

% find index assocaited with maximum TOB that can be calculated
[~, minind] = min(abs(proc_para.fs/2 - TOBu)); 
if TOBu(minind) > proc_para.fs/2
    minind = minind-1;
end
proc_para.oto.f_max = TOB(minind);  % set max TOB based on results

% back to setting up the GUI
set(handles.edit_maxfreq,'String',num2str(proc_para.oto.f_max));
set(handles.edit_NFFT,'String',num2str(proc_para.spec.NFFT));
set(handles.box_windowtype,'Value',1);
set(handles.box_overlap,'Value',1);
set(handles.box_gain,'Value',1);
%% Done entering default data into GUI
guidata(hObject, handles); % Update handles structure
uiwait(handles.figure1); % wait for user response in GUI

% --- Executes on button press in button_done.
function button_done_Callback(hObject, eventdata, handles)

uiresume(handles.figure1);  % resume code following GUI input

global proc_para;           % call global variable

% edit global processing parameters based on GUI input
proc_para.oto.f_min = str2double(get(handles.edit_minfreq,'String'));
proc_para.oto.f_max = str2double(get(handles.edit_maxfreq,'String'));
proc_para.spec.NFFT = str2double(get(handles.edit_NFFT,'String'));
wintype = get(handles.box_windowtype,'Value');
if wintype == 1
    proc_para.spec.type = 'Hann';
    proc_para.spec.win = hann(proc_para.spec.NFFT);
    proc_para.spec.win_cf = sqrt(8/3);
elseif wintype == 2
    proc_para.spec.type = 'Hamming';
    proc_para.spec.win = hamming(proc_para.spec.NFFT);
    proc_para.spec.win_cf = sqrt(5/2);    
elseif wintype == 3
    proc_para.spec.type = 'Rectangular';
    proc_para.spec.win = rectwin(proc_para.spec.NFFT);
    proc_para.spec.win_cf = 1;    
end

overlaps = [0 25 50 75];
proc_para.spec.overlap  = overlaps(get(handles.box_overlap,'Value'))./100;
    
gains = [18 15 12 9];
proc_para.DAQgain = gains(get(handles.box_gain,'Value'));

close all force                          % close GUI
pause(1.5)                               % pause for 1.5 sec
assignin('base','proc_para',proc_para);  % assign proc_para to workspace

return

% Unused functions assocaited with fields in the GUI
% Do not delete without modifying (deleting them) in
% GUIDE Properties Inspector

function varargout = Processing_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% handles    structure with handles and user data (see GUIDATA)

function edit_minfreq_Callback(hObject, eventdata, handles)
% hObject    handle to edit_minfreq (see GCBO)
% handles    structure with handles and user data (see GUIDATA)

function edit_minfreq_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
    get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_maxfreq_Callback(hObject, eventdata, handles)
% hObject    handle to edit_maxfreq (see GCBO)
% handles    structure with handles and user data (see GUIDATA)

function edit_maxfreq_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_NFFT_Callback(hObject, eventdata, handles)
% hObject    handle to edit_NFFT (see GCBO)
% handles    structure with handles and user data (see GUIDATA)

function edit_NFFT_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function box_windowtype_Callback(hObject, eventdata, handles)
% hObject    handle to box_windowtype (see GCBO)
% handles    structure with handles and user data (see GUIDATA)

function box_windowtype_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function box_overlap_Callback(hObject, eventdata, handles)
% hObject    handle to box_overlap (see GCBO)
% handles    structure with handles and user data (see GUIDATA)

function box_overlap_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function box_gain_Callback(hObject, eventdata, handles)
% hObject    handle to box_gain (see GCBO)
% handles    structure with handles and user data (see GUIDATA)

function box_gain_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_fs_Callback(hObject, eventdata, handles)
% hObject    handle to edit_fs (see GCBO)
% handles    structure with handles and user data (see GUIDATA)

function edit_fs_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function figure1_CloseRequestFcn(hObject, eventdata, handles)
delete(hObject); % closes the figure
