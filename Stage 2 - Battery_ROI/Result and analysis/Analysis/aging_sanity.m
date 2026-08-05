clear all; close all; clc;

bat_level = csvread("D:\Jacky\MATLAB\Battery_ROI\MOMSA_code\Benchmark\p2p_CES\subs v3\Battery_Level_CES.csv");

bat_level = bat_level(:, 1:2)';
bat_level(1,:) = bat_level(1,:) / 283.52;
bat_level(2,:) = bat_level(2,:) / 275.64;

% Rainflow cycle counting for each CES
rf1 = rainflow(bat_level(1, :), 48);
rf2 = rainflow(bat_level(2, :), 48);
DODs1 = rf1(:, 2); % depth of discharge fractions (0–1)
counts1 = rf1(:, 1); % 0.5 = half cycle,
DODs2 = rf2(:, 2); % depth of discharge fractions (0–1)
counts2 = rf2(:, 1); % 0.5 = half cycle,
% EFCs = sum(DODs1 .* counts1) + sum(DODs2 .* counts2);

% Aging cost
% Based on datasheet, cycle life = 6000 cycles at (assumed) 80% DOD
N_100_fail = 4300;
kp = 1.5;
eta_c = 0.9;
eta_d = 0.9;

% Battery 1
C_aging1 = sum((DODs1.^kp * 1000 * 283.52) ./ (N_100_fail * eta_c * eta_d) .* counts1);

% Battery 2
C_aging2 = sum((DODs2.^kp * 1000 * 275.64) ./ (N_100_fail * eta_c * eta_d) .* counts2);

C_aging_total = C_aging1 + C_aging2