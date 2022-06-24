% -------------------------------------------------------------------------
%
%             %%%%%   Defines exogenously set parameters %%%%%
%
% -------------------------------------------------------------------------
function [ ExogParams ] = ExogenousParameters

ExogParams.alpha    = 0.5 ;             % elasticity of matches wrt vacancies
ExogParams.rho      = -log(.95)/12 ;    % discount rate

% preset these parameters based on average in 1994-1998
ExogParams.M        = 3/2 * 0.5451 / 11.7862 ; % employment rate divided by average firm size, plus arbitrary adjustment
ExogParams.lambda   = 0.0444470 ; % average ne mobility rate
ExogParams.lambdaMW = 0.0444470 ; % fix to same value
ExogParams.deltaMW  = 0.0651738 ; % average mn mobility rate

end