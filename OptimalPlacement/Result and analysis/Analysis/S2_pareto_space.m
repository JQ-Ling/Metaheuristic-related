clc, clear all, close all;
addpath('D:\Jacky\MATLAB\Standardized_functions');

%% ----------------------------------------------------------------
%  STEP 1 — SET YOUR FILE PATHS
%  Edit these 6 paths to match your actual file locations
%% ----------------------------------------------------------------

bus_sys = 69;
pf_model = "ptdf";

% Exhaustive Search (ES) reference front
% data = py.numpy.load("D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Result\Benchmark - raw collection\benchmark_all.npz", allow_pickle=true);
% pos_all = double(data{'pos_all'});
% obj_all = double(data{'obj_all'});
% pyenv("Version","C:\Users\PC\anaconda3\envs\matlabpy\python.exe")
% inx = zeros(size(pos_all,1),1);

% MOO algorithm results (MOPSO, MOLA, MOMSA)
file_MOMSA = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\MOMSA.xlsx");
file_MOLA  = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\MOLA.xlsx");
file_MOPSO = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\MOPSO.xlsx");

moo1_solutions = xlsread(file_MOPSO, 'Sheet1');
moo1_fits = xlsread(file_MOPSO, 'Sheet2');

moo2_solutions = xlsread(file_MOLA, 'Sheet1');
moo2_fits = xlsread(file_MOLA, 'Sheet2');

moo3_solutions = xlsread(file_MOMSA, 'Sheet1');
moo3_fits = xlsread(file_MOMSA, 'Sheet2');

try
       moo1_inx = xlsread(file_MOPSO, 'Sheet3');
       moo2_inx = xlsread(file_MOLA, 'Sheet3');
       moo3_inx = xlsread(file_MOMSA, 'Sheet3');
catch e
       fprintf('Algorithm index not existed. (MOPSO = 1, MOLA = 2, MOMSA = 3)\n');
       moo1_inx = ones(size(moo1_fits,1),1);
       moo2_inx = ones(size(moo2_fits,1),1);
       moo3_inx = ones(size(moo3_fits,1),1);
end

% Extract objectives
x_moo1 = moo1_fits(:, 1)* 1000; % MW -> kW
y_moo1 = moo1_fits(:, 2);
z_moo1 = moo1_fits(:, 3);

x_moo2 = moo2_fits(:, 1)* 1000;
y_moo2 = moo2_fits(:, 2);
z_moo2 = moo2_fits(:, 3);

x_moo3 = moo3_fits(:, 1) * 1000;
y_moo3 = moo3_fits(:, 2);
z_moo3 = moo3_fits(:, 3);

try
       x_exhaustive = obj_all(:, 1)* 1000;
       y_exhaustive = obj_all(:, 2);
       z_exhaustive = obj_all(:, 3);
catch e
end

%% ----------------------------------------------------------------
%  STEP 2 — Final Ranking of all solutions (MOPSO, MOLA, MOMSA, ES)
%  Use R-method to rank all solutions from all algorithms and exhaustive search.
%% ----------------------------------------------------------------

try
       % all_solutions = [moo1_solutions; moo2_solutions; moo3_solutions; pos_all];
       % all_fits = [moo1_fits; moo2_fits; moo3_fits; obj_all];
       % all_inx = [moo1_inx; moo2_inx; moo3_inx; inx];

       all_solutions = [moo1_solutions; moo2_solutions; moo3_solutions];
       all_fits = [moo1_fits; moo2_fits; moo3_fits];
       all_inx = [moo1_inx; moo2_inx; moo3_inx];
catch e
       fprintf('Exhaustive search result not existed. Only MOO results will be ranked.\n');
       all_solutions = [moo1_solutions; moo2_solutions; moo3_solutions];
       all_fits = [moo1_fits; moo2_fits; moo3_fits];
       all_inx = [moo1_inx; moo2_inx; moo3_inx];
end
[top5_loc, ~, score] = R_method(all_fits,[1 2.5 2.5]);

filename_test = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\All_3MOO.xlsx");
xlswrite(filename_test, all_solutions, 'Sheet1');
xlswrite(filename_test, all_fits, 'Sheet2');
xlswrite(filename_test, all_inx, 'Sheet3');
xlswrite(filename_test, score, 'Sheet4');

FinalFitness = all_fits(top5_loc,:); 
FinalPOS = all_solutions(top5_loc,:);   
Finalinx = all_inx(top5_loc,:);
FinalTScore = score(top5_loc,:);

filename_test = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\All_3MOO_top 5.xlsx");
xlswrite(filename_test, FinalPOS, 'Sheet1');
xlswrite(filename_test, FinalFitness, 'Sheet2');
xlswrite(filename_test, Finalinx, 'Sheet3');
xlswrite(filename_test, FinalTScore, 'Sheet4');


