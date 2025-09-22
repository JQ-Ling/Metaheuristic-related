
filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\Data\MOPSO 70 unrank.xlsx");
moo1_solutions = xlsread(filename_test, 'Sheet1');
moo1_fits = xlsread(filename_test, 'Sheet2');
moo1_inx = xlsread(filename_test, 'Sheet3');

filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\Data\MOLA unrank.xlsx");
moo2_solutions = xlsread(filename_test, 'Sheet1');
moo2_fits = xlsread(filename_test, 'Sheet2');
moo2_inx = xlsread(filename_test, 'Sheet3');

filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\Data\MOMSA unrank.xlsx");
moo3_solutions = xlsread(filename_test, 'Sheet1');
moo3_fits = xlsread(filename_test, 'Sheet2');
moo3_inx = xlsread(filename_test, 'Sheet3');

all_solutions = [moo1_solutions; moo2_solutions; moo3_solutions];
all_fits = [moo1_fits; moo2_fits; moo3_fits];
all_inx = [moo1_inx; moo2_inx; moo3_inx];
% [top5_loc, ~, score] = R_method(all_fits,[3 1.5 1.5]);
[top5_loc, ~, score] = R_method(all_fits,[1 2.5 2.5]);

filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\Data\AllRank_3MOO.xlsx");
xlswrite(filename_test, all_solutions, 'Sheet1');
xlswrite(filename_test, all_fits, 'Sheet2');
xlswrite(filename_test, all_inx, 'Sheet3');
xlswrite(filename_test, score, 'Sheet4');

FinalFitness = all_fits(top5_loc,:); 
FinalPOS = all_solutions(top5_loc,:);   
Finalinx = all_inx(top5_loc,:);
FinalTScore = score(top5_loc,:);

filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\Data\AllBest_3MOO.xlsx");
xlswrite(filename_test, FinalPOS, 'Sheet1');
xlswrite(filename_test, FinalFitness, 'Sheet2');
xlswrite(filename_test, Finalinx, 'Sheet3');
xlswrite(filename_test, FinalTScore, 'Sheet4');

% Extract objectives
x_moo1 = moo1_fits(:, 1);
y_moo1 = moo1_fits(:, 2);
z_moo1 = moo1_fits(:, 3);

x_moo2 = moo2_fits(:, 1);
y_moo2 = moo2_fits(:, 2);
z_moo2 = moo2_fits(:, 3);

x_moo3 = moo3_fits(:, 1);
y_moo3 = moo3_fits(:, 2);
z_moo3 = moo3_fits(:, 3);

% Create 3D scatter plot
figure; hold on;
scatter3(x_moo1, y_moo1, z_moo1, 100, 'bo', 'filled'); 
scatter3(x_moo2, y_moo2, z_moo2, 100, 'r^', 'filled');
scatter3(x_moo3, y_moo3, z_moo3, 100, 'ks', 'filled');
grid on;
xlabel('Power Loss');
ylabel('CES investment cost');
zlabel('Participants Electricity cost');
% title('Comparison of Top 5 Pareto Solutions (Fitness)');
legend('MOPSO', 'MOLA', 'MOMSA');
hold off;
view(35, 20);
% 
% %%
% figure;
% parallelcoords(moo2_solutions, 'LineWidth', 1.5);
% xlabel('Decision Variables and Objectives');
% ylabel('Values');
% title('Parallel Coordinates Plot of Pareto-Optimal Solutions');
% grid on;
