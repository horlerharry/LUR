%% New main file that allows for paralle processing for LUR system

clc; clear; close all
%rng(52); %Interesting rng for static scenario
%% Control Variables to be converted into settings.
P = 6; %Number of Primary Users.
S = 6; %Number of Secondary Users.
near_dist=500; %Max distance for Secondary Users
far_dist=3000; %Max distance for Primary Users
PDA_included = true; %Whether to simulate PDA too
SU_target = 1; %Target rate for Secondary Users
bid_step = 1E-4; %Step size for CDA Auction Game
N = 10; %Number of samples per user generation
U = 10; %Number of different user generations per power unit.
rng_beta = 0.8; %Power allocated to RNG C-NOMA
direct = true; %Does the channel between BS and PU exist?
FB = 1; %Are frequency bands considered?
folderName = "transmitPower_" + int2str(P) + "P" + int2str(S) + "S";
settings = struct("P",P,"S",S,"nd",near_dist,"fd",far_dist,...
    "bid_step",bid_step,"N",N,"U",U,"beta",rng_beta,...
    "fb",FB,"PDA",PDA_included,'xValue','power');

%% Parameters for simulations
T_pwr = 15:25;
no = 10^(-114/10);
e1 = (2.^SU_target)-1;
pmr = struct("T_pwr",T_pwr,"pb",0,"no",no,"e1",e1,"dr",direct,'SU_target',SU_target);
%parpool('local');

%% Output Variables
xlen = length(T_pwr);
if(settings.PDA)
    out_len = 9;
else
    out_len = 7;
end
settings.Olen = out_len;
outputs = cell(1,xlen);
disp("Beginning LUR simulation -- Transmit Power");
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
PU_AVG_SE = reshape(cell2mat(cellfun(@(x) x(3),outputs)),[P,xlen]);
SU_AVG_SE = reshape(cell2mat(cellfun(@(x) x(4),outputs)),[S,xlen]);
PU_RNG_SE = reshape(cell2mat(cellfun(@(x) x(5),outputs)),[P,xlen]);
SU_RNG_SE = reshape(cell2mat(cellfun(@(x) x(6),outputs)),[S,xlen]);
PU_NONOMA_SE = reshape(cell2mat(cellfun(@(x) x(7),outputs)),[P,xlen]);
games = "CDA_";
if(settings.PDA)
    PU_PDA_SE = reshape(cell2mat(cellfun(@(x) x(8),outputs)),[P,xlen]); 
    SU_PDA_SE = reshape(cell2mat(cellfun(@(x) x(9),outputs)),[S,xlen]);
    games = "CDA&PDA_";
    PU_PDA_SUM = sum(PU_PDA_SE);
    SU_PDA_SUM = sum(SU_PDA_SE);
end

PU_CDA_SUM = sum(PU_CDA_SE);
PU_AVG_SUM = sum(PU_AVG_SE);
PU_RNG_SUM = sum(PU_RNG_SE);
PU_NOCOOP_SUM = sum(PU_NONOMA_SE);
SU_CDA_SUM = sum(SU_CDA_SE);
SU_AVG_SUM = sum(SU_AVG_SE);
SU_RNG_SUM = sum(SU_RNG_SE);

%% Folder management and data saving
if(~direct)
    s_dir = "nodirect_";
else
    s_dir = "direct_";
end

mkdir(folderName);

