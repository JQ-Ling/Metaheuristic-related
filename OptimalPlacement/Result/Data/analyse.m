clc, clear all, close all;

% pyenv("Version","C:\Users\PC\anaconda3\envs\matlabpy\python.exe")
% data = py.numpy.load("D:\Jacky\MATLAB\OptimalPlacement\Result\Benchmark\benchmark_all.npz", allow_pickle=true);
% pos_all = double(data{'pos_all'});
% obj_all = double(data{'obj_all'});
% inx = zeros(size(pos_all,1),1);
% size(pos_all)
% size(obj_all)

% filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\Data\CorrectScoreRank\MOPSO 70 unrank.xlsx");
% moo1_solutions = xlsread(filename_test, 'Sheet1');
% moo1_fits = xlsread(filename_test, 'Sheet2');
% moo1_inx = xlsread(filename_test, 'Sheet3');

% filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\Data\CorrectScoreRank\MOLA unrank.xlsx");
% moo2_solutions = xlsread(filename_test, 'Sheet1');
% moo2_fits = xlsread(filename_test, 'Sheet2');
% moo2_inx = xlsread(filename_test, 'Sheet3');

filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\Data\CorrectScoreRank\MOMSA unrank.xlsx");
moo3_solutions = xlsread(filename_test, 'Sheet1');
moo3_fits = xlsread(filename_test, 'Sheet2');
moo3_inx = xlsread(filename_test, 'Sheet3');

[top5_loc, ~, score] = R_method(moo3_fits,[1 2.5 2.5]);

filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\Data\CorrectScoreRank\MOMSA ranked.xlsx");
xlswrite(filename_test, moo3_solutions, 'Sheet1');
xlswrite(filename_test, moo3_fits, 'Sheet2');
xlswrite(filename_test, moo3_inx, 'Sheet3');
xlswrite(filename_test, score, 'Sheet4');

% all_solutions = [moo1_solutions; moo2_solutions; moo3_solutions; pos_all];
% all_fits = [moo1_fits; moo2_fits; moo3_fits; obj_all];
% all_inx = [moo1_inx; moo2_inx; moo3_inx; inx];
% [top5_loc, ~, score] = R_method(all_fits,[1 2.5 2.5]);

% filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\Data\AllRank_3MOO.xlsx");
% xlswrite(filename_test, all_solutions, 'Sheet1');
% xlswrite(filename_test, all_fits, 'Sheet2');
% xlswrite(filename_test, all_inx, 'Sheet3');
% xlswrite(filename_test, score, 'Sheet4');

% FinalFitness = all_fits(top5_loc,:); 
% FinalPOS = all_solutions(top5_loc,:);   
% Finalinx = all_inx(top5_loc,:);
% FinalTScore = score(top5_loc,:);

% filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\Data\AllBest_3MOOwExhaustive.xlsx");
% xlswrite(filename_test, FinalPOS, 'Sheet1');
% xlswrite(filename_test, FinalFitness, 'Sheet2');
% xlswrite(filename_test, Finalinx, 'Sheet3');
% xlswrite(filename_test, FinalTScore, 'Sheet4');

% Extract objectives
% x_moo1 = moo1_fits(:, 1);
% y_moo1 = moo1_fits(:, 2);
% z_moo1 = moo1_fits(:, 3);

% x_moo2 = moo2_fits(:, 1);
% y_moo2 = moo2_fits(:, 2);
% z_moo2 = moo2_fits(:, 3);

x_moo3 = moo3_fits(:, 1) * 1000;
y_moo3 = moo3_fits(:, 2);
z_moo3 = moo3_fits(:, 3);

% x_exhaustive = obj_all(:, 1);
% y_exhaustive = obj_all(:, 2);
% z_exhaustive = obj_all(:, 3);

