clear all
counter = 20;
nfile = input (' How many images in this folder ');
r = zeros(nfile,1);
time = [5:5:3300/4];

for i=1:nfile
    A = imread(sprintf('file_%d.tif',counter));
    whites = find(A==255); %find number of white pixels
    area = length(whites); %1 pix/mm2 so this is the topset area
    r(i) = sqrt(2*area/pi); %calculate semicircle radius
    counter = counter + 20;
    clear A whites area
end

figure;plot(time,r);xlabel('time (mins)');ylabel('r (mm)');
