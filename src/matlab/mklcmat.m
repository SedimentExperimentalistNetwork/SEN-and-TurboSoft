function[] = mklcmat(pathname, outname, matlength)

% mklcmat: make load cell matrix
% lhsu, 2011 october 04
%
% read in the .csv and output a .mat where the data are processed for
% 1) subtract the weight of the plate
% 2) align the zero offset
% 3) convert from kg to Newtons
% 4) bandstop filter to get rid of plate vibration noise
% 5) lowpass filter to simulate 50 Hz cutoff
%
% pathname: folder with raw load cell data
% outname: name of new (processed) load cell data
% matlength: number of points in each profile - depends on drum velocity
%
% Output:
%
% lcmat: 3 column matrix of load cell measurements
% lcmat(:,n,1) is measured newtons after plate weight and offset accounted
% lcmat(:,n,2) is the result with a lowpass filter, making the cutoff
% frequency 50 Hz (massively cutting down on the magnitude of the
% fluctuations.) 
% lcmat(:,n,3) is the result with a bandstop filter to get rid of vibration
% machine noise
% lcmat(:,n,4) is the result of a high pass filter, looking at everything
% above 50 Hz, should be ~equal to calculated excursions


plate_mass = 4.04;

cd(pathname)

% commandlines in 03 Processing Load Cell data appendix

list_files = ls;
%read each of those strings
files = cellstr(list_files);

%get number of files
n = length(files);

lcmat = nan(matlength,n-2, 3); % create an empty matrix

for j = 3:n
% there is +2 because the first two 'files' listed are . and .. on a PC
% this loop goes through each .csv (one wheel rotation) in the folder

    % need to put it in the correct format to use later
    name = files(j);
    namemat = cell2mat(name);
    
    plength = length(namemat) - 4; % -4 for the extension ".mat"
    pname = namemat(1:plength);

    [kilograms] = textread(namemat,'%f','headerlines',22); 
    % read in the load cell data from the .csv file, put it in vector
    % This version of Matlab seems to handle strings differently from the
    % previous version. There is no need to use mat2str, pname can be used
    % as it above.
    
    newtons = kilograms*9.8;
    % convert to newtons - this is weird in a drum but it works out to a
    % factor of 9.8 because the load cell always assumes it is normal to
    % gravity.
    
    % create a matrix the length of kilograms (e.g. 4200 points)
    numpts = length(kilograms);
    num = 1.0:numpts;
    angle = (num/numpts*150) + 45;  
    % distribute the points in the time series between 45 degrees and 195
    % degrees, where 0 degrees is at the 3 o'clock position and positive is
    % clockwise. This is the coordinate system of the instrument system,
    % and the sensor is triggered on at 45 degrees and collects for 150
    % degrees, because that is where the flow is likely to be. 

    plate_weight = plate_mass * 9.81 * sin(angle.*3.14159/180);
    % convert plate mass to weight
    
    mnewtons = newtons - plate_weight';
    % subtract the plate weight (transpose of) from the newtons to get
    % mnewtons which I think I named for "measured newtons" although that
    % makes no sense to me now. In any case, mnewtons is corrected for the
    % varying plate weight as it spins around.
    
    % Here we find the offset of the load cell measurement from zero. The
    % offset is affected by the laboratory temperature and other things. We
    % do this by finding the mean value of mnewtons BEFORE the flow passes
    % over it i.e. there is nothing on top of the flow, it is around the 4
    % or 5 o'clock position and usually the flow does not exist until the 6
    % o'clock position. We are looking from 45 degrees to 61 degrees. This
    % is probably stupid the way it is implemented, but because the time
    % series are of different lengths depending on how fast the drum is
    % going, there needs to be some flexibility to it.
    
    % q = find(angle==61);  
    % find the index of the angle vector corresponding to 61 degrees
    % Doing it this dumb way because there may not be an exact 61    
    q = 1;
    while angle(q) < 61
        q=q+1;
    end
    
    % the load cell offset, lcoffset, is the mean value of mnewtons 
    % between 45 and 61 degrees
    lcoffset = nanmean(mnewtons(1:q));
    
    % now correct mnewtons by this calculated offset, this is our data
    % vector, dat
    dat = mnewtons-lcoffset;
    
    % Here we set up the filtering, which is stuff that Gilead Wurman
    % explained to me.
    
    %only the first half of the fft is useful
    halflen = round(length(dat)/2);

    %this will be convenient when we define the filter
    index = linspace(0,1,halflen);

    % OK, at this point try to figure out what frequencies are most useful
    % to you. That's between you and your data.  Let's say you are
    % interested in everything except for machine noise between index I0
    % and I1 on the x-axis of the plot.  To make the filter:
    % [b, a] = butter(2,[I0 I1],'stop');

    % Following Gilead's wisdom, we apply two different filters, the first
    % to attempt to filter out machine noise. The boundaries were chosen by
    % trial and error to get rid of the periodic vibration we found in ALL
    % experiments. this is a stopgap filter because it filters out
    % frequencies between I0 and I1. For our 1000 Hz sampling frequency,
    % I0 and I1 of 0.005 and 0.1 correspond to 2.5 Hz and 50 Hz. These
    % leaves the very low frequency general shape of the flow, and the high
    % frequency fluctuations above 50 Hz.
    
    % filter stopgap
    [b, a] = butter(2,[0.005 0.1],'stop'); 
    % these particular boundaries I0 and I1 were chosen by trial and error
    % on 05 june 2009

    % The second filter is a low pass filter which lowers the cutoff
    % frequency from 500 Hz (set by the digital filter on the wheel) to 50
    % Hz. This is supposed to be very very safe with regards to avoiding
    % exciting frequencies close to the natural or "ringing" frequencies of
    % the load plate. We tried to measure the natural resonant frequency of
    % the plate but did not obtain a very clear response signal. In any
    % case setting such a lowpass filter and then doing the same analyses
    % on the fluctuations to see if the same trends hold between a
    % fluctuation metric and variables related to the flow.
    
    % filter lowpass
    [c, d] = butter(2, 0.1);  
    % this is supposed to be like changing the cutoff frequency from 500 to
    % 50 Hz
    
    %filter highpass, added this just to see what comes out
    [e, f] = butter(2, 0.1, 'high');
    
    % zero phase digital filtering: filtfilt is 2 pass, so that there is
    % zero phase-distortion that may happen with a 1 pass filter. We desire
    % zero phase distortion because the timing is important.
    
    filtstop = filtfilt(b,a,dat); 
    filtlow = filtfilt(c,d,dat);
    filthigh = filtfilt(e,f,dat);
    
    % the j index is printed out to screen so we can keep track of where we
    % are in the processing, length of dat may be printed as well. At some
    % point this was useful to me.
    
    j  % output something to the screen so you can see it's working
    nlength = length(dat)
      
    % Here, fill in the result matrix
    lcmat(1:nlength,j-2, 1) = dat;
    lcmat(1:nlength,j-2, 2) = filtlow;
    lcmat(1:nlength,j-2, 3) = filtstop; 
    lcmat(1:nlength,j-2, 4) = filthigh;
    clear mnewtons newtons plate_weight; 
    % clear things out for next rotation
    
end

% when all of the rotations are done, move to the output folder and write
% out the matrix for the experiment, named appropriately

cd('C:\hsu_dfdata\01_force_data\02_processed\lcmats');
save(outname, 'lcmat');

