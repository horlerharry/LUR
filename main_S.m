%% LUR Simulation for varying the count of SUs (Iridis Friendly).

clc; clear; close all
%rng(52); %Interesting rng for static scenario
%% settings process
filename = 'S_settings.txt';
fileID = fopen(filename);
data = textscan(fileID,'%f  %*[^\n]');
fclose(fileID);
%% Control Variables to be converted into settings.
maxS = data{1}(1); %Max number of Secondary Users.
gapS = data{1}(2); %Increment for Secondary USers
P = data{1}(3); %Number of Primary Users.
S = data{1}(4); %Min Number of Secondary Users.
near_dist=data{1}(5); %Max distance for Secondary Users
far_dist=data{1}(6); %Max distance for Primary Users
PDA_included = 1; %Whether to simulate PDA too
SU_target = data{1}(8); %Target rate for Secondary Users
bid_step = data{1}(9); %Step size for CDA Auction Game
N = data{1}(10); %Number of samples per user generation
U = data{1}(11); %Number of different user generations per power unit
rng_beta = data{1}(12); %Power allocated to RNG C-NOMA
direct = data{1}(13); %Channel from BS to PU, 0 for none, 1 for weak, 2 for strong
settings = struct("P",P,"S",S,"nd",near_dist,"fd",far_dist,...
    "bid_step",bid_step,"N",N,"U",U,"beta",rng_beta,...
    "fb",1,"PDA",PDA_included,'xValue','maxS');

%% Parameters for simulations
T_pwr = 20; %Transmit Power (in dB)
no = 10^(-114/10); %Noise Power
pb = 10^(T_pwr/10); %Transmit Power
e1 = (2.^SU_target)-1; %Inverse maths for needed rate for SUs
pmr = struct("T_pwr",T_pwr,"pb",pb,"no",no,"e1",e1,"dr",direct,'SU_target',SU_target,'S_values',S:gapS:maxS);
%parpool('local');

%% Output Variables
xPlot = S:gapS:maxS;
xlen = length(xPlot);
if(settings.PDA)
    out_len = 9;
else
    out_len = 7;
end
if(direct==2)
    s_dir = "Sdirect_";
    disp("Strong direct transmission");
elseif(direct==1)
    s_dir = "Wdirect_";
    disp("Weak direct transmission")
else
    s_dir = "nodirect_";
    disp("No direct transmission");
end
settings.Olen = out_len;
outputs = cell(1,xlen);
disp("LUR simulation: " + int2str(T_pwr) + "dB");
disp("From " + int2str(S) + " to " + int2str(maxS) + " SUs" );

%% Main loop
for i = 1:xlen
    disp("Number of SUs: " + int2str(xPlot(i)));
    outputs(i) = {LUR_simulate(i,settings,pmr)};
end

disp("LUR Simulation Complete!");
disp("Beginning saving and plotting...");
%% Output manipulation
PU_CDA_SE = reshape(cell2mat(cellfun(@(x) x(1),outputs)),[P,xlen]);
PU_CDA_AVG_SE = reshape(cell2mat(cellfun(@(x) x(3),outputs)),[P,xlen]);
PU_RNG_SE = reshape(cell2mat(cellfun(@(x) x(5),outputs)),[P,xlen]);
PU_NONOMA_SE = reshape(cell2mat(cellfun(@(x) x(7),outputs)),[P,xlen]);
games = "CDA_";
if(settings.PDA)
    PU_PDA_SE = reshape(cell2mat(cellfun(@(x) x(8),outputs)),[P,xlen]); 
    PU_PDA_AVG_SE = reshape(cell2mat(cellfun(@(x) x(10),outputs)), [P,xlen]);
    games = "CDA&PDA_";
end

