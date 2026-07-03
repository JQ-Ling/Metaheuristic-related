%% ================================================================
%  PARETO METRICS PIPELINE — TABLE 20 STYLE (multi-scenario, mean±std)
%
%  Matches the format of Table 20 in doi:10.1007/s00521-023-08327-0:
%  - Each scenario occupies a row-group in ONE consolidated table
%  - Each metric (HV, SP, DIV, HRS) is a sub-row within that group
%  - Each algorithm column shows  mean ± std  across n_runs trials
%
%  Per-trial architecture: metrics are computed on each trial's front
%  SEPARATELY, then aggregated → mean and std are genuinely across runs,
%  not computed on a pooled/stacked front (which would give one number).
%
%  Shared normalisation: nadir and ideal are built from ALL feasible data
%  across ALL trials × ALL algorithms × ALL scenarios so every HV value
%  is in the same unit box and directly comparable in the table.
%% ================================================================

clear; clc;

%% ----------------------------------------------------------------
%  STEP 1 — CONFIGURE
%% ----------------------------------------------------------------

% Root folder containing individual trial files
% File naming from your Main scripts: "MOMSA result 1.xlsx" etc.
folder_33  = 'D:\Jacky\Data Output\CES size and loc\33bus_ptdf\raw';
folder_69  = 'D:\Jacky\Data Output\CES size and loc\69bus_ptdf\raw';

tpl_MOMSA_33  = 'MOMSA result unrank%d.xlsx';
tpl_MOLA_33   = 'MOLA result unrank%d.xlsx';
tpl_MOPSO_33  = 'MOPSO 70 result unrank%d.xlsx';

tpl_MOMSA_69  = 'MOMSA result %d.xlsx';
tpl_MOLA_69   = 'MOLA result %d.xlsx';
tpl_MOPSO_69  = 'MOPSO result %d.xlsx';

n_runs    = 10;        % independent trials per algorithm
sheet_fit = 'Sheet2';  % sheet with objective values [Ploss, Cost, CES_size]

% ES ground truth file
npz_path_33 = 'D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Result\Benchmark - raw collection\benchmark_all.npz';

% Output file
output_xlsx = 'D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Analysis\pareto_metrics_Table20.xlsx';

penalty_threshold = 1e8;

%% ----------------------------------------------------------------
%  STEP 2 — LOAD TRIALS FOR EACH SCENARIO
%% ----------------------------------------------------------------

fprintf('=== Loading trials ===\n');
fprintf('Scenario 1 — 33-bus full PF\n');
T.MOMSA_s1 = load_trials(folder_33,  tpl_MOMSA_33, n_runs, sheet_fit, penalty_threshold);
T.MOLA_s1  = load_trials(folder_33,  tpl_MOLA_33,  n_runs, sheet_fit, penalty_threshold);
T.MOPSO_s1 = load_trials(folder_33,  tpl_MOPSO_33, n_runs, sheet_fit, penalty_threshold);

% Add Scenario 3 here in same pattern if you have 69-bus data
fprintf('Scenario 2 — 69-bus full PF\n');
T.MOMSA_s2 = load_trials(folder_69,  tpl_MOMSA_69, n_runs, sheet_fit, penalty_threshold);
T.MOLA_s2  = load_trials(folder_69,  tpl_MOLA_69,  n_runs, sheet_fit, penalty_threshold);
T.MOPSO_s2 = load_trials(folder_69,  tpl_MOPSO_69, n_runs, sheet_fit, penalty_threshold);

%% ----------------------------------------------------------------
%  STEP 3 — ONE GLOBAL NADIR AND IDEAL ACROSS ALL SCENARIOS
%  Include ES in the pool so the reference front is never outside the box
%% ----------------------------------------------------------------

ES_33     = load_ES(npz_path_33);
PF_ref_33 = pareto_filter_large(ES_33);

all_data_33 = pool_all({T.MOMSA_s1, T.MOLA_s1, T.MOPSO_s1}, ES_33);
nadir_g_33  = max(all_data_33, [], 1) * 1.10;
ideal_g_33  = min(all_data_33, [], 1);

fprintf('\nScenario 1 (33-bus)');
fprintf('\nGlobal ideal = [%s]\n', num2str(ideal_g_33));
fprintf('Global nadir = [%s]\n', num2str(nadir_g_33));

