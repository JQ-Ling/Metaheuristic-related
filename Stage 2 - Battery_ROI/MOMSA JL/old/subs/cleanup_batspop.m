%% Clean up the populations (both old and new) to give a new population
% This cleanup here is similar to the Non-dominated Sorting Genetic
% Algorithm (NSGA-II) by K. Deb et al. (2002), which can be applied to 
% any cleanup of 2*npop solutions to form a set of npop solutions.
function new_bats = cleanup_batspop(bats, m, ndim, npop)
% The input population to this part has twice (ntwice) of the needed 
% population size (npop). Thus, selection is done based on ranking and 
% crowding distances, calculated from the non-dominated sorting
ntwice= size(bats,1);
% Ranking is stored in column Krank
Krank=m+ndim+1;
% Sort the population of size 2*npop according to their ranks
[~,Index] = sort(bats(:,Krank)); sorted_bats=bats(Index,:);
% Get the maximum rank among the population
RankMax=max(bats(:,Krank)); 

%% Main loop for selecting solutions based on ranks and crowding distances
K = 0;  % Initialization for the rank counter 
% Loop over all ranks in the population
for i =1:RankMax,  
    % Obtain the current rank i from sorted solutions
    RankSol = max(find(sorted_bats(:, Krank) == i));
    % In the new bats/solutions, there can be npop solutions to fill
    if RankSol<npop,
       new_bats(K+1:RankSol,:)=sorted_bats(K+1:RankSol,:);
    end 
    % If the population after addition is large than npop, re-arrangement
    % or selection is carried out
    if RankSol>=npop
        % Sort/Select the solutions with the current rank 
        candidate_bats = sorted_bats(K + 1 : RankSol, :);
        [~,tmp_Rank]=sort(candidate_bats(:,Krank+1),'descend');
        % Fill the rest (npop-K) bats/solutions up to npop solutions 
        for j = 1:(npop-K), 
            new_bats(K+j,:)=candidate_bats(tmp_Rank(j),:);
        end
    end
    % Record and update the current rank after adding new bats 
    K = RankSol;
end
end