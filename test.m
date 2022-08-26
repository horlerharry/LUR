filename = 'settings.txt';
fileID = fopen(filename);
data = textscan(fileID,'%f  %*[^\n]');
fclose(fileID);
data{1}

