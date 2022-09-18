function [u1,u2] = C_NOMA(g1,g2,g3,b1,p)
    beta = b1; alpha=1-beta;
    
    %CNOMA Simulation
    u1 = log2(1+(p.pb*alpha.*g1)/p.no);
    if(~p.dr) %Direct path
        u2_d = 0;
    else
        u2_d = (p.dr/2)*log2(1+(p.pb*beta.*g2)./(p.pb*alpha.*g2+p.no));
    end
    u1_x2 = log2(1+(p.pb*beta.*g1)./(p.pb*alpha.*g1+p.no));
    u2_r = log2(1+(p.pb.*g3./p.no));
    u2 = 0.5*min(u1_x2,u2_d+u2_r);
end