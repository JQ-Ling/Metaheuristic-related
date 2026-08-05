%% Multi-objective Mantis Search Algorithm (MOMSA): A Novel Approach for Engineering Design Problems and Validation
%  Developed in MATLAB R2019a    
%%Author and programmer: Mohjameel (E-mail:  moh.jameel@su.edu.ye; Mohjameel555@gmail.com) 
function [f, gen_sol] = MOMSA(dim,M,lb,ub,SearchAgents_no,Max_iter,ishow) 
fobj=@runP2P;
%%-------------------Controlling parameters--------------------------%%
p=0.5;   %% A probability to exchange between the exploration and exploitation stages
A=1.0;   %% Length of the archive
a=0.5;   %% A probability of the strike’s failure
P=2;     %% A recycling factor to exchange between pursuers and spearers
alp=6; %% The gravitational acceleration rate of the mantis’s strike
Pc=0.2;  %% The percentage of sexual cannibalism 
archive=[[]]; %% an archive to include the positions of a number of camouflaged places
Positions = zeros(SearchAgents_no,dim);
Sol = zeros(SearchAgents_no,dim);
%%  START  THE  EXECUTION  OF  THE  MOMSA ALGORITHM 
%% Initialize the population
for i=1:SearchAgents_no
   Positions(i,:)=lb+(ub-lb).*rand(1,dim); 
   f(i,1:M) = fobj(Positions(i,:),M);
end
new_Sol=[Positions f]; 
new_Sol = solutions_sorting(new_Sol, M, dim);
gen_sol = zeros(Max_iter, M);
%% The main loop of MOMSA algorithm
for t = 1 : Max_iter
    RL=0.05*levy(SearchAgents_no,dim,1.5);   %Levy random number vector
    a2=-1+-1*(t/Max_iter); %% a2 linearly decreases from -1 to -2
    for i=1:SearchAgents_no
        l=(a2-1)*rand+1; %% a Factor including a numerical value between ?1 and -2 to control the gravitational acceleration rate 
        best=  (new_Sol(i,1:(dim)) - new_Sol(1,(1:dim)));
       if (size(archive,1)<A) %% Adding directly to the archive if it is not full; otherwise, remove an existing one selected randomly.
          archive=best;
       else
          archive(randi(A),:)=best;
       end
    
