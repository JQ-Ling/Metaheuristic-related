clc, clear all, close all;
addpath('D:\Jacky\MATLAB\Standardized_functions');

%% ----------------------------------------------------------------
%  STEP 1 — SET YOUR FILE PATHS
%  Edit these 6 paths to match your actual file locations
%% ----------------------------------------------------------------

bus_sys = 69;
pf_model = "ptdf";

% Exhaustive Search (ES) reference front
if bus_sys == 33
    data = py.numpy.load("D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Result\Benchmark - raw collection\benchmark_all.npz", allow_pickle=true);
    pos_all = double(data{'pos_all'});
    obj_all = double(data{'obj_all'});
    pyenv("Version","C:\Users\PC\anaconda3\envs\matlabpy\python.exe")
    inx = zeros(size(pos_all,1),1);
end

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

% try
%        all_solutions = [moo1_solutions; moo2_solutions; moo3_solutions; pos_all];
%        all_fits = [moo1_fits; moo2_fits; moo3_fits; obj_all];
%        all_inx = [moo1_inx; moo2_inx; moo3_inx; inx];

%        % all_solutions = [moo1_solutions; moo2_solutions; moo3_solutions];
%        % all_fits = [moo1_fits; moo2_fits; moo3_fits];
%        % all_inx = [moo1_inx; moo2_inx; moo3_inx];
% catch e
%        fprintf('Exhaustive search result not existed. Only MOO results will be ranked.\n');
%        all_solutions = [moo1_solutions; moo2_solutions; moo3_solutions];
%        all_fits = [moo1_fits; moo2_fits; moo3_fits];
%        all_inx = [moo1_inx; moo2_inx; moo3_inx];
% end

% [top5_loc, ~, score] = R_method(all_fits,[1 2.5 2.5]);

% filename_test = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\All_3MOO.xlsx");
% xlswrite(filename_test, all_solutions, 'Sheet1');
% xlswrite(filename_test, all_fits, 'Sheet2');
% xlswrite(filename_test, all_inx, 'Sheet3');
% xlswrite(filename_test, score, 'Sheet4');

% FinalFitness = all_fits(top5_loc,:); 
% FinalPOS = all_solutions(top5_loc,:);   
% Finalinx = all_inx(top5_loc,:);
% FinalTScore = score(top5_loc,:);

% filename_test = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\All_3MOO_top 5.xlsx");
% xlswrite(filename_test, FinalPOS, 'Sheet1');
% xlswrite(filename_test, FinalFitness, 'Sheet2');
% xlswrite(filename_test, Finalinx, 'Sheet3');
% xlswrite(filename_test, FinalTScore, 'Sheet4');


%% ----------------------------------------------------------------
%  STEP 3 — PLOTTING PARETO SPACE
%  Comment out if no ES solutions are available.
%% ----------------------------------------------------------------

%% ----------------------------------------------------------------
%  STEP 3a — 3D PARETO SURFACE (JOURNAL QUALITY)
%  Replace the old "Density (3D objective space)" block with this.
%  Paste this BEFORE the 2D tiledlayout section.
%
%  Key improvements over previous version:
%   1. scatter3 replaces trisurf — trisurf with 2D Delaunay triangulation
%      on 3D Pareto data creates fold/gap artefacts where the front is
%      not a simple function of (x,y); scatter3 with density colouring
%      is cleaner and avoids triangulation assumptions
%   2. CES cost scaled to ×10⁵ RM — consistent with 2D panels
%   3. 'clim_val' replaces 'clim' (was shadowing the built-in function)
%   4. Colour-blind-safe palette — consistent with 2D section
%   5. has_ES guard — won't crash when ES data is absent
%   6. Proper colorbar label
%   7. Optimised view angle — 35°/22° shows all three trade-off axes
%   8. Consistent FONT_* constants across 3D and 2D sections
%   9. Exported as SVG (vector)
%% ----------------------------------------------------------------

%% ---- Define has_ES once here (used by both 3D and 2D sections) -----------
has_ES = exist('x_exhaustive','var') && ~isempty(x_exhaustive);

