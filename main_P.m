%% LUR Simulation for varying the count of PUs (Iridis Friendly).

clc; clear; close all
%rng(52); %Interesting rng for static scenario
%% settings process
filename = 'P_settings.txt';
fileID = fopen(filename);
data = textscan(fileID,'%f  %*[^\n]');
fclose(fileID);
%% Control Variables to be converted into settings.
maxP = data{1}(1); %Max number of Primary users.
gapP = data{1}(2); %Increment for Primary users.
P = data{1}(3); %Min number of Primary Users.
S = data{1}(4); %Number of Secondary Users.
near_dist=data{1}(5); %Max distance for Secondary Users
far_dist=data{1}(6); %Max distance for Primary Users
PDA_included = 1; %Whether to simulate PDA too
SU_target = data{1}(8); %Target rate for Secondary Users
bid_step = data{1}(9); %Step size for CDA Auction Game
N = data{1}(10); %Number of samples per user generation
U = data{1}(11); %Number of different user generations per power unit.
rng_beta = data{1}(12); %Power allocated to RNG C-NOMA
direct = data{1}(13); %Channel from BS to PU, 0 for none, 1 for weak, 2 for strong
settings = struct("P",P,"S",S,"nd",near_dist,"fd",far_dist,...
    "bid_step",bid_step,"N",N,"U",U,"beta",rng_beta,...
    "fb",1,"PDA",PDA_included,'xValue','maxP','bidMech',0);

%% Parameters for simulations
T_pwr = 20;
no = 10^(-114/10);
pb = 10^(T_pwr/10);
e1 = (2.^SU_target)-1;
pmr = struct("T_pwr",T_pwr,"pb",pb,"no",no,"e1",e1,"dr",direct,'SU_target',SU_target,'P_values',P:gapP:maxP);
%parpool('local');

%% User Generation, generate all users.
settings.P = maxP;
all_PUs = cell(1,U); all_SUs = cell(1,U);
for u = 1:U
    [PU_set,SU_set] = user_gen(settings);
    all_PUs{u} = PU_set; all_SUs{u} = SU_set;
end
settings.P = P;
pmr = struct("T_pwr",T_pwr,"pb",pb,"no",no,"e1",e1,"dr",direct,'SU_target'...
    ,SU_target,'P_values',P:gapP:maxP,'allPUs',{all_PUs},'allSUs',{all_SUs});
%% Output Variables
xPlot = P:gapP:maxP;
xlen = length(xPlot);
if(settings.PDA)
    out_len = 14;
    games = "CDA&PDA_";
else
    out_len = 7;
    games = "CDA_";
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
disp("From " + int2str(P) + " to " + int2str(maxP) + " PUs");
%% Main loop
for i = 1:xlen
    tic;
    disp("Number of PUs: " + int2str(xPlot(i)));
    %outputs(i) = {LUR_simulate(i,settings,pmr)};
    outputs(i) = {LUR_sameusers(i,settings,pmr)};
    toc;
end

disp("LUR Simulation Complete!");
disp("Beginning saving and plotting...");

%% Folder management and data saving
folderName = "varyingP_" + int2str(P) + "to" + int2str(maxP) + "_" + s_dir + int2str(S) + "S";
mkdir("Results/"+folderName);

save_name = "LUR_" + s_dir + games + int2str(P) +...
    "P_to_" +int2str(maxP) +"P_" + int2str(settings.S) + "S.mat";
matfile = fullfile("Results",folderName,save_name);
PUMEAN_name = fullfile("Results",folderName,games + "PU_MEAN_SE");
%SUSE_png = fullfile("Results",folderName,games + "SU_SE.png");
SUMEAN_name = fullfile("Results",folderName,games + "SU_MEAN_SE");
PUSUM_name = fullfile("Results",folderName,games + "PU_SUM_SE");
%SUSUM_png = fullfile("Results",folderName,games + "SU_SUM_SE.png");

save(matfile,'outputs','settings','pmr','-v7.3');
%% Output manipulation
SU_CDA_SE = reshape(cell2mat(cellfun(@(x) x(2),outputs)),[settings.S,xlen]);
SU_CDA_AVG_SE = reshape(cell2mat(cellfun(@(x) x(4),outputs)),[settings.S,xlen]);
SU_RNG_SE = reshape(cell2mat(cellfun(@(x) x(6),outputs)),[settings.S,xlen]);
SU_DMA_SE = reshape(cell2mat(cellfun(@(x) x(14),outputs)),[settings.S,xlen]);
if(settings.PDA)
    SU_PDA_SE = reshape(cell2mat(cellfun(@(x) x(9),outputs)),[settings.S,xlen]);
    SU_PDA_AVG_SE = reshape(cell2mat(cellfun(@(x) x(11),outputs)),[settings.S,xlen]);

