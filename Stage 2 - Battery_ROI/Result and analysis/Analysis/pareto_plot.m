clc, clear all, close all;
filename_test = ("D:\Jacky\MATLAB\Battery_ROI\MOMSA_code\Benchmark\p2p_CES\limit\ProsumerCost.csv");
cost = csvread(filename_test);
mean_cost = mean(cost);

filename_test = strcat("D:\Jacky\Data Output\Battery ROI\For paper\MOMSA unrank limit usage v2 1.xlsx");
moo2_solutions = xlsread(filename_test, 'Sheet1');
moo2_fits = xlsread(filename_test, 'Sheet2');
% moo2_inx = xlsread(filename_test, 'Sheet3');

filename_test = strcat("D:\Jacky\Data Output\Battery ROI\For paper\MOMSA unrank unlimit subsc v4 1.xlsx");
moo3_solutions = xlsread(filename_test, 'Sheet1');
moo3_fits = xlsread(filename_test, 'Sheet2');
% moo3_inx = xlsread(filename_test, 'Sheet3');

x_moo2 = -moo2_fits(:, 1);
y_moo2 = moo2_fits(:, 2);
z_moo2 = moo2_fits(:, 3) + mean_cost;

x_moo3 = -moo3_fits(:, 1);
y_moo3 = moo3_fits(:, 2);
z_moo3 = moo3_fits(:, 3);
% Create 3D scatter plot
figure; hold on;
% scatter3(x_exhaustive, y_exhaustive, z_exhaustive, ...
%          20, 'm*', 'MarkerFaceAlpha', 0.15, 'MarkerEdgeAlpha', 0.15);
% scatter3(x_moo1, y_moo1, z_moo1, 100, 'bo', 'filled'); 
scatter3(x_moo2, y_moo2, z_moo2, 100, 'filled');
scatter3(x_moo3, y_moo3, z_moo3, 100, 'filled');
% scatter3(x_exhaustive, y_exhaustive, z_exhaustive, 100, 'y*', 'filled')
grid on;
xlabel('CES Operator Revenue (RM)', 'fontsize', 14);
ylabel('Battery Aging Cost', 'fontsize', 14);
zlabel('Average Cost of Participants with CES (RM)', 'fontsize', 14);
% title('Comparison of Top 5 Pareto Solutions (Fitness)');
legend('Usage-base', 'Subscription-base', 'fontsize', 14);
hold off;
view([46.43 17.66]);

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
figure; hold on;
% scatter(x_exhaustive, y_exhaustive, 15, density_n, 'filled'); hold on;
% scatter(x_moo1, y_moo1, 60, 'go', 'filled');
scatter(y_moo2, x_moo2, 60, 'filled');
scatter(y_moo3, x_moo3, 60, 'filled');

ylabel('CES Operator Revenue (RM)','FontSize', 14);
xlabel('Battery Aging Cost','FontSize', 14);
% colormap(cmap);
% caxis(clim);
% cb = colorbar;
% cb.Label.String = 'Relative Solution Concentration';

% legend('Exhaustive Search (Density)', 'MOPSO', 'MOLA', 'MOMSA', ...
%        'Location','best');
legend('Usage-base', 'Subscription-base','FontSize', 14,'Location','best');

grid on; hold off;

%% ---------- FIGURE 2: Power Loss vs Average Cost ----------
figure; hold on;
% scatter(x_exhaustive, z_exhaustive, 15, density_n, 'filled'); hold on;
% scatter(x_moo1, z_moo1, 60, 'go', 'filled');
scatter(x_moo2, z_moo2, 60, 'filled');
scatter(x_moo3, z_moo3, 60, 'filled');

xlabel('CES Operator Revenue (RM)','FontSize', 14);
ylabel('Average Cost of Participants with CES (RM)','FontSize', 14);
% colormap(cmap);
% caxis(clim);
% cb = colorbar;
% cb.Label.String = 'Relative Solution Concentration';

% legend('Exhaustive Search (Density)', 'MOPSO', 'MOLA', 'MOMSA', ...
%        'Location','best');
legend('Usage-base', 'Subscription-base','FontSize', 14,'Location','best');

grid on; hold off;

%% ---------- FIGURE 3: CES Investment vs Average Cost ----------
figure; hold on;
% scatter(y_exhaustive, z_exhaustive, 15, density_n, 'filled'); hold on;
% scatter(y_moo1, z_moo1, 60, 'go', 'filled');
scatter(y_moo2, z_moo2, 60, 'filled');
scatter(y_moo3, z_moo3, 60, 'filled');

xlabel('Battery Aging Cost','FontSize', 14);
ylabel('Average Cost of Participants with CES (RM)','FontSize', 14);
% colormap(cmap);
% caxis(clim);
% cb = colorbar;
% cb.Label.String = 'Relative Solution Concentration';

% legend('Exhaustive Search (Density)', 'MOPSO', 'MOLA', 'MOMSA', ...
%        'Location','best');
legend('Usage-base', 'Subscription-base','FontSize', 14,'Location','best');

grid on; hold off;