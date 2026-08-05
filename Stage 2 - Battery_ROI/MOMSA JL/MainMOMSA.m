%%%  Multi-objective Mantis Search Algorithm (MOMSA): A Novel Approach for Engineering Design Problems and Validation
%%  Developed in MATLAB R2019a    
%%Author and programmer: Mohammed jameel  (E-mail:  moh.jameel@su.edu.ye; Mohjameel555@gmail.com) 
clc
clear all

addpath('D:\Jacky\MATLAB\Standardized_functions\two_stage_ROI\Stage2');
global PORT_NUM
PORT_NUM = 8080;
bus_sys = 33;
pf_model = "LDF_stage2";

%% Select the test functions
% True_Pareto=load('OSY-PF.txt');

% Subscription scheme
LB = 0 * ones(1, 33); %lower bounds
UB = 34 * ones(1, 33); %upper bounds
LB(1) = 0.01;
UB(1) = 10;

% Usage scheme
% LB = [0.1 0.1 0.1 0.1 0.1 0.1]; %lower bounds
% UB = [0.57 0.57 2 2 2 2]; %upper bounds

D = length(LB); % Number of decision variables
M = 3; % Number of objective functions
K=M+D;
GEN = 100;  % Set the maximum number of generation (GEN)
N = 100 ;      % Set the population size (N)
ishow = 1;

%% Start the evolution process
%%  START  THE  EXECUTION  OF  THE  ALGORITHM 
for i = 1:10
    [Pareto, gen_sol, PF_log] = MOMSA(D,M, LB,UB,N,GEN,ishow);
    Pareto_objective = Pareto(:,D+1:D+M);
    Pareto_position = Pareto(:,1:D);

    % [top5_loc] = R_method(Pareto_objective,[1 2.5 2.5]);
    % FinalFitness = Pareto_objective(top5_loc,:);
    % FinalPOS = Pareto_position(top5_loc,:);
    FinalPOS = Pareto_position;
    FinalFitness = Pareto_objective;
    filename_test = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\raw\MOMSA result ", num2str(i) ,".xlsx");
    xlswrite(filename_test, FinalPOS, 'Sheet1');
    xlswrite(filename_test, FinalFitness, 'Sheet2');

    filename_test = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\convergence\MOMSA_PF_LOG_", num2str(i) ,".mat");
    save(filename_test, 'PF_log');
end
