% -------------------------------------------------------------------------
% 
%    %%%%%  Find vacancy cost that rationalizes observed flows  %%%%%
% 
% -------------------------------------------------------------------------
function [ status , w , v , vmw , l , lmw , fw , fz , gw , gz , F , G , dw , u , uMW , e , eMW , NumGrids ] = SolveForCost( R_min , minwage , a , Params , ExogParams , NumGrids , Numerical )

% turn off annoying warning
warning('off','MATLAB:ode45:IntegrationTolNotMet')


%% PREASSIGN
status  = 1 ; % solution is assumed unless proven otherwise
delta = NumGrids.delta(a) ; 
deltaMW = NumGrids.deltaMW(a) ;
lambda = NumGrids.lambda(a) ;
lambdaMW = NumGrids.lambdaMW(a) ;
phi     = NumGrids.phi(a) ; 
pi      = NumGrids.pi(a) ; 
z       = NumGrids.z ;
dz      = NumGrids.dz ;
gamma   = NumGrids.gamma ;


%% SOLVE FOR THE SHARE OF WORKERS IN DIFFERENT STATES
T = [ -lambdaMW , 0         ,   0       , delta*pi      ;
       lambdaMW , -deltaMW  ,   0       , 0             ;
          0     , deltaMW   , -lambda   , delta*(1-pi)  ;
          0     , 0         ,  lambda   , -delta        ] ;
[ V , ~ ] = eigs(-T,1,0) ;
V = V ./ sum(V) ;
uMW = V(1) ;
eMW = V(2) ;
u = V(3) ;
e = V(4) ;
S = NumGrids.psi(a) * NumGrids.da(a) * ( u + NumGrids.phi(a)*e ) ;
E = NumGrids.psi(a) * NumGrids.da(a) * e ;
EMW = NumGrids.psi(a) * NumGrids.da(a) * eMW ;
U = NumGrids.psi(a) * NumGrids.da(a) * u ;
UMW = NumGrids.psi(a) * NumGrids.da(a) * uMW ;
V = lambda^(1/ExogParams.alpha)*S ;
VMW = lambdaMW^(1/ExogParams.alpha)*UMW ;

% find the lowest feasible productivity
[ ~ , R_min_pos ] = min( abs( z - R_min ) );

% if no feasible vacancy creation, return
if R_min_pos >= Numerical.Nz-1
    status  = 0 ;
    w       = nan( 1 , Numerical.Nz ) ;
    v       = zeros( 1 , Numerical.Nz ) ;
    vmw     = zeros( 1 , Numerical.Nz ) ;
    l       = zeros( 1 , Numerical.Nz ) ;
    lmw     = zeros( 1 , Numerical.Nz ) ;
    fw      = zeros( 1 , Numerical.Nz ) ;
    fz      = zeros( 1 , Numerical.Nz ) ;
    gw      = zeros( 1 , Numerical.Nz ) ;
    gz      = zeros( 1 , Numerical.Nz ) ;
    F       = zeros( 1 , Numerical.Nz ) ;
    G       = zeros( 1 , Numerical.Nz ) ;
    dw      = zeros( 1 , Numerical.Nz ) ;
    u       = 0 ;
    uMW     = 0 ;
    e       = 0 ;
    eMW     = 0 ;
    NumGrids.cost(a) = NaN ;
    NumGrids.lambdaMW(a) = NaN ;
    return
end
% else remove non-feasible firms
M = ExogParams.M ;
if R_min_pos > 1 
    GAMMA = cumsum( gamma .* dz );
    M = ExogParams.M*(1-GAMMA(R_min_pos-1));
end
gamma = gamma(R_min_pos:end) ;
z = z(R_min_pos:end);
dz = dz(R_min_pos:end);
gamma = gamma / sum( gamma .* dz ) ;

% temp = cumsum(NumGrids.psi.*NumGrids.da) ;
% [ temp(a) , max(NumGrids.R(a),1)./NumGrids.a(a) , R_min_pos ]

%% APPLY A BISECTION TO FIND THE COST OF CREATING JOBS
%   (1) guess an initial cost, solve the problem
%   (2) check whether the CDF integrates to one
%   (3) if too few jobs are created, lower c. otherwise raise c. iterate to convergence
% initial conditions
% start with a low cost: firms need to create "too many" jobs in order for bisection to work
% c0 = 10 ;
if a == 1
    c0 = 1e04 / ( NumGrids.psi(a).*NumGrids.da(a) ) ;
elseif isnan(NumGrids.cost(a-1))
    c0 = 1e04 / ( NumGrids.psi(a).*NumGrids.da(a) ) ;
else
    c0 = NumGrids.cost(a-1) ;
end
c0 = c0/10 ;

% initial condition
y0 = [ R_min ; 0 ] ;

