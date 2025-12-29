%______________________________________________________________________________________
%  Multi-objective Mantis Search Algorithm (MOMSA): A Novel Approach for Engineering Design Problems and Validation
%  Developed in MATLAB R2019a    
%%Author and programmer: Mohammed jameel  (E-mail:  moh.jameel@su.edu.ye; Mohjameel555@gmail.com) 
%______________________________________________________________________________________

function MS=metric_of_maximum_spread(pareto_fun,Factual)

[~,col]=size(Factual);

ms=0;
for i=1:col
   ms=ms+((max(pareto_fun(:,i))-min(pareto_fun(:,i)))/(max(Factual(:,i))-min(Factual(:,i))))^2;
   % ms=ms+((max(Fmin(:,i))-min(Fmin(:,i)))^2);
end
 
MS=sqrt(ms/col);
% MS=sqrt(ms);  

end