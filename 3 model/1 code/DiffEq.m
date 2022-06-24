% -------------------------------------------------------------------------
% 
%          %%%%%  Solve system of differential equations  %%%%%
% 
% -------------------------------------------------------------------------
function dydt = DiffEq( z , y , zt , gamma , M , delta , lambda , phi , u , V , Params , c )

% assign initial condition
w = y( 1 ) ;
h = y( 2 ) ;
    
% interpolate density given at exogenous grid to get at endogenous grid
gamma = interp1( zt , gamma , z ) ; 

% ensure CDF properties hold
% h = max( min( h , 1 ) , 0 );

% differential equations
temp = 1 / c * ...
        ( z - w ) * ...
        u/V * lambda * ...
        (delta + phi*lambda) ./ (delta + phi*lambda*(1-h)).^2  ;
hp = M * gamma / V .* ( max( temp , 0 ) ).^( 1 / Params.eta );
wp = ( z - w ) .* 2 .* phi .* lambda .* hp ./ ( delta + phi*lambda*(1-h) ) ;

% ensure that vacancies increase strictly
dydt = [ max(wp,0) ; max(hp,0) ] ;

end