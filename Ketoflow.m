function varargout = Ketoflow(varargin)
% KETOFLOW MATLAB code for Ketoflow.fig
%      KETOFLOW, by itself, creates a new KETOFLOW or raises the existing
%      singleton*.
%
%      H = KETOFLOW returns the handle to a new KETOFLOW or the handle to
%      the existing singleton*.
%
%      KETOFLOW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in KETOFLOW.M with the given input arguments.
%
%      KETOFLOW('Property','Value',...) creates a new KETOFLOW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Ketoflow_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Ketoflow_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Ketoflow

% Last Modified by GUIDE v2.5 19-Nov-2024 20:29:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Ketoflow_OpeningFcn, ...
                   'gui_OutputFcn',  @Ketoflow_OutputFcn, ...
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


% --- Executes just before Ketoflow is made visible.
function Ketoflow_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Ketoflow (see VARARGIN)

% Choose default command line output for Ketoflow
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Ketoflow wait for user response (see UIRESUME)
% uiwait(handles.figure1);

data = guidata(hObject);
data.EEG = eeg_emptyset();

% push the data to the object (window)
guidata(hObject, data);


% --- Outputs from this function are returned to the command line.
function varargout = Ketoflow_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;


% --- Executes on button press in pushbuttonOpen.
function pushbuttonOpen_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonOpen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = guidata(hObject);
set(hObject, 'Backgroundcolor', [1,0,0])

FilterSpec = {'*.*', 'All files'
    '*.bdf', 'Biosemi'
    '*.cnt', 'ANT Neuro'
    '*.edf', 'European data format'
    '*.set', 'EEGLAB'
    '*.vhdr', 'BrainVision'
    };
fid = fopen('.EegWorkflow_DefaultPath.ini','r');
DefaultPath = ".";
if fid>0
    try
        DefaultPath = fgetl(fid);
        fclose(fid);
    catch
    end
end 
[FileName,PathName,FilterIndex] = uigetfile(FilterSpec,'Select an EEG file', DefaultPath);
fid = fopen('.EegWorkflow_DefaultPath.ini','w');
if fid>0
    fprintf(fid,'%s',PathName);
    fclose(fid);
end 

%try
if isnumeric(FileName) && FileName==0
    beep;