%%Final data manipulation
%Mean of each xValue
PU_CDA_MEAN = mean(PU_CDA_SE);
PU_CDA_AVG_MEAN = mean(PU_CDA_AVG_SE);
PU_RNG_MEAN = mean(PU_RNG_SE);
PU_PDA_MEAN = mean(PU_PDA_SE);
PU_PDA_AVG_MEAN = mean(PU_PDA_AVG_SE);
PU_NOCOOP_MEAN = mean(PU_NONOMA_SE);
SU_CDA_MEAN = cellfun(@mean,cellfun(@(x) x(2),outputs));
SU_CDA_AVG_MEAN = cellfun(@mean,cellfun(@(x) x(4),outputs));
SU_RNG_MEAN = cellfun(@mean,cellfun(@(x) x(6),outputs));
SU_PDA_MEAN = cellfun(@mean,cellfun(@(x) x(9),outputs));
SU_PDA_AVG_MEAN = cellfun(@mean,cellfun(@(x) x(11),outputs));

%Sum of each xValue
PU_CDA_SUM = sum(PU_CDA_SE);
PU_CDA_AVG_SUM = sum(PU_CDA_AVG_SE);
PU_RNG_SUM = sum(PU_RNG_SE);
PU_NOCOOP_SUM = sum(PU_NONOMA_SE);
PU_PDA_SUM = sum(PU_PDA_SE);
PU_PDA_AVG_SUM = sum(PU_PDA_AVG_SE);
SU_CDA_SUM = cellfun(@sum,cellfun(@(x) x(2),outputs));
SU_CDA_AVG_SUM = cellfun(@sum,cellfun(@(x) x(4),outputs));
SU_RNG_SUM = cellfun(@sum,cellfun(@(x) x(6),outputs));
SU_PDA_SUM = cellfun(@sum,cellfun(@(x) x(9),outputs));
SU_PDA_AVG_SUM = cellfun(@sum,cellfun(@(x) x(11),outputs));

%% Folder management and data savingT_pwrT_pwr
folderName = "varyingS_" + int2str(S) + "to" + int2str(maxS) + "_" + s_dir + int2str(P) + "P";
mkdir("Results/"+folderName);

save_name = "LUR_" + s_dir + games + int2str(P) +...
    "P_" + int2str(S) + "S_to_"+ int2str(maxS) + "S.mat";
matfile = fullfile("Results",folderName,save_name);
PUSE_png = fullfile("Results",folderName,games + "PU_SE.png");
PUMEAN_png = fullfile("Results",folderName,games + "PU_MEAN_SE.png");
%SUSE_png = fullfile(folderName,games + "SU_SE.png");
SUMEAN_png = fullfile("Results",folderName,games + "SU_MEAN_SE.png");
PUSUM_png = fullfile("Results",folderName,games + "PU_SUM_SE.png");
SUSUM_png = fullfile("Results",folderName,games + "SU_SUM_SE.png");

maxS_data = outputs;
save(matfile,'maxS_data');

%% Plotting
shapes = ['o','x','s','d','^','p','h','*'];
colours = ["#1b9e77";"#d95f02";"#7570b3";"#e7298a";"#66a61e";"#e6ab02";...
"#a6761d";"#666666"];
lgd = cell(P*2,1);
figure; hold on;
for u = 1:P
    plot(xPlot,PU_CDA_SE(u,:),'Marker',shapes(u),'Color',colours(u));
    plot(xPlot,PU_CDA_AVG_SE(u,:),'--','Marker',shapes(u),'Color',colours(u));
    plot(xPlot,PU_RNG_SE(u,:),':','Marker',shapes(u),'Color',colours(u));
    if settings.PDA, plot(xPlot,PU_PDA_SE(u,:),'-.','Marker',shapes(u),'Color',colours(u));...
    plot(xPlot,PU_PDA_AVG_SE(u,:),' ','Marker',shapes(u),'Color',colours(u));end
    lgd{(4*u)-3} = strcat('PU_{PDA-CSI-',num2str(u),'}');
    lgd{(4*u)-2} = strcat('PU_{CDA-CSI-',num2str(u),'}');
    lgd{(4*u)-1} = strcat('PU_{CDA-No CSI-',num2str(u),'}');
    lgd{4*u} = strcat('PU_{PDA-No CSI-',num2str(u),'}');
