function [PU_rate,SU_rate,pairings] = LUR_CDA(PU_set,SU_set,PU_coop,SU_coop,s,p)
    %%This function completes pairings between the PUs and SUs, until
    %%that can be achieved have been made, including their power allocation.

    P = s.P;
    S = s.S;;
    PU_rate = zeros(1,P);
    SU_rate = zeros(1,S);
    pairings = zeros(P,S);
    while(any(PU_coop) && any(SU_coop))
       % has_change = false;
        PU = PU_coop(1); %Takes the first free PU
        for j = 1:S
            SU=PU_set(PU).Pref_list(j);

            if(SU==0) %No SU can help
                PU_coop(1) = [];
                break
            end
            %This checks to see if SU is open for offers 
            if(~ismember(SU,SU_coop))
                continue
            end
            if(SU_set(SU).Pairing==0) %No matching
                %has_change = true;
                SU_set(SU).Pairing = PU;
                PU_set(PU).Pairing = SU;
                SU_set(SU).Power = 1-SU_set(SU).Budget(PU^s.fb);
                PU_set(PU).Power = 1-SU_set(SU).Power;
                PU_coop(1) = [];
                break
            else %Must run auction game
                if(SU_set(SU).Current_rate >= SU_set(SU).Maxrates(PU))
                    continue %Skip the game if its unwinnable for new choice
                end
                if(s.fb==1) %General case where FB is considered
                    [winner,power,crate]=CDA_FB(PU_set(PU),PU_set(SU_set(SU).Pairing),SU_set(SU),s,p);
                else %Special case where FB is not considered (or not known!!)
                    [winner,power,crate]=CDA_noFB(PU_set(PU),PU_set(SU_set(SU).Pairing),SU_set(SU),s,p);
                end
                %Did the challenger beat the defender?
                if(winner~=SU_set(SU).Pairing)
                    %has_change = true;
                    %Previous match is returned to the pool
                    loser = SU_set(SU).Pairing;
                    PU_set(loser).Pairing = 0;
                    PU_set(loser).Power = 0;
                    PU_coop(end+1) = loser;

                    %New matching is achieved.
                    SU_set(SU).Pairing = PU;
                    PU_set(PU).Pairing = SU;
                    SU_set(SU).Power = power;
                    %Max power function, rounding necessary due to MATLAB's
                    %data precision.
                    if(round(power,4)>=0.2) %Max power
                        SU_coop(SU_coop==SU) = [];
                    end
                    PU_set(PU).Power = 1-power;
                    PU_coop(1) = [];
                    SU_set(SU).Current_rate = crate;
                    break
                end
            end
        end
        if(PU_set(PU).Pairing==0 && SU~=0) %Unable to find suitable match
            PU_coop(1) = [];
        end

    end
    if(s.fb) %Frequency Band
        for pu = 1:P
            PU = PU_set(pu);
            if(PU.Pairing==0) %No cooperation
                PU_rate(pu) = PU.Current_rate;
            else %SU-PU pairing utilised
                SU = SU_set(PU.Pairing);
                [SU_rate(SU.Number),PU_rate(pu)] = C_NOMA(SU.Channel(pu^s.fb),PU.Channel,...
                    PU.Relay_gains(PU.Pairing),PU.Power,p);
                pairings(pu,PU.Pairing) = 1; 
            end
        end
    else %No Frequency Band
        for pu = 1:P
            PU = PU_set(pu);
            if(PU.Pairing~=0) %No cooperation
                pairings(pu,PU.Pairing) = PU.Power;
            end
        end
    end
            
end

function [winner,power,SU_rate] = CDA_noFB(PU1,PU2,SU,s,p)
%AUCTION Simulates an auction between two PUs for a given SU.
PU_players = [PU1;PU2];
PU_count = length(PU_players);
SU_success = zeros(1,PU_count);
bid_amt = SU.Power; %Starting bid is whatever has been offered before
SU_maxrate = zeros(1,PU_count);
max_bet = 1-bid_amt;
bid_step = s.bid_step;
pairing = false;

%Pre-check to see if power has overcapped
if(bid_amt>0.2)
    max_bet(:) = 0.8;
    pairing = true;
end