% solve system of differential equations forward
[t,y] = ode45( @(t,y) DiffEq( t , y , z , gamma , M , delta , lambda , phi , U , V , Params , c0 ) , z , y0 ) ;       
% sometimes ode45 algorithm assigns a degenerate grid for z
if length(z) == 2
    t = [ t(1) ; t(end) ];
    y = [ y( 1 , : ) ; y( end , : ) ] ;
end

% if firms create too few jobs, cut cost
iter = 1;   maxiter = 5 ;
while y(end,2) < 1 && iter < maxiter
    % new initial guess
    c0 = c0 / 100 ;
    y0 = [ R_min ; 0 ] ;
    % solve system of differential equations forward
    [t,y] = ode45( @(t,y) DiffEq( t , y , z , gamma , M , delta , lambda , phi , U , V , Params , c0 ) , z , y0 ) ;
    if length(z) == 2
        t = [ t(1) ; t(end) ];
        y = [ y( 1 , : ) ; y( end , : ) ] ;
    end
    iter = iter + 1;
end

% if no cost is found, exit the problem
if y(end,2) < 1
    status  = -1 ;
    w       = nan( 1 , Numerical.Nz ) ;
    v       = zeros( 1 , Numerical.Nz ) ;
    vmw     = zeros( 1 , Numerical.Nz ) ;
    l       = zeros( 1 , Numerical.Nz ) ;
    lmw     = zeros( 1 , Numerical.Nz ) ;
    fw      = zeros( 1 , Numerical.Nz ) ;
    fz      = zeros( 1 , Numerical.Nz ) ;
    gw      = zeros( 1 , Numerical.Nz ) ;
    gz      = zeros( 1 , Numerical.Nz ) ;
    F       = zeros( 1 , Numerical.Nz ) ;
    G       = zeros( 1 , Numerical.Nz ) ;
    dw      = zeros( 1 , Numerical.Nz ) ;
    u       = 0 ;
    uMW     = 0 ;
    e       = 0 ;
    eMW     = 0 ;
    NumGrids.cost(a) = NaN ;
    NumGrids.lambdaMW(a) = NaN ;
    return
end


% start with a high cost: firms need to create "too few" jobs in order for bisection to work
c1 = 100*c0 ;
y0 = [ R_min ; 0 ] ;

% solve system of differential equations forward
[t,y] = ode45( @(t,y) DiffEq( t , y , z , gamma , M , delta , lambda , phi , U , V , Params , c1 ) , z , y0 ) ;
if length(z) == 2
    t = [ t(1) ; t(end) ];
    y = [ y( 1 , : ) ; y( end , : ) ] ;
end

% if firms create too many jobs, increase cost
iter = 1;   maxiter = 5 ;
while y(end,2) > 1 && iter < maxiter
    % 2nd initial guess for cost
    c1 = c1 * 100 ;
    y0 = [ R_min ; 0 ] ;
    % solve system of differential equations forward
    [t,y] = ode45( @(t,y) DiffEq( t , y , z , gamma , M , delta , lambda , phi , U , V , Params , c1 ) , z , y0 ) ;
    if length(z) == 2
        t = [ t(1) ; t(end) ];
        y = [ y( 1 , : ) ; y( end , : ) ] ;
    end
    iter = iter + 1 ;
end
% if no cost is found, exit the problem
if y(end,2) > 1
    status  = -1 ;
    w       = nan( 1 , Numerical.Nz ) ;
    v       = zeros( 1 , Numerical.Nz ) ;
    vmw     = zeros( 1 , Numerical.Nz ) ;
    l       = zeros( 1 , Numerical.Nz ) ;
    lmw     = zeros( 1 , Numerical.Nz ) ;
    fw      = zeros( 1 , Numerical.Nz ) ;
    fz      = zeros( 1 , Numerical.Nz ) ;
    gw      = zeros( 1 , Numerical.Nz ) ;
    gz      = zeros( 1 , Numerical.Nz ) ;
    F       = zeros( 1 , Numerical.Nz ) ;
    G       = zeros( 1 , Numerical.Nz ) ;
    dw      = zeros( 1 , Numerical.Nz ) ;
    u       = 0 ;
    uMW     = 0 ;
    e       = 0 ;
    eMW     = 0 ;
    NumGrids.cost(a) = NaN ;
    NumGrids.lambdaMW(a) = NaN ;
    return
end


% iterate to convergence
iter = 1 ;
maxiter = 1000 ;
while abs(c0-c1)/((c0+c1)/2) > Numerical.tol && iter < maxiter
    % bisection
    c2 = (c1+c0)/2;
    y0 = [ R_min ; 0 ] ;
    % solve system of differential equations forward
    [t,y] = ode45( @(t,y) DiffEq( t , y , z , gamma , M , delta , lambda , phi , U , V , Params , c2 ) , z , y0 ) ;
    if length(z) == 2
        t = [ t(1) ; t(end) ];
        y = [ y( 1 , : ) ; y( end , : ) ] ;
    end
    % if too few jobs are created, lower the cost, otherwise raise the cost
    if y(end,2)-1 < 0
        c1 = c2;
    else
        c0 = c2;
    end
    iter = iter+1;
    if abs(y(end,2)-1) < Numerical.tol
        break
    end