%% ---- Visual constants (keep in sync with 2D section below) ---------------
FONT_AXIS    = 14;
FONT_LABEL   = 15;
FONT_LEGEND  = 14;
FONT_CBAR    = 13;
FONT_CBAR_LB = 14;
MARKER_SZ_3D = 80;    % slightly larger for 3D — markers look smaller in 3D
LW_MARKER    = 0.6;
COL_MOPSO    = 'g';
COL_MOLA     = 'r';
COL_MOMSA    = 'k';
SCALE_COST   = 1e5;
cmap_es      = flipud(parula);

%% ---- Scale CES cost (y) --------------------------------------------------
y_moo1_s = y_moo1 / SCALE_COST;
y_moo2_s = y_moo2 / SCALE_COST;
y_moo3_s = y_moo3 / SCALE_COST;

%% ---- Compute ES density --------------------------------------------------
if has_ES
    y_exhaustive_s = y_exhaustive / SCALE_COST;

    % knnsearch density in the SCALED 3-objective space
    pts3      = [x_exhaustive, y_exhaustive_s, z_exhaustive];
    [~, d]    = knnsearch(pts3, pts3, 'K', 15);
    density   = 1 ./ mean(d, 2);
    density_n = (density - min(density)) ./ (max(density) - min(density));

    % Clip at 90th percentile so sparse tail doesn't bleach dense core
    clim_val  = [0, prctile(density_n, 90)];
else
    y_exhaustive_s = [];
    density_n      = [];
    clim_val       = [0, 1];
end

%% ---- 3D figure -----------------------------------------------------------
fig3d = figure('Units','centimeters', ...
               'Position',[2 2 16 13], ...
               'Color','w');
ax3d  = axes(fig3d);
hold(ax3d, 'on');

%% ---- Layer 1: ES density as scatter3 (background) -----------------------
% Using scatter3 avoids the triangulation artefacts of trisurf:
% trisurf with delaunayTriangulation(x,y) creates a 2-D mesh lifted to z,
% which folds where the Pareto front is non-monotone in (x,y) projection.
% scatter3 with colour = density_n gives the same visual density information
% without any geometric assumptions about the surface topology.
if has_ES
    sc = scatter3(ax3d, ...
                  x_exhaustive, y_exhaustive_s, z_exhaustive, ...
                  12, density_n, 'filled', ...
                  'MarkerFaceAlpha', 0.2);
    colormap(ax3d, cmap_es);
    clim(ax3d, clim_val);
end

%% ---- Layer 2: MOO algorithm solutions (foreground) ----------------------
scatter3(ax3d, x_moo1, y_moo1_s, z_moo1, MARKER_SZ_3D, 'o', ...
         'MarkerFaceColor', COL_MOPSO, ...
         'MarkerEdgeColor', 'k', 'LineWidth', LW_MARKER);
scatter3(ax3d, x_moo2, y_moo2_s, z_moo2, MARKER_SZ_3D, '^', ...
         'MarkerFaceColor', COL_MOLA, ...
         'MarkerEdgeColor', 'k', 'LineWidth', LW_MARKER);
scatter3(ax3d, x_moo3, y_moo3_s, z_moo3, MARKER_SZ_3D, 's', ...
         'MarkerFaceColor', COL_MOMSA, ...
         'MarkerEdgeColor', 'k', 'LineWidth', LW_MARKER);

%% ---- Axes decoration ----------------------------------------------------
xlabel(ax3d, 'Power Loss (kW)', ...
       'FontSize', FONT_LABEL);
ylabel(ax3d, 'CES Investment Cost (\times10^{5} RM)', ...
       'FontSize', FONT_LABEL, 'Interpreter', 'tex');
zlabel(ax3d, 'Avg. Participant Cost (RM)', ...
       'FontSize', FONT_LABEL);

ax3d.FontSize  = FONT_AXIS;
ax3d.Box       = 'on';
ax3d.XGrid     = 'on';
ax3d.YGrid     = 'on';
ax3d.ZGrid     = 'on';
ax3d.GridAlpha = 0.25;

% View angle: 35° azimuth / 22° elevation — shows all three axes clearly
% without any axis being foreshortened to near-zero width
view(ax3d, 35, 22);

%% ---- Colorbar -----------------------------------------------------------
if has_ES
    cb3d = colorbar(ax3d, 'eastoutside');
    cb3d.Label.String   = 'Exhaustive Search (Density)';
    cb3d.Label.FontSize = FONT_CBAR_LB;
    cb3d.FontSize       = FONT_CBAR;
end

