
original_data = csvread("D:\Jacky\Julia-vscode\ADMM_P2P\Solar_interpolated.csv");
figure(3);
plot(original_data')

% Number of components in the GMM (choose based on your data)
num_components = 5; % You can adjust this number

% Fit a Gaussian Mixture Model (GMM) to the original data
gmm = fitgmdist(original_data, num_components, 'RegularizationValue', 0.01);

% Number of new scenarios you want to generate
num_new_scenarios = 1000;

% Generate new scenarios by sampling from the fitted GMM
new_scenarios = random(gmm, num_new_scenarios);
% Apply a moving average filter to smooth the data
windowSize = 10; % Define the window size for the moving average
smoothed_scenarios = zeros(size(new_scenarios));

for i = 1:size(new_scenarios, 2)
    % Apply moving average filter to each feature column
    smoothed_scenarios(:, i) = movmean(new_scenarios(:, i), windowSize);
end

% Ensure non-negative values
smoothed_scenarios = max(smoothed_scenarios, 0);
figure(5);
plot(smoothed_scenarios')

% Ensure that the distribution of new data is similar to the original data
figure(4);
subplot(1, 2, 1);
histogram(original_data(:));
title('Original Data Distribution');
subplot(1, 2, 2);
histogram(smoothed_scenarios(:));
title('New Scenarios Distribution');

% Assuming original_data and new_scenarios are your datasets
% Compute mean and variance for the whole datasets
mean_original = mean(original_data(:));
var_original = var(original_data(:));
mean_new = mean(smoothed_scenarios(:));
var_new = var(smoothed_scenarios(:));

% Display mean and variance
disp('Original Data Mean:');
disp(mean_original);
disp('New Scenarios Mean:');
disp(mean_new);
disp('Original Data Variance:');
disp(var_original);
disp('New Scenarios Variance:');
disp(var_new);

% Calculate and display absolute differences
mean_diff = abs(mean_original - mean_new);
var_diff = abs(var_original - var_new);

disp('Mean Difference:');
disp(mean_diff);
disp('Variance Difference:');
disp(var_diff);

a = mean(original_data);
b = mean(smoothed_scenarios);
figure(11);
plot(a);
hold on;
plot(b)

% Save the new scenarios for testing
writematrix([original_data; smoothed_scenarios],'Solar_1000+1000.csv')