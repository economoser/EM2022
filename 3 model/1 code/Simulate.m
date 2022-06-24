%% ========================================================================
%
% SIMULATE.m simulates the problem given a solution
%
% =========================================================================
function [ EMPID , WAGE , PROD , EE , EN , MN , E , M , U ] = Simulate( a , w , v , vmw , l , lmw , U , UMW , E , EMW , MinWage , Params , ExogParams , NumGrids , Numerical , N )

rng(1)

% pick up relevant variables -> cannot use eval due to parfor bug
% clear delta deltaMW lambda lambdaMW phi pi piMW
% for s = { 'delta' , 'deltaMW' , 'lambda' , 'lambdaMW' , 'phi' , 'pi' , 'piMW' }
%     eval([ char(s) '= NumGrids.' char(s) '( ' num2str(a) ') ;' ])
% end
delta = NumGrids.delta(a) ; 
deltaMW = NumGrids.deltaMW(a) ;
lambda = NumGrids.lambda(a) ;
lambdaMW = NumGrids.lambdaMW(a) ;
phi = NumGrids.phi(a) ; 
pi = NumGrids.pi(a) ; 
T = Numerical.T ;
Nf = Numerical.Nf ;
z = NumGrids.z_sim ; 

% convert piece rates to wages
w = NumGrids.a(a) * w ;

% assign them a vacancy weight for worker mobility
f = v( z ) ;
f = f / nansum( f ) ;
% assign them an initial weight based on steady-state size
g = l( z ) ;
g = g / nansum( g ) ;
% assign them a vacancy weight for worker mobility
fmw = vmw( z ) ;
fmw = fmw / nansum( fmw ) ;
% assign them an initial weight based on steady-state size
gmw = lmw( z ) ;
gmw = gmw / nansum( gmw ) ;
% assign also an employer ID
firm = (1:Nf)' ; 

% draw an initial firm
% s = RandStream('mlfg6331_64');
% rnd_error = exp( Params.error * randn(N,T)) ;
error = repmat( randn(N,1,T/12) , 1 , 12 , 1 ) ;
error = reshape( error , N , T ) ;
rnd_error = exp( Params.error * error ) ;
clear error

% draw an initial employment state
rnd_employment = datasample( 1:4 , N , 'Weights' , [ UMW ; EMW ; U ; E ] ) ;

% draw an initial firm for those who are regularly employed
rnd_firm_initial = datasample( firm , N , 'Weights' , g ) ;
rnd_firm_initial_mw = datasample( firm , N , 'Weights' , gmw ) ;

% draw firms for those who move in regular employment
rnd_firm = datasample( firm , N*T , 'Weights' , f ) ;
rnd_firm = reshape( rnd_firm , N , T ) ;
rnd_firm_mw = datasample( firm , N*T , 'Weights' , fmw ) ;
rnd_firm_mw = reshape( rnd_firm_mw , N , T ) ;

% draw hazard rates
rnd_trans   = rand( N , T ) ;
WAGE        = zeros( N , T/12 ) ;
PROD        = zeros( N , T/12 ) ;
EMPID       = zeros( N , T/12 ) ;
EE          = zeros( N , T ) ;
EN          = zeros( N , T ) ;
MN          = zeros( N , T ) ;
E           = zeros( N , 1 ) ;
M           = zeros( N , 1 ) ;
for i = 1:N
    
    % allow for up to T employment spells for up to T months
    empid = nan( 1 , T ) ;
    wage = nan( 1 , T ) ;
    prod = nan( 1 , T ) ;   
    months = nan( 1 , T ) ;
    spell = nan(1,T) ;
    
    % start from ergodic distribution
    spell(1) = 0 ;
    status = rnd_employment(i) ;
    if status == 2
        spell(1) = 1 ;
        empid(1) = rnd_firm_initial_mw( i ) ;
        wage(1) = MinWage ;
        prod(1) = NumGrids.z(z(empid(1))) ;
        months(1) = 1 ;
    elseif status == 4
        spell(1) = 1 ; 
        empid(1) = rnd_firm_initial( i ) ;
        wage(1) = w( z( empid(1) ) ) ;
        prod(1) = NumGrids.z(z(empid(1))) ;
        months(1) = 1 ;
    end
    for t=2:T
        spell(t) = spell(t-1) ;
        % those previously minimum wage unemployed
        if status == 1
            % transition across s states comes first
