% -------------------------------------------------------------------------
%
%                %%%%%   Defines numerical settings   %%%%%
%
% -------------------------------------------------------------------------
function Numerical = NumericalApproximations( ExogParams )

Numerical.Nz    = 500   ;   % # firm types
Numerical.Na    = 50    ;   % # worker types
Numerical.N     = 1000000 ;   % # workers of each type to simulate
Numerical.T     = 12*5  ;   % # periods to simulate
Numerical.Nf    = round( ExogParams.M * Numerical.N ) ; % # of simulated firms
Numerical.maxiter = 5000 ;
Numerical.tol   = 1e-10 ;

end