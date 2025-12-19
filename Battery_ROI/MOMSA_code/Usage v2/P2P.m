function [ TNB_revenue_CES, cost_CES, C_aging_total] = P2P(L)
    % global errtol busnum basemva basevoltage busga linedat

    L(3) = L(1) * L(3); % P2P charge price
    L(4) = L(2) * L(4); % P2P discharge price 
    L(5) = L(1) * L(5); % Close charge price
    L(6) = L(2) * L(6); % Close discharge price
    L(1) = L(1); % Base CES charge price
    L(2) = L(2); % Base CES discharge price
    input = L / 0.57;
    
    % Convert inputArray to a string with space-separated values
    inputString = sprintf('%d ', input);


    % Define the full path to the executable file
    exePath = '"C:\Users\PC\source\repos\p2p_optimal placement\x64\Release\p2p_optimal placement.exe"';

    % Call the executable file with appropriate command-line arguments
    command = [exePath ' ' inputString];
    % disp(command)
    status = system(command);

    % Check the status of the system call
    if status == 0
        disp('Execution successful.');
    else
        disp('Execution failed.');
    end

    disp(input);

    % Read the result
    infeasible = str2double(fileread('infeasible.txt'));
    cost_saving_constraint = 0;

    if infeasible == 0 && status == 0
        solar = csvread("Solar.csv") / 1000;
        load = csvread("PowerConsumption.csv");
        CES = csvread("NetLoadCES.csv");
        profit = csvread("TNBProfit.csv");
        cost = csvread("ProsumerCost.csv");
        bat_level = csvread("Battery_Level_CES.csv");
        user_q = csvread("Charge_Discharge.csv");

        bat_level = bat_level(:, 1:2)';
        bat_level(1,:) = bat_level(1,:) / 283.52;
        bat_level(2,:) = bat_level(2,:) / 275.64;
        user_q = user_q(:, 1:32);
        load = [load(:, end) load(:, 1:end - 1)]' / 1000;
        CES = [CES(:, end) CES(:, 1:end - 1)]' / 1000;
        loc_CES = [19 33];

        % Rainflow cycle counting for each CES
        rf1 = rainflow(bat_level(1, :), 48);
        rf2 = rainflow(bat_level(2, :), 48);
        DODs1 = rf1(:, 2); % depth of discharge fractions (0–1)
        counts1 = rf1(:, 1); % 0.5 = half cycle,
        DODs2 = rf2(:, 2); % depth of discharge fractions (0–1)
        counts2 = rf2(:, 1); % 0.5 = half cycle,
        % EFCs = sum(DODs1 .* counts1) + sum(DODs2 .* counts2);

        % Aging cost
        % Based on datasheet, cycle life = 6000 cycles at (assumed) 80% DOD
        N_100_fail = 4300;
        kp = 1.5;
        eta_c = 0.9;
        eta_d = 0.9;

        % Battery 1
        C_aging1 = sum((DODs1.^kp * 1000 * 283.52) ./ (N_100_fail * eta_c * eta_d) .* counts1);

        % Battery 2
        C_aging2 = sum((DODs2.^kp * 1000 * 275.64) ./ (N_100_fail * eta_c * eta_d) .* counts2);

        C_aging_total = C_aging1 + C_aging2;

        % TNB revenue from CES services == CES cost for prosumer
        cost_c = L(1);
        cost_d = L(2);
        cost_c_p2p = L(3);
        cost_d_p2p = L(4);
        cost_c_close = L(5);
        cost_d_close = L(6);
        TNB_revenue_CES = 0;

        cost_c_t = zeros(48,1);
        cost_d_t = zeros(48,1);

        cost_c_t(1:16)   = cost_c;
        cost_d_t(1:16)   = cost_d;

        cost_c_t(17:37)  = cost_c_p2p;
        cost_d_t(17:37)  = cost_d_p2p;

        cost_c_t(38:48)  = cost_c_close;
        cost_d_t(38:48)  = cost_d_close;

        for u = 1:32
            prosumer_CES_cost(u) = 0;

            for t = 1:48
                q = user_q(t,u);

                if q > 0
                    cost = cost_c_t(t) * q;
                elseif q < 0
                    cost = cost_d_t(t) * abs(q);
                else
                    cost = 0;
                end

                TNB_revenue_CES         = TNB_revenue_CES + cost;
                prosumer_CES_cost(u)    = prosumer_CES_cost(u) + cost;
            end
        end


        % Add the CES cost to the total cost for each prosumer
        cost_CES = cost + prosumer_CES_cost';

        % Power flow analysis
        % for t = 1:48
        %     % disp(t)
        %     data33_ga(1);
            
        %     buscs1 = busga;
        %     % buscs1(:,7)=busga(:,7).*load(:,t);
        %     % buscs1(:,8)=busga(:,8).*load(:,t);
        %     % buscs1(:,7)=busga(:,7).*load(:,t);
        %     buscs1(:, 8) = busga(:, 8) .* 0;
        %     buscs1(:, 7) = load(:, t);
        %     buscs1(24:end, 5) = 1.5 * solar(t);
        %     buscs1(19, 5) = 16.5 * solar(t) * 1.5;
        %     buscs1(19, 7) = 20 * load(19, t);

        %     for n = 1:nbCES
        %         % CES Prosumer
        %         if CES(loc_CES(n), t) > 0 % charging
        %             buscs1(loc_CES(n), 7) = buscs1(loc_CES(n), 7) + CES(loc_CES(n), t);
        %         elseif CES(loc_CES(n), t) < 0 % discharging
        %             buscs1(loc_CES(n), 5) = buscs1(loc_CES(n), 5) - CES(loc_CES(n), t);
        %         end

        %         % % CES TNB
        %         % if CES(loc_CES(n)-1,t) > 0 % charging
        %         %     buscs1(loc_CES(n)-1,7) = buscs1(loc_CES(n)-1,7)+CES(loc_CES(n)-1,t);
        %         % elseif CES(loc_CES(n)-1,t) < 0 % discharging
        %         %     buscs1(loc_CES(n)-1,5) = buscs1(loc_CES(n)-1,5)-CES(loc_CES(n)-1,t);
        %         % end
        %     end

        %     [result] = gaLFThukaram(errtol, busnum, basemva, basevoltage, buscs1, linedat);
        %     % [minV, minVno]=min(result.Vm);
        %     % [maxV, maxVno]=max(result.Vm);
        %     ploss(t) = sum(real(result.Lineloss));
        %     vpii(t) = sum((result.Vm - 1) .^ 2);
        % end

        % % ploss = normalize(ploss,'range');
        % % fit = 0.7*sum(ploss)+0.3*sum(vpii);
        % fit = sum(ploss);
        % % disp(sum(ploss))

        % Price range feasibility checking
        %%%% Prosumer cost using CES should minimally be less than the normal (cost(P2P_CES) ≤ cost (P2P) %%%%
        %%%% If not, it means the CES is not economical and should be penalized %%%%
        costN = csvread("Benchmark\p2p_noCES\ProsumerCost_normal tariff.csv");
        costP2P = csvread("Benchmark\p2p_noCES\ProsumerCost.csv");

        if  mean(cost_CES) > mean(costP2P) % meaning with using CES is more expensive
            cost_saving_constraint = 1;
            infeasible = 1;
        end
    end

    if infeasible == 1 || status == 1
        C_aging_total = 1000000;
        TNB_revenue_CES = 0;
        cost_CES = 1000000;
    end
 
    if cost_saving_constraint == 1
        cost_CES = 50000;
    end

    disp(TNB_revenue_CES)
end
