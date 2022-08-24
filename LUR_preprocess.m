function [PU_set,SU_set,PU_coop,SU_coop] = LUR_preprocess(PU_set,SU_set,s,p)
    %Runs the preprocessing needed for either CDA or PDA.
    %   This function determines the budgets and possible pairings of all users
    %   present in the network. This would likely take place at the Base
    %   Station.
    
    
    %% Creating targets and budgets
    P = s.P;
    S = s.S;
    %a1_star should be a (SxP) matrix
    a1_star = (p.e1*p.no)./(p.pb.*cell2mat({SU_set.Channel}.'));
    %Remove any values over 1 as 1 is the maximum allocation
    a1_star(a1_star>1) = 1;
    %Direct transmission from BS to PU
    if(p.dr)
        PUrate_nonoma = log2(1+(p.pb.*cell2mat({PU_set.Channel}))./p.no);
    else
        PUrate_nonoma = zeros(1,P);
    end
    PU_nonoma = num2cell(PUrate_nonoma); [PU_set.Current_rate]=PU_nonoma{:};
    SU_budget = num2cell(1-a1_star,2); [SU_set.Budget]=SU_budget{:};
    %% Generate preference lists
    [user_list,PU_budget,PU_maxrate,SU_maxrate] = support_check(PU_set,SU_set,s,p);
    PU_b = num2cell(PU_budget,2); [PU_set.Budget]=PU_b{:};
    SU_m = num2cell(SU_maxrate,2); [SU_set.Maxrates] = SU_m{:};
    
    %Preference lists are order based on the users that can provide them
    %the greatest throughput
    [~,PU_preflist] = sort(PU_maxrate,2,'descend');
    [~,SU_preflist] = sort(SU_maxrate,2,'descend');
    
%     for pu = 1:P %%wtf does this do now
%         user_list(pu,:) = user_list(pu,PU_preflist(pu,:));
%     end
    %Removes any SUs from PUpref that would not match (i.e. the SU could
    %not be supported)
    PU_preflist = PU_preflist .* user_list;
    PU_prefs = num2cell(PU_preflist,2); [PU_set.Pref_list]=PU_prefs{:};
    SU_prefs = num2cell(SU_preflist,2); [SU_set.Pref_list]=SU_prefs{:};
    %% Determine players of games
    
    %Find cooperators based on user_list, where a row refers to a PU and
    %col refers to a SU. Remove any empty non-players too.
    PU_coop = any(user_list,2) .* [1:P].';
    SU_coop = any(user_list) .* [1:S];
    PU_coop(PU_coop==0) = [];
    SU_coop(SU_coop==0) = [];
    
    %Attempt to remove bias by re-ordering PUs for LUR CDA
    if(size(PU_coop,1)>1)
        PU_coop = PU_coop(randperm(size(PU_coop,1)));
    end
end

function [user_list,PU_budget,PU_maxrate,SU_maxrate] = support_check(PU_set,SU_set,s,p)
%% Generate possible pairings
% user_list(PxS) containing whether a PU-SU pairing is possible
% PU_budget(PxS) contains the max power allocation for a given SU
% PU_maxrate(PxS) is maximum rate for PU in SU-PU pairing, 0 if < PU.C_rate
% SU_maxrate(SxP) is maximum rate for SU in SU-PU pairing, 0 if
% user_list(pu,su)==0
    P = s.P;
    S = s.S;
    a_list = 0.8:0.0001:0.9999;
    PU_budget = zeros(P,S);
    user_list = zeros(P,S);
    PU_maxrate = zeros(P,S);
    SU_maxrate = zeros(S,P);
    for pu = 1:P
        PU = PU_set(pu);
        for su = 1:S
            SU = SU_set(su);
            %First check the maximum rate using the budget determined from
            %a1_star
            [~,PU_maxrate(pu,su)] = C_NOMA(SU.Channel(pu^s.fb),...
                PU.Channel,PU.Relay_gains(su),...
                SU.Budget(pu^s.fb),p);
            %If direct > coop then continue to next PU
            if(PU_maxrate(pu,su)<PU.Current_rate)
                PU_maxrate(pu,su) = 0;
                continue
            end
            for a = 1:length(a_list)
                %Find the threshold for giving a greater power
                [SU_rate,PUrate_withrelay] = C_NOMA(SU.Channel(pu^s.fb)...
                    ,PU.Channel,PU.Relay_gains(su),...
                    a_list(a),p);
                [~,ii] = max([PU.Current_rate,PUrate_withrelay]); 
                if (ii==2) %This means that the relay outperforms the direct
                   break
                end
            end
            %PU_budget is simply the inverse of the threshold found.
            PU_budget(pu,su) = 1-a_list(a);
            %User list is checked to make sure SU is happy to coop with
            %that power value
            user_list(pu,su) = a_list(a)<SU.Budget(pu^s.fb);
            %Given the channel stays the same, this is the max as power
            %will only get smaller than PU_budget.
            SU_maxrate(su,pu) = SU_rate;
        end
    end


end