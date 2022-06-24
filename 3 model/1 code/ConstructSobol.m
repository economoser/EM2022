%% ========================================================================
% 
%                      CONSTRUCTS GRID FOR SEARCH
% 
% =========================================================================

function [ SobolSequence , Grid , ParameterName , ParameterTitle , n_params ] = ConstructSobol( )

% variables to be internally estimated
mu      =   [    .1     ,     2     ] ;
sigma   =   [   .05     ,    .5     ] ;
zeta    =   [     1     ,     7     ] ;
eta     =   [     .1    ,     1     ] ;
error   =   [    .15    ,    .25    ] ;
delta0  =   [   0.04    ,     .1    ] ;
delta1  =   [    -1     ,    -.5    ] ;
phi0    =   [   0.2     ,     1     ] ;
phi1    =   [    0.5    ,     2     ] ;
r0      =   [    -5     ,     1     ] ;
r1      =   [     0     ,     3     ] ;
pi      =   [  .005     ,    .04    ] ;

ParameterName.mu        = '$\mu$' ;
ParameterName.sigma     = '$\sigma$' ;
ParameterName.zeta      = '$\zeta$' ;
ParameterName.eta       = '$\eta$' ;
ParameterName.error     = '$\epsilon$' ;
ParameterName.delta0    = '$\delta_0$' ;
ParameterName.delta1    = '$\delta_1$' ;
ParameterName.phi0      = '$\phi_0$' ;
ParameterName.phi1      = '$\phi_1$' ;
ParameterName.r0        = '$r_0$' ;
ParameterName.r1        = '$r_1$' ;
ParameterName.pi        = '$\pi$' ;

ParameterTitle.mu       = 'Mean of worker ability'                      ;
ParameterTitle.sigma    = 'Shape of worker ability'                     ;
ParameterTitle.zeta     = 'Shape of productivity distribution'          ;
ParameterTitle.eta      = 'Curvature of vacancy cost'                   ;
ParameterTitle.error    = 'Variance of noise'                           ;
ParameterTitle.delta0   = 'Separation rate, intercept'                  ;
ParameterTitle.delta1   = 'Separation rate, slope'                      ;
ParameterTitle.phi0     = 'Relative search intensity, intercept'        ;
ParameterTitle.phi1     = 'Relative search intensity, slope'            ;
ParameterTitle.r0       = 'Reservation wage, intercept'                 ;
ParameterTitle.r1       = 'Reservation wage, slope'                     ;
ParameterTitle.pi       = 'Transition rate to MW'                       ;

% define grid
Grid = [    mu      ;
            sigma   ;
            zeta    ;
            eta     ;
            error   ;
            delta0  ;
            delta1  ;
            phi0    ;
            phi1    ;
            r0      ;
            r1      ;
            pi      ];

% Sobol sequence
n_params = length(Grid);
SobolSequence = sobolset(n_params);



end