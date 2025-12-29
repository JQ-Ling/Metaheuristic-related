function [result]=gaLFThukaram(ep, busnum, basemva, basevoltage, busdat, linedat )
% %%%  load flow analysis  Sweep Thukaram Load Flow
P0=busdat(:,7)/basemva;
Q0=busdat(:,8)/basemva;
Sg=(busdat(:,5)+busdat(:,6)*sqrt(-1))/basemva; 

np=busdat(:,9);
nq=busdat(:,10);
rx=linedat(:,2:6);

%Building the BIBC matrix
n=max(max(rx(:,1)), max(rx(:,2))); % bus number  
 [nb ll]=size(rx);  % nb branch number
    fromb=[];
    BIBC=zeros(nb,n-1);
    for i=1:nb
    fromb=[];
        tob=rx(i,2);
        BIBC(i,tob-1)=1;
        fromb=[fromb; rx(i,2)] ;
        for k=i+1:nb
           if isempty(find(fromb==rx(k,1), 1)) %check tob1 = formb2
           else %check if x same, update 1 until same.
           tob=rx(k,2);
           BIBC(i,tob-1)=1;
           fromb=[fromb; rx(k,2)];
           end
        end
    end
    BIBC;
    
%Power flow calculation
V=ones(n,1).*1.05;
I=zeros(n,1);
eps=1;
it=0; %iteration
 while eps>ep
       it=it+1;
       Vpr=V;
       for ii=1:n
        Pa(ii)=P0(ii)*(abs(V(ii))^np(ii));
        Qa(ii)=Q0(ii)*(abs(V(ii))^nq(ii));
        S(ii)=Pa(ii)+j*Qa(ii);
       end
     
   % determination of the line current
    for ii=1:n
        I(ii)=conj((S(ii)-Sg(ii))/V(ii)); %Sg=S generator
    end
  
  Inew=I;
  Inew(1)=[];
  B=BIBC*Inew;
  Vnew=V; 
  Vnew(1)=[];
  Snew=conj(B).*Vnew;
  
  %Calculation of the busbar voltage
  for i=1:n-1
        s=rx(i,1);
        r=rx(i,2);
        rz=rx(i,3);
        xz=rx(i,4);
        V(r)=V(s)-B(r-1)*(rz+j*xz);
  end
         eps=max(abs(V-Vpr));
 end
 % %%%  load flow analysis  Sweep Thukaram Load Flow
 %%% load flow output data
        it;
        Vm=abs(V);
        Va=angle(V)*180/pi;
        LineCur=B*basemva*1000/basevoltage;
        SLoad=S.'*basemva;
        Lineloss=abs(B).^2.*(rx(:,3)+j*rx(:,4))*basemva;
        Sline=Snew*basemva+Lineloss;
  
        %%% function loadflowoutput(handles)
        result.it=it;
        result.Vm=Vm;
        result.Va=Va;
        result.LineCur=LineCur;
        result.SLoad=SLoad;
        result.Lineloss=Lineloss;
        result.Sline=Sline;
        result.busdat=busdat;
        result.linedat=linedat;
%%% load flow output data
%return