end

%% Mean and sum data
%Mean of each xValue
PU_CDA_MEAN = cellfun(@mean,cellfun(@(x) x(1),outputs));
PU_CDA_AVG_MEAN = cellfun(@mean,cellfun(@(x) x(3),outputs));
PU_RNG_MEAN = cellfun(@mean,cellfun(@(x) x(5),outputs));
PU_NOCOOP_MEAN = cellfun(@mean,cellfun(@(x) x(7),outputs));
PU_PDA_MEAN = cellfun(@mean,cellfun(@(x) x(8),outputs));
PU_PDA_AVG_MEAN = cellfun(@mean,cellfun(@(x) x(10),outputs));
PU_DMA_MEAN = cellfun(@mean,cellfun(@(x) x(13),outputs));
SU_CDA_MEAN = mean(SU_CDA_SE);
SU_CDA_AVG_MEAN = mean(SU_CDA_AVG_SE);
SU_RNG_MEAN = mean(SU_RNG_SE);
SU_PDA_MEAN = mean(SU_PDA_SE);
SU_PDA_AVG_MEAN = mean(SU_PDA_AVG_SE);
SU_DMA_MEAN = mean(SU_DMA_SE);

%Sum of each xValue
PU_CDA_SUM = cellfun(@sum,cellfun(@(x) x(1),outputs));
PU_CDA_AVG_SUM = cellfun(@sum,cellfun(@(x) x(3),outputs));
PU_RNG_SUM = cellfun(@sum,cellfun(@(x) x(5),outputs));
PU_NOCOOP_SUM = cellfun(@sum,cellfun(@(x) x(7),outputs));
PU_PDA_SUM = cellfun(@sum,cellfun(@(x) x(8),outputs));
PU_PDA_AVG_SUM = cellfun(@sum,cellfun(@(x) x(10),outputs));
PU_DMA_SUM = cellfun(@sum,cellfun(@(x) x(13),outputs));
PU_CA_SUM = cellfun(@sum,cellfun(@(x) x(12),outputs));
SU_CDA_SUM = sum(SU_CDA_SE);
SU_CDA_AVG_SUM = sum(SU_CDA_AVG_SE);
SU_RNG_SUM = sum(SU_RNG_SE);
SU_PDA_SUM = sum(SU_PDA_SE);
SU_PDA_AVG_SUM = sum(SU_PDA_AVG_SE);
SU_DMA_SUM = sum(SU_DMA_SE);

%% Plotting
shapes = ['o','x','s','d','^','p','h','*'];
%colours = ["#1b9e77";"#d95f02";"#7570b3";"#e7298a";"#66a61e";"#e6ab02";...
%"#a6761d";"#666666"];
%New Colour Scheme
colours = ["#ff0000","#377eb8","#4daf4a","#984ea3","#ff7f00",...
    "#ffff33","#a65628","#f781bf","#999999"];

