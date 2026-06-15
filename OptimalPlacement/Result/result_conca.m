% Initialize empty arrays to store concatenated data
allPOS = [];
allFitness = [];
MOO = "MOMSA";
bus_sys = "69bus_ptdf";
MOO_idx = 1;

% Loop through each file (from 1 to 10)
for i = 1:10
    % Construct the filename based on your pattern
    filename = strcat("D:\Jacky\Data Output\CES size and loc\", bus_sys, "\raw\", MOO, " result ", num2str(i), ".xlsx");
    
    % Try to read the file
    try
        fprintf('Reading file: %s\n', filename);
        
        % Read data from Sheet1 (POS) and Sheet2 (Fitness)
        [POS, ~, ~] = xlsread(filename, 'Sheet1');
        [Fitness, ~, ~] = xlsread(filename, 'Sheet2');
        
        % Concatenate data
        if isempty(allPOS)
            allPOS = POS;
            allFitness = Fitness;
        else
            % Concatenate vertically - add rows
            allPOS = [allPOS; POS];
            allFitness = [allFitness; Fitness];
        end
        
        fprintf('Successfully read data from file %d\n', i);
    catch e
        fprintf('Error reading file %d: %s\n', i, e.message);
    end
end

% Process the data
allPOS(:,6:9) = allPOS(:,6:9) + 5;
[allPOS, ~] = processed_matrix(allPOS);
trial_m = MOO_idx * ones(size(allPOS,1),1);

% Save the concatenated data to a new Excel file
output_filename = strcat("D:\Jacky\Data Output\CES size and loc\", bus_sys, "\", MOO, ".xlsx");
filename_test = strcat("D:\Jacky\Data Output\CES size and loc\", bus_sys, "\", MOO, "_top 5.xlsx");

folder_path = 'D:\Jacky\MATLAB\Archieve for essential file'; % Replace with your function folder path
addpath(folder_path);
[top5_loc,~,score] = R_method(allFitness,[1 2.5 2.5]);
FinalFitness = allFitness(top5_loc,:);
FinalPOS = allPOS(top5_loc,:);
FinalTrial = trial_m(top5_loc,:);
FinalScore = score(top5_loc,:);

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