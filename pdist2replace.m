% This function circumwents the pdist2 function's dependency on the
% statistics toolbox license.
%
% It is taken from 
% https://statinfer.wordpress.com/2011/11/14/efficient-matlab-i-pairwise-distances/

function D = pdist2replace(X, Y)
D = bsxfun(@plus,dot(X',X',1)',dot(Y',Y',1))-2*(X*Y')
D = D.^0.5;
