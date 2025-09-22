%% Multi-objective Mantis Search Algorithm (MOMSA): A Novel Approach for Engineering Design Problems and Validation
%  Developed in MATLAB R2019a
%% Author and programmer: Mohjameel (E-mail:  moh.jameel@su.edu.ye; Mohjameel555@gmail.com)
function [f, gen_sol, all_evals, pop_log, pool_log] = MOMSA(dim,M,lb,ub,SearchAgents_no,Max_iter,ishow)
fobj = @runP2P;

%% ------------------- Controlling parameters -------------------------- %%
p   = 0.5;    % Probability to exchange between exploration/exploitation
A   = 1.0;    % Length of archive (here used as max rows placeholder)
a   = 0.5;    % Probability of the strike’s failure
P   = 2;      % Recycling factor
alp = 6;      % Gravitational acceleration rate of strike
Pc  = 0.2;    % Percentage of sexual cannibalism

archive   = [[]];
Positions = zeros(SearchAgents_no,dim);
Sol       = zeros(SearchAgents_no,dim);

%% ------------------- NEW: Global logging containers ------------------ %%
max_rows = Max_iter * SearchAgents_no * 2 + SearchAgents_no;  % rough upper bound
all_X   = nan(max_rows, dim);    % decision vars
all_F   = nan(max_rows, M);      % objectives
all_gen = nan(max_rows, 1);      % generation index (0 for init)
all_idx = nan(max_rows, 1);      % agent index within gen
log_ptr = 0;

pop_log  = cell(Max_iter,1);     % survivors per generation (new_Sol)
pool_log = cell(Max_iter,1);     % combined pool per generation (Sort_bats)

%% ------------------- Initialize the population ----------------------- %%
for i = 1:SearchAgents_no
    Positions(i,:) = lb + (ub-lb).*rand(1,dim);
    f(i,1:M)       = fobj(Positions(i,:), M);

    % Log initial population evaluation
    log_ptr = log_ptr + 1;
    all_X(log_ptr,:)   = Positions(i,:);
    all_F(log_ptr,:)   = f(i,1:M);
    all_gen(log_ptr,1) = 0;     % generation 0 = initialization
    all_idx(log_ptr,1) = i;
end

new_Sol = [Positions f];
new_Sol = solutions_sorting(new_Sol, M, dim);
gen_sol = zeros(Max_iter, M);

