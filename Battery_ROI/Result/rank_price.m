type = 'unlimit'; % 'limit' or 'unlimit'

filename = strcat("D:\Jacky\Data Output\Battery ROI\MOMSA unrank ", type, " 1.xlsx");

[POS, ~, ~] = xlsread(filename, 'Sheet1');
[Fitness, ~, ~] = xlsread(filename, 'Sheet2');

[top5_loc, ranking, score] = R_method(Fitness,[1.5 3 1.5]);
[~, sortedIndices] = sort(ranking, 'descend');

ranked_POS = POS(sortedIndices,:);
ranked_Fitness = Fitness(sortedIndices,:);
ranked_score = score(sortedIndices,:);

filename_test = strcat("D:\Jacky\Data Output\Battery ROI\MOMSA ranked ", type, " 1.xlsx");
xlswrite(filename_test, ranked_POS, 'Sheet1');
xlswrite(filename_test, ranked_Fitness, 'Sheet2');
xlswrite(filename_test, ranked_score, 'Sheet3');