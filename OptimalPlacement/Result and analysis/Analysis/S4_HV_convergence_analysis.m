clear; close; clc
%% ================================================================
%  HV_convergence_analysis.m  — UPDATED to match IAS_algo_comp.m
%
%  Key changes from previous version:
%   1. Uses global IDEAL (best feasible per objective) as the lower
%      normalisation bound instead of zeros — same as IAS_algo_comp.m.
%      Using ideal=zeros inflates the box and compresses HV toward 0.
%   2. hv_monte_carlo now receives ideal as explicit argument so
%      both scripts are guaranteed to use identical normalisation.
%   3. compute_global_ideal added alongside compute_global_nadir.
%   4. Both nadir and ideal printed after STEP 3 for sanity check.
%% ================================================================
bus_sys = 33;
pf_model = 'ptdf';

folder            = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\convergence");
n_runs            = 10;
algos             = {'MOMSA','MOLA','MOPSO'};
penalty_threshold = 1e8;

%% ---------- STEP 1: load every run's PF_log ----------
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

%% ---------- STEP 2: feasibility diagnostics ----------
fprintf('\n--- Feasibility diagnostics (threshold = %.3g) ---\n', penalty_threshold);
for a = 1:numel(algos)
    name = algos{a};
    n_total = 0; n_dropped = 0; feas_vals = [];
    for i = 1:n_runs
        for t = 1:numel(PF_all.(name){i})
            PF = PF_all.(name){i}{t};
            if isempty(PF), continue; end
            n_total   = n_total + size(PF,1);
            bad       = any(PF >= penalty_threshold, 2);
            n_dropped = n_dropped + sum(bad);
            feas_vals = [feas_vals; PF(~bad,:)]; %#ok<AGROW>
        end
    end
    pct = 100 * n_dropped / max(n_total,1);
    fprintf('%-6s: %6d / %6d rows infeasible (%.1f%%)\n', name, n_dropped, n_total, pct);
    if ~isempty(feas_vals)
        fprintf('         feasible obj -> min: [%s]\n', num2str(min(feas_vals,[],1)));
        fprintf('                          max: [%s]\n', num2str(max(feas_vals,[],1)));
    else
        warning('%s: NO feasible rows found.', name);
    end
end

%% ---------- STEP 3: ONE global nadir AND ideal from feasible data ----------
% CRITICAL: both use the same box as IAS_algo_comp.m so HV values are
% directly comparable between the convergence plot and the metrics table.
all_logs = {};
for a = 1:numel(algos)
    all_logs = [all_logs, PF_all.(algos{a})]; %#ok<AGROW>
end

nadir_global = compute_global_nadir(all_logs, 1.10, penalty_threshold);
ideal_global = compute_global_ideal(all_logs, penalty_threshold);

fprintf('\nGlobal ideal (feasible min per obj) = [%s]\n', num2str(ideal_global));
fprintf('Global nadir (feasible max*1.1)     = [%s]\n', num2str(nadir_global));
fprintf('Normalisation range per obj          = [%s]\n', ...
        num2str(nadir_global - ideal_global));

%% ---------- STEP 4: compute HV_log per run ----------
HV_all = struct();
for a = 1:numel(algos)
    name = algos{a};
    HV_all.(name) = cell(1, n_runs);
    for i = 1:n_runs
        HV_all.(name){i} = compute_HV_from_log( ...
            PF_all.(name){i}, nadir_global, ideal_global, 200000, penalty_threshold);
    end
end

%% ---------- STEP 5: align to common length & compute mean/std ----------
stats = struct();
for a = 1:numel(algos)
    name = algos{a};
    lens  = cellfun(@numel, HV_all.(name));
    n_min = min(lens);
    if any(lens ~= n_min)
        warning('%s: differing run lengths, truncating to %d', name, n_min);
    end
    M = zeros(n_min, n_runs);
    for i = 1:n_runs
        M(:,i) = HV_all.(name){i}(1:n_min);
    end
    stats.(name).matrix = M;
    stats.(name).mean   = mean(M, 2);
    stats.(name).std    = std(M,  0, 2);
end

%% ---------- STEP 6: plot convergence curves ----------
colors = [0.85 0.10 0.10; 0.10 0.45 0.85; 0.10 0.65 0.30];
figure; hold on; box on;
for a = 1:numel(algos)
    name = algos{a};
    mu = stats.(name).mean;
    sd = stats.(name).std;
    x  = (1:numel(mu))';
    fill([x; flipud(x)], [mu+sd; flipud(mu-sd)], colors(a,:), ...
         'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility','off');
    plot(x, mu, '-', 'Color', colors(a,:), 'LineWidth', 1.8, 'DisplayName', name);