% %       bA= archive;
        bA=archive(randi(size(archive,1)),1:dim); %% Selecting randomly a solution from the archive 
        a1=randi(SearchAgents_no); %% An index selected randomly between 1 and SearchAgents_no
        b=randi(SearchAgents_no); %% An index selected randomly between 1 and SearchAgents_no
        c=randi(SearchAgents_no); %% An index selected randomly between 1 and SearchAgents_no
        while a1==i | a1==b | c==b | c==a1 ||c==i |b==i %% Checking that a1!=b!=c!=i; if the same index is selected twice or more, the following code is applied repeatedly to satisfy this constraint:
            a1=randi(SearchAgents_no); %% An index selected randomly between 1 and SearchAgents_no
            b=randi(SearchAgents_no); %% An index selected randomly between 1 and SearchAgents_no
            c=randi(SearchAgents_no); %% An index selected randomly between 1 and SearchAgents_no
        end
        r1=rand(); % r1 is a random number in [0,1]
        r2=rand(); % r2 is a random number in [0,1]
        r3=rand(); % r1 is a random number in [0,1]
        t2=randn;  % t2 is a normal distribution-based number
        m=1-t/Max_iter; % Eq. (7)
      
        if (rand<p) %% Exchanging between exploration and exploitation
           F=1-rem(t,Max_iter/P)/(Max_iter/P);  % Eq. (11)
           U=rand(1,dim)>rand(1,dim); % A binary vector generated based on Eq. (4).
           for j=1:size(Positions,2)
              if r1<F %% Exploration of pursuers’ behavior
                  if r2<r3 
                     Steps=(Positions(i,j)-Positions(a1,j))*RL(i,j)+abs(t2)*U(j)*(Positions(a1,j)- Positions(b,j)); % Eq. (3a)
                     Positions(i,j)= Positions(i,j)+Steps;      
                  else
                     y = Positions(a1,j)+rand.*(Positions(b,j)-Positions(c,j)); 
                     if rand<=rand %% Merging the characteristics of the new solution and the current one to simulate sudden orientation for the ith mantis
                       Positions(i,j)=y;
                     end
                  end
              else %% Exploration of spearers’ behavior
                  if r2<r3
                     alpha=cos(pi*rand)*m; 
                     Positions(i,j)=Positions(i,j)+alpha*(bA(j)-Positions(b,j)); 
                  else 
                     Positions(i,j)=(bA(j))+(r2*2-1)*m*(lb(j)+rand*(ub(j)- lb(j))); 
                  end
              end
           end
        else %% Attacking the prey: Exploitation stage
                   Best_P=(new_Sol(i,1:(dim)) - new_Sol(1,(1:dim)));
            for j=1:size(Positions,2)
                if rand<r2
                    Positions(i,j)=Positions(i,j)+r1*(Positions(a1,j)-Positions(b,j));      
                else
                    vs=1/(1+exp(alp*l)); 
                    dsi=Best_P(j)-Positions(i,j); 
                    Positions(i,j)=(Positions(i,j)+Best_P(j))/2.0+vs*dsi;      
                    Pf=a*(1-t/Max_iter); 
                    if r2<Pf 
                       Positions(i,j)=(Positions(i,j))+exp(2*l)*cos(2*l*pi)*abs(Positions(i,j)-bA(j))+(rand*2-1)*(ub(j)-lb(j)); 
                    end
                end
            end   
        end
         for j=1:size(Positions,2)
              if  Positions(i,j)>ub(j)
                   Positions(i,j)=lb(j)+rand*(ub(j)-lb(j));
              elseif  Positions(i,j)<lb(j)
                   Positions(i,j)=lb(j)+rand*(ub(j)-lb(j));
               end
         end  
        %%%%%%Return the search agents that exceed the search space's bounds      
         Sol(i,1:dim) = Positions(i,1:dim);      
        for j=1:size(Positions,2)
              if  Sol(i,j)>ub(j)
                   Sol(i,j)=lb(j)+rand*(ub(j)-lb(j));
              elseif  Sol(i,j)<lb(j)
                   Sol(i,j)=lb(j)+rand*(ub(j)-lb(j));
               end
         end  
        %% Evalute the fitness/function values of the new population
        Sol(i, dim+1:M+dim) = fobj(Sol(i,1:dim),M);
        if Sol(i,dim+1:dim+M) <= new_Sol(1,(dim+1:dim+M)) 
           new_Sol(1,1:(dim+M)) = Sol(i,1:(dim+M));  
        end
          Positions(i,1:dim)=  new_Sol(i,1:dim);
   end
    
    if rand<Pc
       % Update the Position of search agents 
        for i=1:SearchAgents_no
            l=(a2-1)*rand+1; 
            r1=rand(); % r1 is a random number in [0,1]
            r3=rand(); % r3 is a random number in [0,1]
            if rand<rand
                  U=rand(1,dim)>rand(1,dim); % A binary vector generated based on Eq. (4).
                  for j=1:size(Positions,2)
                     Positions(i,j)= Positions(i,j)*U(j)+(Positions(1,1)+-rand*(-Positions(1,1)+Positions(i,j))).*(1-U(j)); % Eq. (21)
                  end
            else
                a1=randi(SearchAgents_no);
                while a1==i 
                   a1=randi(SearchAgents_no);
                end
                Pt=r2*(1-t/Max_iter);
                for j=1:size(Positions,2) 
                    if r1<Pt
                        Positions(i,j)= Positions(i,j)+r3*(Positions(i,j)- Positions(a1,j)); 
                        Positions(i,j)=Positions(a1,j)*cos(l*pi*2)*m; 
                    end
                end
            end
           %%%%%%Return the search agents that exceed the search space's bounds      
        Sol(i,1:dim) = Positions(i,1:dim); 
           for j=1:size(Positions,2)
              if  Sol(i,j)>ub(j)
                   Sol(i,j)=lb(j)+rand*(ub(j)-lb(j));
              elseif  Sol(i,j)<lb(j)
                   Sol(i,j)=lb(j)+rand*(ub(j)-lb(j));
              end
           end  
        %% Evalute the fitness/function values of the new population
        Sol(i, dim+1:M+dim) = fobj(Sol(i,1:dim),M);
        if Sol(i,dim+1:dim+M) <= new_Sol(1,(dim+1:dim+M)) 
           new_Sol(1,1:(dim+M)) = Sol(i,1:(dim+M));  
        end
        end
    end 
    %% ! Very important to combine old and new bats !
   Sort_bats(1:SearchAgents_no,:) = new_Sol;
   Sort_bats((SearchAgents_no + 1):(2*SearchAgents_no), 1:M+dim) = Sol;
%% Non-dominated sorting process (a separate function/subroutine)
   Sorted_bats = solutions_sorting(Sort_bats, M, dim); 
%% Select npop solutions among a combined population of 2*npop solutions  
   new_Sol = cleanup_batspop(Sorted_bats, M, dim, SearchAgents_no);    
   if rem(t, ishow) == 0
   fprintf('Generation: %d\n',t);        
   end
   gen_sol(t,:) = new_Sol(1, dim+1:dim+M); 
end
f=new_Sol;