%% ------------------- Main loop of MOMSA ------------------------------ %%
for t = 1:Max_iter
    RL = 0.05 * levy(SearchAgents_no,dim,1.5);   % Levy random number vector
    a2 = -1 + -1*(t/Max_iter);                   % a2 decreases from -1 to -2

    for i = 1:SearchAgents_no
        l    = (a2-1)*rand + 1;
        best = (new_Sol(i,1:dim) - new_Sol(1,1:dim));

        % Archive update
        if (size(archive,1) < A)
            archive = best;
        else
            archive(randi(A),:) = best;
        end

        bA = archive(randi(size(archive,1)),1:dim);
        a1 = randi(SearchAgents_no);
        b  = randi(SearchAgents_no);
        c  = randi(SearchAgents_no);
        while a1==i || a1==b || c==b || c==a1 || c==i || b==i
            a1 = randi(SearchAgents_no);
            b  = randi(SearchAgents_no);
            c  = randi(SearchAgents_no);
        end

        r1 = rand(); r2 = rand(); r3 = rand(); t2 = randn;
        m  = 1 - t/Max_iter;

        if (rand < p)   % ---- Exploration
            F = 1 - rem(t,Max_iter/P)/(Max_iter/P);
            U = rand(1,dim) > rand(1,dim);
            for j = 1:size(Positions,2)
                if r1 < F    % Pursuers
                    if r2 < r3
                        Steps = (Positions(i,j)-Positions(a1,j))*RL(i,j) + abs(t2)*U(j)*(Positions(a1,j)-Positions(b,j));
                        Positions(i,j) = Positions(i,j) + Steps;
                    else
                        y = Positions(a1,j) + rand.*(Positions(b,j)-Positions(c,j));
                        if rand <= rand
                            Positions(i,j) = y;
                        end
                    end
                else          % Spearers
                    if r2 < r3
                        alpha = cos(pi*rand)*m;
                        Positions(i,j) = Positions(i,j) + alpha*(bA(j)-Positions(b,j));
                    else
                        Positions(i,j) = (bA(j)) + (r2*2-1)*m*(lb(j)+rand*(ub(j)-lb(j)));
                    end
                end
            end
        else             % ---- Exploitation
            Best_P = (new_Sol(i,1:dim) - new_Sol(1,1:dim));
            for j = 1:size(Positions,2)
                if rand < r2
                    Positions(i,j) = Positions(i,j) + r1*(Positions(a1,j)-Positions(b,j));
                else
                    vs  = 1/(1+exp(alp*l));
                    dsi = Best_P(j)-Positions(i,j);
                    Positions(i,j) = (Positions(i,j)+Best_P(j))/2.0 + vs*dsi;
                    Pf = a*(1 - t/Max_iter);
                    if r2 < Pf
                        Positions(i,j) = Positions(i,j) + exp(2*l)*cos(2*l*pi)*abs(Positions(i,j)-bA(j)) + (rand*2-1)*(ub(j)-lb(j));
                    end
                end
            end
        end

        % Bound handling
        for j = 1:size(Positions,2)
            if  Positions(i,j) > ub(j) || Positions(i,j) < lb(j)
                Positions(i,j) = lb(j) + rand*(ub(j)-lb(j));
            end
        end

        % Copy to Sol and bound-check
        Sol(i,1:dim) = Positions(i,1:dim);
        for j = 1:size(Positions,2)
            if  Sol(i,j) > ub(j) || Sol(i,j) < lb(j)
                Sol(i,j) = lb(j) + rand*(ub(j)-lb(j));
            end
        end

        % ---- Evaluate & LOG this candidate
        Sol(i, dim+1:M+dim) = fobj(Sol(i,1:dim), M);

        log_ptr = log_ptr + 1;
        all_X(log_ptr,:)   = Sol(i,1:dim);
        all_F(log_ptr,:)   = Sol(i,dim+1:dim+M);
        all_gen(log_ptr,1) = t;
        all_idx(log_ptr,1) = i;

        % Elitism for first individual in new_Sol
        if all(Sol(i,dim+1:dim+M) <= new_Sol(1,dim+1:dim+M))
            new_Sol(1,1:(dim+M)) = Sol(i,1:(dim+M));
        end

        Positions(i,1:dim) = new_Sol(i,1:dim);
    end

    % ---- Pc phase
    if rand < Pc
        for i = 1:SearchAgents_no
            l = (a2-1)*rand + 1;
            r1 = rand(); r3 = rand();

            if rand < rand
                U = rand(1,dim) > rand(1,dim);
                for j = 1:size(Positions,2)
                    Positions(i,j) = Positions(i,j)*U(j) + (Positions(1,1) + -rand*(-Positions(1,1)+Positions(i,j))).*(1-U(j));
                end
            else
                a1 = randi(SearchAgents_no);
                while a1==i
                    a1 = randi(SearchAgents_no);
                end
                Pt = r2*(1 - t/Max_iter);
                for j = 1:size(Positions,2)
                    if r1 < Pt
                        Positions(i,j) = Positions(i,j) + r3*(Positions(i,j)-Positions(a1,j));
                        Positions(i,j) = Positions(a1,j) * cos(l*pi*2) * m;
                    end
                end
            end

            % Bound handling
            Sol(i,1:dim) = Positions(i,1:dim);
            for j = 1:size(Positions,2)
                if  Sol(i,j) > ub(j) || Sol(i,j) < lb(j)
                    Sol(i,j) = lb(j) + rand*(ub(j)-lb(j));
                end
            end

            % ---- Evaluate & LOG this candidate (Pc phase)
            Sol(i, dim+1:M+dim) = fobj(Sol(i,1:dim), M);

            log_ptr = log_ptr + 1;
            all_X(log_ptr,:)   = Sol(i,1:dim);
            all_F(log_ptr,:)   = Sol(i,dim+1:dim+M);
            all_gen(log_ptr,1) = t;
            all_idx(log_ptr,1) = i;

            if all(Sol(i,dim+1:dim+M) <= new_Sol(1,dim+1:dim+M))
                new_Sol(1,1:(dim+M)) = Sol(i,1:(dim+M));
            end
        end
    end

    % ---- Combine old + new then sort & select
    Sort_bats(1:SearchAgents_no,:) = new_Sol;
    Sort_bats((SearchAgents_no+1):(2*SearchAgents_no), 1:M+dim) = Sol;

    Sorted_bats = solutions_sorting(Sort_bats, M, dim);
    new_Sol     = cleanup_batspop(Sorted_bats, M, dim, SearchAgents_no);

    % ---- Log pools for this generation
    pool_log{t} = Sorted_bats;                 % combined pool (2N)
    pop_log{t}  = new_Sol;                     % survivors (N)

    if rem(t, ishow) == 0
        fprintf('Generation: %d\n', t);
    end

    gen_sol(t,:) = new_Sol(1, dim+1:dim+M);    % leader objective trace
end

%% ------------------- Outputs & save logs ----------------------------- %%
f = new_Sol;                                   % final survivors (Pareto-ish)

% Trim prealloc
all_X    = all_X(1:log_ptr,:);
all_F    = all_F(1:log_ptr,:);
all_gen  = all_gen(1:log_ptr,:);
all_idx  = all_idx(1:log_ptr,:);

% Pack all evaluations
all_evals = [all_gen all_idx all_X all_F];     % [gen, agent, x..., f...]

outFile = 'D:\Jacky\Data Output\Battery ROI\momsa_full_log.xlsx';

% one sheet per variable, sheet name = variable name
writematrix(all_X,   outFile, 'Sheet', 'all_X');
writematrix(all_F,   outFile, 'Sheet', 'all_F');
writematrix(all_gen, outFile, 'Sheet', 'all_gen');
writematrix(all_idx, outFile, 'Sheet', 'all_idx');


end
