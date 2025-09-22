clc;clear all;close all;
renewable_data =xlsread("D:\Jacky\MATLAB\Solar Scenarios Generation\SolarData-March2021-March2022.xls");
makedist -reset
Actual = renewable_data(:,5);
Forecast = renewable_data(:,7);
Monitor = renewable_data(:,6);

%% Divide based on PU
Size = size(Actual);

t1=1;t2=1;t3=1;t4=1;t5=1;t6=1;t7=1;t8=1;t9=1;t10=1;
% pu_base = max(Monitor);
pu_base = max(Actual);

% Standardize & Classify Data
for ii = 1:Size
    if Forecast(ii,1)>0  && Forecast(ii,1) <=0.1*pu_base
      actualpu1(t1,1)=Actual(ii,1)/pu_base;  
      pdf01(t1,1) = (Forecast(ii,1)-Actual(ii,1))/pu_base;      
      t1 = t1+1;
    elseif Forecast(ii,1)>0.1*pu_base && Forecast(ii,1)<=0.2*pu_base
        actualpu2(t2,1)=Actual(ii,1)/pu_base;
        pdf02(t2,1) = (Forecast(ii,1)-Actual(ii,1))/pu_base;
        t2 = t2+1;
    elseif Forecast(ii,1)>0.2*pu_base && Forecast(ii,1)<=0.3*pu_base
        actualpu3(t3,1)=Actual(ii,1)/pu_base;
        pdf03(t3,1) = (Forecast(ii,1)-Actual(ii,1))/pu_base;
        t3 = t3+1;
    elseif Forecast(ii,1)>0.3*pu_base && Forecast(ii,1)<=0.4*pu_base
        actualpu4(t4,1)=Actual(ii,1)/pu_base;
        pdf04(t4,1) = (Forecast(ii,1)-Actual(ii,1))/pu_base;
        t4 = t4+1;
    elseif Forecast(ii,1)>0.4*pu_base && Forecast(ii,1)<=0.5*pu_base
        actualpu5(t5,1)=Actual(ii,1)/pu_base;
        pdf05(t5,1) = (Forecast(ii,1)-Actual(ii,1))/pu_base;
        t5 = t5+1;
    elseif Forecast(ii,1)>0.5*pu_base && Forecast(ii,1)<=0.6*pu_base
        actualpu6(t6,1)=Actual(ii,1)/pu_base;
        pdf06(t6,1) = (Forecast(ii,1)-Actual(ii,1))/pu_base;
        t6 = t6+1;
    elseif Forecast(ii,1)>0.6*pu_base && Forecast(ii,1)<=0.7*pu_base
        actualpu7(t7,1)=Actual(ii,1)/pu_base;
        pdf07(t7,1) = (Forecast(ii,1)-Actual(ii,1))/pu_base;
        t7 = t7+1;
    elseif Forecast(ii,1)>0.7*pu_base && Forecast(ii,1)<=0.8*pu_base
        actualpu8(t8,1)=Actual(ii,1)/pu_base;
        pdf08(t8,1) = (Forecast(ii,1)-Actual(ii,1))/pu_base;
        t8 = t8+1;
    elseif Forecast(ii,1)>0.8*pu_base && Forecast(ii,1)<=0.9*pu_base
        actualpu9(t9,1)=Actual(ii,1)/pu_base;
        pdf09(t9,1) = (Forecast(ii,1)-Actual(ii,1))/pu_base;
        t9 = t9+1;
    elseif Forecast(ii,1)>0.9*pu_base
        actualpu10(t10,1)=Actual(ii,1)/pu_base;
        pdf10(t10,1) = (Forecast(ii,1)-Actual(ii,1))/pu_base;
        t10 = t10+1;
    end
end

%% Get the best distribution
D = strings([1,10]);
NLL = zeros(1,10);
T = [t1 t2 t3 t4 t5 t6 t7 t8 t9 t10];
Keys = {1,2,3,4,5,6,7,8,9,10};
Values = {actualpu1 actualpu2 actualpu3 actualpu4 actualpu5 actualpu6 actualpu7 actualpu8 actualpu9 actualpu10};
M = containers.Map(Keys,Values,'UniformValues',false);

for i = 1:10
    if ( T(i) > 1 )     % if T(i) = 1 -> no samples within that pu
        [D(i), NLL(i)] = GetBestDistribution_CJS( M(i) );
    end
end
BestDistribution = ["PU:",1:10; "Distribution:",D; "NLL:",NLL;]

%% Create PDF
% pd1 = createStable1(actualpu1);
% pd2 = createBeta2(actualpu2);
% pd3 = createEpsilonSkewNormal3(actualpu3);
% pd4 = createEpsilonSkewNormal4(actualpu4);
% pd5 = createExtremeValue5(actualpu5);
% pd6 = createBurr6(actualpu6);
% pd7 = createBurr7(actualpu7);

