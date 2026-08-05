function [top5_loc,finalRank] = R_method(Pareto_font,rank_obj)
    % Get the number of columns
    [numSol, numVar] = size(Pareto_font);
    
    % Initialize the rank matrix
    rankVar = zeros(size(Pareto_font));
    
    % Rank each column independently
    for var = 1:numVar
        rankVar(:, var) = tiedrank(Pareto_font(:, var));
    end

    % Prepare the weight set
    weightsVar_set = [];
    denom_sol = 0;
    numRank = 1:numSol;
    for j = 1:numSol
        denom_sol = denom_sol + 1/sum(1 ./ numRank(1:j));
    end
    for j = 1:numSol
        weightsVar_set = [weightsVar_set, (1/sum(1 ./ numRank(1:j))) / denom_sol];
    end

    weightsObj_set = [];
    denom_obj = 0;
    numRankObj = 1:numVar;
    for j = 1:numVar
        denom_obj = denom_obj + 1/sum(1 ./ numRankObj(1:j));
    end
    for j = 1:numVar
        weightsObj_set = [weightsObj_set, (1/sum(1 ./ numRankObj(1:j))) / denom_obj];
    end
    disp(weightsObj_set)
    % Assign weight based on rank
    weightsVar = zeros(size(Pareto_font));
    for i = 1:numSol
        for j = 1:numVar
            weightsVar(i,j) = weightsVar_set(int32(rankVar(i,j)));
        end
    end
    weightsObj = zeros(numVar,1);
    for j = 1:numVar
        if mod(rank_obj(j), 1) ~= 0 % not generalize only set for 1.5
            weightsObj(j) = mean(weightsObj_set(1) + weightsObj_set(2));
        else
            weightsObj(j) = weightsObj_set(int32(rank_obj(j)));
        end
    end

    % Composite score and final rank of solution
    composite_score = weightsVar * weightsObj;
    finalRank = tiedrank(composite_score);
    [~, sortedIndices] = sort(finalRank, 'ascend');
    top5_loc = sortedIndices(1:5);
end