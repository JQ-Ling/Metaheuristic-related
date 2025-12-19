function output = runP2P(POS,M)
    for i = 1:size(POS,1)
        L = POS(i,:);
        [TNB_revenue_CES, cost, C_aging_total] = P2P(L);
        TNB_revenue_CESs(i) = -TNB_revenue_CES;
        C_aging_total(i) = C_aging_total;
        costP(i) = mean(cost);
    end
    output = [TNB_revenue_CESs', C_aging_total', costP'];
end