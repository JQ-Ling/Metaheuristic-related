clear all; clc;

addpath('D:\Jacky\MATLAB\Standardized_functions\two_stage_ROI\Stage2');

global PORT_NUM
PORT_NUM = 8081;
bus_sys = 33;
pf_model = "LDF_stage2";

% Multi-objective function
MultiObjFnc = 'P2P';

switch MultiObjFnc
    case 'P2P'
        MultiObj.fun = @(x) runP2P(x);
        % Subscription scheme
        LB = 0 * ones(1, 33); %lower bounds
        UB = 34 * ones(1, 33); %upper bounds
        LB(1) = 0.01;
        UB(1) = 10;

        % Usage scheme
        % LB = [0.1 0.1 0.1 0.1 0.1 0.1]; %lower bounds
        % UB = [0.57 0.57 2 2 2 2]; %upper bounds
        
        MultiObj.nVar = length(MultiObj.var_min);
        % MultiObj.truePF = PF;
end

% Parameters
params.Np = 100;        % Population size
params.Nr = 100;        % Repository size
params.maxgen = 100;    % Maximum number of generations
params.W = 0.4;         % Inertia weight
params.C1 = 2;          % Individual confidence factor
params.C2 = 2;          % Swarm confidence factor
params.ngrid = 20;      % Number of grids in each dimension
params.maxvel = 5;      % Maxmium vel in percentage
params.u_mut = 0.5;     % Uniform mutation percentage

% MOPSO
for i = 1:10
    REP = MOPSO(params,MultiObj);

    % Display info
    display('Repository fitness values are stored in REP.pos_fit');
    display('Repository particles positions are store in REP.pos');

    % [top5_loc] = R_method(REP.pos_fit,[3 1.5 1.5])
    % FinalFitness = REP.pos_fit(top5_loc,:) 
    % FinalPOS = REP.pos(top5_loc,:)   
    FinalFitness = REP.pos_fit;
    FinalPOS = REP.pos;
    PF_log = REP.PF_log;
    filename_test = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\raw\MOPSO result ", num2str(i) ,".xlsx");
    xlswrite(filename_test, FinalPOS, 'Sheet1');
    xlswrite(filename_test, FinalFitness, 'Sheet2');

    filename_test = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\convergence\MOPSO_PF_LOG_", num2str(i) ,".mat");
    save(filename_test, 'PF_log');
end
