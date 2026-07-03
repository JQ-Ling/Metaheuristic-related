%% ================================================================
%  HV_convergence_analysis.m
%
%  Loads PF_log_*.mat files saved by each algorithm/run, FILTERS OUT
%  infeasible/penalized solutions (e.g. fit = 1e9), builds ONE global
%  nadir from the remaining feasible data, computes HV_log per run,
%  then plots mean +/- std convergence curves for MOMSA, MOLA, MOPSO.
%
%  All helper functions (filter_feasible, compute_global_nadir,
%  compute_HV_from_log, hv_monte_carlo, log_PF) are defined as LOCAL
%  FUNCTIONS at the bottom of this script -- valid in MATLAB R2016b+
%  as long as this file is run as a script (does not start with the
%  keyword `function`). They are usable here and from the command
%  window after this script has run, but NOT from other .m files
%  unless you split them out into their own files.
%
%  ASSUMED FILE LAYOUT (adjust folder/pattern to your own):
%    .../convergence/MOMSA_PF_LOG_1.mat ... MOMSA_PF_LOG_N.mat
%    .../convergence/MOLA_PF_LOG_1.mat  ... MOLA_PF_LOG_N.mat
%    .../convergence/MOPSO_PF_LOG_1.mat ... MOPSO_PF_LOG_N.mat
%  Each .mat contains a variable PF_log (n_iter x 1 cell, each cell
%  an (n_i x M) double -- n_i VARIES iteration to iteration, that's fine,
%  and some rows inside may be penalized/infeasible (e.g. value 1e9) --
%  this script filters those out before any HV math happens.
%% ================================================================

folder            = "D:\Jacky\Data Output\CES size and loc\69bus_ptdf\convergence";
n_runs            = 1;                 % set to however many repeat runs you saved
algos             = {'MOMSA','MOLA','MOPSO'};
penalty_threshold = 1e8;               % anything >= this is treated as infeasible
                                        % (your penalty is 1e9, so 1e8 gives margin
                                        %  -- raise/lower if your real objectives
                                        %  can legitimately get close to 1e8)

%% ---------- STEP 1: load every run's PF_log into one struct ----------
PF_all = struct();
for a = 1:numel(algos)
    name = algos{a};
    PF_all.(name) = cell(1, n_runs);
    for i = 1:n_runs
        fpath = fullfile(folder, sprintf('%s_PF_LOG_%d.mat', name, i));
        S = load(fpath, 'PF_log');
        PF_all.(name){i} = S.PF_log;
    end
end

%% ---------- STEP 2: diagnostics -- how much data is infeasible? ----------
fprintf('\n--- Feasibility diagnostics (threshold = %.3g) ---\n', penalty_threshold);
for a = 1:numel(algos)
    name = algos{a};
    n_total = 0; n_dropped = 0;
    feas_vals = [];
    for i = 1:n_runs
        run_log = PF_all.(name){i};
        for t = 1:numel(run_log)
            PF = run_log{t};
            if isempty(PF), continue; end
            n_total = n_total + size(PF,1);
            bad = any(PF >= penalty_threshold, 2);
            n_dropped = n_dropped + sum(bad);
            feas_vals = [feas_vals; PF(~bad,:)]; %#ok<AGROW>
        end
    end
    if n_total > 0
        pct = 100*n_dropped/n_total;
    else
        pct = NaN;
    end
    fprintf('%-6s: %6d / %6d rows infeasible (%.1f%%)\n', name, n_dropped, n_total, pct);
    if ~isempty(feas_vals)
        fprintf('         feasible obj range -> min: [%s]\n', num2str(min(feas_vals,[],1)));
        fprintf('                                max: [%s]\n', num2str(max(feas_vals,[],1)));
    else
        warning('%s: NO feasible rows found at all across any run/iteration!', name);
    end
end

%% ---------- STEP 3: build ONE global nadir from FEASIBLE data only ----------
% Flatten every run of every algorithm into a single cell-of-cells list
all_logs = {};
for a = 1:numel(algos)
    all_logs = [all_logs, PF_all.(algos{a})]; %#ok<AGROW>
end
nadir_global = compute_global_nadir(all_logs, 1.10, penalty_threshold);
fprintf('\nGlobal nadir (feasible-only) = [%s]\n', num2str(nadir_global));

%% ---------- STEP 4: compute HV_log (per run) for every algorithm ----------
% Different runs/algorithms can have different n_iter -- handle via
% per-run vectors stored in a cell, not a fixed-size matrix.
HV_all = struct();
for a = 1:numel(algos)
    name = algos{a};
    HV_all.(name) = cell(1, n_runs);
    for i = 1:n_runs
        HV_all.(name){i} = compute_HV_from_log(PF_all.(name){i}, nadir_global, 200000, penalty_threshold);
    end
end

%% ---------- STEP 5: align runs to common length & get mean/std ----------
% Different runs of the SAME algorithm should have the same Max_iter
% (set by you), but guard against mismatches by truncating to the
% shortest run within each algorithm.
stats = struct();
for a = 1:numel(algos)
    name = algos{a};
    lens = cellfun(@numel, HV_all.(name));
    n_min = min(lens);
    if any(lens ~= n_min)
        warning('%s: runs have differing lengths (%s) — truncating to %d', ...
            name, num2str(lens), n_min);
    end
    M = zeros(n_min, n_runs);
    for i = 1:n_runs
        M(:,i) = HV_all.(name){i}(1:n_min);
    end
    stats.(name).matrix = M;            % n_iter x n_runs
    stats.(name).mean   = mean(M, 2);
    stats.(name).std    = std(M, 0, 2);
end

%% ---------- STEP 6: plot convergence curves (mean +/- std band) ----------
colors = [0.85 0.10 0.10; 0.10 0.45 0.85; 0.10 0.65 0.30];
figure; hold on; box on;
for a = 1:numel(algos)
    name = algos{a};
    mu  = stats.(name).mean;
    sd  = stats.(name).std;
    x   = (1:numel(mu))';
    % shaded std band
    fill([x; flipud(x)], [mu+sd; flipud(mu-sd)], colors(a,:), ...
         'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility','off');
    plot(x, mu, '-', 'Color', colors(a,:), 'LineWidth', 1.8, 'DisplayName', name);
end
xlabel('Iteration / Generation');
ylabel('Hypervolume');
% title(sprintf('Convergence behaviour: HV vs iteration (mean \\pm std over %d runs)', n_runs));
legend('Location','southeast');
set(gca,'FontSize',11);
hold off;

%% ---------- STEP 7: final-HV table (last iteration, every run) ----------
fprintf('\n--- Final HV (last iteration) summary ---\n');
final_tab = table();
for a = 1:numel(algos)
    name = algos{a};
    last_row = stats.(name).matrix(end, :);     % 1 x n_runs
    final_tab.(name) = [mean(last_row); std(last_row); median(last_row); ...
                         min(last_row); max(last_row)];
end
final_tab.Properties.RowNames = {'mean','std','median','min','max'};
disp(final_tab);

%% ---------- STEP 8 (optional): save everything for later reuse ----------
save(fullfile(folder, 'HV_convergence_results.mat'), ...
     'nadir_global', 'HV_all', 'stats', 'final_tab', 'penalty_threshold');


%% ================================================================
%  LOCAL FUNCTIONS
%  (usable within this script; split into separate files if you also
%  need to call them from MOMSA.m / LA_optimization.m / MOPSO.m or
%  directly from the command window in a fresh session)
%% ================================================================

function PF_obj_clean = filter_feasible(PF_obj, penalty_threshold)
    % Removes rows that hit the infeasibility penalty value (e.g. 1e9)
    % from an objective matrix, so they don't pollute the nadir or HV.
    if nargin < 2
        penalty_threshold = 1e8;
    end
    if isempty(PF_obj)
        PF_obj_clean = PF_obj;
        return;
    end
    infeasible = any(PF_obj >= penalty_threshold, 2);
    PF_obj_clean = PF_obj(~infeasible, :);
end


function PF_log = log_PF(PF_log, t, PF_obj)
    % Stores a COPY of the current Pareto front objectives at iter t.
    % Recommended to filter BEFORE calling this, at the source:
    %   PF_log = log_PF(PF_log, t, filter_feasible(PF_obj, 1e8));
    PF_log{t} = PF_obj;
end


function nadir = compute_global_nadir(all_PF_logs, margin, penalty_threshold)
    % Computes ONE global nadir point from every FEASIBLE front in
    % every log (every iteration, every run, every algorithm).
    % all_PF_logs:       cell array of PF_log cell arrays (cell-of-cells)
    % margin:            multiplicative margin, default 1.10
    % penalty_threshold: rows with any objective >= this are EXCLUDED
    %                     before taking the worst-seen value. Default 1e8.
    %                     Set to Inf to disable filtering.
    if nargin < 2
        margin = 1.10;
    end
    if nargin < 3
        penalty_threshold = 1e8;
    end
    worst = [];
    for i = 1:numel(all_PF_logs)
        run_log = all_PF_logs{i};
        for t = 1:numel(run_log)
            PF = filter_feasible(run_log{t}, penalty_threshold);
            if ~isempty(PF)
                worst = [worst; max(PF, [], 1)]; %#ok<AGROW>
            end
        end
    end
    if isempty(worst)
        error('compute_global_nadir: no feasible non-empty fronts found in logs.');
    end
    nadir = max(worst, [], 1) .* margin;
end


function HV_log = compute_HV_from_log(PF_log, nadir, n_samples, penalty_threshold)
    % Computes HV_log (one HV value per iteration) for a single run's
    % PF_log, using the fixed/global nadir, after dropping infeasible rows.
    % PF_log:            1 x Max_iter cell array of (n x M) objective matrices
    % nadir:             (1 x M) fixed reference point, same for ALL algorithms
    % n_samples:         passed through to hv_monte_carlo (default 200000)
    % penalty_threshold: rows with any objective >= this are EXCLUDED.
    %                     Default 1e8. Set to Inf to disable filtering.
    if nargin < 3
        n_samples = 200000;
    end
    if nargin < 4
        penalty_threshold = 1e8;
    end
    n_iter = numel(PF_log);
    HV_log = zeros(n_iter, 1);
    for t = 1:n_iter
        PF_clean = filter_feasible(PF_log{t}, penalty_threshold);
        HV_log(t) = hv_monte_carlo(PF_clean, nadir, n_samples);
    end
end


function HV = hv_monte_carlo(PF_obj, nadir, n_samples)
    % Computes hypervolume of Pareto front relative to a FIXED nadir.
    % PF_obj:    (n x M) non-dominated, ALREADY-FILTERED feasible objectives
    % nadir:     (1 x M) fixed/global reference point (feasible-only)
    % n_samples: 200000 is fast (~0.1s) and accurate enough per iteration
    if nargin < 3
        n_samples = 200000;
    end
    if isempty(PF_obj)
        HV = 0; return;
    end
    M = size(PF_obj, 2);
    % Drop solutions exceeding nadir (should not happen but safe guard)
    valid  = all(PF_obj < nadir, 2);
    PF_obj = PF_obj(valid, :);
    if isempty(PF_obj)
        HV = 0; return;
    end
    % Normalise consistently to [0, nadir] -> [0,1] for every call, using
    % a FIXED lower bound of 0. Because nadir is the SAME for every
    % algorithm/iteration, this keeps HV in absolute, comparable units.
    ideal  = zeros(1, M);
    range_ = nadir - ideal;
    range_(range_ == 0) = 1;
    PF_norm = (PF_obj - ideal) ./ range_;
    PF_norm = max(0, min(1, PF_norm));
    % Monte Carlo -- fixed seed for reproducibility across iterations/algos
    rng(42, 'twister');
    samples = rand(n_samples, M);
    % Count samples dominated by at least one solution in front
    dominated = false(n_samples, 1);
    for k = 1:size(PF_norm, 1)
        dominated = dominated | all(bsxfun(@le, PF_norm(k,:), samples), 2);
    end
    HV = sum(dominated) / n_samples;
end