% -------------------------------------------------------------------------
%
%                   %%%%%  Solves the problem  %%%%%
%
% -------------------------------------------------------------------------
function [ WAGE , active , Moments , MomentsByDecile , MomentsByDecileFE , Model , NumGrids , error ] = Solve( Params , ExogParams , NumGrids , Numerical , min_wage , options )

EMPID = nan( Numerical.N , Numerical.T/12 ) ;
WAGE = nan( Numerical.N , Numerical.T/12 ) ;
PROD = nan( Numerical.N , Numerical.T/12 ) ;
ABIL = nan( Numerical.N , Numerical.T/12 ) ;
EE = nan( Numerical.N , Numerical.T ) ;
EN = nan( Numerical.N , Numerical.T ) ;
MN = nan( Numerical.N , Numerical.T ) ;
EMP = nan( Numerical.N , 1 ) ;
M = nan( Numerical.N , 1 ) ;
UN = nan( Numerical.N , 1 ) ;
active = ones( Numerical.Na , 1 ) ;
for s = { 'w' , 'v' , 'vmw' , 'l' , 'lmw' , 'fw' , 'fz' , 'gw' , 'gz' , 'F' , 'G' , 'dw' , 'e' , 'u' , 'eMW' , 'uMW' }
    Model.(s{1}) = [] ;
end
i2 = 0 ;
for a = 1:Numerical.Na 
    
    if nanmean(active) == 1
        
        %% solve the problem
        % compute minimum feasible pay in market a 
        %   (1) MW is in logs
        %   (2) We're solving the model in terms of piece rates, so need to
        %       divide by worker ability
        R_min   = max( exp( min_wage ) , NumGrids.R(a) ) / NumGrids.a( a ) ;

        % in estimation, solve for cost that rationalizes equilibrium flows
        if strcmp(options.Estimation,'Y')
            [ status , w , v , vmw , l , lmw , fw , fz , gw , gz , F , G , dw , u , uMW , e , eMW , NumGrids ] = SolveForCost( R_min , exp( min_wage ) / NumGrids.a( a ) , a , Params , ExogParams , NumGrids , Numerical ) ;
        % when computing the effect of the MW hike, solve for equilibrium flows
        % under the estimated cost
        else
            [ status , w , v , vmw , l , lmw , fw , fz , gw , gz , F , G , dw , u , uMW , e , eMW , NumGrids ] = SolveForFlows( R_min , exp( min_wage ) / NumGrids.a( a ) , a , Params , ExogParams , NumGrids , Numerical ) ;
        end
        
        
        % don't do this in eval due to stability issues
        Model.w = [ Model.w ; w ] ;
        Model.v = [ Model.v ; v ] ;
        Model.vmw = [ Model.vmw ; vmw ] ;
        Model.l = [ Model.l ; l ] ;
        Model.lmw = [ Model.lmw ; lmw ] ;
        Model.fw = [ Model.fw ; fw ] ;
        Model.fz = [ Model.fz ; fz ] ;
        Model.gw = [ Model.gw ; gw ] ;
        Model.gz = [ Model.gz ; gz ] ;
        Model.F = [ Model.F ; F ] ;
        Model.G = [ Model.G ; G ] ;
        Model.dw = [ Model.dw ; dw ] ;
        Model.e = [ Model.e ; e ] ;
        Model.u = [ Model.u ; u ] ;
        Model.eMW = [ Model.eMW ; eMW ] ;
        Model.uMW = [ Model.uMW ; uMW ] ;
        
        %% simulate the problem
        if status > 0
            try
                N = floor(Numerical.N*NumGrids.psi(a)*NumGrids.da(a)) ;
                [ empid , wage , prod , ee , en , mn , e , m , u ] = Simulate( a , w , v , vmw , l , lmw , u , uMW , e , eMW , exp( min_wage ) , Params , ExogParams , NumGrids , Numerical , N );
                i1 = i2+1 ;
                i2 = i1+N-1 ;
                EMPID(i1:i2,:) = empid ; 
                WAGE(i1:i2,:) = wage ;
                ABIL(i1:i2,:) = NumGrids.a(a) ;
                PROD(i1:i2,:) = prod ;
                EE(i1:i2,:) = ee ;
                EN(i1:i2,:) = en ;
                MN(i1:i2,:) = mn ;
                EMP(i1:i2) = e ;
                M(i1:i2) = m ;
                UN(i1:i2) = u ;
                active(a) = 1 ;
            catch
                active(a) = 0 ;
            end
        else
            active(a) = 0 ;
        end
        
    end

end

% run AKM on simulated data
if min( isnan( EMPID(:) ) ) == 0 && nanmean(active) == 1
    error = 0 ;
    [ Moments , MomentsByDecile , MomentsByDecileFE ] = ComputeMoments( EMPID , WAGE , ABIL , PROD , EE , EN , EMP , M , UN , MN , min_wage , Params ) ;
else
    error = 1 ;
    Moments = 0 ;
    MomentsByDecile = 0 ;
    MomentsByDecileFE = 0 ;
end

end