end
xlabel('Iteration','FontSize', 18);
ylabel('HV','FontSize', 18);
legend('Location','southeast');
set(gca,'FontSize',18);
grid on;
hold off;
saveas(gcf, 'HV_convergence.svg')

%% ---------- STEP 7: final-HV summary ----------
fprintf('\n--- Final HV (last iteration) ---\n');
final_tab = table();
for a = 1:numel(algos)
    name     = algos{a};
    last_row = stats.(name).matrix(end, :);
    final_tab.(name) = [mean(last_row); std(last_row); ...
                         median(last_row); min(last_row); max(last_row)];
end
final_tab.Properties.RowNames = {'mean','std','median','min','max'};
disp(final_tab);

%% ---------- STEP 8: save ----------
save(fullfile(folder, 'HV_convergence_results.mat'), ...
     'nadir_global', 'ideal_global', 'HV_all', 'stats', ...
     'final_tab', 'penalty_threshold');


%% ================================================================
%  LOCAL FUNCTIONS
%% ================================================================

function PF_clean = filter_feasible(PF_obj, penalty_threshold)
    if nargin < 2, penalty_threshold = 1e8; end
    if isempty(PF_obj), PF_clean = PF_obj; return; end
    PF_clean = PF_obj(~any(PF_obj >= penalty_threshold, 2), :);
end


function nadir = compute_global_nadir(all_PF_logs, margin, penalty_threshold)
    if nargin < 2, margin = 1.10; end
    if nargin < 3, penalty_threshold = 1e8; end
    worst = [];
    for i = 1:numel(all_PF_logs)
        for t = 1:numel(all_PF_logs{i})
            PF = filter_feasible(all_PF_logs{i}{t}, penalty_threshold);
            if ~isempty(PF)
                worst = [worst; max(PF, [], 1)]; %#ok<AGROW>
            end
        end
    end
    if isempty(worst)
        error('compute_global_nadir: no feasible fronts found.');
    end
    nadir = max(worst, [], 1) .* margin;
end


function ideal = compute_global_ideal(all_PF_logs, penalty_threshold)
    % Best (minimum) feasible value per objective across all logs.
    % Using this as the lower bound instead of zeros ensures the
    % normalisation box reflects the actual attainable range, and
    % prevents solutions from being compressed into a tiny corner
    % of [0,1]^M space (which causes artificially low HV values).
    if nargin < 2, penalty_threshold = 1e8; end
    best = [];
    for i = 1:numel(all_PF_logs)
        for t = 1:numel(all_PF_logs{i})
            PF = filter_feasible(all_PF_logs{i}{t}, penalty_threshold);
            if ~isempty(PF)
                best = [best; min(PF, [], 1)]; %#ok<AGROW>
            end
        end
    end
    if isempty(best)
        error('compute_global_ideal: no feasible fronts found.');
    end
    ideal = min(best, [], 1);
end


function HV_log = compute_HV_from_log(PF_log, nadir, ideal, n_samples, penalty_threshold)
    if nargin < 4, n_samples = 200000; end
    if nargin < 5, penalty_threshold = 1e8; end
    n_iter = numel(PF_log);
    HV_log = zeros(n_iter, 1);
    for t = 1:n_iter
        PF_clean  = filter_feasible(PF_log{t}, penalty_threshold);
        HV_log(t) = hv_monte_carlo(PF_clean, nadir, ideal, n_samples);
    end
end


function HV = hv_monte_carlo(PF_obj, nadir, ideal, n_samples)
    % HV using shared [ideal, nadir] normalisation — same as IAS_algo_comp.m.
    % ideal and nadir are FIXED globally so every algorithm and every
    % iteration is in the same unit box and values are directly comparable.
    if nargin < 4, n_samples = 200000; end
    if isempty(PF_obj), HV = 0; return; end
    valid  = all(PF_obj < nadir, 2);
    PF_obj = PF_obj(valid, :);
    if isempty(PF_obj), HV = 0; return; end
    range_ = nadir - ideal;
    range_(range_ == 0) = 1;
    PF_norm = (PF_obj - ideal) ./ range_;
    PF_norm = max(0, min(1, PF_norm));
    rng(42, 'twister');
    samples   = rand(n_samples, size(PF_obj,2));
    dominated = false(n_samples, 1);
    for k = 1:size(PF_norm,1)
        dominated = dominated | all(bsxfun(@le, PF_norm(k,:), samples), 2);
    end
    HV = sum(dominated) / n_samples;
end