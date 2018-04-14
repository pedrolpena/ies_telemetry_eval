function[]=Telemetry_eval(fileName)
%
%  This script is designed to create a figure to help evaluate the quality
%  of a recently telemetered PIES or CPIES.  
%  Christopher S. Meinen

#clear
close all
screensize = get( 0, 'Screensize' );

figHeight = .85 * screensize(4);
figWidth = .9 * (screensize(3) / 2);

if nargin==1
    filename=fileName;
    else
    filename=input('Enter the file name at the prompt:','s');
end

%%%%%% Prompt the user for the file name and load the file

#filename=input('Enter the file name at the prompt:','s');

data=load(filename);

recnum=length(data(:,1)):-1:1;

%%%%%% Separate the file into vectors for each field  

yearday=data(:,1);

tau=data(:,2);

pres=data(:,3)./1000;   % Factor of 1000 converts from decaPascal to dbar

if length(data(1,:))==9    % File is from a PIES
    year=data(:,4);
    month=data(:,5);
    day=data(:,6);
    hour=data(:,7);
    minute=data(:,8);
    second=data(:,9);
else                        % File is from a CPIES
    speed=data(:,4);
    direction=data(:,5);
    year=data(:,6);
    month=data(:,7);
    day=data(:,8);
    hour=data(:,9);
    minute=data(:,10);
    second=data(:,11);
end
clear i data

%%%%% Create a Matlab datenum formatted vector for the time when the
%%%%% signals were received

datenumvec=datenum(year,month,day,hour,minute,second);
clear year month day hour minute second

%%%%% Identify the records that are separated in receive time by more 
%%%%% than 26 seconds (for a PIES) or more than 33 seconds (for a CPIES) 
%%%%% and which are less than one minute (or alternatively are longer 
%%%%% than one minute) to flag the missing data values

% if ~(exist('speed')==1)   % a PIES
%     gap=find((diff(datenumvec)>(26/86400) & diff(datenumvec)<(58/86400)) | ...
%         diff(datenumvec)>(65/86400));
% else   % a CPIES
%     gap=find((diff(datenumvec)>(33/86400) & diff(datenumvec)<(58/86400)) | ...
%         diff(datenumvec)>(65/86400));
% end
if ~(exist('speed')==1)   % a PIES
    gap=find(diff(datenumvec)>(26/86400));
else   % a CPIES
    gap=find(diff(datenumvec)>(33/86400));
end



%%%%% Replace all -99 values (the URI 'missing value' flag) with NaNs

bad=find(tau<-90);tau(bad)=NaN;clear bad
bad=find(pres<-90);pres(bad)=NaN;clear bad

if exist('speed')==1      %%% Only needed for CPIES
    bad=find(speed<-90);speed(bad)=NaN;clear bad
    bad=find(direction<-90);direction(bad)=NaN;clear bad
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Create a 8.5x11 inch figure window; the first figure will be for the
%%%%% travel time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

h=figure('Units','pixels','Position',[.1*figWidth 0 figWidth figHeight],...
'PaperPosition',[.1*figWidth 0 figWidth figHeight],'Units','pixels');

%%%% Make the first plot of the raw travel time data 

subplot(3,1,1)

if length(gap)>1   % If long gaps exist, plot a vertical red line
    plot(recnum(gap(1)).*[1 1],[-10 10],'r-');hold on
    for i=2:length(gap)
        plot(recnum(gap(i)).*[1 1],[-10 10],'r-');
    end
    clear i
end
plot(flipud(recnum),flipud(tau),'x','color',[0 0.5 0]);
set(gca,'ylim',[0 10]);
ylabel('Travel time, both MSB and LSB [ s ]');
xlabel('Record number [ days, time increasing to right ]');

