%% ================================================================
%  PARETO METRICS PIPELINE — CONSOLIDATED FILE VERSION
%
%  Input: one xlsx per algorithm, Sheet2 = all fitness values
%         stacked from 10 trials (no trial separator needed)
%         columns = [power_loss_kW, CES_investment_RM, elec_cost_RM]
%
%  Output: SP, DIV, HV, HRS printed for each algo × scenario
%% ================================================================

clear; clc;

%% ----------------------------------------------------------------
%  STEP 1 — SET YOUR FILE PATHS
%  Edit these 6 paths to match your actual file locations
%% ----------------------------------------------------------------

% Scenario 1 — 33-bus consolidated files
% Same as "D:\Jacky\Data Output\CES size and loc\33bus_ptdf"
file_MOMSA_33 = 'D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Result\Data\CorrectScoreUnrank\MOMSA unrank.xlsx';
file_MOLA_33  = 'D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Result\Data\CorrectScoreUnrank\MOLA unrank.xlsx';
file_MOPSO_33 = 'D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Result\Data\CorrectScoreUnrank\MOPSO 70 unrank.xlsx';

% Scenario 2 — 33-bus consolidated files (filtered by R-method)
file_MOMSA_33r = 'D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Result\Data\CorrectScoreRank\MOMSA unrank.xlsx';
file_MOLA_33r  = 'D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Result\Data\CorrectScoreRank\MOLA unrank.xlsx';
file_MOPSO_33r = 'D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Result\Data\CorrectScoreRank\MOPSO 70 unrank.xlsx';


%% ----------------------------------------------------------------
%  STEP 2 — LOAD SHEET2 (FITNESS) AND FILTER TO NON-DOMINATED
%% ----------------------------------------------------------------

fprintf('Loading Scenario 1 (33-bus)...\n');
PF_MOMSA_33 = pareto_filter(xlsread(file_MOMSA_33, 'Sheet2'));
PF_MOLA_33  = pareto_filter(xlsread(file_MOLA_33,  'Sheet2'));
PF_MOPSO_33 = pareto_filter(xlsread(file_MOPSO_33, 'Sheet2'));

% fprintf('Loading Scenario 2 (33r-bus)...\n');
fprintf('Loading Scenario 2 (33-bus but R-method filtered)...\n');
PF_MOMSA_33r = pareto_filter(xlsread(file_MOMSA_33r, 'Sheet2'));
PF_MOLA_33r  = pareto_filter(xlsread(file_MOLA_33r,  'Sheet2'));
PF_MOPSO_33r = pareto_filter(xlsread(file_MOPSO_33r, 'Sheet2'));

%% ----------------------------------------------------------------
%  STEP 3 — BUILD SHARED NADIR AND REFERENCE FRONT PER SCENARIO
%
%  NADIR:
%    Must be built from ALL solutions including the reference front,
%    so HV normalisation is consistent across all algorithms.
%    nadir = worst value per objective across algos + ES + 10% margin.
%
%  PF_ref (REFERENCE FRONT):
%    Scenario 1 — use exhaustive search front (true optimal).
%                 Nadir also includes ES values.
%    Scenario 2 - same as above but algorithms solutions are filtered by R-method first.
%    Scenario 3 — exhaustive search infeasible; use merged
%                 non-dominated front from all 3 algos.
%                 HRS is still valid as a relative comparison.
%% ----------------------------------------------------------------
 
% --- Scenario 1 — load exhaustive search reference front ---
ES_raw_33 = load_exhaustive_33();   % see helper at bottom — edit path there
PF_ref_33 = pareto_filter(ES_raw_33);
 
% Nadir: worst across ALL algo solutions AND exhaustive search + 10%
all_33   = [PF_MOMSA_33; PF_MOLA_33; PF_MOPSO_33; ES_raw_33];
nadir_33 = max(all_33, [], 1) * 1.10;
 
% --- Scenario 2 — load exhaustive search reference front with R-method ---
all_33r   = [PF_MOMSA_33r; PF_MOLA_33r; PF_MOPSO_33r; ES_raw_33];
nadir_33r = max(all_33r, [], 1) * 1.10;
 
% same reference front as Scenario 1, just filtered solutions for nadir
PF_ref_33r = PF_ref_33;  

% --- Scenario 3 — merged non-dominated front (no exhaustive available) ---
% all_69   = [PF_MOMSA_69; PF_MOLA_69; PF_MOPSO_69];
% NOTE: PF_ref_69 is the merged front — HRS here measures how well each
% algo covers the best-known trade-off space, not a true optimum.
% This is standard practice when exhaustive search is infeasible.
 
 
%% ----------------------------------------------------------------
%  STEP 4 — COMPUTE METRICS
%% ----------------------------------------------------------------
 
fprintf('Computing metrics...\n');
 
m_MOMSA_33 = compute_pareto_metrics(PF_MOMSA_33, nadir_33, PF_ref_33);
m_MOLA_33  = compute_pareto_metrics(PF_MOLA_33,  nadir_33, PF_ref_33);
m_MOPSO_33 = compute_pareto_metrics(PF_MOPSO_33, nadir_33, PF_ref_33);
 
