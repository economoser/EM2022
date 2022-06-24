% -------------------------------------------------------------------------
%
%   %%%%%  Change in the reservation wage to an increase in the MW %%%%%
%
% -------------------------------------------------------------------------
function [ check1 , check2 , check3 ] = CheckReservationWage( Model , ExogParams , NumGrids , Numerical , min_wage , options )

Nz = Numerical.Nz ;
Na = Numerical.Na ;
Delta = 10000 ;
check1 = zeros(Na,1) ;
check2 = zeros(Na,1) ;
check3 = zeros(Na,1) ;
W = ones(Nz+3,1) / ExogParams.rho ;
for a = 1:Na
    
    % preassign
    delta = NumGrids.delta(a) ; 
    deltaMW = NumGrids.deltaMW(a) ;
    lambda = NumGrids.lambda(a) ;
    lambdaMW = NumGrids.lambdaMW(a) ;
    phi = NumGrids.phi(a) ; 
    pi = NumGrids.pi(a) ; 
    w = Model.w(a,:) ;
    v = Model.v(a,:) ;
    R_min = max(NumGrids.R(a),min_wage) ;
    [ ~ , R_min_pos ] = min( abs( NumGrids.a(a)*NumGrids.z - R_min ) );
    R_min_pos = R_min_pos+3 ;
    
    % we're going to multiply these with ability below
    mw = min_wage / NumGrids.a(a) ;
    b = NumGrids.b(a) ;
    
    % offer distribution
    dF = v .* NumGrids.gamma .* NumGrids.dz ;
    dF = dF / sum( dF ) ;

    % transition within and out of minimum wage types, s=0
    MW = [ -lambdaMW    , 0        , sparse( 1 , Nz+1 )     ;
           lambdaMW     , -deltaMW  , sparse( 1 , Nz+1 )    ;
           0            , deltaMW   , sparse( 1 , Nz+1 )    ;
                        sparse( Nz  , Nz+3 )                ] ;

	% separation rate from regular jobs into unemployment and MW
	% unemployment
    S1 = [ sparse(1,3) , pi*delta*ones(1,Nz)     ;
                   sparse(1,Nz+3)                ;
           sparse(1,3) , (1-pi)*delta*ones(1,Nz) ;
                   sparse(Nz,Nz+3)               ] ;
    dia = [ zeros(3,1) ; -delta*ones(Nz,1) ] ;
    S2 = spdiags( dia , 0 , Nz+3 , Nz+3 ) ;
    S = S1+S2 ;
    
    % transition from unemployment to regular jobs and within regular jobs
    M1 = lambda * repmat( [ 1 , phi*ones(1,Nz) ] , Nz+1 , 1 ) .* tril( ones(Nz+1) , -1 ) ;
    M = repmat( [0;dF'] , 1 , Nz+1 ) .* M1 ; 
    m = -spdiags( sum( M , 1 )' , 0 , Nz+1 , Nz+1 ) ;
    M = m+M ;
    M = blkdiag( sparse(2,2) , M ) ;
    A = MW+S+M ;
    T = ( ExogParams.rho + 1/Delta ) * speye( Nz+3 ) - A' ;
    
    % loop over flow values
    error = 1 ;
    iter = 1 ;
    while iter < Numerical.maxiter && error > Numerical.tol
        
        Flow = NumGrids.a(a) * [ b ; mw ; b ; w' ] ;
        Flow(isnan(Flow)) = 0 ;
        W1 = T \ ( Flow + 1/Delta * W ) ;
        error = max(abs(W1-W)) ;
        iter = iter+1 ;
        W = W1 ;
        
    end
    
    % check that workers prefer work to unemployment above reservation wage
    check1(a) = W(3) < W(R_min_pos) ;
    % check that workers prefer unemployment to work below reservation wage
    check2(a) = W(3) >= W(max(R_min_pos-1,3)) ; %| min_wage >= R_min ;
    % check also that workers prefer MW jobs to unemployment
    check3(a) = W(2)>W(1) ;

end

end