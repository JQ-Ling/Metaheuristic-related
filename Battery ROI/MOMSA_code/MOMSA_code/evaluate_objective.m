%Multi-objective Mantis Search Algorithm (MOMSA): A Novel Approach for Engineering Design Problems and Validation
%  Developed in MATLAB R2019a    
%%Author and programmer: Mohammed jameel  (E-mail:  moh.jameel@su.edu.ye; Mohjameel555@gmail.com) 
%__________________________________________________________________________________

function f=evaluate_objective(x,M)
f = [0, 0];
% OSY optimization
 f(1)=-((25*(x(1)-2)^2)+((x(2)-2)^2)+((x(3)-1)^2)+((x(4)-4)^2)+((x(5)-1)^2));
f(2)=(x(1)^2)+(x(2)^2)+(x(3)^2)+(x(4)^2)+(x(5)^2)+(x(6)^2);
f=f+getnonlinear(x);

function Z=getnonlinear(x)
Z=0;
% Penalty constant
lam=10^15;
%OSY
    g(1)=-x(1)-x(2)+2;
    g(2)=-6+x(1)+x(2);
    g(3)=-2+x(2)-x(1);
    g(4)=-2+x(1)-3*x(2);
    g(5)=-4+((x(3)-3)^2)+x(4);
    g(6)=-((x(5)-3)^2)-x(6)+4;
% No equality constraint in this problem, so empty;
geq=[];

% Apply inequality constraints
for k=1:length(g),
    Z=Z+ lam*g(k)^2*getH(g(k));
end
% Apply equality constraints
for k=1:length(geq),
   Z=Z+lam*geq(k)^2*getHeq(geq(k));
end

% Test if inequalities hold
% Index function H(g) for inequalities
function H=getH(g)
if g<=0,
    H=0;
else
    H=1;
end
% Index function for equalities
function H=getHeq(geq)
if geq==0,
   H=0;
else
   H=1;
end
% ----------------- end ------------------------------
