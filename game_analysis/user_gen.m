function [PU_set,SU_set] = user_gen(settings)
    BS = [0,0]; %Set location of Base Station
    R_min = 200; %Minimum distance of User 1
    plc = 4; %Path loss
    R_1 = settings.nd; %Radius of User 1 locations
    R_2 = settings.fd; %Radius of User 2 locations
    P = settings.P;
    S = settings.S;
    %Pre-allocate variables
    PU_coords = zeros(2,P);
    SU_coords = zeros(2,S);
    relay_gains = zeros(P,S);
    
    %SU Coordinates
    u1_angle = 2*pi*rand(1,S);
    R1 = R_1*((R_1-R_min)/R_1) * sqrt(rand(1,S));
    SU_coords(1,:) = BS(1) + R1 .* cos(u1_angle) + R_min.*cos(u1_angle);
    SU_coords(2,:) = BS(2) + R1 .* sin(u1_angle) + R_min.*sin(u1_angle);

    %PU Coordinates
    u2_angle = 2*pi*rand(1,P);
    R2 = (R_2-R_1).* sqrt(rand(1,P));
    PU_coords(1,:) = BS(1) + R2.* cos(u2_angle)+R_1.*cos(u2_angle);
    PU_coords(2,:) = BS(2) + R2.* sin(u2_angle)+R_1.*sin(u2_angle);
%         A = coords(3,:);
    %User target rates
    SU_target = 3;
    PU_target = 2;
    
    %Path loss due to distance
    gain_su = sqrt((SU_coords(1,:)-0).^2+(SU_coords(2,:)-0).^2).^-plc;
    gain_pu = sqrt((PU_coords(1,:)-0).^2+(PU_coords(2,:)-0).^2).^-plc;
    for pu = 1:P
        relay_gains(pu,:) = sqrt((PU_coords(1,pu)-SU_coords(1,:)).^2 +...
                (PU_coords(2,pu)-SU_coords(2,:)).^2).^-plc;
    end
    
  
    PU_set = struct('Number',num2cell(1:P),'Path_loss',num2cell(gain_pu),...
        'Channel',num2cell(gain_pu),'Pref_list',num2cell(zeros(1,P)),...
            'Budget',num2cell(zeros(1,P)),'Power',num2cell(zeros(1,P)),...
        'Pairing',num2cell(zeros(1,P)),'Current_rate',num2cell(zeros(1,P))...
        ,'Relay_PL',num2cell(zeros(1,P)),'Relay_gains',num2cell(zeros(1,P)));
    
    SU_set = struct('Number',num2cell(1:S)...
        ,'Path_loss',num2cell(gain_su),'Channel',num2cell(gain_su,2),...
        'Pref_list',num2cell(zeros(1,S)),'Power',num2cell(zeros(1,S)),...
        'Budget',num2cell(zeros(1,S)),'Pairing',num2cell(zeros(1,S)),...
        'Current_rate',num2cell(zeros(1,S)),'Maxrates',num2cell(zeros(1,S)));
    
    rg = num2cell(relay_gains,2); 
    [PU_set.Relay_PL] = rg{:};
    
    
    end