all_data_69 = pool_all({T.MOMSA_s2, T.MOLA_s2, T.MOPSO_s2}, []);
nadir_g_69  = max(all_data_69, [], 1) * 1.10;
ideal_g_69  = min(all_data_69, [], 1);
PF_ref_69 = pareto_filter_large(all_data_69);

fprintf('\nScenario 2 (69-bus)');
fprintf('\nGlobal ideal = [%s]\n', num2str(ideal_g_69));
fprintf('Global nadir = [%s]\n', num2str(nadir_g_69));


%% ----------------------------------------------------------------
%  STEP 4 — COMPUTE PER-TRIAL METRICS FOR EVERY SCENARIO
%% ----------------------------------------------------------------

fprintf('\n=== Computing metrics ===\n');

% Scenario 1
[S1.MOMSA, R1.MOMSA] = trial_metrics(T.MOMSA_s1, nadir_g_33, ideal_g_33, PF_ref_33);
[S1.MOLA,  R1.MOLA]  = trial_metrics(T.MOLA_s1,  nadir_g_33, ideal_g_33, PF_ref_33);
[S1.MOPSO, R1.MOPSO] = trial_metrics(T.MOPSO_s1, nadir_g_33, ideal_g_33, PF_ref_33);

% Scenario 2
[S2.MOMSA, R2.MOMSA] = trial_metrics(T.MOMSA_s2, nadir_g_69, ideal_g_69, PF_ref_69);
[S2.MOLA,  R2.MOLA]  = trial_metrics(T.MOLA_s2,  nadir_g_69, ideal_g_69, PF_ref_69);
[S2.MOPSO, R2.MOPSO] = trial_metrics(T.MOPSO_s2, nadir_g_69, ideal_g_69, PF_ref_69);


%% ----------------------------------------------------------------
%  STEP 5 — PRINT TABLE 20-STYLE CONSOLIDATED TABLE
%  Rows: Scenario × Metric   Columns: MOMSA | MOLA | MOPSO (mean±std)
%% ----------------------------------------------------------------

scenarios = { ...
    'Sc1 — 33-bus',          S1; ...
    'Sc2 — 69-bus',          S2; ...
};

print_table20(scenarios, n_runs);

%% ----------------------------------------------------------------
%  STEP 6 — SAVE TO XLSX (Table-20 layout + raw per-trial sheet)
%% ----------------------------------------------------------------

save_table20_xlsx(output_xlsx, scenarios, ...
    {R1, R2}, n_runs, nadir_g_33, ideal_g_33, nadir_g_69, ideal_g_69);

fprintf('\nSaved to: %s\n', output_xlsx);


%% ================================================================
%  FUNCTIONS — DATA LOADING
%% ================================================================

function trials = load_trials(folder, tpl, n_runs, sheet, pen)
    trials = cell(n_runs, 1);
    for i = 1:n_runs
        raw = xlsread(fullfile(folder, sprintf(tpl, i)), sheet);
        raw = raw(~any(isnan(raw),2) & ~any(raw>=pen,2), :);
        trials{i} = pareto_filter(raw);
        fprintf('  %s trial %2d: %d pts\n', tpl, i, size(trials{i},1));
    end
end

function ES = load_ES(npz_path)
    data = py.numpy.load(npz_path, pyargs('allow_pickle',true));
    ES   = double(data{'obj_all'});
    ES   = ES(~any(isnan(ES),2), :);
    fprintf('  ES loaded: %d solutions\n', size(ES,1));
end

function all_data = pool_all(trial_groups, ES)
    % ES is optional — pass [] or omit entirely when not available
    % (e.g. 69-bus where exhaustive search is infeasible)
    if nargin < 2 || isempty(ES)
        all_data = [];
    else
        all_data = ES;
    end
    for g = 1:numel(trial_groups)
        for i = 1:numel(trial_groups{g})
            all_data = [all_data; trial_groups{g}{i}]; %#ok<AGROW>
        end
    end
    if isempty(all_data)
        error('pool_all: no data found — all trial groups are empty and ES was not provided.');
    end
end

