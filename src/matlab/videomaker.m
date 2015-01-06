clc
clear all
close all
%%
% WORKDIRECTORY
newFolder = 'E:\SEN_crop\';
cd(newFolder) 

% INPUT SEARCH FOR PHOTOS
p = which('SEN_R00001.jpg');     %filenames example
filelist = dir([fileparts(p) filesep 'SEN_R*****.jpg']);      %add wildcart (*) in which they differ from the example
fileNames = {filelist.name}';
nImages = length(fileNames);

% FILE SAVE PARAMETERS % Name for saved matrix
Experiment ='SEN_Day1'; 
Basin = '1and2';
ExperimentRun = 'R3-R6';

myVideo = VideoWriter(['Video\' num2str(Experiment) '-' num2str(Basin) '-' num2str(ExperimentRun)], 'Motion JPEG AVI');
myVideo.FrameRate = 15;  % Default 30
open(myVideo);

%% LOADING PICTURES (in loop)

tic %starts timer
waittxt = 'tijd voor koffie';
z = waitbar(0,waittxt,'Name','Analysis');

for k = 541:nImages; % LOOP FOR ALL PICTURES TO RUN THROUGH ANALYSIS
   
    A1 = imread(fileNames{k});
    F= [num2str(fileNames{k})];  
     
    %    PLOT TOPSET ACTIVITY
    figure('units','normalized','outerposition',[0 0 1 1]),
    imagesc (A1)
    set (gca, 'xdir', 'normal', 'ydir', 'reverse')
    axis equal, axis tight
    title([num2str(F(1:10))])
    
    % SAVES PREVIOUS FIGURE AT HIGH RESOLUTION (print, -r300 is pixels per square inch)
   % savename1 = ['Video\' fileNames{k}(1:15)] % '_SL_TS']; %Saves in Map Shore_Mig within workdir with first 10 letters of filename(without .jpg) +further name and extension
   % set(gcf,'PaperPositionMode','auto');     
   % print (gcf, savename1, '-r300', '-djpeg');
    
    % SAVES VIDEO OF PREVIOUS FIGURE IN LOOP
    currFrame = getframe(gcf);
    writeVideo(myVideo, currFrame);
    close %closes figure
end

close (myVideo); %writes video to file
close(z); %closes waitbar
clear z waittxt %removes waitbar
 
toc


clc
clear all
close all
