%% ========================================================================
% 
% TARGETEDMOMENTS.m loads empirical moments 
%
% =========================================================================       
%% aggregate data
MomentsData = csv2mat_numeric([options.SaveResults 'Moments.out']) ;
for s=fieldnames(MomentsData)'
    MomentsData.(s{1}) = MomentsData.(s{1})' ;
end
MomentsTitle.e = 'Employment rate (including MW workers)' ;
MomentsTitle.m = 'Share of employed earning the MW' ;
MomentsTitle.me = 'Share of workers with at least one spell of MW and non-MW employment' ;
MomentsTitle.ee = 'JJ rate' ;
MomentsTitle.en = 'EN rate' ;
for s = 5:5:95
    eval([ 'MomentsTitle.wage_p' num2str(s) '_50 = ''Wage percentile ' num2str(s) '-50'';']) ;
%     eval([ 'MomentsData.wage_p' num2str(s) '_50 = 0.0001 ;']) ;
end
MomentsTitle.wage_p50_min = 'Median to minium wage' ;
MomentsTitle.fsize_mean = 'Average firm size (unweighted)' ;
for s = [ 50 100 500 ]
    eval([ 'MomentsTitle.fsize_' num2str(s) ' = ''Employment share of firms with ' num2str(s) '+ empl.'';']) ;
end
MomentsTitle.fsize_std = 'Standard deviation of log firm size (weighted)' ;
MomentsTitle.wage_var = 'Variance of log wages' ;
MomentsTitle.pe_var = 'Variance of AKM person FEs' ;
MomentsTitle.fe_var = 'Variance of AKM firm FEs' ;
MomentsTitle.resid_var = 'Variance of AKM residual' ;
MomentsTitle.pe_fe_corr = 'Correlation between AKM person and firm FEs' ;
MomentsTitle.pe_fe_cov = '2$\times$covariance AKM person-firm FEs' ;


%% by worker PEs
MomentsByDecileData = csv2mat_numeric([options.SaveResults 'MomentsByDecile.out']) ;
MomentsByDecileTitle.pe = 'AKM person FE decile' ;
MomentsByDecileTitle.ee = 'JJ rate' ;
MomentsByDecileTitle.en = 'EN rate' ;
MomentsByDecileTitle.m = 'Share of employed earning the MW' ;
MomentsByDecileTitle.u = 'Share of nonemployed' ;
MomentsByDecileTitle.minwage = 'Lowest wage' ;
MomentsByDecileTitle.wage_p1 = '1st wage percentile' ;
MomentsByDecileTitle.wage_p5 = '5th wage percentile' ;
MomentsByDecileTitle.wage_p10 = '10th wage percentile' ;
MomentsByDecileTitle.wage_mean = 'Mean log wage' ;
MomentsByDecileTitle.wage_var = 'Variance of log wages' ;
MomentsByDecileTitle.fe_mean = 'Mean firm FE' ;
MomentsByDecileTitle.fe_var = 'Variance of firm FEs' ;

MomentsByDecileY1.pe = 0 ;
MomentsByDecileY2.pe = 10 ;
MomentsByDecileYD.pe = 2.5 ;
MomentsByDecileFormat.pe = '%.1f' ;

MomentsByDecileY1.ee = 0 ;
MomentsByDecileY2.ee = .04 ;
MomentsByDecileYD.ee = 0.01 ;
MomentsByDecileFormat.ee = '%.2f' ;

MomentsByDecileY1.en = 0 ;
MomentsByDecileY2.en = .1 ;
MomentsByDecileYD.en = 0.025 ;
MomentsByDecileFormat.en = '%.2f' ;

MomentsByDecileY1.m = 0 ;
MomentsByDecileY2.m = .04 ;
MomentsByDecileYD.m = 0.01 ;
MomentsByDecileFormat.m = '%.2f' ;

MomentsByDecileY1.u = 0 ;
MomentsByDecileY2.u = 1 ;
MomentsByDecileYD.u = 0.25 ;
MomentsByDecileFormat.u = '%.2f' ;

MomentsByDecileY1.minwage = -4 ;
MomentsByDecileY2.minwage = 0 ;
MomentsByDecileYD.minwage = 1 ;
MomentsByDecileFormat.minwage = '%.2f' ;

MomentsByDecileY1.wage_p1 = -1 ;
MomentsByDecileY2.wage_p1 = 3 ;
MomentsByDecileYD.wage_p1 = 1 ;
MomentsByDecileFormat.wage_p1 = '%.2f' ;

MomentsByDecileY1.wage_p5 = -1 ;
MomentsByDecileY2.wage_p5 = 3 ;
MomentsByDecileYD.wage_p5 = 1 ;
MomentsByDecileFormat.wage_p5 = '%.2f' ;

MomentsByDecileY1.wage_p10 = -1 ;
MomentsByDecileY2.wage_p10 = 3 ;
MomentsByDecileYD.wage_p10 = 1 ;
MomentsByDecileFormat.wage_p10 = '%.2f' ;

MomentsByDecileY1.wage_mean = -3 ;
MomentsByDecileY2.wage_mean = 0 ;
MomentsByDecileYD.wage_mean = .75 ;
MomentsByDecileFormat.wage_mean = '%.2f' ;

MomentsByDecileY1.wage_var = 0 ;
MomentsByDecileY2.wage_var = .6 ;
MomentsByDecileYD.wage_var = .15 ;
MomentsByDecileFormat.wage_var = '%.2f' ;

MomentsByDecileY1.fe_mean = -.8 ;
MomentsByDecileY2.fe_mean = 0 ;
MomentsByDecileYD.fe_mean = .2 ;
MomentsByDecileFormat.fe_mean = '%.2f' ;

MomentsByDecileY1.fe_var = 0 ;
MomentsByDecileY2.fe_var = .4 ;
MomentsByDecileYD.fe_var = .1 ;
MomentsByDecileFormat.fe_var = '%.2f' ;




%% by worker PEs
MomentsByDecileFEData = csv2mat_numeric([options.SaveResults 'MomentsByDecileFE.out']) ;
MomentsByDecileFETitle.fe = 'AKM firm FE decile' ;
MomentsByDecileFETitle.wage_mean = 'Mean log wage' ;
MomentsByDecileFETitle.wage_var = 'Variance of log wages' ;

MomentsByDecileFEY1.fe = 0 ;
MomentsByDecileFEY2.fe = 10 ;
MomentsByDecileFEYD.fe = 2.5 ;
MomentsByDecileFEFormat.fe = '%.1f' ;

MomentsByDecileFEY1.wage_mean = -2 ;
MomentsByDecileFEY2.wage_mean = 0 ;
MomentsByDecileFEYD.wage_mean = .5 ;
MomentsByDecileFEFormat.wage_mean = '%.2f' ;

MomentsByDecileFEY1.wage_var = 0 ;
MomentsByDecileFEY2.wage_var = .8 ;
MomentsByDecileFEYD.wage_var = .2 ;
MomentsByDecileFEFormat.wage_var = '%.2f' ;

