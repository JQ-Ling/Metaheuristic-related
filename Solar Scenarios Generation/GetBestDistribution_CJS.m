% Return the best distribution for the given data.
% Distribution with the minimum negative log likelihood is the best.
function [Distribution, NLL] = GetBestDistribution_CJS(data)
DistributionList = [...
    "Beta";
    "Birnbaum Saunders";
    "Burr";
    "EpsilonSkewNormal";
    "Exponential";
    "Extreme Value";
    "Gamma";
    "Generalized Extreme Value";
    "Inverse Gaussian";
    "Log Logistic";
    "Logistic";
    "Lognormal";
    "Nakagami";
    "Normal";
    "Rayleigh";
    "Rician";
    "Stable";
    "t Location Scale";
    "Weibull"
    ];
NLLs = zeros(1, length(DistributionList));

for i = 1:length(DistributionList)
    lastwarn('');   % Reset last warning    
    try
        NLLs(i) = negloglik( fitdist(data, DistributionList(i)) );
        
        % Convert warnings into error, so that they can be catched
        warning('error', 'stats:gamfit:ZerosInData');
        warning('error', 'MATLAB:nearlySingularMatrix');
        warning('error', 'stats:tlsfit:IterLimit');
        warning('error', 'stats:mlecov:NonPosDefHessian');
        warning('error', 'stats:addstable:ConvergedToBoundary2');
        warning('error', 'stats:gevfit:EvalLimit');
    catch
        % Catch for errors
%         fprintf('Skipped %s.\n', DistributionList(i));
    end
end
[NLL, index] = min(NLLs);
Distribution=DistributionList(index);
end