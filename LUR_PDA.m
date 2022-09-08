function [PU_rate,SU_rate,pairings] = LUR_PDA(PU_set,SU_set,PU_coop,SU_coop,s,p)
%Simulates PDA for all cooperating users in the network.

%% Output variables
P = s.P;
S = s.S;
PU_rate = zeros(1,P); %Final rates of each PU
SU_rate = zeros(1,S); %Final rates of each SU


%% Initialise rounds for PDA
if(any(PU_coop) && any(SU_coop))
    rounds = size(PU_coop,1); %Round count equal to number of PUs cooperating
    max_pairings = min(size(PU_coop,1),size(SU_coop,2)); %Are there more PUs or SUs cooperating
else
    rounds = 1; %i.e. no cooperating so no need to do rounds
    max_pairings = 0;
    PU_coop = 1;
end
pairings = zeros(P,rounds); %Round by round pairings
%Needed to reset pairings for rounds
SU_reset = num2cell(zeros(1,S));
PU_reset = num2cell(zeros(1,P));

%% Main PDA code
for r = 1:rounds
    %Perform PDA pairing
    for pu = 1:max_pairings
        pair=false;
        count=1;
        PU = PU_coop(pu);

        while(pair==false)
            SU = PU_set(PU).Pref_list(count);
            if(SU==0) %No avaliable SU meets the PU's needs
                PU_set(PU).Pairing = 0;
                break
            else
                if(SU_set(SU).Pairing == 0) %No PU paired with this SU
                    SU_set(SU).Pairing = PU_set(PU).Number;
                    PU_set(PU).Pairing = SU_set(SU).Number;
                    PU_set(PU).Power = SU_set(SU).Budget(PU^s.fb);
                    break
                else
                    %SU already has a relay buddy
                    count = count+1;
                end
            end
        end
            
    end
         
        %% Run Performance for round
%     PU_round = zeros(P,1);
%     SU_round = zeros(S,1);
   for pu = 1:P
        PU = PU_set(pu);
        if(PU.Pairing==0) %No cooperation
            PU_round = PU.Current_rate;
        else
            SU = SU_set(PU.Pairing);
            [SU_round,PU_round] = C_NOMA(SU.Channel(pu^s.fb),PU.Channel,...
                PU.Relay_gains(PU.Pairing),PU.Power,p);
            pairings(pu,r) = PU.Pairing;
            SU_rate(SU.Number) = SU_rate(SU.Number) + SU_round;
        end
        PU_rate(pu) = PU_rate(pu) + PU_round;
    end
        %Update order of PUs for PDA fairness
    PU_coop=[PU_coop(end); PU_coop];
    PU_coop(end) =[];
    %Reset pairs for next round
    [PU_set.Pairing] = PU_reset{:};
    [SU_set.Pairing] = SU_reset{:};
    
end

%Divide rates by number of rounds for timeslots accounting.
PU_rate = PU_rate/rounds;
SU_rate = SU_rate/rounds;
end