function [output]=nanstd(input);
%
% function [output]=nanstd(input);
%
% This function is designed to find the standard deviation value of each 
% column in an array that includes NaNs.  (If the input array has no NaNs 
% the function will still work but in not as efficient as the Matlab "std"
% function.)  This function will also work on a vector.  
% Christopher S. Meinen
%
[m,n,p,q]=size(input);
if m==1 && n~=1 && p==1 && q==1  %This deals with a row vector
 input=input';
 [m,n]=size(input);
end
if p==1 && q==1
  output=NaN*ones(1,n);
  for i=1:n
    dummy=input(:,i);
    ii=find(~isnan(dummy));
    if ~isempty(ii)
     output(i)=std(dummy(ii));
    end
  end
elseif p~=1 && q==1  
  output=NaN*ones(1,n,p);
  for i=1:n
    for j=1:p
      dummy=squeeze(input(:,i,j));
      ii=find(~isnan(dummy));
      if ~isempty(ii)
        output(1,i,j)=std(dummy(ii));
      end
    end
  end
elseif p~=1 && q~=1
  output=NaN*ones(1,n,p,q);
  for i=1:n
    for j=1:p
      for k=1:q
        dummy=squeeze(input(:,i,j,k));
        ii=find(~isnan(dummy));
        if ~isempty(ii)
          output(1,i,j,k)=std(dummy(ii));
        end
      end
    end
  end
end




