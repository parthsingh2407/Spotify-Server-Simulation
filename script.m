close all;
clear;
lambda=5000;
CacheTime=10^-4;
ParServiceTime=10^3;
C=5;
B=100;
N=10^3;
Pc=0.25;
maxT=23;
minT=8;
songsallocation=importdata('song_allocation.txt');
popularities=importdata('file_popularities.txt');

%Generate arrivals
t=0;
arrivals=[];
while t<maxT
    t=t+exprnd(1/lambda);
    arrivals=[arrivals,t];
end

%Assign the songs
acumulative=zeros(1,N);
acumulative(1)=popularities(1);

for i=2:N
    acumulative(i)=acumulative(i-1)+popularities(i);
end

assignedsongs=zeros(1,length(arrivals));
for i=1:length(arrivals)
   I=find(acumulative>rand); 
   assignedsongs(i)=I(1);
end

%Send a request to one of the servers
servers=zeros(1,length(arrivals));
for i=1:length(arrivals)
   servers(i)=songsallocation(assignedsongs(i));
end

finishtime=zeros(1,length(arrivals));
servicetimes=zeros(1,length(arrivals));
droprequest=zeros(1,C);
serverrequest=zeros(1,C);
variances=zeros(1,C);

for server=1:C
    listarrivals=find(servers==server);
    queue=[];
    clientinservice=0;%Index in original list
    lastClientArrived=0;%Index of last client arrived
    t=0;
    endofservicetime=0;
    z=[];

    while t<0.9*maxT
        if t<minT
            finishtime=zeros(1,length(arrivals));
            servicetimes=zeros(1,length(arrivals));
            droprequest(server)=0;
            serverrequest(server)=0;
        end
        if clientinservice==0 
            if length(queue)==0 %New one in service and in system
                t=arrivals(listarrivals(lastClientArrived+1));
                if rand<Pc
                    servicetimes(listarrivals(lastClientArrived+1))=CacheTime;
                else
                    servicetimes(listarrivals(lastClientArrived+1))=exprnd(1/ParServiceTime);
                end
                endofservicetime=t+servicetimes(listarrivals(lastClientArrived+1));
                clientinservice=listarrivals(lastClientArrived+1);
                lastClientArrived=lastClientArrived+1;

            else %New one in the service 
                clientinservice=queue(1);
                queue=queue(2:end);
                if rand<Pc
                    servicetimes(clientinservice)=CacheTime;
                else
                    servicetimes(clientinservice)=exprnd(1/ParServiceTime);
                end
                endofservicetime=t+servicetimes(clientinservice);
            end
        else
            timenextarrival=arrivals(listarrivals(lastClientArrived+1));
            if endofservicetime<timenextarrival %Service finishes before new arrival Finish of service
                finishtime(clientinservice)=endofservicetime;
                z=[z;endofservicetime-arrivals(clientinservice)];
                clientinservice=0;
                t=endofservicetime;
                serverrequest(server)=serverrequest(server)+1;
                

            else %new one in the system
                if length(queue)<B
                    queue=[queue,listarrivals(lastClientArrived+1)];
                else
                    droprequest(server)=droprequest(server)+1;
                end
                lastClientArrived=lastClientArrived+1;
                t=arrivals(listarrivals(lastClientArrived));
            end
        end
    end
    

    variances(server)=var(z);
    t=0:0.0001:max(z);
    cdf=zeros(1,length(t));
    for i=1:length(t)
        cdf(i)=length(find(z<t(i)))/length(z);
    end
    figure;
    plot(t,cdf);
end

% times=finishtime-arrivals;
% listarrivals=find(servers==5);
% x=finishtime(listarrivals);
% x=finishtime(find(x>0));
% 
% t=0:0.1:max(x);
% cdf=zeros(1,length(t));
% for i=1:length(t)
%     cdf(i)=length(find(x<t(i)))/length(x);
% end
% figure;
% plot(cdf);