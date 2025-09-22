%%%  Multi-objective Mantis Search Algorithm (MOMSA): A Novel Approach for Engineering Design Problems and Validation
%%  Developed in MATLAB R2019a
%%Author and programmer: Mohammed jameel  (E-mail:  moh.jameel@su.edu.ye; Mohjameel555@gmail.com)
clc
clear all
%% Select the test functions
% True_Pareto=load('OSY-PF.txt');
D = 2; % Number of decision variables
M = 3; % Number of objective functions
K = M + D;
GEN = 100; % Set the maximum number of generation (GEN)
N = 100; % Set the population size (N)
ishow = 1;
%OSY optimization problem
LB = [0.1 0.1]; %lower bounds
UB = [0.57 0.57]; %upper bounds
%% Start the evolution process
%%  START  THE  EXECUTION  OF  THE  ALGORITHM
for i = 1:1
    % [Pareto, gen_sol] = MOMSA(D,M, LB,UB,N,GEN,ishow);
    [Pareto, gen_sol, all_evals, pop_log, pool_log] = MOMSA(D, M, LB, UB, N, GEN, ishow);
    Pareto_objective = Pareto(:, D + 1:D + M);
    Pareto_position = Pareto(:, 1:D);
    % Obtained_Pareto_objective=sortrows(Obtained_Pareto,2);
    %  %%%plot
    % plot(Obtained_Pareto(:,1),Obtained_Pareto(:,2),'bo','LineWidth',0.0001,...
    %           'MarkerEdgeColor','k',...
    %            'MarkerFaceColor','c',...
    %            'MarkerSize',15);
    % hold on
    % plot(True_Pareto(:,1),True_Pareto(:,2),'.','color',[0.8290 0.0940 0.00250],'MarkerSize',25);
    % legend('MOSMA','True PF','FontSize',10);
    %     xlabel('Obj_1','FontSize',10);
    %     ylabel('Obj_2','FontSize',10);
    %  set(gca,'FontSize',10)
    % %%  Metric Value
    % M_GD=GD_matlab(Obtained_Pareto,True_Pareto);
    % M_IGD=IGD_matlab(Obtained_Pareto,True_Pareto);
    % M_HV=HV(Obtained_Pareto,True_Pareto);
    % M_MS=metric_of_maximum_spread(Obtained_Pareto,True_Pareto);
    % display(['The GD Metric obtained by MOMSA is  : ', num2str(M_GD)]);
    % display(['The IGD Metric obtained by MOMSA is : ', num2str(M_IGD)]);
    % display(['The MS Metric obtained by MOMSA is  : ', num2str(M_MS)]);
    % display(['The HV Metric obtained by MOMSA is  : ', num2str(M_HV)]);

    % figure;
    % plot(gen_sol(:,1), gen_sol(:,2), gen_sol(:,3), '-o');
    % xlabel('Objective 1');
    % ylabel('Objective 2');
    % title('Convergence of MOMSA');

    % [top5_loc] = R_method(Pareto_objective,[3 1.5 1.5]);
    % FinalFitness = Pareto_objective(top5_loc,:);
    % FinalPOS = Pareto_position(top5_loc,:);
    FinalPOS = Pareto_position;
    FinalFitness = Pareto_objective;
    filename_test = strcat("D:\Jacky\Data Output\Battery ROI\MOMSA unrank ", num2str(i), ".xlsx");
    % xlswrite(filename_test, FinalPOS, 'Sheet1');
    % xlswrite(filename_test, FinalFitness, 'Sheet2');
end
