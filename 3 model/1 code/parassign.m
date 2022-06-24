function [ empid_an , wage_an , prod_an ] = parassign( empid , wage , prod , months , tt )

empid_an = nan( 1 , tt ) ;
wage_an = nan( 1 , tt ) ;
prod_an = nan( 1 , tt ) ;
for t=1:tt
    % employer with most months worked
    [~,m] = max(months(12*(t-1)+1:12*t));
    empid_an( t )   = empid(12*(t-1)+m);    
    wage_an( t )    = wage(12*(t-1)+m);
    prod_an( t )    = prod(12*(t-1)+m);
end

end