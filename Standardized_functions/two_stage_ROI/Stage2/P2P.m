function [TNB_revenue_CES, cost_CES, C_aging_total] = P2P_stage2(L)
% P2P_STAGE2  Stage-2 (price scheme) fitness evaluation via the Julia server.
%
%   Combines the "subs v3" and "Usage v2" P2P.m logic behind one entry point,
%   and talks to main/server_stage2.jl (CO_ROI_stage2.jl) over HTTP instead of
%   calling the C++ p2p.exe. The CES fleet is FIXED on the server at startup,
%   so the particle L now carries the price scheme only.
%
%   SCENARIO = 'subscription'   (33 elements)
%       L(1)     : CES subscription price (monthly, per kWh)
%       L(2:end) : capacity each of the 32 prosumers subscribes to (kWh)
%
%   SCENARIO = 'usage'          (6 elements)
%       L(1) : base CES charge price      L(2) : base CES discharge price
%       L(3) : P2P charge multiplier      L(4) : P2P discharge multiplier
%       L(5) : Close charge multiplier    L(6) : Close discharge multiplier
%
%   Set the scenario with:  global SCENARIO; SCENARIO = 'usage';
%   If SCENARIO is empty it is inferred from numel(L).

    global PORT_NUM SCENARIO

    % =================================================================
    % CONFIG - must match the fleet pinned on the Julia server at startup
    % =================================================================
    CES_TOTAL_CAP = 283.52 + 275.64;    % kWh, subscription cap check (pre-solve)
    ENABLE_COST_SAVING_CHECK = true;    % Usage v2 had this ON, subs v3 had it OFF

    % 1. Resolve the scenario
    if isempty(SCENARIO)
        if numel(L) == 6
            scenario = 'usage';
        else
            scenario = 'subscription';
        end
    else
        scenario = lower(char(SCENARIO));
    end

    CES_capacity_boundary  = 0;
    cost_saving_constraint = 0;

    % 2. Build the request body for the scenario
    switch scenario
        case 'subscription'
            % subs v3: subscription price -> priority based
            priority        = 1 - L(1) / 10;
            CES_subsc_price = L(1) / 30;        % per kWh per day
            CES_subsc       = sum(L(2:end));

            if CES_subsc > CES_TOTAL_CAP
                % Subscribed more capacity than the fleet holds - skip the solve
                CES_capacity_boundary = 1;
            end

            data_to_send = struct( ...
                'scenario', 'subscription', ...
                'priority', double(priority), ...
                'sub_caps', double(L(2:end)') ...
            );

        case 'usage'
            % Usage v2: multipliers -> absolute period prices
            L(3) = L(1) * L(3);     % P2P charge price
            L(4) = L(2) * L(4);     % P2P discharge price
            L(5) = L(1) * L(5);     % Close charge price
            L(6) = L(2) * L(6);     % Close discharge price
            % L(1), L(2) stay as the base CES charge / discharge price

            % The optimiser takes the normalised priority, the revenue section
            % below keeps using the real prices in L - same split as Usage v2.
            cost_array = double(L(1:6)) / 0.5443;

            data_to_send = struct( ...
                'scenario', 'usage', ...
                'cost_array', cost_array(:)' ...
            );

        otherwise
            error('P2P_stage2:BadScenario', ...
                  'Unknown SCENARIO "%s" - expected "subscription" or "usage".', scenario);
    end

    % 3. Send to Julia and get results
    if CES_capacity_boundary == 1
        infeasible = 1;
    else
        options = weboptions('MediaType', 'application/json', 'Timeout', 300);
        try
            results = webwrite('http://127.0.0.1:' + string(PORT_NUM) + '/evaluate', ...
                               data_to_send, options);
        catch ME
            error('Julia server is not responding. Make sure server_stage2.jl is running on port %d.', PORT_NUM);
        end
        infeasible = results.infeasible;
    end

    % =================================================================
    % RESULT ANALYSIS  (logic unchanged from subs v3 / Usage v2, only the
    % horizon is now taken from the data instead of being hard-coded to 48)
    % =================================================================
    if infeasible == 0
        disp('Execution successful.');

        % Julia serialises matrices column-major and flat, so reshape with the
        % shapes it reports. Julia is [Hour, Prosumer], MATLAB wants [Prosumer, Hour].
        shapes     = results.shape';            % [tot_hour; num_user]
        CES_shapes = results.CES_shape';        % [tot_hour; bus_sys]
        nbHour     = shapes(1);
        nbUser     = shapes(2);
        nbDay      = results.num_days;

        ces_sizes = results.ces_sizes(:);
        loc_CES   = results.ces_locs(:);        % used by the power-flow block below
        nbCES     = numel(ces_sizes);

        costwoCES = results.cost;               % prosumer cost, whole week
        profit    = results.profit;
        solar     = reshape(results.solar, shapes)' / 1000;
        load      = reshape(results.load,  shapes)' / 1000;
        CES       = reshape(results.Charge_Discharge_CES, CES_shapes)' / 1000;

        % Prosumer charge/discharge, [Hour, Prosumer] - +ve charge, -ve discharge
        user_q    = reshape(results.Charge_Discharge_user, shapes);

        % CES state of charge as a fraction of each unit's capacity, [CES, Hour]
        bat_level = reshape(results.CES_SOC_grid, [nbHour, nbCES])';
        for n = 1:nbCES
            bat_level(n, :) = bat_level(n, :) / ces_sizes(n);
        end

        % Rainflow cycle counting for each CES
        % Aging cost
        % Based on datasheet, cycle life = 6000 cycles at (assumed) 80% DOD
        N_100_fail = 4300;
        kp = 1.5;
        eta_c = 0.9;
        eta_d = 0.9;

        C_aging_total = 0;
        for n = 1:nbCES
            rf     = rainflow(bat_level(n, :), nbHour);
            DODs   = rf(:, 2);      % depth of discharge fractions (0-1)
            counts = rf(:, 1);      % 0.5 = half cycle
            C_aging_total = C_aging_total + ...
                sum((DODs.^kp * 1000 * ces_sizes(n)) ./ (N_100_fail * eta_c * eta_d) .* counts);
        end

        % TNB revenue from CES services == CES cost for prosumer
        switch scenario
            case 'subscription'
                % For Subscription price scheme, TNB earns a fixed cost from
                % prosumers regardless of usage (daily price x days in horizon)
                TNB_revenue_CES = sum(L(2:end)) * CES_subsc_price * nbDay;

                % Add the CES cost to the total cost for each prosumer
                cost_CES = costwoCES + L(2:end)' * CES_subsc_price * nbDay;

            case 'usage'
                % This is for usage price scheme, TNB earns from prosumer
                % charging/discharging to CES
                cost_c       = L(1);
                cost_d       = L(2);
                cost_c_p2p   = L(3);
                cost_d_p2p   = L(4);
                cost_c_close = L(5);
                cost_d_close = L(6);

                % Period prices, repeated for every day of the horizon. The
                % 16 / 21 / 11 split matches CO_ROI_stage2.jl and the C++.
                cost_c_t = zeros(nbHour, 1);
                cost_d_t = zeros(nbHour, 1);
                for d = 1:nbDay
                    off = (d - 1) * 48;
                    cost_c_t(off + (1:16))  = cost_c;
                    cost_d_t(off + (1:16))  = cost_d;

                    cost_c_t(off + (17:37)) = cost_c_p2p;
                    cost_d_t(off + (17:37)) = cost_d_p2p;

                    cost_c_t(off + (38:48)) = cost_c_close;
                    cost_d_t(off + (38:48)) = cost_d_close;
                end

                TNB_revenue_CES   = 0;
                prosumer_CES_cost = zeros(1, nbUser);

                for u = 1:nbUser
                    for t = 1:nbHour
                        q = user_q(t, u);

                        if q > 0
                            c = cost_c_t(t) * q;
                        elseif q < 0
                            c = cost_d_t(t) * abs(q);
                        else
                            c = 0;
                        end

                        TNB_revenue_CES      = TNB_revenue_CES + c;
                        prosumer_CES_cost(u) = prosumer_CES_cost(u) + c;
                    end
                end

                % Add the CES cost to the total cost for each prosumer
                cost_CES = costwoCES + prosumer_CES_cost';
        end

        % Power flow analysis
        % for t = 1:nbHour
        %     data33_ga(1);
        %     global errtol busnum basemva basevoltage busga linedat
        %
        %     buscs1 = busga;
        %     buscs1(:, 8) = busga(:, 8) .* 0;
        %     buscs1(:, 7) = load(:, t);
        %     buscs1(24:end, 5) = 1.5 * solar(t);
        %     buscs1(19, 5) = 16.5 * solar(t) * 1.5;
        %     buscs1(19, 7) = 20 * load(19, t);
        %
        %     for n = 1:nbCES
        %         % CES Prosumer
        %         if CES(loc_CES(n), t) > 0 % charging
        %             buscs1(loc_CES(n), 7) = buscs1(loc_CES(n), 7) + CES(loc_CES(n), t);
        %         elseif CES(loc_CES(n), t) < 0 % discharging
        %             buscs1(loc_CES(n), 5) = buscs1(loc_CES(n), 5) - CES(loc_CES(n), t);
        %         end
        %     end
        %
        %     [result] = gaLFThukaram(errtol, busnum, basemva, basevoltage, buscs1, linedat);
        %     ploss(t) = sum(real(result.Lineloss));
        %     vpii(t) = sum((result.Vm - 1) .^ 2);
        % end
        % fit = sum(ploss);

        % Price range feasibility checking
        %%%% Prosumer cost using CES should minimally be less than the normal (cost(P2P_CES) <= cost (P2P) %%%%
        %%%% If not, it means the CES is not economical and should be penalized %%%%
        costN   = csvread("Benchmark\p2p_noCES\ProsumerCost_normal tariff.csv");
        costP2P = csvread("Benchmark\p2p_noCES\ProsumerCost.csv");

        if ENABLE_COST_SAVING_CHECK && mean(cost_CES) > mean(costP2P) % meaning with using CES is more expensive
            cost_saving_constraint = 1;
            infeasible = 1;
        end
    else
        disp('Execution failed (Infeasible grid state).');
    end

    if infeasible == 1
        C_aging_total   = 1000000;
        TNB_revenue_CES = 0;
        cost_CES        = 1000000;
    end

    if cost_saving_constraint == 1
        cost_CES = 50000;
    end

    if CES_capacity_boundary == 1
        C_aging_total = 50000;
    end

    disp(TNB_revenue_CES)
end
