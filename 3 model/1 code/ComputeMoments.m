%% ========================================================================
%
% RUNAKM.m runs an AKM decomposition on the simulated output
%
% =========================================================================
function [ Moments , MomentsByDecile , MomentsByDecileFE ] = ComputeMoments( empid , wage , abil , prod , ee , en , e , m , u , mn , MinWage , Params )


% first assign an ID and time
Norig = size(wage,1) ;
Torig = size(wage,2) ;
spellid = (1:Norig*Torig)' ;
id = repmat( (1:Norig)' , 1 , Torig ) ;
year = repmat( (1:Torig) , Norig , 1 ) ;
wage_orig = wage ;


%% store for stata
% filename = [options.SaveResults 'Model_microdata.csv'];
% fid = fopen(filename,'w') ;
% fprintf(fid,'%12s\t %12s\t %12s\t %12s\n','id','empid','year','wage');
% fprintf(fid,'%12.0f\t %12.0f\t %12.0f\t %12.6f\n',[id(:)';empid(:)';year(:)';wage(:)']);
% fclose(fid);

% lagged firm for connected set
lempid = [ nan(size(empid,1),1) , empid( : , 1:end-1 ) ] ;
fempid = empid ;



%% AGGREGATE LABOR MARKET STATISTICS
Moments.e = nansum(e)/(nansum(e)+nansum(u)) ;
Moments.m = nansum(m)/nansum(e) ;
% Moments.me = nanmean(me) ;
Moments.mn = nanmean(mn(:)) ;
Moments.ee = nanmean(ee(:)) ;
Moments.en = nanmean(en(:)) ;



%% SAMPLE SELECTION 1: REMOVE MISSING WAGES
%   ->  summary stats on wage percentiles and aggregate labor market stocks
%       refer to this sample
wage        = log( wage ) ;
ind = isfinite(wage) ;
% % do this as check of eval command
% id = id(ind) ;
% for s = { 'year' , 'empid' , 'lempid' , 'fempid' , 'wage' }
%     eval([ s{1} '=' s{1} '(ind);']) ;
% end
spellid = spellid(ind) ;
id = id(ind) ;
year = year(ind) ;
empid = empid(ind) ;
lempid = lempid(ind) ;
fempid = fempid(ind) ;
wage = wage(ind) ;
clear ind 

% wage percentiles
per = prctile(wage,[5 10 15 20 25 30 35 40 45 55 60 65 70 75 80 85 90 95]);
per50 = prctile(wage,[50]);
Moments.wage_p5_50 = per(1)-per50 ;
Moments.wage_p10_50 = per(2)-per50 ;
Moments.wage_p15_50 = per(3)-per50 ;
Moments.wage_p20_50 = per(4)-per50 ;
Moments.wage_p25_50 = per(5)-per50 ;
Moments.wage_p30_50 = per(6)-per50 ;
Moments.wage_p35_50 = per(7)-per50 ;
Moments.wage_p40_50 = per(8)-per50 ;
Moments.wage_p45_50 = per(9)-per50 ;
Moments.wage_p55_50 = per(10)-per50 ;
Moments.wage_p60_50 = per(11)-per50 ;
Moments.wage_p65_50 = per(12)-per50 ;
Moments.wage_p70_50 = per(13)-per50 ;
Moments.wage_p75_50 = per(14)-per50 ;
Moments.wage_p80_50 = per(15)-per50 ;
Moments.wage_p85_50 = per(16)-per50 ;
Moments.wage_p90_50 = per(17)-per50 ;
Moments.wage_p95_50 = per(18)-per50 ;
Moments.wage_p50_min = per50-MinWage ;
clear per

% firm size by year
empid_year = (max(empid)+1)*(year-1)+empid ;
[~,~,temp] = unique(empid_year) ;
[fsize_firms,~,bin]= histcounts(temp,1:max(temp)+1) ;
fsize = fsize_firms(bin)' ;
Moments.fsize_mean = nanmean( fsize_firms ) ;
Moments.fsize_50 = sum(fsize(:)>=50) ./ sum(fsize(:)>=1) ;
Moments.fsize_100 = sum(fsize(:)>=100) ./ sum(fsize(:)>=1) ;
Moments.fsize_500 = sum(fsize(:)>=500) ./ sum(fsize(:)>=1) ;
Moments.fsize_std = nanstd( log(fsize(:)) ) ;
clear temp fsize_firms empid_year bin




%% SAMPLE SELECTION 2: REMOVE SMALL FIRMS
SizeThreshold = 0 ;
% for s = { 'id' , 'year' , 'empid' , 'lempid' , 'fempid' , 'wage' }
%     eval([ s{1} '=' s{1} '(fsize >= SizeThreshold );']) ;
% end
ind = fsize >= SizeThreshold ;
spellid = spellid(ind) ;
id = id(ind) ;
year = year(ind) ;
empid = empid(ind) ;
lempid = lempid(ind) ;
fempid = fempid(ind) ;
wage = wage(ind) ;
clear ind 



%% SAMPLE SELECTION 3: KEEP ONLY STRICTLY ABOVE MINIMUM WAGE
% drop below minimum wage
% for s = { 'id' , 'year' , 'empid' , 'lempid' , 'fempid' , 'wage' }
%     eval([ s{1} '=' s{1} '(wage ~= MinWage);']) ;
% end
ind = wage ~= MinWage ;
spellid = spellid(ind) ;
id = id(ind) ;
year = year(ind) ;
empid = empid(ind) ;
lempid = lempid(ind) ;
fempid = fempid(ind) ;
wage = wage(ind) ;
clear ind 



%% SAMPLE SELECTION 4: CONNECTED SET
ind1 = isnan(lempid)==0 ;
ind2 = isnan(empid)==0 ;
lempid = lempid( ind1 & ind2 ) ;
fempid = fempid( ind1 & ind2 ) ;
A = digraph(lempid',fempid');
[sindex, sz] = conncomp(A, 'Type', 'strong');
idx=find(sz==max(sz));
firmlst=find(sindex==idx);
sel=ismember(empid,firmlst);
clear firmlst idx sindex s sz A lempid
% for s = { 'id' , 'year' , 'empid' , 'wage' }
%     eval([ s{1} '=' s{1} '(sel);']) ;
% end
spellid = spellid(sel) ;
id = id(sel) ;
year = year(sel) ;
empid = empid(sel) ;
wage = wage(sel) ;
clear sel




%% AKM ESTIMATION
[k,~,id] = unique(id);
N = length(k);
[k,~,empid] = unique(empid);
J = length(k);
NT = length(id);
D = sparse(1:NT,id',1);
F = sparse(1:NT,empid',1);
F = F(:,1:end-1);
X = [D'*D D'*F;F'*D F'*F];
L = ichol(X,struct('type','ict','droptol',1e-2,'diagcomp',.1));
[b,~] = pcg(X,[D'*wage;F'*wage],1e-10,1000,L,L');
ahat = b(1:N);
ghat = b(N+1:N+J-1); % J-1 firm fixed effects (last one is dropped)
pe = D*ahat;
fe = F*ghat;
resid = wage-pe-fe;
C = cov([wage,pe,fe,resid]);
C = full(C);

% summarize AKM outcomes
Moments.wage_var = C(1,1) ;
Moments.pe_var = C(2,2) ;
Moments.fe_var = C(3,3) ;
Moments.resid_var = C(4,4) ;
Moments.pe_fe_cov = 2*C(2,3) ;
Moments.pe_fe_corr = C(2,3) / sqrt( C(2,2)*C(3,3) ) ;




%% SUMMARY STATS ON FLOWS BY AKM PERSON EFFECTS
% map estimated person and firm effects back to original order
pe_orig = pe ;
pe = nan( Norig*Torig , 1 ) ;
pe(spellid) = pe_orig ;
pe = reshape( pe , Norig , Torig ) ;
fe_orig = fe ;
fe = nan( Norig*Torig , 1 ) ;
fe(spellid) = fe_orig ;
fe = reshape( fe , Norig , Torig ) ;
empid_orig = empid ;
empid = nan( Norig*Torig , 1 ) ;
empid(spellid) = empid_orig ;
empid = reshape( empid , Norig , Torig ) ;

% we only need one person FE per worker
pe = nanmean( pe , 2 ) ;

% return original wage before sample selection
wage = wage_orig ;

% keep only those with valid person effects
x = isnan( pe ) ;
% for s = { 'ee' , 'en' , 'wage' }
%     eval([ s{1} '(x,:) = [] ;'])
% end
% for s = { 'e' , 'm' , 'u' , 'me' , 'pe' }
%     eval([ s{1} '(x) = [] ;'])
% end
ee(x,:) = [] ;
en(x,:) = [] ;
wage(x,:) = [] ;
fe(x,:) = [] ;
empid(x,:) = [] ;
e(x) = [] ;
m(x) = [] ;
u(x) = [] ;
pe(x) = [] ;

% compute mobility by decile of worker FEs
[ ~ , x ] = sort( pe ) ;
y = ceil( 10*(1:length(x))' / length(x) ) ;
MomentsByDecile.pe = (1:10)' ;
for s = { 'ee' , 'en' , 'u' }
    eval([ 'temp = ' s{1} '(x,:);']) ;
    temp_m = zeros(10,1) ;
    for i=1:10
        temp2 = temp( y == i , : ) ;
        temp_m(i) = nanmean( temp2(:) ) ;
    end
    eval( [ 'MomentsByDecile.' s{1} ' = temp_m ; '] )
end
% compute the share that earns the minimum wage
tempe = e(x) ;
for s = { 'm' } 
    eval([ 'temp = ' s{1} '(x);']) ;
    temp_m = zeros(10,1) ;
    for i=1:10
        temp_m(i) = nansum( temp( y == i ) ) / nansum( tempe( y == i ) ) ;
    end
    eval( [ 'MomentsByDecile.' s{1} ' = temp_m ; '] )
end


% pay outcomes
temp = wage(x,:) ; 
temp_m = nan(10,1) ;
temp_p1 = nan(10,1) ;
temp_p5 = nan(10,1) ;
temp_p10 = nan(10,1) ;
temp_mean = nan(10,1) ;
temp_var = nan(10,1) ;
for i=1:10
    % pick out relevant group
    temp2 = log( temp( y == i , : ) ) ;
    temp2 = temp2( : ) ;
    temp2( temp2 == MinWage | isnan(temp2) ) = [] ;
    if isempty(temp2) == 0
        temp_m(i) = nanmin( temp2 ) ;
        per = prctile(temp2,[ 1 5 10 ]) ;
        temp_p1(i) = per(1) ; 
        temp_p5(i) = per(2) ; 
        temp_p10(i) = per(3) ; 
        temp_mean(i) = nanmean(temp2) ;
        temp_var(i) = nanvar(temp2) ;
    end
end

% pay outcomes
temp = fe(x,:) ; 
temp_fe_mean = nan(10,1) ;
temp_fe_var = nan(10,1) ;
for i=1:10
    % pick out relevant group
    temp2 = temp( y == i , : ) ;
    temp2 = temp2( : ) ;
    temp2( isnan(temp2) ) = [] ;
    if isempty(temp2) == 0
        temp_fe_mean(i) = nanmean(temp2) ;
        temp_fe_var(i) = nanvar(temp2) ;
    end
end

MomentsByDecile.minwage = temp_m ;
MomentsByDecile.wage_p1 = temp_p1 ;
MomentsByDecile.wage_p5 = temp_p5 ;
MomentsByDecile.wage_p10 = temp_p10 ;
MomentsByDecile.wage_mean = temp_mean ;
MomentsByDecile.wage_var = temp_var ;
MomentsByDecile.fe_mean = temp_fe_mean ;
MomentsByDecile.fe_var = temp_fe_var ;
clear temp tempe tempm temp_m y x temp_mean temp_var



%% store for stata
% filename = [options.SaveResults 'Model_microdata.csv'];
% fid = fopen(filename,'w') ;
% id = repmat( (1:size(empid,1))' , 1 , size(empid,2) ) ;
% year = repmat( (1:size(empid,2)) , size(empid,1) , 1 ) ;
% perep = repmat( pe , 1 , size(empid,2) ) ;
% fprintf(fid,'%12s\t %12s\t %12s\t %12s\t %12s\t %12s\n','id','empid','year','wage','pe','fe');
% fprintf(fid,'%12.0f\t %12.0f\t %12.0f\t %12.6f\t %12.6f\t %12.6f\n',[id(:)';empid(:)';year(:)';wage(:)';perep(:)';fe(:)']);
% fclose(fid);


% compute mobility by decile of firm unweighted FEs
fe = fe(:) ;
empid = empid(:) ;
wage = wage(:) ;
x = isnan(fe) ;
fe(x) = [] ;
empid(x) = [] ;
wage(x) = [] ;
% compute number of people at a given empid
[~,~,temp] = unique(empid) ;
[weight,~,bin]= histcounts(temp,1:max(temp)+1) ;
% weight is inverse of size for unweighted
weight = weight(bin)' ;
weight = 1./weight ;
% sort by firm FE
[ ~ , x ] = sort( fe ) ;
weight = weight(x) ;
fe = fe(x) ;
wage = wage(x) ;
% cdf of firms
cdff = cumsum( weight ) ;
cdff = cdff / cdff(end) ;

% 10 buckets based on unweighted cdf
y = ceil( 10*cdff ) ;
MomentsByDecileFE.fe = (1:10)' ;

% pay outcomes
temp = wage ; 
temp_mean = nan(10,1) ;
temp_var = nan(10,1) ;
for i=1:10
    % pick out relevant group
    temp2 = log( temp( y == i , : ) ) ;
    temp2 = temp2( : ) ;
    temp2( temp2 == MinWage | isnan(temp2) ) = [] ;
    if isempty(temp2) == 0
        temp_mean(i) = nanmean(temp2) ;
        temp_var(i) = nanvar(temp2) ;
    end
end
MomentsByDecileFE.wage_mean = temp_mean ;
MomentsByDecileFE.wage_var = temp_var ;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % POTENTIALLY STORE RESIDUAL PLOT
% if strcmp(options.PlotResidual,'Y') & PERIOD == 1
%     q1 = quantile(pe,(1:9)/10);
%     dec_pe = discretize(pe,[-inf q1 inf]);
%     q1 = quantile(fe,(1:9)/10);
%     dec_fe = discretize(fe,[-inf q1 inf]);
%     err = zeros(10);
%     for i=1:10
%         for j=1:10
%             err(11-i,j) = mean(resid(dec_pe==i & dec_fe == j));
%         end
%     end
%     
%     o = figure;
%     AX = bar3(err);
%     %xlabh = get(gca,'XLabel');
%     %set(xlabh,'Position',get(xlabh,'Position') - [0 .4 0])
%     ylabel('Worker effect decile')
%     xlabel('Firm effect decile')
%     black = .3;
%     for i = 1:10
%         AX(i).FaceColor = [black+(1-black)*(i-1)/9 black+(1-black)*(i-1)/9 black+(1-black)*(i-1)/9];
%     end
%     zlim(gca,[-.15 .1])
%     set(gca,'YTickLabel',(10:-1:1));
%     print([options.SaveGraphs '3dresid.eps'],'-depsc')
%     
%     % read the data
%     period = 0;
%     X = xlsread('/Users/niklasengbom/Dropbox/Brazil/5 Code/9_ColumbiaGSB/6_extracts/4_estimation/3dresidual_data','3dresidual_data');
% %     X = xlsread('/Users/niklasengbom/Dropbox/Brazil/9 Extracts/8_EXTRACT_0305000998_2014_35em13_06_2016/1_Tabelas de saida/3dresidual_byperiod','3dresidual_byp_lset_1988_2012');
%     X = X(100*(period+1)+1:100*(period+2),3);
%     X = reshape(X,10,10)';
%     err = zeros(10);
%     for i=1:10
%         for j=1:10
%             err(11-i,j) = X(i,j);
%         end
%     end
%     
%     o = figure;
%     AX = bar3(err);
%     %xlabh = get(gca,'XLabel');
%     %set(xlabh,'Position',get(xlabh,'Position') - [0 .4 0])
%     ylabel('Worker effect decile')
%     xlabel('Firm effect decile')
%     black = .3;
%     for i = 1:10
%         AX(i).FaceColor = [black+(1-black)*(i-1)/9 black+(1-black)*(i-1)/9 black+(1-black)*(i-1)/9];
%     end
%     zlim(gca,[-.15 .1])
%     set(gca,'YTickLabel',(10:-1:1));
%     print([options.SaveGraphs '3dresid_data.eps'],'-depsc')
%     
%     error('Stopping in Runakm.m to adjust 3d graphs')
%     
% end  
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % STORE FOR MATLAB ANALYSIS
% store = 0;
% if store
%     S = struct('pe',pe,'fe',fe,'firm',p,'worker',abil);
%     filename = [SAVERESULTS 'AKMresults_' num2str(period) '.mat'];
%     save(filename,'-struct','S')
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