%% ---- Legend (proxy handles) ---------------------------------------------
% scatter3 returns a Scatter object usable directly in legend,
% but we create proxy handles so the marker size is controlled
% independently of the plot marker size.
hold(ax3d, 'on');
if has_ES
    h3_es = scatter3(ax3d, NaN,NaN,NaN, 30, 'filled', ...
                     'MarkerFaceColor', [0.95 0.85 0.20], ...
                     'MarkerFaceAlpha', 0.6, ...
                     'DisplayName',     'Exhaustive Search (Density)');
end
h3_mopso = scatter3(ax3d, NaN,NaN,NaN, MARKER_SZ_3D, 'o', ...
                    'MarkerFaceColor', COL_MOPSO, ...
                    'MarkerEdgeColor', 'k', 'LineWidth', LW_MARKER, ...
                    'DisplayName',     'MOPSO');
h3_mola  = scatter3(ax3d, NaN,NaN,NaN, MARKER_SZ_3D, '^', ...
                    'MarkerFaceColor', COL_MOLA, ...
                    'MarkerEdgeColor', 'k', 'LineWidth', LW_MARKER, ...
                    'DisplayName',     'MOLA');
h3_momsa = scatter3(ax3d, NaN,NaN,NaN, MARKER_SZ_3D, 's', ...
                    'MarkerFaceColor', COL_MOMSA, ...
                    'MarkerEdgeColor', 'k', 'LineWidth', LW_MARKER, ...
                    'DisplayName',     'MOMSA');
hold(ax3d, 'off');

if has_ES
    leg3d_h = [h3_es, h3_mopso, h3_mola, h3_momsa];
else
    leg3d_h = [h3_mopso, h3_mola, h3_momsa];
end

legend(ax3d, leg3d_h, ...
       'Location',   'best', ...
       'FontSize',   FONT_LEGEND, ...
       'Box',        'on', ...
       'EdgeColor',  [0.5 0.5 0.5]);

%% ---- Export as SVG -------------------------------------------------------
% SAVE_FOLDER = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Analysis");
% out_svg_3d  = fullfile(SAVE_FOLDER, ...
%               sprintf('Pareto_3D_%dbus.svg', bus_sys));

% fig3d.Renderer = 'painters';   % force vector renderer before print
% print(fig3d, out_svg_3d, '-dsvg', '-r0');
% fprintf('3D figure saved:\n  %s\n', out_svg_3d);


%% ----------------------------------------------------------------
%  STEP 3 — PLOTTING PARETO SPACE (JOURNAL QUALITY)
%  Changes from previous version:
%   1. Panel labels (a)(b)(c) placed BELOW x-axis label — standard
%      practice in Nature/IEEE two-column figures for easy referencing
%   2. CES Investment Cost normalised to 10^5 RM — axis label carries
%      the multiplier, axis ticks show clean integers (0–10)
%      eliminating MATLAB's auto-generated ×10^5 offset annotation
%  Requires MATLAB R2019b+ for tiledlayout / exportgraphics
%% ----------------------------------------------------------------

%% ---- 0. Global visual parameters ----------------------------------------
FONT_AXIS    = 14;
FONT_LABEL   = 15;
FONT_PANEL   = 15;   % (a)(b)(c) bold, same size as axis labels
FONT_LEGEND  = 14;
FONT_CBAR    = 13;
FONT_CBAR_LB = 14;

MARKER_SZ    = 65;
LW_MARKER    = 0.6;

COL_MOPSO = 'g';
COL_MOLA  = 'r';
COL_MOMSA = 'k';

SCALE_COST = 1e5;   % divide CES investment cost by this value
                    % → axis ticks show 0–10, label reads (×10⁵ RM)

SAVE_FOLDER = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Analysis");

%% ---- 1. Scale CES investment cost data -----------------------------------
% Scaling is done ONCE here so every use of y_moo*/y_exhaustive is clean.
y_moo1_s = y_moo1 / SCALE_COST;
y_moo2_s = y_moo2 / SCALE_COST;
y_moo3_s = y_moo3 / SCALE_COST;

%% ---- 2. Compute ES density -----------------------------------------------

if has_ES
    y_exhaustive_s = y_exhaustive / SCALE_COST;   % scale ES cost too
    pts3      = [x_exhaustive, y_exhaustive_s, z_exhaustive];
    [~, d]    = knnsearch(pts3, pts3, 'K', 15);
    density   = 1 ./ mean(d, 2);
    density_n = (density - min(density)) ./ (max(density) - min(density));
    clim_val  = [0, prctile(density_n, 90)];
    cmap_es   = flipud(parula);
