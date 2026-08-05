function [fit, profit, cost, sizeCES] = P2P_stage1(L)
    global errtol busnum basemva basevoltage busga linedat PORT_NUM
    
    nbCES = round(L(1));
    if length(L) == 17 % decision variables dimension (69 bus = 17, else 33 bus)
        bus_sys = 69;
        sizeCES = L(10:9+nbCES) + 5; 
    else
        bus_sys = 33;
        sizeCES = L(6:5+nbCES) + 5; 
    end
    
    % Prepare the arrays for Julia (ensuring they are double column vectors)
    ces_locs = double(round(L(2:1+nbCES))');
    ces_sizes = double(sizeCES');
    disp('CES numbers: ' + string(nbCES) + ', Locations: ' + string(ces_locs) + ', Sizes: ' + string(ces_sizes));
    
    data_to_send = struct(...
        'ces_sizes', double(ces_sizes), ...
        'ces_locs', double(ces_locs) ...
    );

    % 2. Set options for JSON communication
    % Week-ahead is 7 LPs per call, so allow more headroom than the day-ahead 60 s
    options = weboptions('MediaType', 'application/json', 'Timeout', 300);

    % 3. Send to Julia and get results (MATLAB converts JSON back to struct automatically)
    try
        results = webwrite('http://127.0.0.1:' + string(PORT_NUM) + '/evaluate', data_to_send, options);
    catch ME
        error('Julia server is not responding. Make sure server.jl is running.');
    end
    
    % Check feasibility directly from the struct
    if results.infeasible == 0 
        disp('Execution successful.');        
        % Read data straight from RAM (Instantaneous!)
        % Note: Julia arrays are [Hour, Prosumer], MATLAB expects [Prosumer, Hour]
        shapes = results.shape';
        CES_shapes = results.CES_shape';
        cost = results.cost;
        profit = results.profit;
        pros_solar = results.pros_solar;
        CES = reshape(results.Charge_Discharge_CES, CES_shapes)'/1000;

        % Horizon comes from the data: 48 for day-ahead, 336 for week-ahead
        nbHour = shapes(1);

        % Day-ahead modules (CO_Placement_*.jl) return solar as one system-wide
        % irradiance vector [Hour]. The week-ahead module (CO_ROI_stage1.jl)
        % returns per-bus PV [Hour, Prosumer], already scaled - no multipliers.
        week_ahead = numel(results.solar) == prod(shapes);
        if week_ahead
            solar = reshape(results.solar, shapes)' / 1000;  % [Prosumer, Hour]
        else
            solar = results.solar/1000;                      % [Hour, 1]
        end

        % 1. Extract, transpose, and kW -> MW (Size will be 68 x nbHour)
        load_temp = reshape(results.load, shapes)' / 1000;

        % 2. Pad a zero row at the top for Bus 1 (Final size will be 69 x nbHour)
        load = [zeros(1, size(load_temp, 2)); load_temp];
        disp("Load data prepared for evaluation (" + string(nbHour) + " steps, week_ahead=" + string(week_ahead) + ").");
        ploss = zeros(1, nbHour);   % preallocate: 336 power flows instead of 48
        for t = 1:nbHour
            if bus_sys == 69
                data69_ga(1);
            else
                data33_ga(1);
            end
            global errtol busnum basemva basevoltage busga linedat

            buscs1=busga;
            % buscs1(:,7)=busga(:,7).*load(:,t);
            % buscs1(:,8)=busga(:,8).*load(:,t);
            % buscs1(:,7)=busga(:,7).*load(:,t);
            buscs1(:,8)=busga(:,8).*0;
            buscs1(:,7)=load(:,t);

            % Case Study
            if week_ahead
                % CO_ROI_stage1.jl already carries per-bus PV and leaves the
                % load adjustments commented out, so no multipliers here.
                buscs1(2:end,5)=solar(:,t);
            elseif bus_sys == 69
                buscs1(pros_solar+1:end,5)=1.5*solar(t);
                buscs1(27,7)=10*load(27,t);
                buscs1(35,7)=10*load(35,t);
                buscs1(52,7)=10*load(52,t);
            else
                buscs1(24:end,5)=1.5*solar(t);
                buscs1(19,5)=16.5*solar(t)*1.5;
                buscs1(19,7)=20*load(19,t);
            end

            for n=1:nbCES
                % CES Prosumer
                if CES(ces_locs(n),t) > 0 % charging
                    buscs1(ces_locs(n),7) = buscs1(ces_locs(n),7)+CES(ces_locs(n),t);
                elseif CES(ces_locs(n),t) < 0 % discharging
                    buscs1(ces_locs(n),5) = buscs1(ces_locs(n),5)-CES(ces_locs(n),t);
                end
                % % CES TNB
                % if CES(ces_locs(n)-1,t) > 0 % charging
                %     buscs1(ces_locs(n)-1,7) = buscs1(ces_locs(n)-1,7)+CES(ces_locs(n)-1,t);
                % elseif CES(ces_locs(n)-1,t) < 0 % discharging
                %     buscs1(ces_locs(n)-1,5) = buscs1(ces_locs(n)-1,5)-CES(ces_locs(n)-1,t);
                % end
            end
            [result_pf] = gaLFThukaram(errtol, busnum, basemva, basevoltage, buscs1, linedat);
            ploss(t)=sum(real(result_pf.Lineloss));
            % ploss(t) = 0;
        end

        % ploss = normalize(ploss,'range');
        % fit = 0.7*sum(ploss)+0.3*sum(vpii);
        fit = sum(ploss);
        % fit.load = reshape(results.load, shapes)';
        % fit.solar = results.solar;
        % fit.CES = CES;
        if result_pf.infeasible == 1
            disp('Execution failed (Infeasible power flow).');
            fit = 1e9; % Assign heavy penalty
            profit = 0;
            cost = 1e9;
            sizeCES = 1e9;
        end
    else
        disp('Execution failed (Infeasible grid state).');
        fit = 1e9; % Assign heavy penalty
        profit = 0;
        cost = 1e9;
        sizeCES = 1e9;
    end
end