save_name = "LUR_" + s_dir + games + int2str(P) + "P" + int2str(S) + "S.mat";
matfile = fullfile(folderName,save_name);
PUSE_png = fullfile(folderName,games + "PU_SE.png");
PUSUM_png = fullfile(folderName,games + "PU_SUM_SE.png");
SUSE_png = fullfile(folderName,games + "SU_SE.png");
SUSUM_png = fullfile(folderName,games + "SU_SUM_SE.png");
% PUSE_data = [PU_CDA_SE;
save(matfile,'PU_CDA_SE','PU_RNG_SUM','PU_CDA_SUM','PU_AVG_SE','PU_AVG_SUM',...
    'SU_CDA_SUM','SU_AVG_SUM','SU_RNG_SUM','PU_NOCOOP_SUM','-v7.3');

%% Plotting
shapes = ['o','x','s','d','^','p','h','*'];
colours = ["#1b9e77";"#d95f02";"#7570b3";"#e7298a";"#66a61e";"#e6ab02";...
"#a6761d";"#666666"];
lgd = cell(P*2,1);
figure; hold on;
for u = 1:P
    plot(T_pwr,PU_CDA_SE(u,:),'Marker',shapes(u),'Color',colours(u));
    plot(T_pwr,PU_AVG_SE(u,:),'--','Marker',shapes(u),'Color',colours(u));
    plot(T_pwr,PU_RNG_SE(u,:),':','Marker',shapes(u),'Color',colours(u));
    if settings.PDA, plot(T_pwr,PU_PDA_SE(u,:),'-.','Marker',shapes(u),'Color',colours(u)); end
    lgd{(4*u)-3} = strcat('PU_{PDA-CSI-',num2str(u),'}');
    lgd{(4*u)-2} = strcat('PU_{CDA-CSI-',num2str(u),'}');
    lgd{(4*u)-1} = strcat('PU_{CDA-No CSI-',num2str(u),'}');
    lgd{4*u} = strcat('PU_{RNG-',num2str(u),'}');
end
xlabel('Transmit Power (dB)');ylabel('Spectral Efficiency (bits/s/Hz)');
title('Spectral Efficiency of all Primary Users'); 
legend(lgd,'NumColumns',1,'location','bestoutside');
saveas(gcf,PUSE_png);

figure; hold on;
plot(T_pwr,PU_CDA_SUM,'Marker',shapes(1)); plot(T_pwr,PU_AVG_SUM,'--','Marker',shapes(2));
plot(T_pwr,PU_RNG_SUM,'Marker',shapes(3)); plot(T_pwr,PU_NOCOOP_SUM,'Marker',shapes(4));
if settings.PDA, plot(T_pwr,PU_PDA_SUM,'Marker',shapes(5)), end
xlabel('Transmit Power (dB)');ylabel('Sum Spectral Efficiency (bits/s/Hz)');
title('Sum Spectral Efficiency of all Primary Users');
legend('CDA with CSI','CDA without CSI','Random C-NOMA','Direct transmission','PDA with CSI',...
    'location','northwest');
saveas(gcf,PUSUM_png);
figure; hold on;
for u = 1:S
    plot(T_pwr,SU_CDA_SE(u,:),'Marker',shapes(u),'Color',colours(u));
    plot(T_pwr,SU_AVG_SE(u,:),'--','Marker',shapes(u),'Color',colours(u));
    plot(T_pwr,SU_RNG_SE(u,:),':','Marker',shapes(u),'Color',colours(u));
    if settings.PDA, plot(T_pwr,PU_PDA_SE(u,:),'-.','Marker',shapes(u),'Color',colours(u)); end
    lgd{(4*u)-3} = strcat('SU_{PDA-CSI-',num2str(u),'}');
    lgd{(4*u)-2} = strcat('SU_{CDA-CSI-',num2str(u),'}');
    lgd{(4*u)-1} = strcat('SU_{CDA-No CSI-',num2str(u),'}');
    lgd{4*u} = strcat('SU_{RNG-',num2str(u),'}');
end
xlabel('Transmit Power (dB)');ylabel('Spectral Efficiency (bits/s/Hz)');
title('Spectral Efficiency of all Secondary Users'); 
legend(lgd,'NumColumns',1,'location','bestoutside');
saveas(gcf,SUSE_png);

figure; hold on;
plot(T_pwr,SU_CDA_SUM,'Marker',shapes(1)); plot(T_pwr,SU_AVG_SUM,'--','Marker',shapes(2));
plot(T_pwr,SU_RNG_SUM,'Marker',shapes(3)); 
if settings.PDA, plot(T_pwr,SU_PDA_SUM,'Marker',shapes(5),'Color','#77AC30');end
xlabel('Transmit Power (dB)');ylabel('Sum Spectral Efficiency (bits/s/Hz)');
title('Sum Spectral Efficiency of all Secondary Users');
legend('CDA with CSI','CDA without CSI','Random C-NOMA','PDA with CSI',...
    'location','northwest');
saveas(gcf,SUSUM_png);