%% ----------------------------------------------------------------
%  STEP 3 — PLOTTING PARETO SPACE
%  Comment out if no ES solutions are available.
%% ----------------------------------------------------------------

%%---------- Density (3D objective space) ----------
figure; hold on;

% pts3 = [x_exhaustive, y_exhaustive, z_exhaustive];
% [~, d] = knnsearch(pts3, pts3, 'K', 15);
% density = 1 ./ mean(d, 2);
% density_n = (density - min(density)) ./ (max(density) - min(density));
% 
% clim = [0 prctile(density_n, 90)];   % consistent color scale
% cmap = flipud(parula);
% 
% DT = delaunayTriangulation(x_exhaustive, y_exhaustive);
% trisurf(DT.ConnectivityList, ...
%         x_exhaustive, y_exhaustive, z_exhaustive, ...
%         density_n, ...
%         'FaceAlpha', 0.15, ...
%         'EdgeColor', 'none');

scatter3(x_moo1, y_moo1, z_moo1, 100, 'go', 'filled');
scatter3(x_moo2, y_moo2, z_moo2, 100, 'r^', 'filled');
scatter3(x_moo3, y_moo3, z_moo3, 100, 'ks', 'filled');

set(gca, 'FontSize', 18);

colormap(flipud(parula));
colorbar;
grid on;
xlabel('Power Loss (kW)', 'FontSize', 18);
ylabel('CES Investment Cost (RM)', 'FontSize', 18);
zlabel('Average Participant Cost (RM)', 'FontSize', 18);
% legend('Exhaustive Search (Density)', 'MOPSO', 'MOLA', 'MOMSA', ...
legend('MOPSO', 'MOLA', 'MOMSA', ...
       'Location','best', 'FontSize', 14);view(25, 20);
hold off;

%% ---------- FIGURE 1: Power Loss vs CES Investment ----------
figure; hold on;
% scatter(x_exhaustive, y_exhaustive, 15, density_n, 'filled'); 
scatter(x_moo1, y_moo1, 60, 'go', 'filled');
scatter(x_moo2, y_moo2, 60, 'r^', 'filled');
scatter(x_moo3, y_moo3, 60, 'ks', 'filled');

xlabel('Power Loss (kW)','FontSize', 18);
ylabel('CES Investment Cost (RM)','FontSize', 18);
% colormap(cmap);
% caxis(clim);
% cb = colorbar;
% % cb.Label.String = 'Relative Solution Concentration';
set(gca, 'FontSize', 18);

% legend('Exhaustive Search (Density)', 'MOPSO', 'MOLA', 'MOMSA', ...
legend('MOPSO', 'MOLA', 'MOMSA', ...
       'Location','best', 'FontSize', 14);
grid on;

%% ---------- FIGURE 2: Power Loss vs Average Cost ----------
figure;hold on;
% scatter(x_exhaustive, z_exhaustive, 15, density_n, 'filled'); hold on;
scatter(x_moo1, z_moo1, 60, 'go', 'filled');
scatter(x_moo2, z_moo2, 60, 'r^', 'filled');
scatter(x_moo3, z_moo3, 60, 'ks', 'filled');

xlabel('Power Loss (kW)','FontSize', 18);
ylabel('Average Participant Cost (RM)','FontSize', 18);
% colormap(cmap);
% caxis(clim);
% cb = colorbar;
% % cb.Label.String = 'Relative Solution Concentration';
set(gca, 'FontSize', 18);

% legend('Exhaustive Search (Density)', 'MOPSO', 'MOLA', 'MOMSA', ...
legend('MOPSO', 'MOLA', 'MOMSA', ...
       'Location','best', 'FontSize', 14);
grid on;

%% ---------- FIGURE 3: CES Investment vs Average Cost ----------
figure;hold on;
% scatter(y_exhaustive, z_exhaustive, 15, density_n, 'filled'); hold on;
scatter(y_moo1, z_moo1, 60, 'go', 'filled');
scatter(y_moo2, z_moo2, 60, 'r^', 'filled');
scatter(y_moo3, z_moo3, 60, 'ks', 'filled');

xlabel('CES Investment Cost (RM)','FontSize', 18);
ylabel('Average Participant Cost (RM)', 'FontSize', 18);
% colormap(cmap);
% caxis(clim);
% cb = colorbar;
% % cb.Label.String = 'Relative Solution Concentration';
set(gca, 'FontSize', 18);

% legend('Exhaustive Search (Density)', 'MOPSO', 'MOLA', 'MOMSA', ...
legend('MOPSO', 'MOLA', 'MOMSA', ...
       'Location','best', 'FontSize', 14);
grid on;