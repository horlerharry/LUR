%% LUR Simulation for varying the transmit power at the Base Station (Iridis Friendly).

clc; clear; close all
%rng(52); %Interesting rng for static scenario
%% settings process
filename = 'settings.txt';
fileID = fopen(filename);
data = textscan(fileID,'%f  %*[^\n]');
fclose(fileID);
%% Control Variables to be converted into settings.
P = data{1}(1); %Number of Primary Users.
S = data{1}(2); %Number of Secondary Users.
near_dist=data{1}(3); %Max distance for Secondary Users
far_dist=data{1}(4); %Max distance for Primary Users
PDA_included = data{1}(5); %Whether to simulate PDA too
SU_target = data{1}(6); %Target rate for Secondary Users
bid_step = data{1}(7); %Step size for CDA Auction Game
N = data{1}(8); %Number of samples per user generation
U = data{1}(9); %Number of different user generations per power unit.
rng_beta = data{1}(10); %Power allocated to RNG C-NOMA
direct = data{1}(11); %Does the channel between BS and PU exist?
settings = struct("P",P,"S",S,"nd",near_dist,"fd",far_dist,...
    "bid_step",bid_step,"N",N,"U",U,"beta",rng_beta,...
    "fb",1,"PDA",PDA_included,'xValue','power');

%% Parameters for simulations
T_pwr = 15:25;
no = 10^(-114/10);
e1 = (2.^SU_target)-1;
pmr = struct("T_pwr",T_pwr,"pb",0,"no",no,"e1",e1,"dr",direct,'SU_target',SU_target);
%parpool('local');

%% Output Variables
xlen = length(T_pwr);
if(settings.PDA)
    out_len = 11;
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
disp("LUR Simulation: " + int2str(P) + " PUs and " + int2str(S) + " SUs");
disp("From " + int2str(T_pwr(1)) + "dB to " + int2str(T_pwr(end)) + "dB");

%% Main loop
for i = 1:xlen
    disp("Transmit Power: " + int2str(T_pwr(i)));
    outputs(i) = {LUR_simulate(i,settings,pmr)};
end
disp("LUR Simulation Complete!");
disp("Beginning saving and plotting...");

%% Output manipulation
PU_CDA_SE = reshape(cell2mat(cellfun(@(x) x(1),outputs)),[P,xlen]);
SU_CDA_SE = reshape(cell2mat(cellfun(@(x) x(2),outputs)),[S,xlen]);
PU_CDA_AVG_SE = reshape(cell2mat(cellfun(@(x) x(3),outputs)),[P,xlen]);
SU_CDA_AVG_SE = reshape(cell2mat(cellfun(@(x) x(4),outputs)),[S,xlen]);
PU_RNG_SE = reshape(cell2mat(cellfun(@(x) x(5),outputs)),[P,xlen]);
SU_RNG_SE = reshape(cell2mat(cellfun(@(x) x(6),outputs)),[S,xlen]);
PU_NONOMA_SE = reshape(cell2mat(cellfun(@(x) x(7),outputs)),[P,xlen]);
games = "CDA_";
if(settings.PDA)
    PU_PDA_SE = reshape(cell2mat(cellfun(@(x) x(8),outputs)),[P,xlen]); 
    SU_PDA_SE = reshape(cell2mat(cellfun(@(x) x(9),outputs)),[S,xlen]);
    PU_PDA_AVG_SE = reshape(cell2mat(cellfun(@(x) x(10),outputs)),[P,xlen]);
    SU_PDA_AVG_SE = reshape(cell2mat(cellfun(@(x) x(11),outputs)), [S,xlen]);
    games = "CDA&PDA_";
end
%% Summing data
PU_PDA_SUM = sum(PU_PDA_SE);
SU_PDA_SUM = sum(SU_PDA_SE);
PU_PDA_AVG_SUM = sum(PU_PDA_AVG_SE);
SU_PDA_AVG_SUM = sum(SU_PDA_AVG_SE);
PU_CDA_SUM = sum(PU_CDA_SE);
PU_CDA_AVG_SUM = sum(PU_CDA_AVG_SE);
PU_RNG_SUM = sum(PU_RNG_SE);
PU_NOCOOP_SUM = sum(PU_NONOMA_SE);
SU_CDA_SUM = sum(SU_CDA_SE);
SU_CDA_AVG_SUM = sum(SU_CDA_AVG_SE);
SU_RNG_SUM = sum(SU_RNG_SE);

%% Folder management and data saving

folderName = "tpwr_"+s_dir + int2str(P) + "P" + int2str(S) + "S_";

mkdir("Results/"+folderName);


save_name = "LUR_" + s_dir + games + int2str(P) + "P" + int2str(S) + "S.mat";
matfile = fullfile("Results",folderName,save_name);
PUSE_png = fullfile("Results",folderName,games + "PU_SE.png");
PUSUM_png = fullfile("Results",folderName,games + "PU_SUM_SE.png");
SUSE_png = fullfile("Results",folderName,games + "SU_SE.png");
SUSUM_png = fullfile("Results",folderName,games + "SU_SUM_SE.png");
save(matfile,'outputs','settings','pmr','-v7.3');

%% PlottingxPlot
%LOAD DATA
%load('dataname.mat');

%Custom plotting data
shapes = ['o','x','s','d','^','p','h','*'];
%Old Colour Scheme
% colours = ["#1b9e77";"#d95f02";"#7570b3";"#e7298a";"#66a61e";"#e6ab02";...
% "#a6761d";"#666666"];
%New Colour Scheme
colours = ["#ff0000","#377eb8","#4daf4a","#984ea3","#ff7f00",...
    "#ffff33","#a65628","#f781bf","#999999"];