end
cost = c2;


% output error
if (iter == maxiter && abs(y(end,2)-1) > 1.e-02) || cost < 1.e-12 || length(t) < length(z)
    status  = -1 ;
    w       = nan( 1 , Numerical.Nz ) ;
    v       = zeros( 1 , Numerical.Nz ) ;
    vmw     = zeros( 1 , Numerical.Nz ) ;
    l       = zeros( 1 , Numerical.Nz ) ;
    lmw     = zeros( 1 , Numerical.Nz ) ;
    fw      = zeros( 1 , Numerical.Nz ) ;
    fz      = zeros( 1 , Numerical.Nz ) ;
    gw      = zeros( 1 , Numerical.Nz ) ;
    gz      = zeros( 1 , Numerical.Nz ) ;
    F       = zeros( 1 , Numerical.Nz ) ;
    G       = zeros( 1 , Numerical.Nz ) ;
    dw      = zeros( 1 , Numerical.Nz ) ;
    u       = 0 ;
    uMW     = 0 ;
    e       = 0 ;
    eMW     = 0 ;
    NumGrids.cost(a) = NaN ;
    NumGrids.lambdaMW(a) = NaN ;
    return
end

% get derivative to construct vacancy policy and flow value of leisure
[ wp , fz ] = GetDerivative( t , y , z , gamma , M , delta , lambda , phi , U , V , Params , cost ) ;

% force fz to integrate to one
fz = fz ./ nansum( fz' .* dz ) ;

% vacancy policy
v = V / M * fz ./ gamma' ;
v( gamma == 0 ) = 0 ;

% assign
w = y( : , 1 ) ;
h = y( : , 2 ) ;
F = h ;
fw = fz ./ wp ;

% wage distribution
gw = U/E * fw * ( delta/lambda + phi ) ./ ( delta/lambda + phi * ( 1 - F ) ).^2 ;
gz = U/E * fz * ( delta/lambda + phi ) ./ ( delta/lambda + phi * ( 1 - F ) ).^2 ;
G = lambda * F ./ ( delta + phi*lambda*(1-F)) .* U / E ;

% steady state firm size
l = (v / V) .* ( U + phi*E*G ) ./ ( delta/lambda + phi*( 1 - F ) ) ;
l( isnan( l ) ) = 0 ;

% force also mass to add up to overall employment
l = E * l ./ sum( l' .* gamma .* dz ) / M ;

% include inactive firms
F = [ zeros(R_min_pos-1,1) ; F ]' ;
F = F ./ F(end) ;
G = [ zeros(R_min_pos-1,1) ; G ]' ;
G = G ./ G(end) ;
fw = [ zeros(R_min_pos-1,1) ; fw ]' ;
fz = [ zeros(R_min_pos-1,1) ; fz ]' ;
gw = [ zeros(R_min_pos-1,1) ; gw ]' ;
gz = [ zeros(R_min_pos-1,1) ; gz ]' ;
w = [ nan(R_min_pos-1,1) ; w ]' ;
% dw = w'(z) * dz
dw = [ nan(R_min_pos-1,1) ; wp ]' ;
dw = dw .* NumGrids.dz ;
l = [ zeros(R_min_pos-1,1) ; l ]' ;
v = [ zeros(R_min_pos-1,1) ; v ]' ;

% make sure it integrates to one
fz = fz ./ nansum( fz .* NumGrids.dz ) ;
fw = fw ./ nansum( fw .* dw ) ;
gw = gw ./ nansum( gw .* dw ) ;
gz = gz ./ nansum( gz .* NumGrids.dz ) ;
%% solve problem in minimum wage market
temp = sum( max(NumGrids.z - minwage,0).^(1/Params.eta) .* NumGrids.gamma .* NumGrids.dz ) ;
c = ExogParams.M^Params.eta * UMW^(1-ExogParams.alpha) * VMW^(ExogParams.alpha-1-Params.eta) * 1/deltaMW * temp.^Params.eta ;
vmw = ( max(NumGrids.z - minwage,0) * ( VMW / UMW )^(ExogParams.alpha-1) * 1/deltaMW * 1/c ).^(1/Params.eta) ;
lmw = vmw / deltaMW * ( VMW / UMW )^(ExogParams.alpha-1) ;
costMW = c ;

NumGrids.cost(a) = cost ;
NumGrids.costMW(a) = costMW ;

end