end
xlabel('Number of SUs (S)');ylabel('Spectral Efficiency (bits/s/Hz)');
title('Spectral Efficiency of all Primary Users');  ylim([0 inf]);
legend(lgd,'NumColumns',1,'location','bestoutside');
saveas(gcf,PUSE_png);

figure; hold on;
plot(xPlot,PU_CDA_MEAN,'Marker',shapes(1),'Color',colours(1)); plot(xPlot,PU_CDA_AVG_MEAN,'--','Marker',shapes(2),'Color',colours(3));
plot(xPlot,PU_RNG_MEAN,':','Marker',shapes(3),'Color',colours(5)); plot(xPlot,PU_NOCOOP_MEAN,'Color',colours(6));
if settings.PDA, plot(xPlot,PU_PDA_MEAN,'Marker',shapes(5),'Color',colours(2)), plot(xPlot,PU_PDA_AVG_MEAN,'Marker',shapes(6),'Color',colours(4)); end
xlabel('Number of SUs (P)');ylabel('Average Spectral Efficiency (bits/s/Hz)');
title('Average Spectral Efficiency of Primary Users');ylim([0 inf]);
lgd = legend('CDA with CSI','CDA without CSI','Random C-NOMA','Direct transmission','PDA with CSI','PDA without CSI',...
    'location','northwest');
saveas(gcf,PUMEAN_png);

figure; hold on;
plot(xPlot,SU_CDA_MEAN,'Marker',shapes(1),'Color',colours(1)); plot(xPlot,SU_CDA_AVG_MEAN,'--','Marker',shapes(2),'Color',colours(3));
plot(xPlot,SU_RNG_MEAN,':','Marker',shapes(3),'Color',colours(5));
if settings.PDA, plot(xPlot,SU_PDA_MEAN,'Marker',shapes(5),'Color',colours(2)); 
    plot(xPlot,SU_PDA_AVG_MEAN,'--','Marker',shapes(6),'Color',colours(4)); end
xlabel('Number of SUs (P)');ylabel('Average Spectral Efficiency (bits/s/Hz)');
title('Average Spectral Efficiency of all Secondary Users'); ylim([0 inf]);
legend('CDA with CSI','CDA without CSI','Random C-NOMA','PDA with CSI','PDA without CSI',...
    'location','northwest');
saveas(gcf,SUMEAN_png);

figure; hold on;
plot(xPlot,PU_CDA_SUM,'Marker',shapes(1),'Color',colours(1)); plot(xPlot,PU_CDA_AVG_SUM,'--','Marker',shapes(2),'Color',colours(3));
plot(xPlot,PU_RNG_SUM,':','Marker',shapes(2),'Color',colours(5)); plot(xPlot,PU_NOCOOP_SUM,'Color',colours(6));
if settings.PDA, plot(xPlot,PU_PDA_SUM,'Marker',shapes(5),'Color',colours(2)), plot(xPlot,PU_PDA_AVG_SUM,'--','Marker',shapes(6),'Color',colours(4)), end
xlabel('Number of SUs (P)');ylabel('Sum Spectral Efficiency (bits/s/Hz)');
title('Sum Spectral Efficiency of all Primary Users'); ylim([0 inf]);
lgd = legend('CDA with CSI','CDA without CSI','Random C-NOMA','Direct transmission','PDA with CSI','PDA without CSI',...
    'location','northwest');
saveas(gcf,PUSUM_png);

% figure; hold on;
% plot(xPlot,SU_CDA_SUM,'Marker',shapes(1)); plot(xPlot,SU_CDA_AVG_SUM,'--','Marker',shapes(2));
% plot(xPlot,SU_RNG_SUM,'Marker',shapes(3)); 
% if settings.PDA, plot(xPlot,SU_PDA_SUM,'Marker',shapes(5),'Color','#77AC30');end
% xlabel('Transmit Power (dB)');ylabel('Sum Spectral Efficiency (bits/s/Hz)');
% title('Sum Spectral Efficiency of SUs for an increasing number of SUs');
% legend('CDA with CSI','CDA without CSI','Random C-NOMA','PDA with CSI',...
%     'location','northwest');
% saveas(gcf,SUSUM_png);