% %Primary User Average SE
% figure; hold on;
% plot(xPlot,PU_CDA_MEAN,'Marker',shapes(1),'Color',colours(1)); 
% plot(xPlot,PU_CDA_AVG_MEAN,'--','Marker',shapes(1),'Color',colours(2));
% plot(xPlot,PU_RNG_MEAN,'Marker',shapes(2),'Color',"#000000"); 
% plot(xPlot,PU_NOCOOP_MEAN,'Marker',shapes(4),'Color',colours(8));
% plot(xPlot,PU_DMA_MEAN,'Marker',shapes(5),'Color',colours(4));
% if settings.PDA, plot(xPlot,PU_PDA_MEAN,'Marker',shapes(3),'Color',colours(3)),
%     plot(xPlot,PU_PDA_AVG_MEAN,'--','Marker',shapes(3),'Color',colours(5)),
%     %plot(T_pwr,PU_CA_SUM,'Marker',shapes(6),'Color',colours(7)), 
% end
% xlabel('Number of PUs (P)');ylabel('Average Spectral Efficiency (bits/s/Hz)');
% title('Average Spectral Efficiency of all Primary Users');
% legend('CDA with CSI','CDA without CSI','Random C-NOMA','Direct transmission'...
%     ,'DMA with CSI','PDA with CSI','PDA without CSI','location','northwest');
% h = get(gca,'Children');
% set(gca,'Children',[h(4),h(5),h(6),h(1),h(3),h(7),h(2)]);
% ylim([0 inf]);
% saveas(gcf,strcat(PUSUM_name,'.png'));
% saveas(gcf,strcat(PUSUM_name,'.fig'));
% figure; hold on;
% for u = 1:S
%     plot(xPlot,SU_CDA_SE(u,:),'Marker',shapes(u),'Color',colours(u));
%     plot(xPlot,SU_CDA_AVG_SE(u,:),'--','Marker',shapes(u),'Color',colours(u));
%     %plot(T_pwr,SU_RNG_SE(u,:),':','Marker',shapes(u),'Color',colours(u));
%     if settings.PDA, plot(xPlot,SU_PDA_SE(u,:),'-.','Marker',shapes(u),'Color',colours(u));...
%     plot(xPlot,SU_PDA_AVG_SE(u,:),' ','Marker',shapes(u),'Color',colours(u));end
%     labels{(4*u)-3} = strcat('SU_{PDA-No CSI-',num2str(u),'}');
%     labels{(4*u)-2} = strcat('SU_{PDA-CSI-',num2str(u),'}');
%     labels{(4*u)-1} = strcat('SU_{CDA-CSI-',num2str(u),'}');
%     labels{(4*u)} = strcat('SU_{CDA-No CSI-',num2str(u),'}');
%     %labels{5*u} = strcat('SU_{RNG-',num2str(u),'}');
% end
% xlabel('Number of PUs (P)');ylabel('Spectral Efficiency (bits/s/Hz)');
% title('Spectral Efficiency of all Secondary Users');  ylim([0 inf]);
% legend(labels,'NumColumns',1,'location','bestoutside');
% saveas(gcf,SUSE_png);

%Primary User Sum Spectral Efficiency
figure; hold on;
plot(xPlot,PU_CA_SUM,'Marker',shapes(6),'Color',colours(7)); 
plot(xPlot,PU_PDA_SUM,'Marker',shapes(3),'Color',colours(3));
plot(xPlot,PU_CDA_SUM,'Marker',shapes(1),'Color',colours(1)); 
plot(xPlot,PU_DMA_SUM,'Marker',shapes(5),'Color',colours(4));
plot(xPlot,PU_PDA_AVG_SUM,'--','Marker',shapes(3),'Color',colours(5));
plot(xPlot,PU_CDA_AVG_SUM,'--','Marker',shapes(1),'Color',colours(2));
plot(xPlot,PU_NOCOOP_SUM,'Marker',shapes(4),'Color',colours(8));
plot(xPlot,PU_RNG_SUM,'Marker',shapes(2),'Color',"#000000"); 
xlabel('Number of PUs (P)');ylabel('Sum Spectral Efficiency (bits/s/Hz)');
title('Sum Spectral Efficiency of all Primary Users');
legend('CA','PDA with CSI','CDA with CSI','DMA with CSI','PDA without CSI',...
    'CDA without CSI','Direct transmission','Random C-NOMA','location','northwest');
ylim([0 inf]);
%saveas(gcf,strcat(PUSUM_name,'.png'));
%saveas(gcf,strcat(PUSUM_name,'.fig'));

%Secondary User Average Spectral Efficiency
%Secondary User Sum Spectral Efficiency
figure; hold on;
plot(xPlot,SU_PDA_SUM,'Marker',shapes(6),'Color',colours(7));
plot(xPlot,SU_PDA_SUM,'Marker',shapes(3),'Color',colours(3));
plot(xPlot,SU_CDA_SUM,'Marker',shapes(1),'Color',colours(1));
plot(xPlot,SU_DMA_SUM,'Marker',shapes(4),'Color',colours(4));
plot(xPlot,SU_PDA_AVG_SUM,'--','Marker',shapes(3),'Color',colours(5));
plot(xPlot,SU_CDA_AVG_SUM,'--','Marker',shapes(1),'Color',colours(2));
plot(xPlot,SU_RNG_SUM,'Marker',shapes(2),'Color',"#000000");
xlabel('Number of PUs (P)');ylabel('Sum Spectral Efficiency (bits/s/Hz)');
title('Sum Spectral Efficiency of all Secondary Users');
legend('CA','PDA with CSI','CDA with CSI','DMA with CSI','PDA without CSI',...
    'CDA without CSI','Random C-NOMA','location','east');
ylim([0 inf]);
saveas(gcf,strcat(SUSUM_name,'.png'));
saveas(gcf,strcat(SUSUM_name,'.fig'));
