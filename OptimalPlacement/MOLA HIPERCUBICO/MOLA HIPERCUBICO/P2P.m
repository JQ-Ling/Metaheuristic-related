function [fit, profit, cost, sizeCES] = P2P(L)
 global errtol busnum basemva basevoltage busga linedat
    nbCES = round(L(1));
    sizeCES = L(6:5+nbCES) + 5; 

    % first=nbCES second=loc_CES third=size of TNB_CES
    input = [nbCES round(L(2:1+nbCES)) L(6:5+nbCES) + 5];
    % let the CES has buffer to handle the worst congestion
    % need to investigate how much is the buffer

    % Convert inputArray to a string with space-separated values
    inputString = sprintf('%d ', input);

    % Define the full path to the executable file
    exePath = '"D:\Jacky\Julia-vscode\(Cpp)ADMM_P2P\x64\Release\p2p.exe"';

    % Call the executable file with appropriate command-line arguments
    command = [exePath ' ' inputString];
    status =  system(command);

    % Check the status of the system call
    if status == 0
        disp('Execution successful.');
    else
        disp('Execution failed.');
    end
    disp(input);

    % Read the result
    infeasible = str2double(fileread('infeasible.txt'));

    if infeasible == 0 && status == 0
        solar = csvread("Solar.csv")/1000;
        load = csvread("PowerConsumption.csv");
        CES = csvread("NetLoadCES.csv");
        profit = csvread("TNBProfit.csv");
        cost = csvread("ProsumerCost.csv");
        load = [load(:,end) load(:,1:end-1)]'/1000;
        CES = [CES(:,end) CES(:,1:end-1)]'/1000;
        loc_CES = input(2:1+nbCES);

        for t = 1:48
            % disp(t)
            data33_ga(1);
            global errtol busnum basemva basevoltage busga linedat

            buscs1=busga;
            % buscs1(:,7)=busga(:,7).*load(:,t);
            % buscs1(:,8)=busga(:,8).*load(:,t);
            % buscs1(:,7)=busga(:,7).*load(:,t);
            buscs1(:,8)=busga(:,8).*0;
            buscs1(:,7)=load(:,t);
            buscs1(24:end,5)=1.5*solar(t);
            buscs1(19,5)=16.5*solar(t)*1.5;
            buscs1(19,7)=20*load(19,t);

            for n=1:nbCES
                % CES Prosumer
                if CES(loc_CES(n),t) > 0 % charging
                    buscs1(loc_CES(n),7) = buscs1(loc_CES(n),7)+CES(loc_CES(n),t);
                elseif CES(loc_CES(n),t) < 0 % discharging
                    buscs1(loc_CES(n),5) = buscs1(loc_CES(n),5)-CES(loc_CES(n),t);
                end
                % % CES TNB
                % if CES(loc_CES(n)-1,t) > 0 % charging
                %     buscs1(loc_CES(n)-1,7) = buscs1(loc_CES(n)-1,7)+CES(loc_CES(n)-1,t);
                % elseif CES(loc_CES(n)-1,t) < 0 % discharging
                %     buscs1(loc_CES(n)-1,5) = buscs1(loc_CES(n)-1,5)-CES(loc_CES(n)-1,t);
                % end
            end

            [result] = gaLFThukaram(errtol, busnum, basemva, basevoltage, buscs1, linedat);
            % [minV, minVno]=min(result.Vm);
            % [maxV, maxVno]=max(result.Vm);
            ploss(t)=sum(real(result.Lineloss));
            vpii(t)=sum((result.Vm-1).^2);
        end
        % ploss = normalize(ploss,'range');
        % fit = 0.7*sum(ploss)+0.3*sum(vpii);
        fit = sum(ploss);
        % disp(sum(ploss))
    end
    if infeasible == 1 || status == 1
        fit = 100000;
        sizeCES = 100000;
        profit=0;
        cost=10000;
    end
    % disp(fit)
end