function PF = pareto_filter(F)
    if isempty(F), PF = F; return; end
    F = F(~any(isnan(F),2),:);
    nd = arrayfun(@(i) ~any(all(F<=F(i,:),2) & any(F<F(i,:),2)), 1:size(F,1));
    PF = F(nd, :);
end

function PF = pareto_filter_large(F)
    % Fast version for large datasets (ES with 1000s of solutions).
    % Identical result to pareto_filter, just vectorised inner check.
    F = F(~any(isnan(F),2), :);
    n = size(F,1);
    if n == 0, PF = F; return; end
    [~, ord] = sortrows(F, 1:size(F,2));
    F    = F(ord,:);
    keep = true(n,1);
    for i = 1:n
        if ~keep(i), continue; end
        later = (i+1):n;
        if isempty(later), break; end
        dom = all(F(later,:) >= F(i,:), 2) & any(F(later,:) > F(i,:), 2);
        keep(later(dom)) = false;
    end
    PF = F(keep,:);
end

%% ================================================================
%  FUNCTIONS — METRICS
%% ================================================================

function [stats, raw] = trial_metrics(trials, nadir, ideal, PF_ref)
    n      = numel(trials);
    fields = {'HV','SP','DIV','HRS'};
    for f = fields, raw.(f{1}) = zeros(n,1); end

    range_     = nadir - ideal;
    range_(range_==0) = 1;
    ref_norm   = max(0, min(1, (PF_ref-ideal)./range_));

    for i = 1:n
        PF   = trials{i};
        PFn  = max(0, min(1, (PF-ideal)./range_));
        raw.HV(i)  = hv_mc(PFn, 500000);
        raw.SP(i)  = spacing(PFn);
        raw.DIV(i) = diversity(PFn);
        raw.HRS(i) = hrs(PFn, ref_norm);
    end
    for f = fields
        stats.(f{1}).mean = mean(raw.(f{1}));
        stats.(f{1}).std  = std(raw.(f{1}));
        stats.(f{1}).min  = min(raw.(f{1}));
        stats.(f{1}).max  = max(raw.(f{1}));
    end
end

function HV = hv_mc(PFn, ns)
    rng(42,'twister');
    smp  = rand(ns, size(PFn,2));
    dom  = false(ns,1);
    for k = 1:size(PFn,1)
        dom = dom | all(bsxfun(@le, PFn(k,:), smp), 2);
    end
    HV = sum(dom)/ns;
end

function SP = spacing(PFn)
    n = size(PFn,1);
    if n<2, SP=0; return; end
    d = zeros(n,1);
    for i = 1:n
        dv = sqrt(sum((PFn-PFn(i,:)).^2,2));
        dv(i) = Inf;
        d(i) = min(dv);
    end
    SP = std(d);
end

function DIV = diversity(PFn)
    DIV = mean(max(PFn,[],1) - min(PFn,[],1));
end

function HRS = hrs(PFn, ref_norm)
    nr = size(ref_norm,1);
    if nr==0, HRS=NaN; return; end
    gap = arrayfun(@(i) min(sqrt(sum((PFn-ref_norm(i,:)).^2,2))), 1:nr)';
    mx = 0;
    for i=1:nr, for j=i+1:nr
        mx = max(mx, norm(ref_norm(i,:)-ref_norm(j,:)));
    end, end
    if mx==0, mx=1; end
    HRS = mean(gap)/mx;
end

%% ================================================================
%  FUNCTIONS — DISPLAY  (Table 20 style)
%% ================================================================

