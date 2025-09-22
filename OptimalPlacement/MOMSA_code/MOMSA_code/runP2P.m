function output = runP2P(POS,M)
    for i = 1:size(POS,1)
        L = POS(i,:);
        [fit, profit, cost, sizeCES] = P2P(L);
        ploss(i) = fit;
        investC(i) = sum(sizeCES) * 1000; % use $1M for 1MW 
        costP(i) = mean(cost);
    end
    output = [ploss', investC', costP'];
end