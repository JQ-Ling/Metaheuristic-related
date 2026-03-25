clc; clear;

Pareto_font = [
    1   10  100;
    2   20   90;
    3   30   80;
    4   40   70;
    5   50   60
];

rank_obj = [1 2 3];

[top5_loc, finalRank, composite_score] = R_method(Pareto_font, rank_obj);

disp('--- MATLAB RESULTS ---')
disp('Top 5 locations (1-based):')
disp(top5_loc)

disp('Final Rank:')
disp(finalRank)

disp('Composite Score (Top 5):')
disp(composite_score)
