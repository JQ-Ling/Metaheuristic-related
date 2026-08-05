L = 10 * ones(1,33);
L(1) = 0.23;

input_sol = L;
nbCES = 2;

% Convert inputArray to a string with space-separated values
input_sol(1) = 1 - input_sol(1)/1; % CES subscription price -> priority based
inputString = sprintf('%d ', input_sol);
CES_subsc_price = L(1);
CES_subsc = sum(L(2:end));
total_size = 283.52 + 275.64;

% Define the full path to the executable file
if CES_subsc <= total_size
    exePath = '"C:\Users\PC\source\repos\p2p_optimal placement\x64\Release\p2p_optimal placement.exe"';
    % Call the executable file with appropriate command-line arguments
    command = [exePath ' ' inputString];
    % disp(command)
    status = system(command);
    CES_capacity_boundary = 1;
else
    CES_capacity_boundary = 0;
end

% Check the status of the system call
if status == 0
    disp('Execution successful.');
else
    disp('Execution failed.');
end

disp(input_sol);