eval(['title(''Travel time record for file: ',filename,''');']);

%%%% For the second plot, focus in on the LSB variability

subplot(3,1,2)

if length(gap)>1    % If long gaps exist, plot a vertical red line
    plot(recnum(gap(1)).*[1 1],[-10 10],'r-');hold on
    for i=2:length(gap)
        plot(recnum(gap(i)).*[1 1],[-10 10],'r-');
    end
    clear i
end
plot(flipud(recnum),flipud(tau),'x','color',[0 0.5 0]);
LSBonly=SimpleDespike(tau(find(tau<=0.5 & tau>=0)));
% LSBonly=(tau(find(tau<=0.5 & tau>=0)));
set(gca,'ylim',...
    [nanmedian(LSBonly)-3.*nanstd(LSBonly) ...
     nanmedian(LSBonly)+3.*nanstd(LSBonly)]);
ylabel('Travel time variabilty, LSB only [ s ]');
xlabel('Record number [ days, time increasing to right ]');

%%%% In the third plot, include some statistics as text

MSBonly=tau(find(tau>0.5));
medianMSBtau=median(MSBonly);
medianLSBtau=nanmedian(LSBonly);
stdLSBtau=nanstd(LSBonly);

subplot(3,1,3)

plot([0 1 NaN NaN],[NaN NaN 0 1],'w-');hold on
eval(['hand=text(0.05,0.85,''Median MSB: ',num2str(medianMSBtau - ...
    rem(medianMSBtau,0.5),4),' sec'');']);
set(hand,'fontsize',12,'fontweight','bold','color',[0 0.5 0]);
eval(['hand=text(0.05,0.75,''Median LSB: ',num2str(medianLSBtau,3),...
    ' sec'');']);
set(hand,'fontsize',12,'fontweight','bold','color',[0 0.5 0]);

%%% Test whether the STD is larger than expected

if stdLSBtau>0.005
    eval(['hand=text(0.05,0.65,''STD LSB: ',num2str(stdLSBtau,2),...
        ' sec'');']);
    set(hand,'fontsize',12,'fontweight','bold','color',[1 0 0]);
else
    eval(['hand=text(0.05,0.65,''STD LSB: ',num2str(stdLSBtau,2),...
        ' sec'');']);
    set(hand,'fontsize',12,'fontweight','bold','color',[0 0.5 0]);
end
hand=text(0.05,0.35,'Typical standard deviations: 0.7-5 msec');
set(hand,'fontsize',12,'fontweight','bold','color',[0 0.5 0]);

set(gca,'xtick',[],'ytick',[]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%  Now move to the pressure figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


h=figure('Units','pixels','Position',[figWidth + .125*figWidth 0 figWidth figHeight],...
'PaperPosition',[figWidth + .125*figWidth  0 figWidth figHeight],'Units','pixels');

%%%% Make the first plot of the raw pressure data 

subplot(3,1,1)

if length(gap)>1   % If long gaps exist, plot a vertical red line
    plot(recnum(gap(1)).*[1 1],[-10 6000],'r-');hold on
    for i=2:length(gap)
        plot(recnum(gap(i)).*[1 1],[-10 6000],'r-');
    end
    clear i
end
plot(flipud(recnum),flipud(pres),'x','color',[0 0.5 0]);
set(gca,'ylim',[0 6000]);
ylabel('Pressure, both MSB and LSB [ dbar ]');
xlabel('Record number [ days, time increasing to right ]');

eval(['title(''Pressure record for file: ',filename,''');']);

%%%% For the second plot, focus in on the LSB variability

subplot(3,1,2)

if length(gap)>1    % If long gaps exist, plot a vertical red line
    plot(recnum(gap(1)).*[1 1],[-10 6000],'r-');hold on
    for i=2:length(gap)
        plot(recnum(gap(i)).*[1 1],[-10 6000],'r-');
    end
    clear i
end
plot(flipud(recnum),flipud(pres),'x','color',[0 0.5 0]);
LSBonly=SimpleDespike(pres(find(pres<=2 & pres>=0)));
% LSBonly=(pres(find(pres<=2 & pres>=0)));
set(gca,'ylim',...
    [nanmedian(LSBonly)-3.*nanstd(LSBonly) ...
     nanmedian(LSBonly)+3.*nanstd(LSBonly)]);
ylabel('Pressure variabilty, LSB only [ dbar ]');
xlabel('Record number [ days, time increasing to right ]');

%%%% In the third plot, include some statistics as text

MSBonly=pres(find(pres>100));
medianMSBpres=median(MSBonly);
medianLSBpres=nanmedian(LSBonly);
stdLSBpres=nanstd(LSBonly);

subplot(3,1,3)

plot([0 1 NaN NaN],[NaN NaN 0 1],'w-');hold on
eval(['hand=text(0.05,0.85,''Median MSB: ',num2str(medianMSBpres - ...
    rem(medianMSBtau,0.5),4),' dbar'');']);
set(hand,'fontsize',12,'fontweight','bold','color',[0 0.5 0]);
eval(['hand=text(0.05,0.75,''Median LSB: ',num2str(medianLSBpres,3),...
    ' dbar'');']);
set(hand,'fontsize',12,'fontweight','bold','color',[0 0.5 0]);

%%% Test whether the STD is larger than expected

if stdLSBtau>0.005
    eval(['hand=text(0.05,0.65,''STD LSB: ',num2str(stdLSBpres,2),...
        ' dbar'');']);
    set(hand,'fontsize',12,'fontweight','bold','color',[1 0 0]);
else
    eval(['hand=text(0.05,0.65,''STD LSB: ',num2str(stdLSBpres,2),...
        ' dbar'');']);
    set(hand,'fontsize',12,'fontweight','bold','color',[0 0.5 0]);
end
hand=text(0.05,0.35,'Typical standard deviations: 0.02-0.10 dbar');
set(hand,'fontsize',12,'fontweight','bold','color',[0 0.5 0]);

set(gca,'xtick',[],'ytick',[]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%  Now move to the pressure figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