labels = cell(P*2,1);

%All Primary Users' Spectral Efficiency
% if(P<9) %Likely unreadable/useless after a certain number of PUs.
%     figure; hold on;
%     for u = 1:P
%         plot(T_pwr,PU_CDA_SE(u,:),'Marker',shapes(u),'Color',colours(u));
%         plot(T_pwr,PU_CDA_AVG_SE(u,:),'Marker',shapes(u),'Color',colours(u));
%         %plot(T_pwr,PU_RNG_SE(u,:),':','Marker',shapes(u),'Color',colours(u));
%         if (settings.PDA)
%             plot(T_pwr,PU_PDA_SE(u,:),'--','Marker',shapes(u),'Color',colours(u)); 
%             plot(T_pwr,PU_PDA_AVG_SE(u,:),'--','Marker',shapes(u),'Color',colours(u));
%         end
%         labels{(4*u)-3} = strcat('PU_{PDA-No CSI-',num2str(u),'}');
%         labels{(4*u)-2} = strcat('PU_{PDA-CSI-',num2str(u),'}');
%         labels{(4*u)-1} = strcat('PU_{CDA-CSI-',num2str(u),'}');
%         labels{(4*u)} = strcat('PU_{CDA-No CSI-',num2str(u),'}');
%         %labels{5*u} = strcat('PU_{RNG-',num2str(u),'}');
%     end
%     xlabel('Transmit Power (dB)');ylabel('Spectral Efficiency (bits/s/Hz)');
%     title('Spectral Efficiency of all Primary Users'); 
%     legend(labels,'NumColumns',1,'location','bestoutside');
%     ylim([0 inf]);
%     saveas(gcf,PUSE_png);
% end

%Primary User Sum Spectral Efficiency
figure; hold on;
plot(T_pwr,PU_CDA_SUM,'Marker',shapes(1),'Color',colours(1)); 
plot(T_pwr,PU_CDA_AVG_SUM,'--','Marker',shapes(1),'Color',colours(2));
plot(T_pwr,PU_RNG_SUM,'Marker',shapes(2),'Color',colours(9)); 
plot(T_pwr,PU_NOCOOP_SUM,'Marker',shapes(4),'Color',colours(4));
if settings.PDA, plot(T_pwr,PU_PDA_SUM,'Marker',shapes(3),'Color',colours(3)),
    plot(T_pwr,PU_PDA_AVG_SUM,'--','Marker',shapes(3),'Color',colours(5)), end
xlabel('Transmit Power (dB)');ylabel('Sum Spectral Efficiency (bits/s/Hz)');
title('Sum Spectral Efficiency of all Primary Users');
legend('CDA with CSI','CDA without CSI','Random C-NOMA','Direct transmission','PDA with CSI','PDA without CSI',...
    'location','northwest');
h = get(gca,'Children');
set(gca,'Children',[h(4),h(3),h(5),h(1),h(6),h(2)]);
ylim([0 inf]);
saveas(gcf,PUSUM_png);

%All Secondary Users' Spectral Efficiency
% if(S<9)
%     figure; hold on;
%     for u = 1:S
%         plot(T_pwr,SU_CDA_SE(u,:),'Marker',shapes(u),'Color',colours(u));
%         plot(T_pwr,SU_CDA_AVG_SE(u,:),'--','Marker',shapes(u),'Color',colours(u));
%         %plot(T_pwr,SU_RNG_SE(u,:),':','Marker',shapes(u),'Color',colours(u));
%         if settings.PDA, plot(T_pwr,SU_PDA_SE(u,:),'-.','Marker',shapes(u),'Color',colours(u));...
%         plot(T_pwr,SU_PDA_AVG_SE(u,:),' ','Marker',shapes(u),'Color',colours(u));end
%         labels{(4*u)-3} = strcat('SU_{PDA-No CSI-',num2str(u),'}');
%         labels{(4*u)-2} = strcat('SU_{PDA-CSI-',num2str(u),'}');
%         labels{(4*u)-1} = strcat('SU_{CDA-CSI-',num2str(u),'}');
%         labels{(4*u)} = strcat('SU_{CDA-No CSI-',num2str(u),'}');
%         %labels{5*u} = strcat('SU_{RNG-',num2str(u),'}');
%     end
%     xlabel('Transmit Power (dB)');ylabel('Spectral Efficiency (bits/s/Hz)');
%     title('Spectral Efficiency of all Secondary Users'); 
%     legend(labels,'NumColumns',1,'location','bestoutside');
%     ylim([0 inf]);
%     saveas(gcf,SUSE_png);
% end

%Secondary User Sum Spectral Efficiency
figure; hold on;
plot(T_pwr,SU_CDA_SUM,'Marker',shapes(1),'Color',colours(1)); 
plot(T_pwr,SU_CDA_AVG_SUM,'--','Marker',shapes(1),'Color',colours(2));
plot(T_pwr,SU_RNG_SUM,'Marker',shapes(2),'Color',colours(9));
if settings.PDA, plot(T_pwr,SU_PDA_SUM,'Marker',shapes(3),'Color',colours(3)); 
    plot(T_pwr,SU_PDA_AVG_SUM,'--','Marker',shapes(3),'Color',colours(5)); end
xlabel('Transmit Power (dB)');ylabel('Sum Spectral Efficiency (bits/s/Hz)');
title('Sum Spectral Efficiency of all Secondary Users');
legend('CDA with CSI','CDA without CSI','Random C-NOMA','PDA with CSI','PDA without CSI',...
    'location','northwest');
h = get(gca,'Children');
set(gca,'Children',[h(3),h(4),h(1),h(5),h(2)]);
ylim([0 inf]);
saveas(gcf,SUSUM_png);