function print_table20(scenarios, n_runs)
    metrics = {'HV','SP','DIV','HRS'};
    better  = {'↑','↓','↑','↓'};

    W = 82;
    fprintf('\n%s\n', repmat('=',1,W));
    fprintf('  Pareto front quality metrics — mean ± std over %d independent trials\n', n_runs);
    fprintf('  Normalisation: shared global [ideal, nadir] box across all scenarios\n');
    fprintf('%s\n', repmat('=',1,W));
    fprintf('  %-28s | %-6s | %-18s | %-18s | %-18s | Dir\n', ...
            'Scenario','Metric','MOMSA','MOLA','MOPSO');
    fprintf('  %-28s | %-6s | %-18s | %-18s | %-18s |\n', ...
            '','','(mean ± std)','(mean ± std)','(mean ± std)');
    fprintf('  %s\n', repmat('-',1,W-2));

    for s = 1:size(scenarios,1)
        label = scenarios{s,1};
        S     = scenarios{s,2};
        for k = 1:numel(metrics)
            mn  = metrics{k};
            fM  = sprintf('%.4f ± %.4f', S.MOMSA.(mn).mean, S.MOMSA.(mn).std);
            fL  = sprintf('%.4f ± %.4f', S.MOLA.(mn).mean,  S.MOLA.(mn).std);
            fP  = sprintf('%.4f ± %.4f', S.MOPSO.(mn).mean, S.MOPSO.(mn).std);
            % Only print scenario label on the first metric row
            if k==1
                lbl = label;
            else
                lbl = '';
            end
            fprintf('  %-28s | %-6s | %-18s | %-18s | %-18s | %s\n', ...
                    lbl, mn, fM, fL, fP, better{k});
        end
        if s < size(scenarios,1)
            fprintf('  %s\n', repmat('-',1,W-2));   % separator between scenarios
        end
    end
    fprintf('%s\n', repmat('=',1,W));
end

%% ================================================================
%  FUNCTIONS — SAVE (Table-20 layout to xlsx)
%% ================================================================

function save_table20_xlsx(fpath, scenarios, raw_groups, n_runs, nadir, ideal, nadir2, ideal2)
    metrics = {'HV','SP','DIV','HRS'};
    algos   = {'MOMSA','MOLA','MOPSO'};

    % ---- Sheet 1: Table 20 layout (mean ± std as text) ----
    rows = {};
    rows(end+1,:) = {'Scenario','Metric', ...
                     'MOMSA mean','MOMSA std', ...
                     'MOLA mean', 'MOLA std', ...
                     'MOPSO mean','MOPSO std', ...
                     'Better (direction)'};
    dir_map = struct('HV','higher','SP','lower','DIV','higher','HRS','lower');
    for s = 1:size(scenarios,1)
        S = scenarios{s,2};
        for k = 1:numel(metrics)
            mn = metrics{k};
            rows(end+1,:) = { ...
                scenarios{s,1}, mn, ...
                S.MOMSA.(mn).mean, S.MOMSA.(mn).std, ...
                S.MOLA.(mn).mean,  S.MOLA.(mn).std, ...
                S.MOPSO.(mn).mean, S.MOPSO.(mn).std, ...
                dir_map.(mn) };
        end
    end
    T_main = cell2table(rows(2:end,:), 'VariableNames', rows(1,:));
    writetable(T_main, fpath, 'Sheet', 'Table20_Summary');

    % ---- Sheet 2: Raw per-trial data ----
    raw_rows = {'Scenario','Algorithm','Trial','HV','SP','DIV','HRS'};
    raw_data = {};
    for s = 1:size(scenarios,1)
        R = raw_groups{s};
        for a = 1:numel(algos)
            alg = algos{a};
            rv  = R.(alg);
            for i = 1:n_runs
                raw_data(end+1,:) = { ...
                    scenarios{s,1}, alg, i, ...
                    rv.HV(i), rv.SP(i), rv.DIV(i), rv.HRS(i) }; %#ok<AGROW>
            end
        end
    end
    T_raw = cell2table(raw_data, 'VariableNames', raw_rows);
    writetable(T_raw, fpath, 'Sheet', 'RawPerTrial');

    % ---- Sheet 3: Normalisation reference ----
    obj_names = {'Ploss_kW','CES_invest','Elec_cost'}';
    T_ref = table(obj_names, nadir', ideal', nadir'-ideal', ...
                  'VariableNames',{'Objective','Nadir','Ideal','Range'});
    writetable(T_ref, fpath, 'Sheet', 'NadirIdeal_Sce1');

        % ---- Sheet 4: Normalisation reference ----
    obj_names = {'Ploss_kW','CES_invest','Elec_cost'}';
    T_ref = table(obj_names, nadir2', ideal2', nadir2'-ideal2', ...
                  'VariableNames',{'Objective','Nadir','Ideal','Range'});
    writetable(T_ref, fpath, 'Sheet', 'NadirIdeal_Sce2');
end