%Auction Game
   while(pairing~=true) %This could just be an infinite while loop
        bid_amt = bid_amt + bid_step; %Increase bid amount
        temp_a2 = 1-bid_amt;
        %This does two things: 1. Keeps users within useful C-NOMA ranges.
        %2. Stops power from accidently being set to 1 (1-0 = 1).
        if bid_amt > 0.2
            max_bet(:) = 0.8;
            break
        end
        for pu = 1:2
            PU = PU_players(pu);
            %Run R_1, R_2 to fulfil the requirements
            [R1,R2] = C_NOMA(SU.Channel,PU.Channel,...
                    PU.Relay_gains(SU.Number),temp_a2,p);
            if(R2 > PU.Current_rate) %User 2 throughtput
                if(R1>p.SU_target) %User 1 throughput
                    SU_success(pu) = 1; %Yes
                    SU_maxrate(pu) = R1;
                    max_bet(pu) = temp_a2;
                end
            else

                SU_success(pu) = 0; %No
            end
        end
        if(size(find(SU_success))==1) %If one is left or if both tapped out simultaniously.
            break
        end
   end
   [~,PU_winner] = max(max_bet);
   SU_rate = SU_maxrate(PU_winner);
    winner = PU_players(PU_winner).Number;
    power = 1-max_bet(PU_winner);
end

function [winner,power,SU_rate] = CDA_FB(PU1,PU2,SU,s,p)
%AUCTION Simulates an auction between two PUs for a given SU.
PU_players = [PU1;PU2];
PU_count = length(PU_players);
SU_success = zeros(1,PU_count);
bid_amt = SU.Power*ones(1,PU_count); %Starting bid is whatever has been offered before
SU_maxrate = zeros(1,PU_count);
max_bet = 1-bid_amt;
bid_step = s.bid_step;
pairing = false;

%Pre-check to see if power has overcapped
if(bid_amt>0.2)
    max_bet(:) = 0.8;
    pairing = true;
end
%Initalise SU_maxrate 
for pu = 1:2
    PU = PU_players(pu);
   [SU_maxrate(pu),~] = C_NOMA(SU.Channel(PU.Number^s.fb),PU.Channel,...
    PU.Relay_gains(SU.Number),1-bid_amt(pu),p);
end
%Auction Game
   while(pairing~=true)
       for pu = 1:2
           while(max(SU_maxrate)>SU_maxrate(pu))
                bid_amt(pu) = bid_amt(pu) + bid_step; %Increase bid amount
                temp_a2 = 1-bid_amt(pu);
                if bid_amt(pu) > 0.2
%                     SU_maxrate(pu) = 0;
                    pairing=true;
                    break
                end
                [R1,R2] = C_NOMA(SU.Channel(PU.Number^s.fb),PU.Channel,...
                    PU.Relay_gains(SU.Number),temp_a2,p);
                if(R2 > PU.Current_rate) %User 2 throughtput
                    if(R1>p.SU_target) %User 1 throughput
                        %SU_success(pu) = 1; %Yes
                        SU_maxrate(pu) = R1;
                        max_bet(pu) = temp_a2;
                    end
                else

                    %SU_success(pu) = 0; %No
                    pairing=true;
                    break
                end
           end
       end
       if(pairing==true)
           break
       end
       %Break a stalemate if both SU rates are equal
       if(all(SU_maxrate == SU_maxrate(1)))
           bid_amt = bid_amt + bid_step;
           if(any(bid_amt > 0.2))
               break %Escape the endless loop
           end
           for pu = 1:2 %Reset SUmaxrate with new bid amt
                PU = PU_players(pu);
               [SU_maxrate(pu),~] = C_NOMA(SU.Channel(PU.Number^s.fb),PU.Channel,...
                    PU.Relay_gains(SU.Number),1-bid_amt(pu),p);
           end
       end
       %If one PU is left i.e. one has lost
%        if(size(find(SU_success))==1) 
%           break
%        end

   end
   %Bias logic here!!!!!!
   [SU_rate,PU_winner] = max(SU_maxrate);
    winner = PU_players(PU_winner).Number;
    power = 1-max_bet(PU_winner);
    if(power>0.2) %Catch clause incase I missed anything
        error('Power value has overcapped');
    end
end

