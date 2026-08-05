close all
clear all
clc

addpath('D:\Jacky\MATLAB\Standardized_functions\two_stage_ROI\Stage2');
global PORT_NUM
PORT_NUM = 8080;
bus_sys = 33;
pf_model = "LDF_stage2";

% Optimizator Parameters
% Subscription scheme
LB = 0 * ones(1, 33); %lower bounds
UB = 34 * ones(1, 33); %upper bounds
LB(1) = 0.01;
UB(1) = 10;

% Usage scheme
% LB = [0.1 0.1 0.1 0.1 0.1 0.1]; %lower bounds
% UB = [0.57 0.57 2 2 2 2]; %upper bounds

pop = 100;         %Population
n_iter = 100;      %Max number os iterations/gerations
ref = 0.4;         %if more than zero, a second LF is created with refinement % the size of the other
IntCon = [0];      %zero if there are no variables that must be integers. Ex.: IntCon = [1,2];   
Np = 100000;       %Number of Particles (If 3D, better more than 10000)
S_c = 1;           %Stick Probability: Percentage of particles that can don´t stuck in the
                   %cluster. Between 0 and 1. Near 0 there are more aggregate, the density of
                   %cluster is bigger and difusity is low. Near 1 is the opposite. 
Rc = 150;          %Creation Radius (if 3D, better be less than 80, untill 150)
M = 0;             %If M = 0, no lichtenberg figure is created (it is loaded a optimized figure); if 1, a single is created and used in all iterations; If 2, one is created for each iteration.(creating an LF figure takes about 2 min)
d = length(UB);    %problem dimension
ngrid = 30;        %Number of grids in each dimension
Nr = 100;          %Maximum number of solutions in PF
for i = 1:10
    [x,fval, PF_log] = LA_optimization(@objectives,d,pop,LB,UB,ref,n_iter,Np,Rc,S_c,M,ngrid,Nr,IntCon,@constraint);
 
    FinalPOS = x;
    FinalFitness = fval;
    filename_test = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\raw\MOLA result_", num2str(i) ,".xlsx");
    xlswrite(filename_test, FinalPOS, 'Sheet1');
    xlswrite(filename_test, FinalFitness, 'Sheet2');

    filename_test = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\convergence\MOLA_PF_LOG_", num2str(i) ,".mat");
    save(filename_test, 'PF_log');
end