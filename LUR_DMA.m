 function [PU_rate,SU_rate,pairings] = LUR_DMA(PU_set,SU_set,PU_coop,SU_coop,s,p)
   
    P = s.P;
    S = s.S;
    init_alpha = 0.2; %Selected value based on typical NOMA constructs.
    tal = 0.001;
    %Construct init PUlist
    for pu = 1:P
        PU_set(pu).Power = cellfun(@(x) x(pu),{SU_set.Budget});
        PU_set = gen_PUlist(PU_set,SU_set,pu,S,p);
    end
    PU_notmatched = PU_coop;
    CU_notmatched = SU_coop;
    PU_matched = zeros(1,P);
    pu=1; cu=1;
    matching=false;
    while(any(PU_notmatched))
        PU = PU_notmatched(1);
        SU = PU_set(PU).Pref_list(1);
        if(SU==0) %This PU has had enough
            PU_notmatched(PU_notmatched==PU) = [];
            continue
        end
        if(SU_set(SU).Pairing==0) %SU has no matching
            PU_set(PU).Pairing=SU;
            SU_set(SU).Pairing=PU;
            PU_notmatched(PU_notmatched==PU) = [];
            CU_notmatched(CU_notmatched==SU) = [];
            PU_matched(PU) = 1;
            [SU_set(SU).Current_rate,~] = C_NOMA(SU_set(SU).Channel(PU),...
            PU_set(PU).Channel,PU_set(PU).Relay_gains(SU),PU_set(PU).Power(SU),p);
        else %SU has a pair
            [newrate,~] = C_NOMA(SU_set(SU).Channel(PU),...
            PU_set(PU).Channel,PU_set(PU).Relay_gains(SU),PU_set(PU).Power(SU),p);
            if(newrate>SU_set(SU).Current_rate)
                PU_cur = SU_set(SU).Pairing;
                PU_set(PU).Pairing=SU;
                SU_set(SU).Pairing=PU;
                PU_notmatched(PU_notmatched==PU) = [];
                PU_notmatched = [PU_notmatched; PU_cur];
                PU_matched(PU) = 1;
                PU_matched(PU_cur) = 0;
                PU = PU_cur;
            end
            PU_set(PU).Power(SU) = PU_set(PU).Power(SU) - tal;
            PU_set = gen_PUlist(PU_set,SU_set,PU,S,p);
            if(~(any(PU_set(PU).Pref_list)))
                PU_notmatched(PU_notmatched==PU) = [];
            end
        end
    end
    PU_rate = zeros(1,P);
    SU_rate = zeros(1,S);
    pairings = zeros(1,P);
      %disp("DMA Results");
       % disp("PU-SU Pair| R_PU  | R_SU")
        for pu = 1:P
            PU = PU_set(pu);
            if(PU.Pairing==0) %No cooperation
                PU_rate(pu) = PU.Current_rate;
                %disp("PU" + int2str(PU.Number) + " Direct" + ...
                %"| " + num2str(PU.Current_rate,"%.3f") + " | ");
            else %SU-PU pairing utilised
                SU = SU_set(PU.Pairing);
                [SU_rate(SU.Number),PU_rate(pu)] = C_NOMA(SU.Channel(pu),PU.Channel,...
                    PU.Relay_gains(PU.Pairing),PU.Power(PU.Pairing),p);
                pairings(pu,PU.Pairing) = 1;
               %  disp("PU" + int2str(PU.Number) + " -> SU" + int2str(SU.Number)...
               % + "| " + num2str(PU_rate(pu),"%.3f") + " | " + num2str(SU_rate(SU.Number),"%.3f")...
              %  + " | " + num2str(PU.Power(PU.Pairing)));
            end
        end
    end
   
function [PU_set] = gen_PUlist(PU_set,SU_set,pu,S,p)
    for su = 1:S
            [~,PU_set(pu).Maxrates(su)] = C_NOMA(SU_set(su).Channel(pu),...
                PU_set(pu).Channel,PU_set(pu).Relay_gains(su),PU_set(pu).Power(su),p);
             if(PU_set(pu).Maxrates(su)<PU_set(pu).Current_rate)
                PU_set(pu).Maxrates(su) = 0;
            end
    end
     [PU_or,PU_set(pu).Pref_list] = sort(PU_set(pu).Maxrates,'descend');
    PU_set(pu).Pref_list(PU_or==0) = 0;
end