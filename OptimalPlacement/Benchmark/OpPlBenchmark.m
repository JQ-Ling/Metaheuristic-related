% clear all; clc;

% Starting point
LB = [1 2 2 2 2 76 76 76 76];  % Lower bounds (size need +5)
UB = [2 33 33 33 33 304 304 304 304];  % Upper bounds
initial_POS = [2, 30, 21, 0, 0, 101, 221, 0, 0];
numCES_start = initial_POS(1);
index = 1;

% Initialize PBEST with the starting point
PBEST = initial_POS;
PBEST_fit = runP2P(PBEST);

          
% Loop starting from the specified numCES
for numCES = numCES_start:UB(1)
    % Initialize all locations and sizes to 0
    locCES = zeros(1,4);
    sizeCES = zeros(1,4);
    
    % If we're starting with the initial POS, use those values
    if numCES == numCES_start && index == 1
        locCES(1:4) = initial_POS(2:5);
        sizeCES(1:4) = initial_POS(6:9);
        
        % Evaluate the initial point
        POS = initial_POS;
        POS_fit = PBEST_fit;
        index = index + 1;
        
        disp("Starting from:");
        disp((POS));
        disp((POS_fit));
        
        % Continue the loop from the next values
        start_i1 = locCES(1);
        start_i2 = locCES(2);
        start_i3 = locCES(3);
        start_i4 = locCES(4);
    else
        start_i1 = LB(2);
        start_i2 = LB(3);
        start_i3 = LB(4);
        start_i4 = LB(5);
    end
    
    % Main nested loops, start from appropriate values
    for i1 = start_i1:UB(2)
        locCES(1) = i1;
        
        % Set loop limits based on numCES
        if numCES > 1
            % If we're at the starting point's first iteration, start from next value
            if numCES == numCES_start && index == 2 && i1 == start_i1
                i2_range = start_i2:UB(3);
            else
                i2_range = LB(3):UB(3);
            end
        else
            i2_range = 0;
        end
        
        for i2 = i2_range
            locCES(2) = i2;
            
            if numCES > 2
                % If we're at the starting point's first iteration, start from next value
                if numCES == numCES_start && index == 2 && i1 == start_i1 && i2 == start_i2
                    loc3_range = start_i3:UB(4);
                else
                    loc3_range = LB(4):UB(4);
                end
            else
                loc3_range = 0;
            end
            
            for i3 = loc3_range
                locCES(3) = i3;
                
                if numCES > 3
                    % If we're at the starting point's first iteration, start from next value
                    if numCES == numCES_start && index == 2 && i1 == start_i1 && i2 == start_i2 && i3 == start_i3
                        loc4_range = start_i4:UB(5);
                    else
                        loc4_range = LB(5):UB(5);
                    end
                else
                    loc4_range = 0;
                end
                
                for i4 = loc4_range
                    locCES(4) = i4;
                    
                    % Size loops
                    % If this is the first iteration at the starting point, use initial values
                    if numCES == numCES_start && index == 2 && i1 == start_i1 && i2 == start_i2
                        start_s1 = sizeCES(1);
                        start_s2 = sizeCES(2);
                        start_s3 = sizeCES(3);
                        start_s4 = sizeCES(4);
                    else
                        start_s1 = LB(6);
                        start_s2 = LB(7);
                        start_s3 = LB(8);
                        start_s4 = LB(9);
                    end
                    
                    for s1 = start_s1:5:UB(6)
                        sizeCES(1) = s1;
                        
                        if numCES > 1
                            % If at starting point's first iteration, start from the next value
                            if numCES == numCES_start && index == 2 && i1 == start_i1 && i2 == start_i2 && s1 == start_s1
                                s2_range = start_s2:5:UB(7);
                            else
                                s2_range = LB(7):5:UB(7);
                            end
                        else
                            s2_range = 0;
                        end
                        
                        for s2 = s2_range
                            sizeCES(2) = s2;
                            
                            if numCES > 2
                                % If at starting point's first iteration, start from the next value
                                if index == 2 
                                    size3_range = start_s3:5:UB(8);
                                else
                                    size3_range = LB(8):5:UB(8);
                                end
                            else
                                size3_range = 0;
                            end
                            
                            for s3 = size3_range
                                sizeCES(3) = s3;
                                
                                if numCES > 3
                                    % If at starting point's first iteration, start from the next value
                                    if index == 2 
                                        size4_range = start_s4:5:UB(9);
                                    else
                                        size4_range = LB(9):5:UB(9);
                                    end
                                else
                                    size4_range = 0;
                                end
                                
                                for s4 = size4_range
                                    sizeCES(4) = s4;
                                    
                                    % Create POS array and evaluate
                                    POS = [numCES, locCES, sizeCES];
                                    POS_fit = runP2P(POS);

                                    % Skip if this is our initial point (already evaluated)
                                    if numCES == numCES_start && index == 1
                                        index = index + 1;
                                        continue;
                                    end
                                    infeasible = str2double(fileread('infeasible.txt'));
                                    % Update best solution if needed
                                    if infeasible == 0
                                        PBEST_fit = [PBEST_fit; POS_fit];
                                        PBEST = [PBEST; POS];
                                        filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\benchmark_result_middle.xlsx");
                                        xlswrite(filename_test, PBEST, 'Sheet1');
                                        xlswrite(filename_test, PBEST_fit, 'Sheet2');
                                    else
                                        file=fopen('log.txt','w'); 
                                        fprintf(file,'%3d %3d %3d %3d %3d %3d %3d %3d %3d',POS); 
                                        fclose(file); 
                                    end
                                    
                                    disp((POS));
                                    % disp((POS_fit));
                                    % disp((PBEST_fit));
                                    
                                    index = index + 1;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
 
filename_test = strcat("D:\Jacky\MATLAB\OptimalPlacement\Result\benchmark_result.xlsx");
xlswrite(filename_test, PBEST, 'Sheet1');
xlswrite(filename_test, PBEST_fit, 'Sheet2');

%% 
% % Example fitness values for POS_fit and PBEST_fit
% POS_fit = [0.5, 0.3];   % Current fitness (for example, two objectives)
% PBEST_fit = [0.6, 0.4]; % Best known fitness so far

% % Check if POS_fit dominates PBEST_fit
% if all(POS_fit <= PBEST_fit) && any(POS_fit < PBEST_fit)
%     disp("Y")
% end

%% function
% Function that returns 1 if x dominates y and 0 otherwise
function d = dominates(x,y)
    d = all(x<=y,2) & any(x<y,2);
end

