% -------------------------------------------------------------------------
%
%       %%%%%  Computes the associated flow value of leisure %%%%%
%
% -------------------------------------------------------------------------
function [ NumGrids , check ] = FindFlowValue( Model , ExogParams , NumGrids , Numerical , min_wage , options )

Nz = Numerical.Nz ;
Na = Numerical.Na ;
Delta = 10000 ;
B = 5*ones(Na,1) ;
check = zeros(Na,1) ;
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
    R_min   = max( exp( min_wage ) , NumGrids.R(a) ) ;
    [ ~ , R_min_pos ] = min( abs( NumGrids.a(a)*NumGrids.z - R_min ) );
    R_min_pos = R_min_pos+3 ;
    
    % we're going to multiply these with ability below
    mw = min_wage / NumGrids.a(a) ;
    if a == 1
        b = B(a) ;
    else
        b = 1.5*b ;
    end
    
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
        W = T \ ( Flow + 1/Delta * W ) ;
        error = W(3) > W(R_min_pos) ;
        iter = iter+1 ;
        if W(3) > W(R_min_pos)
            b = b-.05 ;
        end
        
    end
    B(a) = b ;
    
    % check that workers prefer MW jobs to unemployment
    check(a) = W(2)>W(1) ;

end
NumGrids.b = B ;

end