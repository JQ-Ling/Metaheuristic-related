function [map]=LA_figure(d,Np,Rc,S,M)
if M==1 || M==2
Rk = Rc*1.1;
add = Rk+2;
particle = 0;
stuck = 0;
escape = 0;
die = 0;
walk = 0;
if d<3 || d>3
map = zeros(((Rk+2)*2));
map(add,add)=1;
    X = 0; x = 0;
    Y = 0; y = 0;
    while (( particle >= Np) + (escape))==0 
    particle=particle+1; 
    phi=rand*2*3.14159265359; 
    X=Rc*cos(phi);
    Y=Rc*sin(phi);
    x=round(X);
    y=round(Y);
    stuck = 0; 
    die = 0;
    while ((stuck+die+escape) == 0)
    walk=rand;
    if walk<.25      
        if map(add+x,add+y+1)==0 
        y=y+1;
        end
    elseif walk<.5    
    	if map(add+x+1,add+y)==0 
        x=x+1;
        end
    elseif walk<.75   
        if map(add+x,add+y-1)==0 
        y=y-1;
        end
    else             
        if map(add+x-1,add+y)==0 
        x=x-1;
        end
    end
    if (hypot(x,y)>=Rk) 
    die=1;
    else
    stuck=0;
            if (map(add+x+1,add+y) + map(add+x-1,add+y) + map(add+x,add+y-1) + map(add+x,add+y+1))~=0 
                if (rand<S) 
                	stuck=1;
                end
            end 
          end 
    end 
    if stuck 
        map(add+x,add+y)=1; 
        stuck=0;
        clf
    if ((hypot(x,y)*1.2)>=Rc)
        escape = 1;
      end 
    end 

    end 
    if (escape==1) 
        disp('The cluster has reached the creation radius');
    end
    return
end
if d==3
map = zeros((2*Rk+4),(2*Rk+4),(2*Rk+4));
map(add,add,add)=1;
    X = 0; x = 0;
    Y = 0; y = 0;
    Z = 0; z=  0;
    while (( particle >= Np) + (escape))==0 
    particle=particle+1; 
    alfa=rand*2*pi;
    beta=rand*2*pi;
    X=Rc*sin(alfa)*cos(beta);
    Y=Rc*sin(alfa)*sin(beta);
    Z=Rc*cos(alfa);
    x=round(X);
    y=round(Y);
    z=round(Z);
    stuck = 0; 
    die = 0;
    while ((stuck+die+escape) == 0)
    walk = 1.5*rand;
    if walk<.25       
        if map(add+x,add+y+1, add+z)==0 
        y=y+1;
        end
    elseif walk<.5    
        if map(add+x+1,add+y, add+z)==0 
        x=x+1;
        end
	elseif walk<.75    
        if map(add+x,add+y-1, add+z)==0 
        y=y-1;
        end
    elseif walk<1      
         if map(add+x-1,add+y, add+z)==0 
         x=x-1;
         end
    elseif walk<1.25   
         if map(add+x,add+y, add+z+1)==0 
         z=z+1;
         end
    else              
        if map(add+x, add+y, add+z-1)==0
        z=z-1;
        end
    end
    if (sqrt(abs(x).^2+abs(y).^2+abs(z).^2)>=Rk) 
    die=1;
    else
    stuck=0;
        	if (map(add+x+1,add+y, add+z) + map(add+x-1,add+y, add+z) + map(add+x,add+y+1, add+z) + map(add+x,add+y-1,add+z) + map(add+x,add+y,add+z+1) + map(add+x,add+y,add+z-1))~=0
            	if (rand<S) 
                	stuck=1;
                end
            end 
        end 
    end 
    if stuck 
     map(add+x,add+y,add+z)=1;
     stuck=0;
     clf
    if (sqrt(abs(x).^2+abs(y).^2+abs(z).^2)*1.2>=Rc)
        escape = 1;
    end 
    end 
    end 
    if (escape==1) 
    	disp('The simulation ended before all particle could be tried because boundaries were exceeded');
    end
end
end
if M==0
    if d<3 | d>3
        load('LFND');
        map=LFND;
    else
        load('LF3D');
        map=LF3D;
    end
end      
return