function [fit, profit, cost, sizeCES] = P2P(L)
    global errtol busnum basemva basevoltage busga linedat
    
    nbCES = round(L(1));
    sizeCES = L(6:5+nbCES) + 5; 
    
    % Prepare the arrays for Julia (ensuring they are double column vectors)
    ces_locs = double(round(L(2:1+nbCES))');
    ces_sizes = double(sizeCES');
    disp('CES numbers: ' + string(nbCES) + ', Locations: ' + string(ces_locs) + ', Sizes: ' + string(ces_sizes));
    
    data_to_send = struct(...
        'ces_sizes', double(ces_sizes), ...
        'ces_locs', double(ces_locs) ...
    );

    % 2. Set options for JSON communication
    options = weboptions('MediaType', 'application/json', 'Timeout', 60);

    % 3. Send to Julia and get results (MATLAB converts JSON back to struct automatically)
    try
        results = webwrite('http://127.0.0.1:8080/evaluate', data_to_send, options);
    catch ME
        error('Julia server is not responding. Make sure server.jl is running.');
    end
    
    % Check feasibility directly from the struct
    if results.infeasible == 0 
        disp('Execution successful.');        
        % Read data straight from RAM (Instantaneous!)
        % Note: Julia arrays are [Hour, Prosumer], so you might need to 
        % transpose them (') in MATLAB if your old code expected [Prosumer, Hour]
        shapes = results.shape';
        CES_shapes = results.CES_shape';
        cost = results.cost;
        profit = results.profit;
        solar = results.solar/1000;
        pros_solar = results.pros_solar;
        CES = reshape(results.Charge_Discharge_CES, CES_shapes)'; 

        % 1. Extract, transpose, and convert to kW/MW (Size will be 68 x 48)
        load_temp = reshape(results.load, shapes)' / 1000;

        % 2. Pad a zero row at the top for Bus 1 (Final size will be 69 x 48)
        load = [zeros(1, size(load_temp, 2)); load_temp];
        disp("Load data prepared for evaluation.");
        for t = 1:48
            data69_ga(1);
            global errtol busnum basemva basevoltage busga linedat

            buscs1=busga;
            % buscs1(:,7)=busga(:,7).*load(:,t);
            % buscs1(:,8)=busga(:,8).*load(:,t);
            % buscs1(:,7)=busga(:,7).*load(:,t);
            buscs1(:,8)=busga(:,8).*0;
            buscs1(:,7)=load(:,t);
            buscs1(pros_solar+1:end,5)=1.5*solar(t);

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
            [result] = gaLFThukaram(errtol, busnum, basemva, basevoltage, buscs1, linedat);
            % [minV, minVno]=min(result.Vm);
            % [maxV, maxVno]=max(result.Vm);
            ploss(t)=sum(real(result.Lineloss));
            % vpii(t)=sum((result.Vm-1).^2);
        end

        % ploss = normalize(ploss,'range');
        % fit = 0.7*sum(ploss)+0.3*sum(vpii);
        fit = sum(ploss);
        % disp(sum(ploss))
    else
        disp('Execution failed (Infeasible grid state).');
        fit = 1e9; % Assign heavy penalty
        profit = 0;
        cost = 1e9;
        sizeCES = 1e9;
    end
end