else
    y_exhaustive_s = [];
    density_n = [];
    clim_val  = [0, 1];
    cmap_es   = flipud(parula);
end

%% ---- 3. Axis label strings -----------------------------------------------
% Multiplier is carried in the label — axis ticks are clean numbers.
% \times10^{5} renders as ×10⁵ in MATLAB text interpreter.
lbl_ploss = 'Power Loss (kW)';
lbl_cost  = 'CES Investment Cost (\times10^{5} RM)';
lbl_elec  = 'Avg. Participant Cost (RM)';

%% ---- 4. Build figure with tiledlayout ------------------------------------
fig = figure('Units','centimeters', ...
             'Position',[2 2 26 9.5], ...   % extra height for below-axis labels
             'Color','w');

t = tiledlayout(fig, 1, 3, ...
                'TileSpacing', 'compact', ...
                'Padding',     'loose');     % 'loose' gives room for sub-labels

%% ---- 5. Draw each panel --------------------------------------------------

% Panel (a): Power Loss vs CES Investment Cost (scaled)
if has_ES, xa = x_exhaustive; ya = y_exhaustive_s;
else,      xa = [];            ya = []; end

ax1 = draw_panel(t, 1, xa, ya, ...
    x_moo1, y_moo1_s, x_moo2, y_moo2_s, x_moo3, y_moo3_s, ...
    has_ES, density_n, clim_val, cmap_es, ...
    lbl_ploss, lbl_cost, '(a)', ...
    COL_MOPSO, COL_MOLA, COL_MOMSA, ...
    MARKER_SZ, LW_MARKER, FONT_AXIS, FONT_LABEL, FONT_PANEL);

% Panel (b): Power Loss vs Avg Participant Cost
if has_ES, xb = x_exhaustive; yb = z_exhaustive;
else,      xb = [];            yb = []; end

ax2 = draw_panel(t, 2, xb, yb, ...
    x_moo1, z_moo1, x_moo2, z_moo2, x_moo3, z_moo3, ...
    has_ES, density_n, clim_val, cmap_es, ...
    lbl_ploss, lbl_elec, '(b)', ...
    COL_MOPSO, COL_MOLA, COL_MOMSA, ...
    MARKER_SZ, LW_MARKER, FONT_AXIS, FONT_LABEL, FONT_PANEL);

% Panel (c): CES Investment Cost (scaled) vs Avg Participant Cost
if has_ES, xc = y_exhaustive_s; yc = z_exhaustive;
else,      xc = [];              yc = []; end

ax3 = draw_panel(t, 3, xc, yc, ...
    y_moo1_s, z_moo1, y_moo2_s, z_moo2, y_moo3_s, z_moo3, ...
    has_ES, density_n, clim_val, cmap_es, ...
    lbl_cost, lbl_elec, '(c)', ...
    COL_MOPSO, COL_MOLA, COL_MOMSA, ...
    MARKER_SZ, LW_MARKER, FONT_AXIS, FONT_LABEL, FONT_PANEL);

%% ---- 6. ONE shared colorbar (spans all panels) ---------------------------
if has_ES
    colormap(ax1, cmap_es); clim(ax1, clim_val);
    colormap(ax2, cmap_es); clim(ax2, clim_val);
    colormap(ax3, cmap_es); clim(ax3, clim_val);

    cb = colorbar(ax3, 'eastoutside');
    cb.Layout.Tile      = 'east';
    cb.Label.String     = 'Exhaustive Search (Density)';
    cb.Label.FontSize   = FONT_CBAR_LB;
    cb.FontSize         = FONT_CBAR;
end

%% ---- 7. ONE shared legend (below all panels) -----------------------------
hold(ax1, 'on');
if has_ES
    h_es = scatter(ax1, NaN, NaN, 18, 'filled', ...
                   'MarkerFaceColor', [0.95 0.85 0.20], ...
                   'MarkerFaceAlpha', 0.6, ...
                   'DisplayName',     'Exhaustive Search (Density)');
