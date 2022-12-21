%%% File for just plotting the data
%% Load Data
filename = "Results\PaperWorthResults\Results\tpwr_Wdirect_6P3S_\LUR_Wdirect_CDA&PDA_6P3S.mat"; %Change this to datafile, must include path
load(filename);
T_pwr = 15:25;
xPlot = 15:25;
xlen = length(xPlot);
%% Output manipulation
PU_CDA_SE = reshape(cell2mat(cellfun(@(x) x(1),outputs)),[settings.P,xlen]);
SU_CDA_SE = reshape(cell2mat(cellfun(@(x) x(2),outputs)),[settings.S,xlen]);
PU_CDA_AVG_SE = reshape(cell2mat(cellfun(@(x) x(3),outputs)),[settings.P,xlen]);
SU_CDA_AVG_SE = reshape(cell2mat(cellfun(@(x) x(4),outputs)),[settings.S,xlen]);
PU_RNG_SE = reshape(cell2mat(cellfun(@(x) x(5),outputs)),[settings.P,xlen]);
SU_RNG_SE = reshape(cell2mat(cellfun(@(x) x(6),outputs)),[settings.S,xlen]);
PU_NONOMA_SE = reshape(cell2mat(cellfun(@(x) x(7),outputs)),[settings.P,xlen]);
games = "CDA_";
if(settings.PDA)
    PU_PDA_SE = reshape(cell2mat(cellfun(@(x) x(8),outputs)),[settings.P,xlen]); 
    SU_PDA_SE = reshape(cell2mat(cellfun(@(x) x(9),outputs)),[settings.S,xlen]);
    PU_PDA_AVG_SE = reshape(cell2mat(cellfun(@(x) x(10),outputs)),[settings.P,xlen]);
    SU_PDA_AVG_SE = reshape(cell2mat(cellfun(@(x) x(11),outputs)), [settings.S,xlen]);
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

folderName = "JustPlot_" + int2str(settings.P) + "P" + int2str(settings.S) + "S_";

mkdir("Results/"+folderName);


%save_name = "LUR_" + s_dir + games + int2str(settings.P) + "P" + int2str(settings.S) + "S.mat";
%matfile = fullfile("Results",folderName,save_name);
%PUSE_png = fullfile("Results",folderName,games + "PU_SE");
PUSUM_name = fullfile("Results",folderName,games + "PU_SUM_SE");
%SUSE_png = fullfile("Results",folderName,games + "SU_SE");
SUSUM_name = fullfile("Results",folderName,games + "SU_SUM_SE");
%save(matfile,'outputs','settings','pmr','-v7.3');

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
labels = cell(settings.P*2,1);

%All Primary Users' Spectral Efficiency
% if(settings.P<9) %Likely unreadable/useless after a certain number of PUs.
%     figure; hold on;
%     for u = 1:settings.P
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
plot(T_pwr,PU_RNG_SUM,'Marker',shapes(2),'Color',"#000000"); 
plot(T_pwr,PU_NOCOOP_SUM,'Marker',shapes(4),'Color',colours(8));
if settings.PDA, plot(T_pwr,PU_PDA_SUM,'Marker',shapes(3),'Color',colours(3)),
    plot(T_pwr,PU_PDA_AVG_SUM,'--','Marker',shapes(3),'Color',colours(5)),
    %plot(T_pwr,PU_CA_SUM,'Marker',shapes(6),'Color',colours(7)), 
end
xlabel('Transmit Power (dB)');ylabel('Sum Spectral Efficiency (bits/s/Hz)');
title('Sum Spectral Efficiency of all Primary Users');
legend('CDA with CSI','CDA without CSI','Random C-NOMA','Direct transmission','PDA with CSI','PDA without CSI',...
    'location','best');
a = gca;
a.XTickMode = 'manual';
a.XTick = T_pwr;
h = get(gca,'Children');

set(gca,'Children',[h(4),h(3),h(5),h(1),h(6),h(2)]);
ylim([0 inf]);
saveas(gcf,strcat(PUSUM_name,'.png'));
saveas(gcf,strcat(PUSUM_name,'.fig'));

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
plot(T_pwr,SU_RNG_SUM,'Marker',shapes(2),'Color',"#000000");
if settings.PDA, plot(T_pwr,SU_PDA_SUM,'Marker',shapes(3),'Color',colours(3)); 
    plot(T_pwr,SU_PDA_AVG_SUM,'--','Marker',shapes(3),'Color',colours(5)); end
xlabel('Transmit Power (dB)');ylabel('Sum Spectral Efficiency (bits/s/Hz)');
title('Sum Spectral Efficiency of all Secondary Users');
legend('CDA with CSI','CDA without CSI','Random C-NOMA','PDA with CSI','PDA without CSI',...
    'location','best');
h = get(gca,'Children');
set(gca,'Children',[h(3),h(4),h(1),h(5),h(2)]);
ylim([0 inf]);
saveas(gcf,strcat(SUSUM_name,'.png'));
saveas(gcf,strcat(SUSUM_name,'.fig'));