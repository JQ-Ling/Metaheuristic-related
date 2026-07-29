%% ================================================================
%  PARETO FRONT PIPELINE — CONCATENATE RESULTS FROM MULTIPLE TRIALS
%  Input: 10 xlsx files per algorithm, each containing:
%         Sheet1 = POS (decision variables)
%         Sheet2 = Fitness (objectives)
%  Output: a single Excel file with all POS and fitness values
%
%  Note: Re-run required for multiple algorithms (MOPSO, MOLA, MOMSA) and scenarios (33-bus, 69-bus, PTDF, LDF)
%% ================================================================
clear all; close all; clc;

% Add the path to the standardized functions
addpath('D:\Jacky\MATLAB\Standardized_functions');
bus_sys = 69;
pf_model = "LDF"; % "ptdf" or "LDF"

all_MOO = ['MOPSO'; 'MOLA '; 'MOMSA'];
% all_MOO = ['MOMSA'];

for MOO_idx = 1:size(all_MOO,1)
    % Initialize empty arrays to store concatenated data
    allPOS = [];
    allFitness = [];
    allPOS_top5 = [];
    allFitness_top5 = [];

    % Scenario and algorithm
    MOO = all_MOO(MOO_idx,:);
    if MOO_idx == 2
        MOO = 'MOLA';
    end

    % Loop through each file (from 1 to 10)
    for i = 1:10
        % Construct the filename based on your pattern
        filename = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\raw\", MOO, " result ", num2str(i), ".xlsx");

        % Try to read the file
        try
            % fprintf('Reading file: %s\n', filename);
            
            % Read data from Sheet1 (POS) and Sheet2 (Fitness)
            [POS, ~, ~] = xlsread(filename, 'Sheet1');
            [Fitness, ~, ~] = xlsread(filename, 'Sheet2');
            
            [top5_loc,~,~] = R_method(Fitness,[1 2.5 2.5]);

            % Concatenate data
            if isempty(allPOS)
                allPOS = POS;
                allFitness = Fitness;
                allPOS_top5 = POS(top5_loc,:);
                allFitness_top5 = Fitness(top5_loc,:);
            else
                % Concatenate vertically - add rows
                allPOS = [allPOS; POS];
                allFitness = [allFitness; Fitness];
                allPOS_top5 = [allPOS_top5; POS(top5_loc,:)];
                allFitness_top5 = [allFitness_top5; Fitness(top5_loc,:)];
            end
            
            fprintf('Successfully read data from file %d\n', i);
        catch e
            fprintf('Error reading file %d: %s\n', i, e.message);
        end
    end

    % Process the data
    if bus_sys == 69 
        allPOS(:,10:17) = allPOS(:,10:17) + 5;
        allPOS_top5(:,10:17) = allPOS_top5(:,10:17) + 5;
    else
        allPOS(:,6:9) = allPOS(:,6:9) + 5;
        allPOS_top5(:,6:9) = allPOS_top5(:,6:9) + 5;
    end

    [allPOS, ~] = processed_matrix(allPOS);
    trial_m = MOO_idx * ones(size(allPOS,1),1);
    [allPOS_top5, ~] = processed_matrix(allPOS_top5);
    trial_m_top5 = MOO_idx * ones(size(allPOS_top5,1),1);

    % Save the concatenated data to a new Excel file
    output_filename = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\", MOO, "_unrank.xlsx");
    filename_test = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\", MOO, "_unrank_top 5.xlsx");

    ranked_raw_file = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\", MOO, ".xlsx");
    ranked_top5_file = strcat("D:\Jacky\Data Output\CES size and loc\", string(bus_sys), "bus_", pf_model, "\", MOO, "_top 5.xlsx");

    [rank5,~,score] = R_method(allFitness,[1 2.5 2.5]);
    FinalFitness = allFitness(rank5,:);
    FinalPOS = allPOS(rank5,:);
    FinalTrial = trial_m(rank5,:);
    FinalScore = score(rank5,:);

    [rank5_top5,~,score_top5] = R_method(allFitness_top5,[1 2.5 2.5]);
    FinalFitness_top5 = allFitness_top5(rank5_top5,:);
    FinalPOS_top5 = allPOS_top5(rank5_top5,:);
    FinalTrial_top5 = trial_m_top5(rank5_top5,:);
    FinalScore_top5 = score_top5(rank5_top5,:);

    % Write to the output file
    try
        xlswrite(output_filename, allPOS, 'Sheet1');
        xlswrite(output_filename, allFitness, 'Sheet2');
        xlswrite(output_filename, trial_m, 'Sheet3');
        xlswrite(output_filename, score, 'Sheet4');
        fprintf('Successfully saved concatenated data to: %s\n', output_filename);
    catch e
        fprintf('Error saving concatenated data: %s\n', e.message);
    end

    % Write to the output file
    try
        xlswrite(filename_test, FinalPOS, 'Sheet1');
        xlswrite(filename_test, FinalFitness, 'Sheet2');
        xlswrite(filename_test, FinalTrial, 'Sheet3');
        xlswrite(filename_test, FinalScore, 'Sheet4');
        fprintf('Successfully saved top 5 data to: %s\n', filename_test);
    catch e
        fprintf('Error saving top 5 data: %s\n', e.message);
    end

    % Write to the output file
    try
        xlswrite(ranked_raw_file, allPOS_top5, 'Sheet1');
        xlswrite(ranked_raw_file, allFitness_top5, 'Sheet2');
        xlswrite(ranked_raw_file, trial_m_top5, 'Sheet3');
        xlswrite(ranked_raw_file, score_top5, 'Sheet4');
        fprintf('Successfully saved concatenated data to: %s\n', ranked_raw_file);
    catch e
        fprintf('Error saving concatenated data: %s\n', e.message);
    end

    % Write to the output file
    try
        xlswrite(ranked_top5_file, FinalPOS_top5, 'Sheet1');
        xlswrite(ranked_top5_file, FinalFitness_top5, 'Sheet2');
        xlswrite(ranked_top5_file, FinalTrial_top5, 'Sheet3');
        xlswrite(ranked_top5_file, FinalScore_top5, 'Sheet4');
        fprintf('Successfully saved top 5 data to: %s\n', ranked_top5_file);
    catch e
        fprintf('Error saving top 5 data: %s\n', e.message);
    end
end