end
h_mopso = scatter(ax1, NaN, NaN, MARKER_SZ, 'o', ...
                  'MarkerFaceColor', COL_MOPSO, ...
                  'MarkerEdgeColor', 'k', 'LineWidth', LW_MARKER, ...
                  'DisplayName',     'MOPSO');
h_mola  = scatter(ax1, NaN, NaN, MARKER_SZ, '^', ...
                  'MarkerFaceColor', COL_MOLA, ...
                  'MarkerEdgeColor', 'k', 'LineWidth', LW_MARKER, ...
                  'DisplayName',     'MOLA');
h_momsa = scatter(ax1, NaN, NaN, MARKER_SZ, 's', ...
                  'MarkerFaceColor', COL_MOMSA, ...
                  'MarkerEdgeColor', 'k', 'LineWidth', LW_MARKER, ...
                  'DisplayName',     'MOMSA');
hold(ax1, 'off');

if has_ES
    leg_handles = [h_es, h_mopso, h_mola, h_momsa];
else
    leg_handles = [h_mopso, h_mola, h_momsa];
end

lgd = legend(ax1, leg_handles, ...
             'Orientation', 'horizontal', ...
             'NumColumns',  numel(leg_handles), ...
             'FontSize',    FONT_LEGEND, ...
             'Box',         'on', ...
             'EdgeColor',   [0.5 0.5 0.5]);
lgd.Layout.Tile = 'south';

%% ---- 8. Export (SVG — vector, lossless, preferred by most journal portals) -
% exportgraphics does not support SVG. Use print() with -dsvg driver instead.
% SVG is a W3C open vector format accepted by IEEE, Elsevier, Springer, etc.
% Editors can re-flow text and rescale without quality loss.
% out_svg = fullfile(SAVE_FOLDER, ...
%           sprintf('Pareto_2D_projections_%dbus.svg', bus_sys));
 
% print(fig, out_svg, '-dsvg', '-r0');
% fprintf('Saved:\n  %s\n', out_svg);


%% ================================================================
%  LOCAL FUNCTION — must appear at the END of the script file
%% ================================================================

function ax = draw_panel(t, idx, xES, yES, ...
                         x1, y1, x2, y2, x3, y3, ...
                         has_ES, density_n, clim_val, cmap_es, ...
                         xl, yl, panel_lbl, ...
                         COL_MOPSO, COL_MOLA, COL_MOMSA, ...
                         MARKER_SZ, LW_MARKER, FONT_AXIS, FONT_LABEL, FONT_PANEL)

    ax = nexttile(t, idx);
    hold(ax, 'on');

    % Background: ES density
    if has_ES && ~isempty(xES)
        scatter(ax, xES, yES, 18, density_n, 'filled', ...
                'MarkerFaceAlpha', 0.5);
        colormap(ax, cmap_es);
        clim(ax, clim_val);
    end

    % Algorithm solutions
    scatter(ax, x1, y1, MARKER_SZ, 'o', ...
            'MarkerFaceColor', COL_MOPSO, ...
            'MarkerEdgeColor', 'k', 'LineWidth', LW_MARKER);
    scatter(ax, x2, y2, MARKER_SZ, '^', ...
            'MarkerFaceColor', COL_MOLA, ...
            'MarkerEdgeColor', 'k', 'LineWidth', LW_MARKER);
    scatter(ax, x3, y3, MARKER_SZ, 's', ...
            'MarkerFaceColor', COL_MOMSA, ...
            'MarkerEdgeColor', 'k', 'LineWidth', LW_MARKER);

    % ------------------------------------------------------------------
    % Panel label BELOW the x-axis label (two-line xlabel).
    % Using a cell array as the xlabel string creates a second line.
    % The panel label is bold via \bf; tex interpreter is on by default.
    % This is the standard approach in Nature/IEEE multi-panel figures:
    % the label reads as part of the x-axis annotation, making it
    % unambiguous to cite in the manuscript as "as shown in Fig. X(a)".
    % ------------------------------------------------------------------
    xlabel(ax, {xl, ['\bf' panel_lbl]}, ...
           'FontSize', FONT_LABEL, ...
           'Interpreter', 'tex');

    ylabel(ax, yl, 'FontSize', FONT_LABEL);
    ax.FontSize  = FONT_AXIS;
    ax.Box       = 'on';
    ax.XGrid     = 'on';
    ax.YGrid     = 'on';
    ax.GridAlpha = 0.25;

    hold(ax, 'off');
end