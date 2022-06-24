%% ========================================================================
% 
%     SOLVE DIFFERENTIAL EQUATION SYSTEM FOR GIVEN PARAMETER VALUES
% 
% =========================================================================
function [ wp , Jp ] = GetDerivative( z , y , zt , gamma , M , delta , lambda , phi , u , V , Params , c )

% assign initial condition
w = y( 1 , 1 ) ;
J = y( 1 , 2 ) ;

% interpolate density given at exogenous grid to get at endogenous grid
g = interp1( zt , gamma , z ) ; 

% ensure CDF properties hold
% J = max( min( J , 1 ) , 0 );

% differential equations
temp = 1 / c * ...
        ( z - w ) * ...
        u/V * lambda * ...
        (delta + phi*lambda) ./ (delta + phi*lambda*(1-J)).^2  ;
temp2 = M * g / V .* ( max( temp , 0 ) ).^( 1 / Params.eta );
temp1 = ( z - w ) .* 2 .* phi .* lambda .* temp2 ./ ( delta + phi*lambda*(1-J) ) ;

Jp = temp2 ;
wp = temp1 ;

end