% Create 3D scatter plot
figure; hold on;
% scatter3(x_exhaustive, y_exhaustive, z_exhaustive, ...
%          20, 'm*', 'MarkerFaceAlpha', 0.15, 'MarkerEdgeAlpha', 0.15);
% scatter3(x_moo1, y_moo1, z_moo1, 100, 'bo', 'filled'); 
% scatter3(x_moo2, y_moo2, z_moo2, 100, 'r^', 'filled');
scatter3(x_moo3, y_moo3, z_moo3, 100, 'filled');
% scatter3(x_exhaustive, y_exhaustive, z_exhaustive, 100, 'y*', 'filled')
grid on;
xlabel('Power Loss (kW)', 'fontsize', 14);
ylabel('CES investment cost (RM)', 'fontsize', 14);
zlabel('Average Cost of Participants (RM)', 'fontsize', 14);
% title('Comparison of Top 5 Pareto Solutions (Fitness)');
% legend('Exhaustive Search', 'MOPSO', 'MOLA', 'MOMSA', 'fontsize', 12);
hold off;
view(25, 20);

% Build 2D triangulation
% DT = delaunayTriangulation(x_exhaustive, y_exhaustive);

% % Estimate point density in x–y plane
% pts = [x_exhaustive, y_exhaustive];
% [~, density] = knnsearch(pts, pts, 'K', 15);
% density = 1 ./ mean(density, 2);   % higher = denser

% figure; hold on;
% density_n = (density - min(density)) ./ (max(density) - min(density));

% % Density-colored Pareto surface
% trisurf(DT.ConnectivityList, ...
%         x_exhaustive, y_exhaustive, z_exhaustive, ...
%         density_n, ...                 % <-- color = density
%         'FaceAlpha', 0.15, ...
%         'EdgeColor', 'none');

% % Overlay MOO solutions
% scatter3(x_moo1, y_moo1, z_moo1, 80, 'go', 'filled');
% scatter3(x_moo2, y_moo2, z_moo2, 80, 'r^', 'filled');
% scatter3(x_moo3, y_moo3, z_moo3, 80, 'ks', 'filled');

% xlabel('Power Loss (kW)');
% ylabel('CES Investment Cost (RM)');
% zlabel('Average Participant Cost (RM)');

% % Colorbar = concentration
% cb = colorbar;
% cb.Label.String = 'Solution Concentration (Relative Density)';
% cb.FontSize = 12;


% colormap(parula);          % base colormap
% colormap(flipud(parula)); % reverse: high density = dark
% colorbar;
% view(25,20);
% grid on;

% legend('Exhaustive Solution Density', 'MOPSO', 'MOLA', 'MOMSA');


% % 3D density based on objective space
% pts3 = [x_exhaustive, y_exhaustive, z_exhaustive];
% [~, d] = knnsearch(pts3, pts3, 'K', 15);
% density = 1 ./ mean(d, 2);
% 
% % Normalize density to [0,1]
% density_n = (density - min(density)) ./ (max(density) - min(density));
% 
% figure; hold on;
% 
% scatter(x_exhaustive, y_exhaustive, 15, density_n, 'filled');
% scatter(x_moo1, y_moo1, 60, 'bo', 'filled');
% scatter(x_moo2, y_moo2, 60, 'r^', 'filled');
% scatter(x_moo3, y_moo3, 60, 'ks', 'filled');
% 
% xlabel('Power Loss (kW)');
% ylabel('CES Investment Cost (RM)');
% 
% colormap(flipud(parula));
% caxis([0 prctile(density_n, 90)]);
% cb = colorbar;
% cb.Label.String = 'Relative Solution Concentration';
% 
% grid on;
% legend('Exhaustive Density', 'MOPSO', 'MOLA', 'MOMSA');
% 
% figure; hold on;
% 
% scatter(x_exhaustive, z_exhaustive, 15, density_n, 'filled');
% scatter(x_moo1, z_moo1, 60, 'bo', 'filled');
% scatter(x_moo2, z_moo2, 60, 'r^', 'filled');
% scatter(x_moo3, z_moo3, 60, 'ks', 'filled');
% 
% xlabel('Power Loss (kW)');
% ylabel('Average Participant Cost (RM)');
% 
% colormap(flipud(parula));
% caxis([0 prctile(density_n, 90)]);
% cb = colorbar;
% cb.Label.String = 'Relative Solution Concentration';
% 
% grid on;
% 
% figure; hold on;
% 
% scatter(y_exhaustive, z_exhaustive, 15, density_n, 'filled');
% scatter(y_moo1, z_moo1, 60, 'bo', 'filled');
% scatter(y_moo2, z_moo2, 60, 'r^', 'filled');
% scatter(y_moo3, z_moo3, 60, 'ks', 'filled');
% 
% xlabel('CES Investment Cost (RM)');
% ylabel('Average Participant Cost (RM)');
% 
% colormap(flipud(parula));
% caxis([0 prctile(density_n, 90)]);
% cb = colorbar;
% cb.Label.String = 'Relative Solution Concentration';
% 
% grid on;


