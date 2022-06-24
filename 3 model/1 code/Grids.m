% -------------------------------------------------------------------------
%
%        %%%%%   Constructs grids for worker and firm types %%%%%
%
% -------------------------------------------------------------------------
function [ NumGrids ] = Grids( Params , ExogParams , Numerical )




%% worker ability groups
a = linspace( 0 , icdf('exp',.99,Params.sigma) , Numerical.Na/2+1 ) ;
cdf1 = cdf('exp',a,Params.sigma) ;
dens1 = cdf1(2:end)-cdf1(1:end-1) ;
a2 = sort(-a(2:end)) ;
a = [ a2' ; a' ] ;
dens2 = sort(dens1) ;
dens = [ dens2' ; dens1' ] ;
% distance between points
a = exp( Params.mu + a ) ;
d = a(2:end)-a(1:end-1) ;
a = (a(2:end)+a(1:end-1))/2 ;

% density should ensure cumulative sum holds
% dens = (1/(Numerical.Na+1)) ./ d ;
% dens(end) = 5*dens(end) ; 
dens = dens ./ d ;
dens = dens ./ sum( dens .* d ) ;
NumGrids.a = a ;
NumGrids.da = d ;
NumGrids.psi = dens ;

% load labor market flows
% grid = (1:Numerical.Na)/Numerical.Na ;
grid = cumsum( dens .* d ) ;
NumGrids.delta      = max( Params.delta0 + Params.delta0*Params.delta1*grid , 1e-03 ) ;
NumGrids.deltaMW    = ExogParams.deltaMW * ones( size(a) ) ;
NumGrids.phi        = max( Params.phi0 + Params.phi0*Params.phi1*(exp(grid)-exp(grid(1))) , 1e-03 ) ;
NumGrids.lambda     = ExogParams.lambda * ones( size(a) ) ;
NumGrids.lambdaMW   = ExogParams.lambdaMW * ones( size(a) ) ;
NumGrids.pi         = Params.pi * ones( size(a) ) ;
NumGrids.cost       = nan( Numerical.Na , 1 ) ;
NumGrids.costMW     = nan( Numerical.Na , 1 ) ;
NumGrids.R          = Params.r0 + Params.r1*(a-a(1)) ;



%% firm productivity type
z = linspace( icdf('gp',.01,1/Params.zeta,1/Params.zeta,1) , icdf('gp',.999,1/Params.zeta,1/Params.zeta,1) , Numerical.Nz+1 ) ;
dens = cdf('gp',z,1/Params.zeta,1/Params.zeta,1) ;
d = z(2:end)-z(1:end-1);
dens = dens(2:end)-dens(1:end-1);
z = (z(1:end-1)+z(2:end))/2 ;
% convert pmf to pdf
dens = dens ./ d ;
dens = dens ./ sum( dens .* d ) ;
NumGrids.z = z ;
NumGrids.dz = d ;
NumGrids.gamma = dens ;




%% pre-assign a set of firms for simulation
rng(1)
NumGrids.z_sim = datasample(1:Numerical.Nz,Numerical.Nf,'Weights',NumGrids.gamma.*NumGrids.dz)' ;



end