% pd1 = createNormal1(actualpu1);
% pd2 = createNormal1(actualpu2);
% pd3 = createNormal1(actualpu3);
% pd4 = createNormal1(actualpu4);
% pd5 = createNormal1(actualpu5);
% pd6 = createNormal1(actualpu6);
% pd7 = createNormal1(actualpu7);

pd1 = create3_pd1(actualpu1);
pd2 = create3_pd2(actualpu2);
pd3 = create3_pd3(actualpu3);
pd4 = create3_pd4(actualpu4);
pd5 = create3_pd5(actualpu5);
pd6 = create3_pd6(actualpu6);
pd7 = create3_pd7(actualpu7);
pd8 = create3_pd8(actualpu8);
pd9 = create3_pd9(actualpu9);
pd10 = create3_pd10(actualpu10);


%% Obtain Forecast Data and Generate N scenarios
Big_S = 1;
M = 5;
N = 1100;
if Big_S > 1
    n = Big_S * M * N; 
else
    n = N;
end
w=100;%wind farm size kw

Current_data = xlsread('D:\Jacky\MATLAB\Solar Scenarios Generation\SolarData-20220405.xls');
Current_Forecast = Current_data(:,7);
Current_Monitor = Current_data(:,6);
% Current_PuBase = Current_Forecast / max(Current_Monitor);
Current_PuBase = Current_Forecast / max(Current_Forecast);

Data_Generated = zeros(n,24);

PD_Count1 = 0;
PD_Count2 = 0;
PD_Count3 = 0;
PD_Count4 = 0;
PD_Count5 = 0;
PD_Count6 = 0;
PD_Count7 = 0;
PD_Count8 = 0;
PD_Count9 = 0;
PD_Count10 = 0;

for i = 1:size(Current_Forecast)
    A = Current_PuBase(i,1);
    if A == 0
%         Data_Generated(:,i) = 0;
        Current_PDF = pd1;
        PD_Count1 = PD_Count1 + 1;
        Data_Generated(:,i) = random(Current_PDF,n,1)*w;
    else
        if A > 0 && A <= 0.1
            Current_PDF = pd1;
            PD_Count1 = PD_Count1 + 1;

        elseif A > 0.1 && A <= 0.2
            Current_PDF = pd2;
            PD_Count2 = PD_Count2 + 1;

        elseif A > 0.2 && A <= 0.3
            Current_PDF = pd3;
            PD_Count3 = PD_Count3 + 1;

        elseif A > 0.3 && A <= 0.4
            Current_PDF = pd4;
            PD_Count4 = PD_Count4 + 1;

        elseif A > 0.4 && A <= 0.5
            Current_PDF = pd5;
            PD_Count5 = PD_Count5 + 1;

        elseif A > 0.5 && A <= 0.6
            Current_PDF = pd6;
            PD_Count6 = PD_Count6 + 1;

        elseif A > 0.6 && A <= 0.7
            Current_PDF = pd7;
            PD_Count7 = PD_Count7 + 1; 

        elseif A > 0.7 && A <= 0.8
            Current_PDF = pd8;
            PD_Count8 = PD_Count8 + 1; 

        elseif A > 0.8 && A <= 0.9
            PD_Count9 = PD_Count9 + 1;
            Current_PDF = pd9;

        elseif Current_PuBase(i,1) > 0.9
            PD_Count10 = PD_Count10 + 1;
            Current_PDF = pd10;
        end
        
        Data_Generated(:,i) = random(Current_PDF,n,1)*w;
    end
end

%% Pre-process to eliminate negative solar generation
for i = 1:size(Data_Generated,1)
    for j = 1:size(Data_Generated,2)
        if (Data_Generated(i,j) < 0)
            Data_Generated(i,j) = 0;
        end
    end
end

%% Pre-process to eliminate solar generation in night-time
sunrise = 6;        % 6am
sunset = 12 + 8;    % 8pm
for i = 1:size(Data_Generated,1)
    for j = 1:size(Data_Generated,2)
        if (j <= sunrise || j >= sunset)
            Data_Generated(i,j) = randi([1,10000000],1,1)/10000000;
        end
    end
end

%% Plotting for sanity check
X = (1:24).*ones(size(Data_Generated,1),24);
figure;
for i = 1:size(Data_Generated,1)
    plot(X(i,:), Data_Generated(i,:));
    hold on;
end
xlabel('Hour')
ylabel('Solar Generation (MW)')
title('Solar Generation VS Hour')
xlim([1, 24])

%% Store to excel file
writematrix(Data_Generated,'SolarGeneration.csv');