%% ---------- Density (3D objective space) ----------
% pts3 = [x_exhaustive, y_exhaustive, z_exhaustive];
% [~, d] = knnsearch(pts3, pts3, 'K', 15);
% density = 1 ./ mean(d, 2);
% density_n = (density - min(density)) ./ (max(density) - min(density));

% clim = [0 prctile(density_n, 90)];   % consistent color scale
% cmap = flipud(parula);

%% ---------- FIGURE 1: Power Loss vs CES Investment ----------
figure;
% scatter(x_exhaustive, y_exhaustive, 15, density_n, 'filled'); hold on;
% scatter(x_moo1, y_moo1, 60, 'go', 'filled');
% scatter(x_moo2, y_moo2, 60, 'r^', 'filled');
scatter(x_moo3, y_moo3, 60, 'filled');

xlabel('Power Loss (kW)','FontSize', 14);
ylabel('CES Investment Cost (RM)','FontSize', 14);
% colormap(cmap);
% caxis(clim);
% cb = colorbar;
% cb.Label.String = 'Relative Solution Concentration';

% legend('Exhaustive Search (Density)', 'MOPSO', 'MOLA', 'MOMSA', ...
%        'Location','best');
grid on;

%% ---------- FIGURE 2: Power Loss vs Average Cost ----------
figure;
% scatter(x_exhaustive, z_exhaustive, 15, density_n, 'filled'); hold on;
% scatter(x_moo1, z_moo1, 60, 'go', 'filled');
% scatter(x_moo2, z_moo2, 60, 'r^', 'filled');
scatter(x_moo3, z_moo3, 60, 'filled');

xlabel('Power Loss (kW)','FontSize', 14);
ylabel('Average Participant Cost (RM)','FontSize', 14);
% colormap(cmap);
% caxis(clim);
% cb = colorbar;
% cb.Label.String = 'Relative Solution Concentration';

% legend('Exhaustive Search (Density)', 'MOPSO', 'MOLA', 'MOMSA', ...
%        'Location','best');
grid on;

%% ---------- FIGURE 3: CES Investment vs Average Cost ----------
figure;
% scatter(y_exhaustive, z_exhaustive, 15, density_n, 'filled'); hold on;
% scatter(y_moo1, z_moo1, 60, 'go', 'filled');
% scatter(y_moo2, z_moo2, 60, 'r^', 'filled');
scatter(y_moo3, z_moo3, 60, 'filled');

xlabel('CES Investment Cost (RM)','FontSize', 14);
ylabel('Average Participant Cost (RM)', 'FontSize', 14);
% colormap(cmap);
% caxis(clim);
% cb = colorbar;
% cb.Label.String = 'Relative Solution Concentration';

% legend('Exhaustive Search (Density)', 'MOPSO', 'MOLA', 'MOMSA', ...
%        'Location','best');
grid on;