close all
clear all
clc

% Optimizator Parameters
LB = [1 2 2 2 2 76 76 76 76];  %lower bounds
UB = [4 33 33 33 33 304 304 304 304];   %upper bounds
pop = 70;         %Population
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
    [x,fval] = LA_optimization(@objectives,d,pop,LB,UB,ref,n_iter,Np,Rc,S_c,M,ngrid,Nr,IntCon,@constraint);

    % % % TOPSIS
    % [npf nf] = size(fval);
    % MED = abs(mean(fval));
    % STD = abs(std(fval));
    % w = [0.333 0.5 0.1666]
    % for i=1:nf
    %       fvalN(:,i) = abs((fval(:,i)-MED(i))/STD(i)); %normalizing
    %      SQ(:,i) = w(i)*(fvalN(:,i)/sqrt(sum(fvalN(:,i).^2)));
    % %      SQ(:,i) = (1/nf)*(fvalN(:,i)/sqrt(sum(fvalN(:,i).^2)));
    %       SQ1(:,i) = (SQ(:,i)-min(SQ(:,i))).^2;
    %       SQ2(:,i) = (SQ(:,i)-max(SQ(:,i))).^2;
    % end
    % for i=1:npf
    %     P (i,:) = sqrt(sum(SQ2(i,:)))/(sqrt(sum(SQ2(i,:)))+sqrt(sum(SQ1(i,:)))); %Performance Score
    % end
    % best_pos=find(P==max(P));
    % Xbest = x(best_pos,:);
    % Fbest = fval(best_pos,:);
    % 
    % %FIGURE
    % figure
    % plot(fval(:,1),fval(:,2),'ZDataSource','',...
    %     'MarkerFaceColor',[1 0 0],...
    %     'MarkerEdgeColor',[0 0 0],...
    %     'MarkerSize',8,...
    %     'Marker','o',...
    %     'LineWidth',0.3,...
    %     'LineStyle','none',...
    %     'Color',[0 0 0]);
    % hold on
    % box on
    % %plot3(fval(best_pos,1),fval(best_pos,2),fval(best_pos,3),'MarkerFaceColor',[1 1 0],'MarkerSize',14,'Marker','pentagram','LineWidth', 0.2, 'LineStyle','none','Color',[0 0 0]);
    % %legend('PF','TOPSIS');
    % set(0,'DefaultAxesFontSize', 10)
    % set(0,'DefaultTextFontSize', 10)
    % set(findall(gcf,'-property','FontName'),'FontName','Italic')
    % set(findall(gcf,'-property','FontAngle'),'FontAngle','italic')
    % set(gcf,'position',[200,200,600,320])
    % title('Non-dominated solutions','fontweight','bold');
    % %axis([0 3000 0 30000 0 -1])
    % xlabel('f_1')
    % ylabel('f_2')
    % %zlabel('f_3')

    % [top5_loc] = R_method(fval,[3 1.5 1.5])
    % FinalFitness = fval(top5_loc,:) 
    % FinalPOS = x(top5_loc,:)   
    FinalPOS = x;
    FinalFitness = fval;
    filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\MOLA result unrank", num2str(i) ,".xlsx");
    xlswrite(filename_test, FinalPOS, 'Sheet1');
    xlswrite(filename_test, FinalFitness, 'Sheet2');
end