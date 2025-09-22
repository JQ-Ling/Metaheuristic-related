function [pro_m, trial_m] = processed_matrix(test_matrix)

    % Get dimensions of the input matrix
    [rows, ~] = size(test_matrix);

    % Initialize the processed matrix with zeros
    pro_m = zeros(rows, 9);

    % Process each row
    for i = 1:rows
        % Round all elements in the row
        rounded_row = round(test_matrix(i, 1:5));
        rounded_row = [rounded_row, test_matrix(i,6:9)];
        
        % Get the value of the first element
        x = rounded_row(1);
        
        % Check if x is within the valid range (1 to 4)
        if x >= 1 && x <= 4
            % Only keep values in positions (2:x+1) and (6:5+x)
            valid_indices_1 = 2:(x+1);
            valid_indices_2 = 6:(5+x);
            
            % Copy the first element and values at valid positions
            pro_m(i, 1) = x;
            
            % Fill in valid positions from first range
            for j = valid_indices_1
                pro_m(i, j) = rounded_row(j);
            end
            
            % Fill in valid positions from second range
            for j = valid_indices_2
                pro_m(i, j) = rounded_row(j);
            end
        else
            % If x is outside the valid range, limit it to the valid range (1-4)
            limited_x = min(max(round(x), 1), 4);
            pro_m(i, 1) = limited_x;
            
            % Apply the same logic with the corrected x value
            valid_indices_1 = 2:(limited_x+1);
            valid_indices_2 = 6:(5+limited_x);
            
            % Fill in valid positions from first range
            for j = valid_indices_1
                pro_m(i, j) = rounded_row(j);
            end
            
            % Fill in valid positions from second range
            for j = valid_indices_2
                pro_m(i, j) = rounded_row(j);
            end
        end
    end

    % Create the repeated numbers matrix
    trial_m = zeros(50,1);

    % Fill with numbers 1 to 10, each appearing 5 times
    index = 1;
    for num = 1:10
        for count = 1:5
            trial_m(index,:) = num;
            index = index + 1;
        end
    end

end