else
    zz = strsplit(FileName,'.');
    switch zz{end}
        case 'cnt'
            data.EEG = pop_loadeep_v4([PathName FileName], 'triggerfile', 'on');
            data.EEG.filename = [PathName FileName];
            tmp = data.EEG;

            % insert boundaries and events
            evtcnt = 0;
            for ev=1:length(tmp.event)
                if tmp.event(ev).latency>1
                    evtcnt = evtcnt + 1;
                    if strcmp(tmp.event(ev).type,'__')
                        typ = 'boundary';
                    else
                        typ = strtrim(tmp.event(ev).type);
                    end
                    tmp.event(evtcnt).type = typ;
                    tmp.event(evtcnt).latency = data.EEG.event(ev).latency;
                    tmp.event(evtcnt).duration = data.EEG.event(ev).duration;
                end
            end

            % check for event length (>10 events), start of first event named 31 (>100 sec), and
            % existence of a boundary event. If not, search for a "jump" in
            % activity just before the first event and put in a boundary
            % event (segment will not work otherwise.)
            if length(tmp.event)>10 && ~isempty(str2num(tmp.event(1).type)) ...
                    && tmp.event(1).latency>100*tmp.srate ...
                    && sum(strcmpi('boundary',{tmp.event.type}))==0
                sig = tmp.data(:,(tmp.event(1).latency-tmp.srate*4):tmp.event(1).latency);
                z = abs(zscore(mean(abs(diff(sig')')))');
                ndx = tmp.event(1).latency-tmp.srate*4 + min(find(z>10)) + 0;
                dummy = tmp.event(1);
                dummy.type = 'boundary';
                dummy.latency = ndx;
                dummy.duration = 0;
                tmp.event = cat(1,dummy,tmp.event(:));
            end        
            data.EEG = tmp;

        case 'set'
            data.EEG = pop_loadset([PathName FileName]);
            data.EEG.filename = [PathName FileName];

        case 'vhdr'
            % read header
            data.EEG = pop_loadbv(PathName, FileName, [], []);
            data.EEG.filename = FileName;
    end

    if ~isempty(data.EEG) && ~isempty(data.EEG.event)
        for e=1:length(data.EEG.event)
            if isnumeric(data.EEG.event(e).type) 
                if isinteger(data.EEG.event(e).type)
                    data.EEG.event(e).type = bitand(data.EEG.event(e).type , 255);
                end
            elseif ~isempty(str2num(data.EEG.event(e).type))
                data.EEG.event(e).type = sprintf('%d', bitand(str2num(data.EEG.event(e).type), 255));
            end
        end
    end
    
    data.EEG = eeg_checkset(data.EEG);

end

guidata(hObject,data)

set(hObject, 'Backgroundcolor', [1,1,0])
data.pushbuttonExtract.BackgroundColor = [0,1,0];





% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbuttonOpen.
function pushbuttonOpen_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbuttonOpen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)





% --- Executes on button press in pushbuttonExtract.
function pushbuttonExtract_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonExtract (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = guidata(hObject);
set(hObject, 'Backgroundcolor', [1,0,0])

data.EEG = pop_select(data.EEG, 'channel', {'POz','Oz'});
if data.EEG.nbchan<2
    beep
    warning('One or more channels (Oz, PO5) are missing')
else
    SD = std(data.EEG.data(:,:)');
    if any(SD<3)
        beep
        warning('One of the channels is a flatline')
    end
    data.EEG = pop_reref(data.EEG, 'Oz');
end

% push the data
guidata(hObject,data)

% color this and next button
set(hObject, 'Backgroundcolor', [1,1,0])
data.pushbuttonEpoch.BackgroundColor = [0,1,0];




% --- Executes on button press in pushbuttonEpoch.
function pushbuttonEpoch_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonEpoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = guidata(hObject);
set(hObject, 'Backgroundcolor', [1,0,0])

data.EEG = pop_epoch(data.EEG,  {15,16,17,18,19,20}, [-.200 .300]);   % epoch is in seconds
data.EEG = pop_rmbase(data.EEG, [], find(data.EEG.times< -120));      % times is in ms

% push the data
guidata(hObject,data)

% color this and next button
set(hObject, 'Backgroundcolor', [1,1,0])
data.pushbuttonScore.BackgroundColor = [0,1,0];
    


% --- Executes on button press in pushbuttonSave.
function pushbuttonSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonFilter.
function pushbuttonFilter_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = guidata(hObject);

locutoff = str2num(data.popupmenuLo.String{data.popupmenuLo.Value});
hicutoff = str2num(data.popupmenuHi.String{data.popupmenuHi.Value});
data.EEG = pop_eegfiltnew(data.EEG, locutoff, hicutoff);
data.EEG = pop_eegfiltnew(data.EEG, 48, 52, [], true);

% push the data
guidata(hObject,data)



% --- Executes on button press in pushbuttonScore.
function pushbuttonScore_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonScore (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = guidata(hObject);

tmp=data.EEG;
evt = nan(1,tmp.trials);
scr = nan(1,tmp.trials);
for e=1:tmp.trials
    % get trial info
    ndx = find([tmp.epoch(e).eventlatency{:}]==0);
    evt(e) = str2num(tmp.epoch(e).eventtype{ndx});
    % extract score in 20-120 ms window
    ndx = tmp.times>=20 & tmp.times<120;
    scr(e) = max(tmp.data(1,:,e));
end

data.uitableScores.Data = [evt' scr'];

% aggragate scores
avg = nan(1,5);
typ = [15:19];
for t=typ
    avg(t-14) = mean(scr(evt==t));
end

data.uitableAggScores.Data = [typ' avg'];
    


% --- Executes on button press in pushbuttonView.
function pushbuttonView_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonView (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = guidata(hObject);

tmp = data.EEG;
if size(tmp.data,3)>1
    tmp = pop_rmbase(tmp, [tmp.xmin 0]);
else
    tmp = pop_rmbase(tmp, []);
end

scr = get(0, 'ScreenSize');

eegplot(tmp.data, 'eloc_file',tmp.chanlocs, 'winlength',8, 'spacing', 50, ...
    'events', tmp.event, 'srate', tmp.srate, 'position', [scr(1),scr(2),scr(3)*.7,scr(4)*.8] );


% --- Executes on button press in pushbuttonAbs.
function pushbuttonAbs_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAbs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = guidata(hObject);

data.EEG.data = abs(data.EEG.data);

% push the data
guidata(hObject,data)



% --- Executes on button press in pushbuttonEnvelope.
function pushbuttonEnvelope_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonEnvelope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = guidata(hObject);

data.EEG.data = abs(hilbert(data.EEG.data'))';

% push the data
guidata(hObject,data)


% --- Executes on selection change in popupmenuLo.
function popupmenuLo_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuLo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuLo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuLo


% --- Executes during object creation, after setting all properties.
function popupmenuLo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuLo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuHi.
function popupmenuHi_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuHi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuHi contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuHi


% --- Executes during object creation, after setting all properties.
function popupmenuHi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuHi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