m_MOMSA_33r = compute_pareto_metrics(PF_MOMSA_33r, nadir_33r, PF_ref_33r);
m_MOLA_33r  = compute_pareto_metrics(PF_MOLA_33r,  nadir_33r, PF_ref_33r);
m_MOPSO_33r = compute_pareto_metrics(PF_MOPSO_33r, nadir_33r, PF_ref_33r);
 
 
%% ----------------------------------------------------------------
%  STEP 5 — PRINT RESULTS TABLE
%% ----------------------------------------------------------------
 
print_table(m_MOMSA_33, m_MOLA_33, m_MOPSO_33, 'Scenario 1 — IEEE 33-bus');
print_table(m_MOMSA_33r, m_MOLA_33r, m_MOPSO_33r, 'Scenario 2 — IEEE 33-bus (R-method filtered)');
 
 
%% ================================================================
%  FUNCTIONS
%% ================================================================
 
function metrics = compute_pareto_metrics(PF, nadir, PF_ref)
    ideal   = min(PF, [], 1);
    range_  = nadir - ideal;
    range_(range_ == 0) = 1;
    PF_norm = (PF - ideal) ./ range_;
    PF_norm = max(0, min(1, PF_norm));
 
    metrics.HV  = compute_hypervolume(PF_norm);
    metrics.SP  = compute_spacing(PF_norm);
    metrics.DIV = compute_diversity(PF_norm);
 
    PF_ref_norm = (PF_ref - ideal) ./ range_;
    PF_ref_norm = max(0, min(1, PF_ref_norm));
    metrics.HRS = compute_HRS(PF_norm, PF_ref_norm);
end
 
function HV = compute_hypervolume(PF_norm)
    rng(42, 'twister');
    samples   = rand(500000, 3);
    dominated = false(500000, 1);
    for k = 1:size(PF_norm, 1)
        dominated = dominated | all(bsxfun(@le, PF_norm(k,:), samples), 2);
    end
    HV = sum(dominated) / 500000;
end
 
function SP = compute_spacing(PF_norm)
    n = size(PF_norm, 1);
    if n < 2, SP = 0; return; end
    d = zeros(n, 1);
    for i = 1:n
        dists = sqrt(sum((PF_norm - PF_norm(i,:)).^2, 2));
        dists(i) = Inf;
        d(i) = min(dists);
    end
    SP = std(d);
end
 
function DIV = compute_diversity(PF_norm)
    DIV = mean(max(PF_norm,[],1) - min(PF_norm,[],1));
end
 
function HRS = compute_HRS(PF_norm, PF_ref_norm)
    n_ref = size(PF_ref_norm, 1);
    if n_ref == 0, HRS = NaN; return; end
    gap = zeros(n_ref, 1);
    for i = 1:n_ref
        dists = sqrt(sum((PF_norm - PF_ref_norm(i,:)).^2, 2));
        gap(i) = min(dists);
    end
    max_dist = 0;
    for i = 1:n_ref
        for j = i+1:n_ref
            d = norm(PF_ref_norm(i,:) - PF_ref_norm(j,:));
            if d > max_dist, max_dist = d; end
        end
    end
    if max_dist == 0, max_dist = 1; end
    HRS = mean(gap) / max_dist;
end
 
function PF = pareto_filter(F)
    % Remove NaN rows first (safety for Excel imports)
    F = F(~any(isnan(F), 2), :);
    n = size(F, 1);
    dominated = false(n, 1);
    for i = 1:n
        for j = 1:n
            if i ~= j && all(F(j,:) <= F(i,:)) && any(F(j,:) < F(i,:))
                dominated(i) = true;
                break;
            end
        end
    end
    PF = F(~dominated, :);
end
 
function ES = load_exhaustive_33()
    % Loads exhaustive search objective values for 33-bus.
    % Returns (n x 3) matrix: [power_loss, CES_invest, elec_cost]
    %
    % Edit the path below to your actual exhaustive search file.
    % Your file is a .npz — load via Python bridge:
 
    npz_path = 'D:\Jacky\MATLAB\OptimalPlacement\Result and analysis\Result\Benchmark - raw collection\benchmark_all.npz';
    data = py.numpy.load(npz_path, pyargs('allow_pickle', true));
    ES   = double(data{'obj_all'});
 
    % Safety: remove NaN rows
    ES = ES(~any(isnan(ES), 2), :);
 
    fprintf('  Exhaustive search loaded: %d solutions\n', size(ES, 1));
end
 
function print_table(m_MOMSA, m_MOLA, m_MOPSO, title_str)
    fprintf('\n%s\n', repmat('=', 1, 72));
    fprintf('  %s\n', title_str);
    fprintf('%s\n', repmat('=', 1, 72));
    fprintf('  %-6s | %-14s | %-14s | %-14s | Better\n', ...
            'Metric', 'MOMSA', 'MOLA', 'MOPSO');
    fprintf('  %s\n', repmat('-', 1, 68));
 
    metrics = {'HV', 'SP', 'DIV', 'HRS'};
    better  = {'higher', 'lower', 'higher', 'lower'};
 
    for k = 1:length(metrics)
        mn = metrics{k};
        v1 = m_MOMSA.(mn);
        v2 = m_MOLA.(mn);
        v3 = m_MOPSO.(mn);
        fprintf('  %-6s | %-14.4f | %-14.4f | %-14.4f | %s\n', ...
                mn, v1, v2, v3, better{k});
    end
    fprintf('%s\n', repmat('-', 1, 72));
end