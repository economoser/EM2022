% -------------------------------------------------------------------------
% 
%    %%%%%  Find vacancy cost that rationalizes observed flows  %%%%%
% 
% -------------------------------------------------------------------------
function [ status , w , v , vmw , l , lmw , fw , fz , gw , gz , F , G , dw , u , uMW , e , eMW , NumGrids ] = SolveForFlows( R_min , minwage , a , Params , ExogParams , NumGrids , Numerical ) 

% turn off annoying warning
warning('off','MATLAB:ode45:IntegrationTolNotMet')


%% PREASSIGN
status  = 1 ; % solution is assumed unless proven otherwise
Nz      = Numerical.Nz ; 
for s = { 'delta' , 'deltaMW' , 'lambda' , 'lambdaMW' , 'phi' , 'pi' , 'cost' , 'costMW' }
    eval([ char(s) '= NumGrids.' char(s) '( ' num2str(a) ') ;' ])
end
delta = delta ; % This is needed because of a MATLAB BUG!!!!
deltaMW = deltaMW ; % This is needed because of a MATLAB BUG!!!!
lambda = lambda ; % This is needed because of a MATLAB BUG!!!!
lambdaMW = lambdaMW ; % This is needed because of a MATLAB BUG!!!!
phi = phi ; % This is needed because of a MATLAB BUG!!!!
pi = pi ; % This is needed because of a MATLAB BUG!!!!
cost = cost ; % This is needed because of a MATLAB BUG!!!!
costMW = costMW ; % This is needed because of a MATLAB BUG!!!!
z       = NumGrids.z ;
dz      = NumGrids.dz ;
gamma   = NumGrids.gamma ;

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



%% START FROM ORIGINAL FINDING RATES AND REDUCE GRADUALLY
iter = 1 ;
error = 1 ;
update = .01 ;
updateMW = .01 ;
tol = 10*Numerical.tol ;
while error > tol && iter < Numerical.maxiter

    % compute stocks
%     denom = piMW*deltaMW*lambda + piMW*deltaMW*delta + pi*deltaMW*delta + pi*delta*lambdaMW ;
%     uMW = pi * deltaMW * delta / denom ;
%     u = piMW * deltaMW * delta / denom ;
%     eMW = pi * lambdaMW * delta / denom ;
%     e = 1-uMW-u-eMW ;
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
    U = NumGrids.psi(a) * NumGrids.da(a) * u ;
    V = lambda^(1/ExogParams.alpha)*S ;

    % initial conditions
    y0 = [ R_min ; 0 ] ;

    % solve system of differential equations forward
    [t,y] = ode45( @(t,y) DiffEq( t , y , z , gamma , M , delta , lambda , phi , U , V , Params , cost ) , z , y0 ) ;

    % sometimes ode45 algorithm assigns a degenerate grid for z
    if length(z) == 2
        t = [ t(1) ; t(end) ];
        y = [ y( 1 , : ) ; y( end , : ) ] ;
    end
    error1 = abs( y(end,2)-1 ) ;
    
    % solve problem in minimum wage market
    EMW = NumGrids.psi(a) * NumGrids.da(a) * eMW ;
    UMW = NumGrids.psi(a) * NumGrids.da(a) * uMW ;
    VMW = lambdaMW^(1/ExogParams.alpha)*UMW ;
    qmw = ( VMW / UMW )^(ExogParams.alpha-1) ;
    vmw = ( max(NumGrids.z - minwage,0) * qmw * 1/deltaMW * 1/costMW ).^(1/Params.eta) ;
    VMW1 = M * sum( vmw .* (NumGrids.gamma .* NumGrids.dz) ) ;
    error2 = abs( (VMW1-VMW)/VMW ) ;

    % check convergence
    if error1 > tol 
        if y(end,2) - 1 > 0
            lambda = lambda+update ;
        else
            lambda = lambda-update ;
        end
        if mod( iter , 20 ) == 0
            update = update / 2 ;
        end
    end
    if error2 > tol 
        if VMW1 > VMW
            lambdaMW = lambdaMW+updateMW ;
        else
            lambdaMW = lambdaMW-updateMW ;
        end
        if mod( iter , 20 ) == 0
            updateMW = updateMW / 2 ;
        end
    end
    iter = iter+1;
    error = max([error1,error2]) ;
 
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

% average firm size in market
lmw = vmw / deltaMW * ( VMW / UMW )^(ExogParams.alpha-1) ;

NumGrids.lambda(a) = lambda ;
NumGrids.lambdaMW(a) = lambdaMW ;

end