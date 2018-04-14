function output=SimpleDespike(input,numstdlev);
%
% function output=SimpleDespike(input,numstdlev);
%
% This function does a simple despike of an input vector by removing points 
% greater or less than numstdlev standard deviations away from the median 
% value.  The default number of standard deviations is three.  
% Christopher S. Meinen
%

if ~exist('numstdlev','var');
    numstdlev=3;
end

input=input(:);

nonnan=find(~isnan(input));
MedianValue=median(input(nonnan));
STDValue=std(input(nonnan));

bad=find(abs(input-MedianValue)>(numstdlev*STDValue));
input(bad)=NaN;

output=input;