%             if rnd_trans(i,t) < piMW
%                 status = 3 ;
            % minimum wage job offer
            if rnd_trans(i,t) < lambdaMW
                spell(t) = spell(t)+1 ;
                status = 2 ;
                empid( t ) = rnd_firm_mw( i , t ) ;
                wage( t ) = MinWage ;
                prod( t ) = NumGrids.z(z(empid(t))) ;
                months( t ) = 1 ;
            else
                status = 1 ;
            end
        elseif status == 2
            % if separated, return to regular market
            if rnd_trans(i,t) < deltaMW
                status = 3 ;
            else
                status = 2 ;
                empid( t ) = empid( t-1 ) ;
                wage( t ) = MinWage ;
                prod( t ) = NumGrids.z(z(empid(t))) ;
                % start of new year
                if mod(t,12)==1
                    months(t) = 1;
                else
                    months(t) = months(t-1)+1;
                end
            end
        elseif status == 3
            % transition across s states comes first
%             if rnd_trans(i,t) < pi
%                 status = 1 ;
            % regular job offer
            if rnd_trans(i,t) < lambda
                spell(t) = spell(t)+1 ;
                status = 4 ;
                empid( t ) = rnd_firm( i , t ) ;
                wage( t ) = w( z( empid( t ) ) ) ;
                prod( t ) = NumGrids.z(z(empid(t))) ;
                months( t ) = 1 ;
            else
                status = 3 ;
            end
        else
            % separation to regular unemployment
            if rnd_trans(i,t) < delta*(1-pi)
                status = 3 ;
            % separation to MW unemployment                
            elseif rnd_trans(i,t) < delta
                status = 1 ;
            elseif rnd_trans(i,t) < delta+lambda*phi && z(rnd_firm( i , t )) >= z(empid(t-1))
                spell(t) = spell(t)+1 ;
                status = 4 ;
                empid( t ) = rnd_firm( i , t ) ;
                wage( t ) = w( z( empid( t ) ) ) ;
                prod( t ) = NumGrids.z(z(empid(t))) ;
                months( t ) = 1 ;
            else
                status = 4 ;
                empid( t ) = empid( t-1 ) ;
                wage( t ) = wage( t-1 ) ;
                prod( t ) = prod( t-1 ) ;
                % start of new year
                if mod(t,12)==1
                    months(t) = 1;
                else
                    months(t) = months(t-1)+1;
                end

            end
        end

    end
    
    % add random noise to wages at the spell level
    error = rnd_error(i,:) ;
%     wage = wage .* ( wage == MinWage ) + wage .* ( wage ~= MinWage ) .* error(spell+1) ;
    wage = wage .* ( wage == MinWage ) + wage .* ( wage ~= MinWage ) .* error ;
    
    % people earning above 120 times the minimum wage are dropped
    empid( wage >= 120*MinWage ) = NaN ;
    wage( wage >= 120*MinWage ) = NaN ;
    
    % ee rate
    ee = nan( 1 , T ) ;
    cond = isnan( empid(1:end-1) ) == 0 ;
    out = isnan(empid(2:end)) == 0 & ...
          empid(2:end) ~= empid(1:end-1) ;
    ee( cond ) = out( cond ) ;
    EE( i , : ) = ee ; 
    
    % en rate -> delta(a)
    en = nan( 1 , T ) ;
    cond = isnan( empid(1:end-1) ) == 0 ;
    out = isnan( empid(2:end) ) == 1 ;
    en( cond ) = out( cond ) ;
    EN( i , : ) = en ; 

    % mn rate -> delta_MW
    mn = nan( 1 , T ) ;
    cond = isnan( empid(1:end-1) ) == 0 & wage(1:end-1) == MinWage ;
    out = isnan( empid(2:end) ) == 1 ;
    mn( cond ) = out( cond ) ;
    MN( i , : ) = mn ; 

    
    % stock of employed measured at end of sample, but only for those who
    % have been employed in any of the 5 years -> lambda (independent of a)
    ind = min( isnan( empid ) ) ;
    if ind
        e = NaN ;
    else
        e = isnan(wage(end)) == 0 ;
    end
    E( i ) = e ;
    
    % stock of MW workers measured at end of sample, but only for those who
    % have been employed in any of the 5 years -> lambda (independent of a)
    if ind
        m = NaN ;
    else
        m = wage(end) == MinWage ;
    end
    M( i ) = m ;

    % stock of nonemployed workers measured at end of sample
    if ind
        u = NaN ;
    else
        u = isnan(wage(end)) ;
    end
    U( i ) = u ;
%     % share of workers with at least one spell in each market -> piMW (independent of a)
%     e = nanmax( wage ~= MinWage & isnan(wage) == 0 ) ;
%     m = nanmax( wage == MinWage ) ;
%     if ind
%         me = NaN ;
%     else
%         me = e == 1 & m == 1 ;
%     end
%     ME( i ) = me ;
    
    tt = T / 12 ;
    [ empid_an , wage_an , prod_an ] = parassign( empid , wage , prod , months , tt ) ;
    EMPID( i , : ) = empid_an ; 
    WAGE( i , : ) = wage_an ; 
    PROD( i , : ) = prod_an ; 
    
end


end

