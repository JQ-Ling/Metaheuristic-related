%% Example: Cycle counting from SOC using rainflow

% Example SOC profile (raw, maybe 20%–80% range)
soc_raw = [60 62 65 70 80 75 70 65 60 55 50 45 ...
           50 55 60 65 70 75 80 78 74 70 65 60 ...
           55 50 45 40 45 50 55 60 65 70 75 78 ...
           74 70 65 60 55 50 45 40 42 44 47 50];

%% Step 1: Normalize SOC to 0–1
soc_norm = (soc_raw - min(soc_raw)) / (max(soc_raw) - min(soc_raw));

%% Step 2: Apply rainflow
rf = rainflow(soc_norm, 48);

DODs   = rf(:,2);   % depth of discharge fractions (0–1)
counts = rf(:,1);   % 0.5 = half cycle, 1 = full cycle

%% Step 3: Compute Equivalent Full Cycles
EFCs = sum(DODs .* counts);

%% Step 4: Report
fprintf('SOC min = %.2f, max = %.2f\n', min(soc_norm), max(soc_norm));
fprintf('Total equivalent full cycles = %.3f\n', EFCs);

% Optional: per day cost proxy (e.g. cost_per_cycle = 1 unit)
cost_per_cycle = 1;   % arbitrary units
deg_cost_day = EFCs * cost_per_cycle;
fprintf('Degradation cost proxy = %.3f units\n', deg_cost_day);
