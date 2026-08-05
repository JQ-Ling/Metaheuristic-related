function output = runP2P(POS,M)
    for i = 1:size(POS,1)
        L = POS(i,:);
        [fit, TNB_revenue_CES, cost, EFC] = P2P(L);
        TNB_revenue_CESs(i) = -TNB_revenue_CES;
        EFCs(i) = EFC;
        costP(i) = mean(cost);
    end
    output = [TNB_revenue_CESs', EFCs', costP'];
end