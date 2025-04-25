function varargout = Chest_gui(varargin)
% CHEST_GUI MATLAB code file for Chest_gui.fig
%      CHEST_GUI, by itself, creates a new CHEST_GUI or raises the existing
%      singleton*.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Chest_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @Chest_gui_OutputFcn, ...
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

% --- Executes just before Chest_gui is made visible.
function Chest_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for Chest_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = Chest_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
varargout{1} = handles.output;

% --- Executes on button press in Browse.
function Browse_Callback(hObject, eventdata, handles)
% Load the chest X-ray image
[I, path] = uigetfile({'*.*', 'All Image Files'}, 'Select an input image');
if isequal(I, 0)
    disp('No image selected, exiting...');
    return;
end
str = fullfile(path, I);
handles.originalImage = imread(str);

% Display the original image on the first axes
axes(handles.axes9);
imshow(handles.originalImage);
title('Original Image', 'Color', 'white');  % Set title color to white
guidata(hObject, handles);

% --- Executes on button press in gray_image.
function gray_image_Callback(hObject, eventdata, handles)
% Convert the image to grayscale and display it
if isfield(handles, 'originalImage')
    grayImage = im2gray(handles.originalImage);
    axes(handles.axes1);
    imshow(grayImage);
    title('Grayscale Image', 'Color', 'white');  % Set title color to white
    handles.grayImage = grayImage;
    guidata(hObject, handles);
else
    msgbox('Please load an image first', 'Error', 'error');
end

% --- Executes on button press in highpass.
function highpass_Callback(hObject, eventdata, handles)
% Apply high-pass filter
if isfield(handles, 'grayImage')
    kernel = -1 * ones(3);
    kernel(2,2) = 9;
    enhancedImage = imfilter(handles.grayImage, kernel);
    axes(handles.axes2);
    imshow(enhancedImage);
    title('High-pass Filtered Image', 'Color', 'white');  % Set title color to white
    handles.enhancedImage = enhancedImage;
    guidata(hObject, handles);
else
    msgbox('Please apply the grayscale conversion first', 'Error', 'error');
end

% --- Executes on button press in median.
function median_Callback(hObject, eventdata, handles)
% Apply median filter
if isfield(handles, 'enhancedImage')
    medianFiltered = medfilt2(handles.enhancedImage);
    axes(handles.axes11);
    imshow(medianFiltered);
    title('Median Filtered Image', 'Color', 'white');  % Set title color to white
    handles.medianFiltered = medianFiltered;
    guidata(hObject, handles);
else
    msgbox('Please apply the high-pass filter first', 'Error', 'error');
end

% --- Executes on button press in threshold.
function threshold_Callback(hObject, eventdata, handles)
% Apply thresholding
if isfield(handles, 'medianFiltered')
    BW = imbinarize(handles.medianFiltered, 0.6);
    axes(handles.axes5);
    imshow(BW);
    title('Threshold Segmentation', 'Color', 'white');  % Set title color to white
    handles.BW = BW;
    guidata(hObject, handles);
else
    msgbox('Please apply the median filter first', 'Error', 'error');
end

% --- Executes on button press in watershed.
function watershed_Callback(hObject, eventdata, handles)
% Apply watershed segmentation
if isfield(handles, 'BW')
    I = imresize(handles.originalImage, [200, 200]);
    I = im2gray(I);
    I = imbinarize(I, 0.6);
    hy = fspecial('sobel');
    hx = hy';
    Iy = imfilter(double(I), hy, 'replicate');
    Ix = imfilter(double(I), hx, 'replicate');
    gradmag = sqrt(Ix.^2 + Iy.^2);
    L = watershed(gradmag);
    Lrgb = label2rgb(L);  % Label the watershed regions with distinct colors
    axes(handles.axes8);
    imshow(Lrgb);
    title('Watershed Segmentation', 'Color', 'white');  % Set title color to white
else
    msgbox('Please apply the threshold segmentation first', 'Error', 'error');
end

% --- Executes on button press in morphology.
function morphology_Callback(hObject, eventdata, handles)
% Apply morphological operations
if isfield(handles, 'BW')
    se1 = strel('disk', 2);
    se2 = strel('disk', 20);
    first = imclose(handles.BW, se1);  % Perform closing operation
    second = imopen(first, se2);  % Perform opening operation
    axes(handles.axes12);
    imshow(second);
    title('After Morphological Operations', 'Color', 'white');  % Set title color to white
    handles.second = second;
    guidata(hObject, handles);
else
    msgbox('Please apply the threshold segmentation first', 'Error', 'error');
end

% --- Executes on button press in tumor.
function tumor_Callback(hObject, eventdata, handles)
% Tumor detection algorithm
if isfield(handles, 'second')
    stats = regionprops('table', handles.second, 'Centroid', 'MajorAxisLength', 'MinorAxisLength');
    centers = stats.Centroid;
    diameters = mean([stats.MajorAxisLength stats.MinorAxisLength], 2);
    radii = diameters / 2;
    finalRadii = radii + 40;

    if any(radii > 5)  % If a valid tumor is detected (radius > 5)
        K = im2uint8(handles.second);
        final = imadd(K, handles.grayImage);
        axes(handles.axes6);
        imshow(final, []);
        viscircles(centers, finalRadii);  % Draw circles around the detected tumor
        title('Detected Tumor', 'Color', 'white');  % Set title color to white
        msgbox('Tumor Detected', 'Detection Result', 'warn');
    else
        K = im2uint8(handles.second);
        final = imadd(K, handles.grayImage);
        axes(handles.axes8);
        imshow(final, []);
        title('No Tumor Detected', 'Color', 'white');  % Set title color to white
        msgbox('No Tumor Detected', 'Detection Result', 'help');
    end
else
    msgbox('Please apply the morphological operations first', 'Error', 'error');
end

% --- Executes on button press in Reset.
function Reset_Callback(hObject, eventdata, handles)
% Clear the content from each axes in the GUI
axes(handles.axes9);
cla;
title('Original Image', 'Color', 'white');  % Set title color to white

axes(handles.axes1);
cla;
title('Grayscale Image', 'Color', 'white');  % Set title color to white

axes(handles.axes2);
cla;
title('High-pass Filtered Image', 'Color', 'white');  % Set title color to white

axes(handles.axes11);
cla;
title('Median Filtered Image', 'Color', 'white');  % Set title color to white

axes(handles.axes5);
cla;
title('Threshold Segmentation', 'Color', 'white');  % Set title color to white

axes(handles.axes8);
cla;
title('Watershed Segmentation', 'Color', 'white');  % Set title color to white

axes(handles.axes12);
cla;
title('After Morphological Operations', 'Color', 'white');  % Set title color to white

axes(handles.axes6);
cla;
title('Tumor Location', 'Color', 'white');  % Set title color to white


% Reset handles for stored images
handles.originalImage = [];
handles.grayImage = [];
handles.enhancedImage = [];
handles.medianFiltered = [];
handles.BW = [];
handles.second = [];
guidata(hObject, handles);  % Update handles structure after reset
