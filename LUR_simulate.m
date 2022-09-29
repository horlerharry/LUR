function outputs = LUR_simulate(tb,s,p)
%Main body for simulating the LUR system
%   Here is the main file for housing all the work to simulate LUR.
%   The structure of this code allows for additional systems to be tested
%   alongside the CDA and PDA solutions for scaleability. 
% 
% 
    %TODO: Fix output sizes, need a better method to store final results if
    %P and S are to change.

    %This is the dependent value in the system, for now we are only
    %supporting one changing value, but more could be investigated.
    if(strcmp(s.xValue,'power'))
        p.pb = 10^(p.T_pwr(tb)/10);
    elseif(strcmp(s.xValue,'maxP'))
        s.P = p.P_values(tb);
    elseif(strcmp(s.xValue,'maxS'))
        s.S = p.S_values(tb);
    end

    
    P = s.P;S = s.S;U = s.U;N = s.N;
    outputs = cell(1,s.Olen);
    %Different named output variables for simplicity
    PU_CDA_SE = zeros(1,P); SU_CDA_SE = zeros(1,S);
    PU_PDA_SE = zeros(1,P); SU_PDA_SE = zeros(1,S);
    PU_CDA_AVG_SE = zeros(1,P); SU_CDA_AVG_SE = zeros(1,S);
    PU_PDA_AVG_SE = zeros(1,P); SU_PDA_AVG_SE = zeros(1,S);
    PU_RNG_SE = zeros(1,P); SU_RNG_SE = zeros(1,S);
    PU_NOCOOP_SE = zeros(1,P);
    PU_direct = zeros(1,P); PU_CA_SE = 0;
    %% Main loop
    for u = 1:U
        %Generate users and channels
        [PU_set,SU_set] = user_gen(s);
        secondary_c = abs((randn(S,N*P)+1i*randn(S,N*P))/sqrt(2)).^2;
        SU_channels = reshape(secondary_c,[S,P,N]);
        PU_channels = abs((randn(N,P)+1i*randn(N,P))/sqrt(2)).^2;
        relay_channels = abs((randn(P,N*S)+1i*randn(P,S*N))/sqrt(2)).^2;
        SU_PU_channels = reshape(relay_channels,[P,S,N]);
        
        SU_channels = SU_channels .* cell2mat({SU_set.Path_loss}).';
        PU_channels = PU_channels .* cell2mat({PU_set.Path_loss});
        SU_PU_channels = SU_PU_channels .* reshape(cell2mat({PU_set.Relay_PL}),[S,P]).';
        for n = 1:N
            %Channel assignment
            h_SU = num2cell(SU_channels(:,:,n),2); 
            h_PU = num2cell(PU_channels(n,:)); 
            h_Relay = num2cell(SU_PU_channels(:,:,n),2);
            [PU_set.Channel] = h_PU{:}; [SU_set.Channel] = h_SU{:};
            [PU_set.Relay_gains] = h_Relay{:};
            
            %LUR preprocessing for game operation
            [PU_set,SU_set,PU_coop,SU_coop] = LUR_preprocess(PU_set,SU_set,s,p);
            
            [CDA_PUrate,CDA_SUrate,~] = LUR_CDA(PU_set,SU_set,PU_coop,SU_coop,s,p);
            PU_CDA_SE = PU_CDA_SE + CDA_PUrate;
            SU_CDA_SE = SU_CDA_SE + CDA_SUrate;
            if(s.PDA)
                [PDA_PUrate,PDA_SUrate,~,PU_CArate] = LUR_PDA(PU_set,SU_set,PU_coop,SU_coop,s,p);
                PU_PDA_SE = PU_PDA_SE + PDA_PUrate;
                SU_PDA_SE = SU_PDA_SE + PDA_SUrate;
                PU_CA_SE = PU_CA_SE + PU_CArate;
            end
        end
        %Reset channels to Path loss
        [PU_set.Channel] = PU_set.Path_loss;
        [SU_set.Channel] = SU_set.Path_loss;
        [PU_set.Relay_gains] = PU_set.Relay_PL;
        s.fb = 0;
        rounds = 0;
        
        if(p.dr~=0) %Direct transmission from BS to PU
            PU_direct = (p.dr/2)*mean(log2(1+(p.pb.*PU_channels)/p.no));
            PU_NOCOOP_SE = PU_NOCOOP_SE + PU_direct;
        end

        %Run LUR for just path loss
        [PU_set,SU_set,PU_coop,SU_coop] = LUR_preprocess(PU_set,SU_set,s,p);
        [~,~,CDA_pairs] = LUR_CDA(PU_set,SU_set,PU_coop,SU_coop,s,p);
        if(s.PDA)
            [~,~,PDA_pairs] = LUR_PDA(PU_set,SU_set,PU_coop,SU_coop,s,p);
            rounds = size(PDA_pairs,2);
        end
        PU_CDA_AVG = zeros(1,P); SU_CDA_AVG = zeros(1,S);
        PU_PDA_AVG = zeros(1,P); SU_PDA_AVG = zeros(1,S);
        PU_RNG = zeros(1,P); SU_RNG= zeros(1,S);
        for pu = 1:P
            %CDA NO CSI
            cda_su = find(CDA_pairs(pu,:));
            pda_su = PDA_pairs(pu,:);
            power = CDA_pairs(pu,cda_su);        

          
            if(isempty(power))
                %i.e. No cooperation
                PU_CDA_AVG(pu) = PU_direct(pu);
            else
                cda_relay = reshape(SU_PU_channels(pu,cda_su,:),N,1);
                cda_SU_ch = reshape(SU_channels(cda_su,pu,:),N,1);
                [CDA_SU,CDA_PU] = C_NOMA(cda_SU_ch,...
                    PU_channels(:,pu),cda_relay,power,p);
                SU_CDA_AVG(cda_su) = mean(CDA_SU);
                PU_CDA_AVG(pu) = mean(CDA_PU);
            end
            %Random C-NOMA transmission
            if(pu<=S) %For uneven situations.
                rng_relay = reshape(SU_PU_channels(pu,pu,:),N,1);
                rng_second = reshape(SU_channels(pu,pu,:),N,1);
                [RNG_SU,RNG_PU] = C_NOMA(rng_second,PU_channels(:,pu)...
                    ,rng_relay,s.beta,p);
                SU_RNG(pu) = mean(RNG_SU);
                PU_RNG(pu) = mean(RNG_PU);
            end
              %PDA NO CSI
            for r = 1:rounds
                SU = pda_su(r); %Pick the SU for round R
                if(SU==0) %If the PU had no pairing
                    PU_PDA_AVG(pu) = PU_PDA_AVG(pu) + PU_direct(pu);
                else %PU paired with an SU
                    pda_relay = reshape(SU_PU_channels(pu,SU,:),N,1);
                    pda_SU = reshape(SU_channels(SU,pu,:),N,1);
                    [PDA_SU,PDA_PU] = C_NOMA(pda_SU,...
                        PU_channels(:,pu),pda_relay,SU_set(SU).Budget(pu^s.fb),p);
                    PU_PDA_AVG(pu) = PU_PDA_AVG(pu) + mean(PDA_PU);
                    SU_PDA_AVG(SU) = SU_PDA_AVG(SU) + mean(PDA_SU);
                end

            end
        end
        
        %Outputs and reset fb setting
        PU_CDA_AVG_SE = PU_CDA_AVG_SE + PU_CDA_AVG;
        SU_CDA_AVG_SE = SU_CDA_AVG_SE + SU_CDA_AVG;
        PU_PDA_AVG_SE = PU_PDA_AVG_SE + PU_PDA_AVG/rounds;
        SU_PDA_AVG_SE = SU_PDA_AVG_SE + SU_PDA_AVG/rounds;
        PU_RNG_SE = PU_RNG_SE + PU_RNG;
        SU_RNG_SE = SU_RNG_SE + SU_RNG;
        s.fb = 1;

    end
    
    %% Data manipulation

    %Output assignment
    outputs{1} = PU_CDA_SE/N;
    outputs{2} = SU_CDA_SE/N;
    outputs{3} = PU_CDA_AVG_SE;
    outputs{4} = SU_CDA_AVG_SE;
    outputs{5} = PU_RNG_SE;
    outputs{6} = SU_RNG_SE;
    outputs{7} = PU_NOCOOP_SE;
    if(s.PDA)
        outputs{8} = PU_PDA_SE/N;
        outputs{9} = SU_PDA_SE/N;
        outputs{10} = PU_PDA_AVG_SE;
        outputs{11} = SU_PDA_AVG_SE;
        outputs{12} = PU_CA_SE/N;
    end

    %Final manipulation
    outputs = cellfun(@(x) x./U, outputs,'UniformOutput',0);
end