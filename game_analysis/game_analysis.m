%% Analyse the decisions of users in both the CDA and PDA game for C-NOMA

clc; clear; close all
rng(52); %Interesting rng for static scenario
%% Control Variables to be converted into settings.
P = 3; %Number of Primary Users.
S = 2; %Number of Secondary Users.
near_dist=500; %Max distance for Secondary Users
far_dist=3000; %Max distance for Primary Users
PDA_included = 1; %Whether to simulate PDA too
SU_target = 1; %Target rate for Secondary Users
bid_step = 1E-4; %Step size for CDA Auction Game
N = 1; %Number of samples per user generation
U = 1; %Number of different user generations per power unit.
rng_beta = 0.8; %Power allocated to RNG C-NOMA
direct = 1; %Does the channel between BS and PU exist?
FB = 1; %Are frequency bands considered?
folderName = "transmitPower_" + int2str(P) + "P" + int2str(S) + "S";
settings = struct("P",P,"S",S,"nd",near_dist,"fd",far_dist,...
    "bid_step",bid_step,"N",N,"U",U,"beta",rng_beta,...
    "fb",FB,"PDA",PDA_included,'xValue','power');

%% Parameters for simulations
T_pwr = 20;
pb = 10^(T_pwr/10);
no = 10^(-114/10);
e1 = (2.^SU_target)-1;
pmr = struct("T_pwr",T_pwr,"pb",pb,"no",no,"e1",e1,"dr",direct,'SU_target',SU_target);
%parpool('local');

%% Output Variables
xlen = 2; 
if(settings.PDA)
    out_len = 11;
else
    out_len = 7;
end
settings.Olen = out_len;
outputs = cell(1,xlen);
disp("Analysis of CDA and PDA Games");
disp("P="+int2str(P)+",S="+int2str(S)+",TP="+int2str(T_pwr)+"dB,direct="+int2str(direct));

%% Main loop

%User and channel gen
[PU_set,SU_set] = user_gen(settings);
h_SU = num2cell(abs((randn(S,P)+1i*randn(S,P))/sqrt(2)).^2 .* cell2mat({SU_set.Path_loss}).',2);
h_PU = num2cell(abs((randn(1,P)+1i*randn(1,P))/sqrt(2)).^2 .* cell2mat({PU_set.Path_loss}));
h_Relay = num2cell(abs((randn(P,S)+1i*randn(P,S))/sqrt(2)).^2 .* reshape(cell2mat({PU_set.Relay_PL}),[S,P]).',2);

 [PU_set.Channel] = h_PU{:}; [SU_set.Channel] = h_SU{:};
 [PU_set.Relay_gains] = h_Relay{:};

[PU_set,SU_set,PU_coop,SU_coop] = LUR_preprocess(PU_set,SU_set,settings,pmr);

[CDA_PUrate,CDA_SUrate,CDA_pairs] = LUR_CDA(PU_set,SU_set,PU_coop,SU_coop,settings,pmr)
[PDA_PUrate,PDA_SUrate,PDA_pairs] = LUR_PDA(PU_set,SU_set,PU_coop,SU_coop,settings,pmr)
   

