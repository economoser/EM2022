clc
fprintf('*****************************************************************************************************\n\n')
fprintf('DESCRIPTION:       Reproduces all model output in sections 5-7 of Engbom & Moser (2022) \n\n')
fprintf('AUTHOR:            Niklas Engbom (New York University) \n')
fprintf('                   Christian Moser (Columbia University) \n\n')
fprintf('REFERENCES:        Please cite the following papers: \n')
fprintf('                   - Engbom, Niklas, and Christian Moser, 2022. "Earnings Inequality and the Minimum \n')
fprintf('                     Wage: Evidence from Brazil," American Economic Review, Forthcoming \n\n')
time = datetime ; 
fprintf('Start date:        %02.0f/%02.0f/%4.0f\n',month(time),day(time),year(time))
fprintf('Start time:        %02.0f:%02.0f \n\n\n\n',hour(time),minute(time))
close all; clear all;







%% ************************************************************************
%                   SPECIFY SETTINGS & DIRECTORIES
%**************************************************************************
% a user needs to supply the main directory where the replication package
% is stored on their local machine; everything else is set internally
options.Directory           = '/Users/niklasengbom/Dropbox/Brazil/_replication_package' ;
options.DisplayFigure       = 'off' ;   % Suppress figures when executing code: off; on
options.Age                 = 'all' ;   % All workers or young workers only: all = all workers; young = 18-29 only

% where to load and store results
options.MainDirectory       = [ options.Directory '/3 model' ] ;
options.ReadResults         = [ options.MainDirectory, '/2 data/Results' ] ;
options.SaveResults         = [ options.MainDirectory, '/2 data/'  options.Age '/' ] ;
options.SaveTables          = [ options.MainDirectory, '/3 tables/' options.Age '/' ] ;
options.SaveGraphs          = [ options.MainDirectory, '/4 graphs/' options.Age '/' ] ;
options.SaveEstimates       = [ options.MainDirectory, '/2 data/' options.Age '/Estimates' ] ;
%**************************************************************************
























%% ************************************************************************
%
%                               MAIN CODE  
%                               ---------
%
%**************************************************************************
step = 1 ;
fprintf('(%2.0f ) Deleting old folders and creating new ones to store results in \n',step)
step = step+1 ;
fprintf('---------------------------------------------------------------------\n\n\n')
[~,~,~] = rmdir( [ options.MainDirectory '/3 tables' ] , 's' ) ;
[~,~,~] = mkdir( options.MainDirectory , '3 tables' ) ;
[~,~,~] = mkdir( [ options.MainDirectory '/3 tables' ] , options.Age ) ;
[~,~,~] = rmdir( [ options.MainDirectory '/4 graphs' ] , 's' ) ;
[~,~,~] = mkdir( options.MainDirectory , '4 graphs' ) ;
[~,~,~] = mkdir( [ options.MainDirectory '/4 graphs' ] , options.Age ) ;

























fprintf('(%2.0f ) Resolving the model under the estimated parameter vector \n',step)
step = step+1 ;
fprintf('---------------------------------------------------------------\n\n\n')

% load settings
run ReadData.m
run LoadTargets.m
[ ~ , ~ , ParameterName , ParameterTitle , n_params ] = ConstructSobol( ) ;
load([options.SaveEstimates '.mat']);

% set external parameters
[ ExogParams ] = ExogenousParameters ;
[ Numerical ] = NumericalApproximations(ExogParams) ;

% construct grids
[ NumGrids ] = Grids( Params , ExogParams , Numerical ) ;
%     [ ~ , ~ , ~ , ParameterName , ~ ] = ConstructSobol( ) ;
if NumGrids.z(end) > 1.e+10
    error('Productivity grid is too large - please change parameter choice')
    return
end
if NumGrids.a(end) > 1.e+10
    error('Ability grid is too large - please change parameter choice')
    return
end

% consider the following potential minimum wages
MinWageGrid = [ 0 , .577 ] ;

fprintf('(%2.0f ) Solving the baseline model to recover vacancy cost parameters \n',step)
step = step+1;
fprintf('--------------------------------------------------------------------\n\n\n')
options.Estimation = 'Y' ;
mw = 1 ;
[ WAGE , active , Moments , MomentsByDecile , MomentsByDecileFE , Model , NumGrids , error ] = Solve( Params , ExogParams , NumGrids , Numerical , MinWageGrid(mw) , options ) ;

% calculate implied flow value of leisure
[ NumGrids , check ] = FindFlowValue( Model , ExogParams , NumGrids , Numerical , exp(MinWageGrid(mw)) , options ) ;




% TABLE 4: PARAMETER ESTIMATES
fid = fopen([options.SaveTables 'Parameters.tex'],'w');
fprintf(fid,'\\begin{tabular}{l l c l c c} \\hline \\hline \\addlinespace[1ex] \n');
fprintf(fid,' \\multicolumn{2}{l}{Parameter} & Estimate & Targeted moment & Data & Model \\\\ \n');
fprintf(fid,'\\hline \\addlinespace[1.5ex] \n');
fprintf(fid,'& \\multicolumn{5}{c}{\\textit{Panel A. Pre-determined parameters}} \\\\ \\cline{2-6} \\addlinespace[1ex] \n');
fprintf(fid,'$\\rho$ & Discount rate & %4.3f & 4\\%% annual real interest rate \\\\ \n', ...
                                                                   ExogParams.rho) ;
fprintf(fid,'$\\chi$ & Matching efficiency & %4.3f & Normalization \\\\ \n', ...
                                                                   1) ;
fprintf(fid,'$\\alpha$ & Elasticity of matches w.r.t. vacancies & %4.3f & \\citet{petrongolopissarides2001} \\\\ \n', ...
                                                                   ExogParams.alpha) ;                                                                       
fprintf(fid,'\\addlinespace[1.5ex] \n');
fprintf(fid,'& \\multicolumn{5}{c}{\\textit{Panel B. Structural and auxiliary parameters calibrated offline}} \\\\ \\cline{2-6} \\addlinespace[1ex] \n');                                                                       
fprintf(fid,'$M$ & Mass of firms & %4.3f & Average firm size & %4.3f & %4.3f \\\\ \n', ...
                                                                   ExogParams.M, ...
                                                                   MomentsData.fsize_mean(1), ...
                                                                   Moments.fsize_mean) ;
fprintf(fid,'$\\delta(a,0)$ & Separation rate of those with $s=0$ & %4.3f & EN rate from MW jobs & %4.3f & %4.3f \\\\ \n', ...
                                                                   ExogParams.deltaMW, ...
                                                                   MomentsData.mn(1), ...
                                                                   ExogParams.deltaMW) ;
fprintf(fid,'$\\lambda$ & Job finding rate & %4.3f & NE rate & %4.3f & %4.3f \\\\ \n', ...
                                                                   ExogParams.lambda, ...
                                                                   MomentsData.ne(1), ...
                                                                   ExogParams.lambda) ;
fprintf(fid,'\\addlinespace[1.5ex] \n');
fprintf(fid,'& \\multicolumn{5}{c}{\\textit{Panel C. Internally estimated structural parameters}} \\\\ \\cline{2-6} \\addlinespace[1ex] \n');                                                                       
for params = fieldnames(Params)'
    if strcmp(params{1},'r0') == 0 && strcmp(params{1},'r1') == 0
        str = Targets.(params{1}) ;
        if length(str)==1 && length(str{1}) > 0
            fprintf(fid,'%s & %s & %4.3f & %s & %4.3f & %4.3f \\\\ \n', ...
                                                                       ParameterName.(params{1}), ...
                                                                       ParameterTitle.(params{1}), ...
                                                                       Params.(params{1}), ...
                                                                       MomentsTitle.(Targets.(params{1}){1}), ...
                                                                       MomentsData.(Targets.(params{1}){1})(1),...
                                                                       Moments.(Targets.(params{1}){1})(1)) ;
        elseif length(str{1}) == 0
            fprintf(fid,'%s & %s & %4.3f & %s & \\multicolumn{2}{c}{See figure \\ref{figure: model fit 2}} \\\\ \n', ...
                                                                       ParameterName.(params{1}), ...
                                                                       ParameterTitle.(params{1}), ...
                                                                       Params.(params{1}), ...
                                                                       MomentsByDecileTitle.(TargetsByDecile.(params{1}){1}) ) ;                
        else
            fprintf(fid,'%s & %s & %4.3f & Percentiles of wage distribution & \\multicolumn{2}{c}{See figure \\ref{figure: model fit}} \\\\ \n', ...
                                                                       ParameterName.(params{1}), ...
                                                                       ParameterTitle.(params{1}), ...
                                                                       Params.(params{1})) ;
        end
    end
end
fprintf(fid,'\\addlinespace[1.5ex] \n');
fprintf(fid,'& \\multicolumn{5}{c}{\\textit{Panel D. Internally estimated auxiliary parameters}} \\\\ \\cline{2-6} \\addlinespace[1ex] \n');                                                                               
for params = fieldnames(Params)'
    if strcmp(params{1},'r0') || strcmp(params{1},'r1')
        str = Targets.(params{1}) ;
        if length(str)==1 && length(str{1}) > 0
            fprintf(fid,'%s & %s & %4.3f & %s & %4.3f & %4.3f \\\\ \n', ...
                                                                       ParameterName.(params{1}), ...
                                                                       ParameterTitle.(params{1}), ...
                                                                       Params.(params{1}), ...
                                                                       MomentsTitle.(Targets.(params{1}){1}), ...
                                                                       MomentsData.(Targets.(params{1}){1})(1),...
                                                                       Moments.(Targets.(params{1}){1})(1)) ;
        else
            fprintf(fid,'%s & %s & %4.3f & %s & \\multicolumn{2}{c}{See figure \\ref{figure: model fit 2}} \\\\ \n', ...
                                                                       ParameterName.(params{1}), ...
                                                                       ParameterTitle.(params{1}), ...
                                                                       Params.(params{1}), ...
                                                                       MomentsByDecileTitle.(TargetsByDecile.(params{1}){1}) ) ;
        end
    end
end
fprintf(fid,'\\addlinespace[.5ex] \\hline \n');
fprintf(fid,'\\end{tabular}');
fclose(fid);




% FIGURE 41: PARAMETER ESTIMATES
settings.x1 = 0 ;
settings.x2 = 2 ;
settings.xd = .5 ;
settings.xformat = '%2.1f' ;
settings.y1 = 0.3 ;
settings.y2 = 1.5 ;
settings.yd = .3 ;
settings.yformat = '%3.2f' ;
settings.size = 33 ;
settings.type = 'oneaxis' ;
titles.x = 'Worker ability, $\log a$' ;    
titles.y = 'Relative search efficiency, $s(a)$' ;
gKey = { '$s>0$' } ;
name = [options.SaveGraphs 'Model_phi.png'] ;
draw.x = log(NumGrids.a) ;
draw.y = NumGrids.phi ;
Graphs( draw , titles , gKey , settings , options , name ) ;    
settings.y1 = 0 ;
settings.y2 = .12 ;
settings.yd = .03 ;
settings.yformat = '%3.2f' ;
settings.size = 33 ;
settings.type = 'oneaxis' ;
titles.x = 'Worker ability, $\log a$' ;    
titles.y = 'Separation rate, $\delta(a,s)$' ;
gKey = { '$s>0$' , 's=0' } ;
name = [options.SaveGraphs 'Model_delta.png'] ;
draw.x = log(NumGrids.a) ;
draw.y = [ NumGrids.delta , NumGrids.deltaMW ] ;
Graphs( draw , titles , gKey , settings , options , name ) ;
settings.y1 = 0 ;
settings.y2 = 8 ;
settings.yd = 2 ;
settings.yformat = '%3.2f' ;
settings.size = 33 ;
settings.type = 'oneaxis' ;
titles.x = 'Worker ability, $\log a$' ;    
titles.y = 'Reservation wage, $r(a,s)$' ;
name = [options.SaveGraphs 'Model_r.png'] ;
draw.x = log(NumGrids.a) ;
draw.y = NumGrids.R ;   
Graphs( draw , titles , gKey , settings , options , name ) ;    



% FIGURE 5: PARAMETER ESTIMATES OF COST AND FLOW VALUE
% panel a
settings.x1 = 0 ;
settings.x2 = 2 ;
settings.xd = .5 ;
settings.xformat = '%2.1f' ;
settings.y1 = 7 ;
settings.y2 = 15 ;
settings.yd = 2 ;
settings.yformat = '%2.0f' ;
settings.size = 33 ;
settings.type = 'oneaxis' ;
titles.x = 'Worker ability, $\log a$' ;    
titles.y = 'Cost of creating jobs, $\log c(a,s)$' ;
gKey = { '$s>0$' , 's=0' } ;
name = [options.SaveGraphs 'Model_cost.png'] ;
draw.x = log(NumGrids.a) ;
draw.y = [ log(NumGrids.cost) , log(NumGrids.costMW) ] ;   
Graphs( draw , titles , gKey , settings , options , name ) ;
% panel b
settings.x1 = 0 ;
settings.x2 = 2 ;
settings.xd = .5 ;
settings.xformat = '%2.1f' ;
settings.y1 = 0 ;
settings.y2 = 10 ;
settings.yd = 2.5 ;
settings.yformat = '%2.1f' ;
settings.size = 33 ;
settings.type = 'oneaxis' ;    
titles.x = 'Worker ability, $\log a$' ;
titles.y = 'Flow value of leisure, $ab(a)$' ;
gKey = { 'Flow value of leisure' } ;
name = [options.SaveGraphs 'Model_b.png'] ;
draw.x = log(NumGrids.a) ;
draw.y = NumGrids.a .* NumGrids.b ;
Graphs( draw , titles , gKey , settings , options , name ) ;
% panel c
settings.x1 = 0 ;
settings.x2 = 2 ;
settings.xd = .5 ;
settings.xformat = '%2.1f' ;
settings.y1 = .2 ;
settings.y2 = 1 ;
settings.yd = .2 ;
settings.yformat = '%2.1f' ;
settings.size = 33 ;
settings.type = 'oneaxis' ;    
titles.x = 'Worker ability, $\log a$' ;
titles.y = 'Flow value of leisure to average wage' ;
gKey = { 'Flow value of leisure to average wage, $\frac{b(a)}{\overline{w}(a)}$' } ;
name = [options.SaveGraphs 'Model_bw.png'] ;
draw.x = log(NumGrids.a) ;
average = nansum( Model.w .* ( Model.gw .* Model.dw ) ./ nansum( Model.gw .* Model.dw , 2 ) , 2 ) ;
draw.y = NumGrids.b./average ;
Graphs( draw , titles , gKey , settings , options , name ) ;
% Figure 40
settings.x1 = 0 ;
settings.x2 = 2 ;
settings.xd = .5 ;
settings.xformat = '%2.1f' ;
settings.y1 = 0 ;
settings.y2 = 4 ;
settings.yd = 1 ;
settings.yformat = '%2.1f' ;
settings.size = 33 ;
settings.type = 'oneaxis' ;    
titles.x = 'Worker ability, $\log a$' ;
titles.y = 'Ratio of mean to minimum wage' ;
gKey = { 'Min-to-mean ratio' } ;
name = [options.SaveGraphs 'Model_MeanMin.png'] ;
draw.x = log(NumGrids.a) ;
average = nansum( Model.w .* ( Model.gw .* Model.dw ) ./ nansum( Model.gw .* Model.dw , 2 ) , 2 ) ;
draw.y = average ./ nanmin( Model.w , [] , 2 ) ;
Graphs( draw , titles , gKey , settings , options , name ) ;    


% FIGURE 6: WAGE DISTRIBUTION
gKey = { 'Data' , 'Model' } ;
% load empirical wage distribution
data = csv2mat_numeric([options.SaveResults 'wages_data_1994_1998.out']) ;
data = data.wage ; 
model = log(WAGE(:)) ;
bins = -.5:.05:4.5 ;
dx = bins(2:end)-bins(1:end-1) ;
[y,~] = histcounts(data,bins) ;
y = y/sum(y) ;
y = y ./ dx ; 
y = y ./ sum( y.*dx ) ;
y_data = y ;
[y,~] = histcounts(model,bins) ;
y = y/sum(y) ;
y = y ./ dx ; 
y = y ./ sum( y.*dx ) ;
y_model = y ;
bins = bins(1:end-1) ;
font = 'Garamond' ;
color1 = [50 0 200]/255 ;
color2 = [230 0 30]/255 ;
color3 = [0 150 0]/255 ;
color4 = [255 150 0]/255 ;
linestyle1 = '-' ;
linestyle2 = '-.' ;
linestyle3 = '--' ;
linestyle4 = ':' ;
FontSize = 15 ;
LegendSize = 15 ;
GridWidth = .9 ;
LineWidth = 2.5 ;
settings.x1 = -1 ;
settings.x2 = 5 ;
settings.xd = 1.5 ;
settings.y1 = 0 ;
settings.yd = .2 ;
settings.y2 = .8 ;
titles.x = 'Log wage' ;
titles.y = 'Density' ;
settings.xformat = '%.1f';
settings.yformat = '%.1f';
name = [options.SaveGraphs 'WageDistribution_' num2str(1994) '_' num2str(1998) '.png'] ;
figure('visible',options.DisplayFigure,'units','pixels','InnerPosition',[500 , 500 , 500 , 450 ])
set(gcf,'color','w');
AX = plot(bins,[y_data',y_model']) ; hold on
xlim([settings.x1,settings.x2]);
xticks(settings.x1:settings.xd:settings.x2) ;        
ylim([settings.y1,settings.y2]);
yticks(settings.y1:settings.yd:settings.y2) ;
AX(1).Color = color1 ;
AX(1).LineStyle = linestyle1 ;
AX(1).LineWidth = LineWidth ;
AX(2).Color = color2 ;
AX(2).LineStyle = linestyle2 ;
AX(2).LineWidth = LineWidth ;
ax = ancestor(AX(1), 'axes') ;
ax.YAxis.Exponent = 0 ;
xtickformat(settings.xformat)
ytickformat(settings.yformat)
set(gca,'fontsize',FontSize,'ticklabelinterpreter','latex');
set(gca,'FontName',font);
% include vertical pink line at minimum wage
plot([MinWageGrid(1),MinWageGrid(1)],[0,500],'LineStyle','--','Color',[0 0 0]/255,'linewidth',LineWidth/2);    
xlabel(sprintf('%s',titles.x),'interpreter','latex','FontSize',FontSize);
ylabel(sprintf('%s',titles.y),'interpreter','latex','FontSize',FontSize);
ax = gca ;
ax.XGrid = 'on' ;
ax.YGrid = 'on' ;
ax.GridColor = [ 0 0 0 ] / 255 ;
ax.GridAlpha = 1 ;
ax.LineWidth = GridWidth ;
ax.GridLineStyle = ':' ;
ax.TickLabelInterpreter = 'latex' ;
ax.FontSize = FontSize ;
legHdl = legend(AX(1:2),gKey,'Interpreter','latex') ;
legHdl.Location = 'NorthEast' ;
legHdl.FontSize = LegendSize ;
legHdl.Color = [1,1,1,0] ;
set(legHdl.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;1]))
legHdl.Visible = 'on' ;
set(legHdl,'EdgeColor','none');
print(name,'-dpng')
drawnow
hold off


% FIGURE 42: WORKER MOBILITY BY WORKER AKM FES
j = { 'pe' } ;
NAME = { 'ee'       ;
         'en'       ; 
         'm'        ;
         'u'        ;
         'wage_p1'  ;
         'wage_p5'  ;
         'wage_p10' } ;
settings.size = 49 ;
settings.type = 'oneaxis' ;         
gKey = { 'Data' , 'Model' } ;
for i=NAME'

    % settings
    settings.x1 = MomentsByDecileY1.(j{1}) ;
    settings.x2 = MomentsByDecileY2.(j{1}) ;
    settings.xd = MomentsByDecileYD.(j{1}) ;
    settings.xformat = MomentsByDecileFormat.(j{1}) ;
    settings.y1 = MomentsByDecileY1.(i{1}) ;
    settings.y2 = MomentsByDecileY2.(i{1}) ;
    settings.yd = MomentsByDecileYD.(i{1}) ;
    settings.yformat = MomentsByDecileFormat.(i{1}) ;
    titles.x = MomentsByDecileTitle.(j{1}) ;
    titles.y = MomentsByDecileTitle.(i{1}) ;

    % pick up relevant object
    name = [options.SaveGraphs 'ModelFit_' i{1} '.png'] ;
    draw.x = MomentsByDecile.(j{1}) ;
    yaxis_data = MomentsByDecileData.(i{1})(MomentsByDecileData.period==1) ;
    yaxis_model = MomentsByDecile.(i{1}) ;
    draw.y = [ yaxis_data , yaxis_model ] ;
    Graphs( draw , titles , gKey , settings , options , name ) ;

end




% FIGURE 7: MODEL MECHANICS
XAXIS.sorting = log( NumGrids.a ) ;
X1.sorting = -.25 ;
X2.sorting = 2.15 ;
XD.sorting = .6 ;
XFORMAT.sorting = '%3.2f' ;
XTITLE.sorting = 'Log worker ability' ; 
Y11.sorting = .75 ;
Y12.sorting = 1.75 ;
YD1.sorting = .25 ;
YFORMAT1.sorting = '%3.2f' ;
YTITLE1.sorting = 'Mean log productivity' ;
YAXIS1.sorting = sum( log( NumGrids.z ) .* ( Model.gz .* NumGrids.dz ) , 2 ) ./ sum( Model.gz .* NumGrids.dz , 2 ) ;    
Y21.sorting = 0 ;
Y22.sorting = 1 ;
YD2.sorting = .25 ;
YFORMAT2.sorting = '%3.2f' ;
YTITLE2.sorting = 'Cumulative density function' ;
YAXIS2.sorting = cumsum(NumGrids.psi.*NumGrids.da) ;
GKEY.sorting = { 'Productivity' , 'Density' } ;

[ ~ , aa ] = min( abs(cumsum( NumGrids.psi.*NumGrids.da )- .01) ) ;
XAXIS.gradient = log( NumGrids.z ) ;
X1.gradient = 0 ;
X2.gradient = 2 ;
XD.gradient = .5 ;
XFORMAT.gradient = '%3.2f' ;
XTITLE.gradient = 'Log firm productivity' ;    
Y11.gradient = -.25 ;
Y12.gradient = .75 ;
YD1.gradient = .25 ;    
YFORMAT1.gradient = '%3.2f' ;
YTITLE1.gradient = 'Log piece rate' ;
YAXIS1.gradient = log( Model.w(aa,:) ) ;
Y21.gradient = 0 ;
Y22.gradient = 1 ;
YD2.gradient = .25 ;    
YFORMAT2.gradient = '%3.2f' ;
YTITLE2.gradient = 'Cumulative density function' ;
YAXIS2.gradient = cumsum( NumGrids.gamma .* NumGrids.dz );
GKEY.gradient = { 'Piece rate' , 'Density' } ;
NAME = { 'gradient' , 'sorting' } ;
settings.type = 'twoaxes_thiny2' ;
for i=NAME

    settings.x1 = X1.(i{1}) ;
    settings.x2 = X2.(i{1}) ;
    settings.xd = XD.(i{1}) ;
    settings.xformat = XFORMAT.(i{1}) ;
    settings.y1_a1 = Y11.(i{1}) ;
    settings.y2_a1 = Y12.(i{1}) ;
    settings.yd_a1 = YD1.(i{1}) ;
    settings.yformat_a1 = YFORMAT1.(i{1}) ;
    settings.y1_a2 = Y21.(i{1}) ;
    settings.y2_a2 = Y22.(i{1}) ;
    settings.yd_a2 = YD2.(i{1}) ;
    settings.yformat_a2 = YFORMAT2.(i{1}) ;
    gKey = GKEY.(i{1}) ;
    titles.x = XTITLE.(i{1}) ;
    titles.y1 = YTITLE1.(i{1}) ;
    titles.y2 = YTITLE2.(i{1}) ;
    draw.x = XAXIS.(i{1});
    draw.y1 = YAXIS1.(i{1});
    draw.y2 = YAXIS2.(i{1});
    name = [options.SaveGraphs 'ModelMechanics_' i{1} '.png'] ;
    Graphs( draw , titles , gKey , settings , options , name ) ;

end
clear draw titles settings






% FIGURE 47: ADDITIONAL MODEL VALIDATION
settings.size = 49 ;
j = { 'pe' } ;
NAME = { 'wage_mean'    ;
         'wage_var'     ;
         'fe_mean'      ;
         'fe_var'       } ;
gKey = { 'Data' , 'Model' } ;
settings.type = 'oneaxis' ;
for i=NAME'

    % settings
    settings.x1 = MomentsByDecileY1.(j{1}) ;
    settings.x2 = MomentsByDecileY2.(j{1}) ;
    settings.xd = MomentsByDecileYD.(j{1}) ;
    settings.xformat = MomentsByDecileFormat.(j{1}) ;
    settings.y1 = MomentsByDecileY1.(i{1}) ;
    settings.y2 = MomentsByDecileY2.(i{1}) ;
    settings.yd = MomentsByDecileYD.(i{1}) ;
    settings.yformat = MomentsByDecileFormat.(i{1}) ;

    titles.x = MomentsByDecileTitle.(j{1}) ;
    titles.y = MomentsByDecileTitle.(i{1}) ;

    % pick up relevant object
    draw.x = MomentsByDecile.(j{1}) ;
    yaxis_model = MomentsByDecile.(i{1}) ;
    yaxis_data = MomentsByDecileData.(i{1})(MomentsByDecileData.period==1) ;
    % normalize mean by wages at top
    if strcmp(i{1},'wage_mean') || strcmp(i{1},'fe_mean')
        yaxis_model = yaxis_model-yaxis_model(end);
        yaxis_data = yaxis_data-yaxis_data(end);
    end
    draw.y = [ yaxis_data , yaxis_model ] ;
    name = [options.SaveGraphs 'ModelValidation_' i{1} '.png' ] ;

    Graphs( draw , titles , gKey , settings , options , name ) ;

end

j = { 'fe' } ;
NAME = { 'wage_mean'    ;
         'wage_var'     } ;
for i=NAME'

    % settings
    settings.x1 = MomentsByDecileFEY1.(j{1}) ;
    settings.x2 = MomentsByDecileFEY2.(j{1}) ;
    settings.xd = MomentsByDecileFEYD.(j{1}) ;
    settings.xformat = MomentsByDecileFEFormat.(j{1}) ;
    settings.y1 = MomentsByDecileFEY1.(i{1}) ;
    settings.y2 = MomentsByDecileFEY2.(i{1}) ;
    settings.yd = MomentsByDecileFEYD.(i{1}) ;
    settings.yformat = MomentsByDecileFEFormat.(i{1}) ;
    titles.x = MomentsByDecileFETitle.(j{1}) ;
    titles.y = MomentsByDecileFETitle.(i{1}) ;
    draw.x = MomentsByDecileFE.(j{1}) ;
    yaxis_model = MomentsByDecileFE.(i{1}) ;
    yaxis_data = MomentsByDecileFEData.(i{1})(MomentsByDecileFEData.period==1) ;
    % normalize mean by wages at top
    if strcmp(i{1},'wage_mean') || strcmp(i{1},'fe_mean')
        yaxis_model = yaxis_model-yaxis_model(end);
        yaxis_data = yaxis_data-yaxis_data(end);
    end
    draw.y = [ yaxis_data , yaxis_model ] ;        
    name = [options.SaveGraphs 'ModelValidation_' i{1} 'FE.png' ] ;
    Graphs( draw , titles , gKey , settings , options , name ) ;

end

    
    
    
    
    
    





































fprintf('(%2.0f ) Solving the model for a different minimum wage \n',step)
step = step+1 ;
fprintf('-----------------------------------------------------\n\n\n')
options.Estimation = 'N' ;
mw = 2 ;
[ WAGE2 , active2 , Moments2 , MomentsByDecile2 , MomentsByDecileFE2 , Model2 , NumGrids2 , error2 ] = Solve( Params , ExogParams , NumGrids , Numerical , MinWageGrid(mw) , options ) ;
% check that reservation wage does not change as a result of the
% minimum wage in non-binding markets
[ check1 , check2 , check3 ] = CheckReservationWage( Model2 , ExogParams , NumGrids2 , Numerical , exp(MinWageGrid(mw)) , options ) ;
for s = fieldnames(Moments)'
    MOMENTS.(s{1}) = [ Moments.(s{1}) , Moments2.(s{1}) ];
end
for s = fieldnames(MomentsByDecile)'
    MOMENTSBYDECILE.(s{1}) = [ MomentsByDecile.(s{1}) , MomentsByDecile2.(s{1}) ];
end    
for s = fieldnames(MomentsByDecileFE)'
    MOMENTSBYDECILEFE.(s{1}) = [ MomentsByDecileFE.(s{1}) , MomentsByDecileFE2.(s{1}) ];
end    





% FIGURE 9: CDF OF WAGES
FontSize = 15 ;
LegendSize = 15 ;
GridWidth = .9 ;
LineWidth = 2.5 ;
% panel a
gKey = { '1996' , '2018' } ;
[y,x] = histcounts(log(WAGE(:)),(-.5:.1:4.5)') ;
y1_model = y/sum(y) ;
x1 = x(1:end-1) ;
[y,x] = histcounts(log(WAGE2(:)),(-.5:.1:4.5)') ;
y2_model = y/sum(y) ;
x2 = x(1:end-1) ; 
h=figure('visible',options.DisplayFigure,'Pos',[500 , 500 , 500 , 450 ]);
AX = plot(cumsum(y1_model),x1,cumsum(y2_model),x2) ; hold on
AX(1).Color = [50 0 200]/255 ;
AX(1).LineStyle = '-';
AX(1).LineWidth = LineWidth ;
AX(2).Color = [230 0 30]/255 ;
AX(2).LineStyle = '-.';
AX(2).LineWidth = LineWidth ;
ax = ancestor(AX(1), 'axes') ;
ax.YAxis.Exponent = 0 ;
xtickformat('%.2f')
ytickformat('%.2f')
ylim([-.4,3.6]) ;
yticks(-.4:1:3.6) ;
xlim([0,1]) ;
xticks(0:.25:1) ;
set(gca,'fontsize',FontSize,'ticklabelinterpreter','latex');        
xlabel(sprintf('%s','Cdf of wages'),'interpreter','latex','FontSize',FontSize);
ylabel(sprintf('%s','Log wage'),'interpreter','latex','FontSize',FontSize);
ax = gca ;
ax.XGrid = 'on' ;
ax.YGrid = 'on' ;
ax.GridColor = [ 0 0 0 ] / 255 ;
ax.GridAlpha = 1;
ax.GridLineStyle = ':' ;
ax.LineWidth = GridWidth ;
ax.TickLabelInterpreter = 'latex' ;
ax.FontSize = FontSize ;    
legHdl = legend(AX,gKey,'Interpreter','latex') ;
legHdl.Location = 'NorthWest' ;
legHdl.FontSize = LegendSize ;
legHdl.Color = [1,1,1,0] ;
set(legHdl.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;1]))
legHdl.Visible = 'on' ;
set(legHdl,'EdgeColor','none');
drawnow
print([options.SaveGraphs 'WageCDF1.png'],'-dpng')
% panel b
temp1 = cumsum(y2_model) ;
temp2 = x2 ;
temp1(y2_model == 0) = [] ;
temp2(y2_model == 0) = [] ;
cdf2 = interp1(temp1,temp2,cumsum(y1_model),'linear','extrap') ;
diff = cdf2'-x1 ;
diff(2:end-1) = (diff(1:end-2)+diff(2:end-1)+diff(3:end))/3 ;
h=figure('visible',options.DisplayFigure,'Pos',[500 , 500 , 500 , 450 ]);
AX = plot(cumsum(y1_model),diff) ; hold on
AX(1).Color = [50 0 200]/255 ;
AX(1).LineStyle = '-';
AX(1).LineWidth = LineWidth ;
ax = ancestor(AX(1), 'axes') ;
ax.YAxis.Exponent = 0 ;
xtickformat('%.2f')
ytickformat('%.2f')
xlim([0,1]) ;
xticks(0:.25:1) ;
ylim([0,.6]) ;
yticks(0:.15:.6) ;
set(gca,'fontsize',FontSize,'ticklabelinterpreter','latex');        
ylabel(sprintf('%s','Change in wage (log)'),'interpreter','latex','FontSize',FontSize);
xlabel(sprintf('%s','Cdf of initial wages'),'interpreter','latex','FontSize',FontSize);
ax = gca ;
ax.XGrid = 'on' ;
ax.YGrid = 'on' ;
ax.GridColor = [ 0 0 0 ] / 255 ;
ax.GridAlpha = 1;
ax.GridLineStyle = ':' ;
ax.LineWidth = GridWidth ;
ax.TickLabelInterpreter = 'latex' ;
ax.FontSize = FontSize ;    
drawnow
print([options.SaveGraphs 'WageCDF2.png'],'-dpng')





% TABLE 5: IMPACT OF A HIGHER MINIMUM WAGE
Title = { 'Variance' , 'P5-50' , 'P10-50' , 'P25-50' , 'P75-50' , 'P90-50' , 'P95-50' } ;
Outcome = { 'wage_var' , 'wage_p5_50' , 'wage_p10_50' , 'wage_p25_50' , 'wage_p75_50' , 'wage_p90_50' , 'wage_p95_50' } ;
fid = fopen([options.SaveTables 'Results.tex'],'w');
fprintf(fid,'\\begin{tabular}{l cc c cc c ccc} \n');
fprintf(fid,'\\hline \\hline \\addlinespace[1ex] \n');
fprintf(fid,'& \\multicolumn{2}{c}{1996} && \\multicolumn{2}{c}{2018} && \\multicolumn{3}{c}{Change} \\\\ \\cline{2-3} \\cline{5-6} \\cline{8-10} \n ');
fprintf(fid,'& \\phantom{\\textbf{Due to M}} & \\phantom{\\textbf{Due to M}} && \\phantom{\\textbf{Due to M}} & \\phantom{\\textbf{Due to M}} && \\phantom{\\textbf{Due to M}} & \\phantom{\\textbf{Due to M}} & \\phantom{\\textbf{Due to}} \\\\ \\addlinespace[-1ex] \n');
fprintf(fid,'& Data & Model && Data & Model && Data & Model & \\textbf{Due to MW} \\\\ \\hline');
fprintf(fid,'\\addlinespace[1.5ex] \n');
i=1 ;
for s = Outcome
    fprintf(fid,'%s \\hspace{.4in} & %4.3f & %4.3f && %4.3f & %4.3f && %4.3f & %4.3f & \\textbf{%4.1f\\%%} \\\\ \n',Title{i},MomentsData.(s{1})(1),MOMENTS.(s{1})(1),MomentsData.(s{1})(2),MOMENTS.(s{1})(2),MomentsData.(s{1})(2)-MomentsData.(s{1})(1),MOMENTS.(s{1})(2)-MOMENTS.(s{1})(1),100*(MOMENTS.(s{1})(2)-MOMENTS.(s{1})(1))/(MomentsData.(s{1})(2)-MomentsData.(s{1})(1)));
    i = i+1 ;
end
fprintf(fid,'\\addlinespace[.5ex] \\hline \n');
fprintf(fid,'\\end{tabular}');
fclose(fid);




% TABLE 6: DECOMPOSITION OF EFFECT OF A HIGHER MINIMUM WAGE
clear Decomposition
for s = { 'total' , 'total_vacancy' , 'total_wage' , 'within' , 'within_vacancy' , 'within_wage' , 'across' , 'across_vacancy' , 'across_wage' , 'average' , 'variance' , 'productivity' }
    Decomposition.(s{1}) = [] ;
end
Model1 = Model ;
for i=1:2

    % pick up relevant part
    eval(['w = Model' num2str(i) '.w ;']);
    eval(['e = Model' num2str(i) '.e ;']);
    eval(['eMW = Model' num2str(i) '.eMW ;']);
    eval(['g = Model' num2str(i) '.gz ;']);
    eval(['MinWage = MinWageGrid(' num2str(i) ');']);

    % integrate to right amount
    g = g .* NumGrids.dz ;
    g(isnan(g)) = 0 ;
    g = g ./ nansum( g , 2 ) ;
    e = e .* NumGrids.psi .* NumGrids.da ;
    eMW = eMW .* NumGrids.psi .* NumGrids.da ;

    % convert to actual wage
    wage = log( NumGrids.a.*w ) ;

    % compute means and variances
    within_avg = ( nansum( wage .* g , 2 ) .* e + MinWage .* eMW ) ./ (e+eMW) ;
    within_var = ( nansum( (wage-within_avg).^2 .* g , 2 ) .* e + (MinWage-within_avg).^2 .* eMW ) ./ (e+eMW) ;
    grand_avg = nansum( nansum( wage .* g , 2 ) .* e + MinWage .* eMW ) ./ sum(e+eMW) ;
    across = nansum( (within_avg-grand_avg).^2 .* ( e + eMW ) , 1 ) ./ sum(e+eMW);
    within = nansum( within_var  .* (e+eMW) ) ./ sum(e+eMW) ;
    variance = nansum( ( nansum( (wage-grand_avg).^2 .* g , 2 ) .* e + (MinWage-grand_avg).^2 .* eMW ) ) ./ sum(e+eMW) ;
    within_prod = nansum( log(NumGrids.z) .* g , 2 ) ;

    % assign for later decomposition
    eval(['w' num2str(i) ' = wage ;']) ;
    eval(['e' num2str(i) ' = e ;']) ;
    eval(['eMW' num2str(i) ' = eMW ;']) ;
    eval(['g' num2str(i) ' = g ;']) ;
    eval(['MinWage' num2str(i) ' = MinWage ;']) ;

    Decomposition.average = [ Decomposition.average , within_avg-within_avg(end) ] ; 
    Decomposition.variance = [ Decomposition.variance , within_var ] ;
    Decomposition.productivity = [ Decomposition.productivity , within_prod-within_prod(end) ] ;
    Decomposition.total = [ Decomposition.total , variance ] ;
    Decomposition.within = [ Decomposition.within , within ] ;
    Decomposition.across = [ Decomposition.across , across ] ;            

end
clear wage w MinWage e eMW g
% fixed vacancy/wage counterfactual
for i=1:2
    for j=1:2

        eval(['wage = w' num2str(i) ' ;']) ;
        eval(['MinWage = MinWage' num2str(i) ' ;']) 
        eval(['e = e' num2str(j) ' ;']) ;
        eval(['eMW = eMW' num2str(j) ' ;']) ;
        eval(['g = g' num2str(j) ' ;']) ;

        within_avg = ( nansum( wage .* g , 2 ) .* e + MinWage .* eMW ) ./ (e+eMW) ;
        grand_avg = nansum( nansum( wage .* g , 2 ) .* e + MinWage .* eMW ) ./ sum(e+eMW) ;
        across = nansum( (within_avg-grand_avg).^2 .* ( e + eMW ) , 1 ) ./ sum(e+eMW);
        within = nansum( ( ( nansum( (wage-within_avg).^2 .* g , 2 ) .* e + (MinWage-within_avg).^2 .* eMW ) ./ (e+eMW) ) .* (e+eMW) ) ./ sum(e+eMW) ;
        variance = nansum( ( nansum( (wage-grand_avg).^2 .* g , 2 ) .* e + (MinWage-grand_avg).^2 .* eMW ) ) ./ sum(e+eMW) ;

        if i==1
            Decomposition.total_vacancy = [ Decomposition.total_vacancy , variance ] ;
            Decomposition.within_vacancy = [ Decomposition.within_vacancy , within ] ;
            Decomposition.across_vacancy = [ Decomposition.across_vacancy , across ] ;
        end
        if j==1
            Decomposition.total_wage = [ Decomposition.total_wage , variance ] ;
            Decomposition.within_wage = [ Decomposition.within_wage , within ] ;
            Decomposition.across_wage = [ Decomposition.across_wage , across ] ;
        end

    end
end

Title = { 'Total variance' , '\hspace{.05in} \textit{Rent} channel (change in firm wage policy only, fixed allocation)' , '\hspace{.05in} \textit{Reallocation} channel (reallocation only, fixed firm wage policy)' , ...
          'Between variance' , '\hspace{.05in} \textit{Rent} channel (change in firm wage policy only, fixed allocation)' , '\hspace{.05in} \textit{Reallocation} channel (reallocation only, fixed firm wage policy)' , ...
          'Within variance' , '\hspace{.05in} \textit{Rent} channel (change in firm wage policy only, fixed allocation)' , '\hspace{.05in} \textit{Reallocation} channel (reallocation only, fixed firm wage policy)' } ;
Outcome = { 'total' , 'total_wage' , 'total_vacancy' , 'across' , 'across_wage' , 'across_vacancy' , 'within' , 'within_wage' , 'within_vacancy' } ;
fid = fopen([options.SaveTables 'Decomposition.tex'],'w');
fprintf(fid,'\\begin{tabular}{l c c c c } \n');
fprintf(fid,'\\hline \\hline \\addlinespace[1.5ex] \n');
fprintf(fid,'&& 1996 & 2018 & Change \\\\ \\hline ');
fprintf(fid,'\\addlinespace[1.5ex] \n');
i=1;
for s=Outcome
    if contains(s{1},'_')
        fprintf(fid,'%s && -- & %4.3f & %4.3f \\\\ \n',Title{i},Decomposition.(s{1})(2),Decomposition.(s{1})(2)-Decomposition.(s{1})(1));
    else
        fprintf(fid,'\\textbf{%s} && \\textbf{%4.3f} & \\textbf{%4.3f} & \\textbf{%4.3f} \\\\ \n',Title{i},Decomposition.(s{1})(1),Decomposition.(s{1})(2),Decomposition.(s{1})(2)-Decomposition.(s{1})(1));
    end
    if contains(s{1},'_vacancy')
        fprintf(fid,'\\addlinespace[1.5ex] \n');
    end
    i=i+1;
end
fprintf(fid,'\\hline \n');
fprintf(fid,'\\end{tabular}');
fclose(fid);






% FIGURE 10: CHANGES IN FIRMS' POLICIES
% pay by firm productivity in first percentile of ability market
[ ~ , aa ] = min( abs(cumsum( NumGrids.psi.*NumGrids.da )- .01) ) ;
XAXIS.wage = log( NumGrids.z ) ;
X1.wage = .4 ;
X2.wage = 2 ;
XD.wage = .4 ;
XFORMAT.wage = '%3.2f' ;
XTITLE.wage = 'Log firm productivity' ;
Y1.wage = 20 ;
Y2.wage = 100 ;
YD.wage = 20 ;    
YFORMAT.wage = '%3.0f' ;
YTITLE.wage = 'Change in piece rate (\%)' ;
YAXIS.wage = 100*(Model2.w(aa,:)-Model.w(aa,:))./Model.w(aa,:) ;
XAXIS.vacancy = log( NumGrids.z ) ;
X1.vacancy = .4 ;
X2.vacancy = 2 ;
XD.vacancy = .4 ;
XFORMAT.vacancy = '%3.2f' ;
XTITLE.vacancy = 'Log firm productivity' ;
Y1.vacancy = -100 ;
Y2.vacancy = 100 ;
YD.vacancy = 50 ;
YFORMAT.vacancy = '%3.0f' ;
YTITLE.vacancy = 'Change in vacancies (\%)' ;
YAXIS.vacancy = 100*(Model2.v(aa,:)-Model.v(aa,:))./Model.v(aa,:) ;
NAME = { 'wage' , 'vacancy' } ;
settings.size = 49 ;
settings.type = 'oneaxis' ;
for i=NAME

    % settings
    settings.x1 = X1.(i{1}) ;
    settings.x2 = X2.(i{1}) ;
    settings.xd = XD.(i{1}) ;
    settings.xformat = XFORMAT.(i{1}) ;
    titles.x = XTITLE.(i{1}) ;
    draw.x = XAXIS.(i{1});
    settings.y1 = Y1.(i{1}) ;
    settings.y2 = Y2.(i{1}) ;
    settings.yd = YD.(i{1}) ;
    settings.yformat = YFORMAT.(i{1}) ;
    titles.y = YTITLE.(i{1}) ;
    draw.y = YAXIS.(i{1});
    name = [options.SaveGraphs 'ModelMechanicsChange_' i{1} '.png'] ;
    Graphs( draw , titles , gKey , settings , options , name ) ;

end








% FIGURE 49: WITHIN VS BETWEEN MODEL
clear settings
settings.type = 'oneaxis' ;
settings.size = 49 ;
settings.x1 = 0 ;
settings.x2 = 1 ;
settings.xd = .25 ;
settings.xformat = '%.2f' ;
titles.x = 'Cdf of worker ability' ;
TITLE.average = 'Mean log wage' ;
X1.average = -6 ;
X2.average = 0 ;
XD.average = 1.5 ;
FORMAT.average = '%.2f' ;
TITLE.variance = 'Variance of log wages' ;
X1.variance = 0 ;
X2.variance = .6 ;
XD.variance = .15 ;
FORMAT.variance = '%.2f' ;
TITLE.productivity = 'Mean log productivity' ;
X1.productivity = -.75 ;
X2.productivity = .25 ;
XD.productivity = .25 ;
FORMAT.productivity = '%.2f' ;    
gKey = { '1996' , '2018' } ;
NAME = { 'average' , 'variance' , 'productivity' } ;
for i=NAME

    % settings
    settings.y1 = X1.(i{1}) ;
    settings.y2 = X2.(i{1}) ;
    settings.yd = XD.(i{1}) ;
    settings.yformat = FORMAT.(i{1}) ;
    titles.y = TITLE.(i{1}) ;

    % pick up relevant object
    draw.x = cumsum( NumGrids.psi .* NumGrids.da ) ;
    draw.y = Decomposition.(i{1}) ;
    name = [options.SaveGraphs 'Change_' i{1} '_model.png'] ;
    Graphs( draw , titles , gKey , settings , options , name ) ;

end

% pay by firm productivity
clear Outcome
pay1 = log( nansum( NumGrids.a.*Model.w.*Model.l , 1 ) ./ nansum( Model.l , 1 ) ) ;
pay2 = log( nansum( NumGrids2.a.*Model2.w.*Model2.l , 1 ) ./ nansum( Model2.l , 1 ) ) ;
ability1 = log( nansum( NumGrids.a.*Model.l , 1 ) ./ nansum( Model.l , 1 ) ) ;
ability2 = log( nansum( NumGrids2.a.*Model2.l , 1 ) ./ nansum( Model2.l , 1 ) ) ;    
Decomposition.pay = [ pay1-pay1(end) ; pay2-pay1(end) ] ;
Decomposition.ability = [ ability1-ability1(end) ; ability2-ability1(end) ] ;

settings.x1 = 0 ;
settings.x2 = 1 ;
settings.xd = .25 ;
settings.xformat = '%.2f' ;
titles.x = 'Cdf of firm productivity' ;
TITLE.pay = 'Mean log wage' ;
X1.pay = -6 ;
X2.pay = 0 ;
XD.pay = 1.5 ;
FORMAT.pay = '%.2f' ;
TITLE.ability = 'Mean log worker ability' ;
X1.ability = -2 ;
X2.ability = 0 ;
XD.ability = .5 ;
FORMAT.ability = '%.2f' ;    
gKey = { '1996' , '2018' } ;
NAME = { 'pay' , 'ability' } ;
for i=NAME

    % settings
    settings.y1 = X1.(i{1}) ;
    settings.y2 = X2.(i{1}) ;
    settings.yd = XD.(i{1}) ;
    settings.yformat = FORMAT.(i{1}) ;
    titles.y = TITLE.(i{1}) ;
    draw.x = cumsum( NumGrids.gamma .* NumGrids.dz ) ;
    draw.y = Decomposition.(i{1}) ;
    name = [options.SaveGraphs 'Change_firm_' i{1} '_model.png'] ;
    Graphs( draw , titles , gKey , settings , options , name ) ;

end

clear settings y1 y2 yd yformat y
j = { 'pe' } ;
NAME = { 'wage_mean'    ;
         'wage_var'     ;
         'fe_mean'      ;
         'fe_var'       } ;
gKey = { 'Data, level' , 'Model, level' , 'Data, change' , 'Model, change' } ;
settings.type = 'twoaxes' ;
settings.size = 49 ;
settings.legendcols = 2 ;
for i=NAME'

    % settings
    settings.x1 = MomentsByDecileY1.(j{1}) ;
    settings.x2 = MomentsByDecileY2.(j{1}) ;
    settings.xd = MomentsByDecileYD.(j{1}) ;
    settings.xformat = MomentsByDecileFormat.(j{1}) ;
    titles.x = MomentsByDecileTitle.(j{1}) ;

    y1.left = MomentsByDecileY1.(i{1}) ;
    y2.left = MomentsByDecileY2.(i{1}) ;
    yd.left = MomentsByDecileYD.(i{1}) ;
    yformat.left = '%.1f' ;
    y1.right = -.3 ;
    y2.right = .9 ;
    yd.right = .3 ;
    yformat.right = '%.1f' ;
    settings.y1 = y1 ;
    settings.yd = yd ;
    settings.y2 = y2 ;
    settings.yformat = yformat ;
    y.left = '1994--1998 level' ;
    y.right = '1994--2014 change' ;
    titles.y = y ;

    % pick up relevant object
    draw.x = MomentsByDecile.(j{1}) ;
    yaxis_model1 = MomentsByDecile.(i{1}) ;
    yaxis_model2 = MomentsByDecile2.(i{1}) ;        
    yaxis_data1 = MomentsByDecileData.(i{1})(MomentsByDecileData.period==1) ;
    yaxis_data2 = MomentsByDecileData.(i{1})(MomentsByDecileData.period==2) ;
    % normalize mean by wages at top
    if strcmp(i{1},'wage_mean') || strcmp(i{1},'fe_mean')
        yaxis_model2 = yaxis_model2-yaxis_model2(end);
        yaxis_model1 = yaxis_model1-yaxis_model1(end);
        yaxis_data2 = yaxis_data2-yaxis_data2(end);
        yaxis_data1 = yaxis_data1-yaxis_data1(end);            
    end
    change_model = yaxis_model2-yaxis_model1 ;
    change_data = yaxis_data2-yaxis_data1 ;        
    draw.y = [ yaxis_data1 , yaxis_model1 , change_data , change_model ] ;
    draw.loc = { 'left' , 'left' , 'right' , 'right' } ;
    name = [options.SaveGraphs 'ModelDataChange_' i{1} '.png' ] ;
    Graphs( draw , titles , gKey , settings , options , name ) ;

end















% TABLE 15: AKM DECOMPOSITION IN MODEL VS DATA
Outcome = { 'wage_var' , 'pe_var' , 'fe_var' , 'resid_var' , 'pe_fe_cov' } ;
fid = fopen([options.SaveTables 'AKM.tex'],'w');
fprintf(fid,'\\begin{tabular}{l cc c cc c ccc} \n');
fprintf(fid,'\\hline \\hline \\addlinespace[1ex] \n');
fprintf(fid,'& \\multicolumn{2}{c}{1994--1998} && \\multicolumn{2}{c}{2014--2018} && \\multicolumn{3}{c}{Change} \\\\ \\cline{2-3} \\cline{5-6} \\cline{8-10} \n ');
fprintf(fid,'& \\phantom{\\textbf{Due to M}} & \\phantom{\\textbf{Due to M}} && \\phantom{\\textbf{Due to M}} & \\phantom{\\textbf{Due to M}} && \\phantom{\\textbf{Due to M}} & \\phantom{\\textbf{Due to M}} & \\phantom{\\textbf{Due to}} \\\\ \\addlinespace[-1ex] \n');
fprintf(fid,'& Data & Model && Data & Model && Data & Model & \\textbf{Due to MW} \\\\ \\hline');
fprintf(fid,'\\addlinespace[1.5ex] \n');
for s = Outcome
    fprintf(fid,'%s & %4.3f & %4.3f && %4.3f & %4.3f && %4.3f & %4.3f & \\textbf{%4.1f\\%%} \\\\ \n',MomentsTitle.(s{1}),MomentsData.(s{1})(1),MOMENTS.(s{1})(1),MomentsData.(s{1})(2),MOMENTS.(s{1})(2),MomentsData.(s{1})(2)-MomentsData.(s{1})(1),MOMENTS.(s{1})(2)-MOMENTS.(s{1})(1),100*(MOMENTS.(s{1})(2)-MOMENTS.(s{1})(1))/(MomentsData.(s{1})(2)-MomentsData.(s{1})(1)));
end
fprintf(fid,'\\addlinespace[.5ex] \\hline \n');
fprintf(fid,'\\end{tabular}');
fclose(fid);











% TABLE 7: AGGREGATE OUTCOMES
Model1 = Model ;

clear Aggregate
for s = { 'Emp' , 'Output' , 'Wage' , 'Cost' , 'NetOutput' , 'Prod' , 'LS' , 'Profits' }
    Aggregate.(s{1}) = [] ;
end
for i=[1,2]
    % number of firms
    eval(['firms' num2str(i) ' = ExogParams.M * repmat( NumGrids.gamma .* NumGrids.dz , Numerical.Na , 1 );']);
    % size
    eval(['fsize' num2str(i) ' = Model' num2str(i) '.l+Model' num2str(i) '.lmw ;']);
    % output per firm
    eval(['output' num2str(i) ' = repmat( NumGrids.a , 1 , Numerical.Nz ) .* repmat( NumGrids.z , Numerical.Na , 1 ) .* fsize' num2str(i) ' ; '])
    % wage bill per firm
    eval(['wagebill' num2str(i) ' = repmat( NumGrids.a , 1 , Numerical.Nz ) .* Model' num2str(i) '.w  .* fsize' num2str(i) ' ; '])
    % vacancy cost per firm
    eval(['c' num2str(i) ' = repmat( NumGrids.a.*NumGrids.cost , 1 , Numerical.Nz ) .* Model' num2str(i) '.v.^(1+Params.eta) /(1+Params.eta) ; '])
    eval(['cmw' num2str(i) ' = repmat( NumGrids.a.*NumGrids.costMW , 1 , Numerical.Nz ) .* Model' num2str(i) '.vmw.^(1+Params.eta) /(1+Params.eta) ; '])

    % aggregate outcomes -> integrate against number of firms
    eval(['Aggregate.Emp = [ Aggregate.Emp , nansum( fsize' num2str(i) '(:) .* firms' num2str(i) '(:) ) ] ;']);
    eval(['Aggregate.Output = [ Aggregate.Output , log( nansum( output' num2str(i) '(:) .* firms' num2str(i) '(:) ) ) ] ;']);
    eval(['Aggregate.Wage = [ Aggregate.Wage , log( nansum( wagebill' num2str(i) '(:) .* firms' num2str(i) '(:) ) ) ] ;']);
    eval(['Aggregate.Cost = [ Aggregate.Cost , log( nansum( ( c' num2str(i) '(:) + cmw' num2str(i) '(:) ) .* firms' num2str(i) '(:) ) ) ] ;']);
    eval(['Aggregate.NetOutput = [ Aggregate.NetOutput , log( exp( Aggregate.Output(' num2str(i) '))-exp( Aggregate.Cost(' num2str(i) ')) ) ] ;']);
    eval(['Aggregate.Prod = [ Aggregate.Prod , Aggregate.Output(' num2str(i) ')-log(Aggregate.Emp(' num2str(i) ')) ] ;']);
    eval(['Aggregate.LS = [ Aggregate.LS , exp(Aggregate.Wage(' num2str(i) ')-Aggregate.Output(' num2str(i) ') ) ];'])
    eval(['Aggregate.Profits = [ Aggregate.Profits , log( exp(Aggregate.NetOutput(' num2str(i) '))-exp(Aggregate.Wage(' num2str(i) ')) ) ];'])

end
% overwrite with simulated employment
Aggregate.Emp = MOMENTS.e ;

Title = { 'Employment rate, $E = \int e(a,s) d\Omega(a,s)$' , 'Aggregate output, $\log Y = \log \left( \int azdG(z|a,s)e(a,s)d\Omega(a,s) \right) $' , 'Labor productivity, $\log (Y/E)$' , 'Aggregate cost of recruiting, $\log C = \log \left( M \int a c(a,s) \frac{v(z|a,s)^{1+\eta}}{1+\eta} d\Gamma(z)dads\right) $' , 'Aggregate output minus recruiting costs, $\log (Y-C)$' , 'Total wage bill, $\log W = \log \left( \int a w(z|a,s)dG(z|a,s)e(a,s)d\Omega(a,s)\right)$' , 'Total profits, $\log(Y-W-C)$' , 'Labor share, $W/Y$' } ;
Outcome = { 'Emp' , 'Output' , 'Prod' , 'Cost' , 'NetOutput' , 'Wage' , 'Profits' , 'LS' } ;
fid = fopen([options.SaveTables 'Aggregate.tex'],'w');
fprintf(fid,'\\begin{tabular}{l c c c } \n');
fprintf(fid,'\\hline \\hline \\addlinespace[1.5ex] \n');
fprintf(fid,'& 1996 & 2018 & \\textbf{Due to MW} \\\\ \\hline ');
fprintf(fid,'\\addlinespace[1.5ex] \n');
i=1;
for s=Outcome
    fprintf(fid,'%s & %4.3f & %4.3f & \\textbf{%4.3f} \\\\ \n',Title{i},Aggregate.(s{1})(1),Aggregate.(s{1})(2),Aggregate.(s{1})(2)-Aggregate.(s{1})(1));
    if strcmp(s{1},'Prod') || strcmp(s{1},'Cost')
        fprintf(fid,'\\addlinespace[0.5ex] \n');
    else
        fprintf(fid,'\\addlinespace[1ex] \n');
    end
    i=i+1;
end
fprintf(fid,'\\addlinespace[.5ex] \\hline \n');
fprintf(fid,'\\end{tabular}');
fclose(fid);



% FIGURE 50: EMPLOYMENT RESPONSE
FontSize = 15 ;
LegendSize = 15 ;
GridWidth = .9 ;
LineWidth = 2.5 ;

x1 = 0 ;
x2 = 1 ;
xd = .25 ;
xformat = '%.2f' ;
xtitle = 'Cdf of worker ability' ;
y1 = -20 ;
y2 = 0 ;
yd = 5 ;
yformat = '%.0f' ;
ytitle = 'Change in employment (\%)' ;
figure('visible',options.DisplayFigure,'Pos',[500 , 500 , 500 , 450 ]);
AX = plot(cumsum(NumGrids.psi.*NumGrids.da),100*((Model2.e+Model2.eMW)./(Model1.e+Model1.eMW)-1)); hold on;
xlim([x1,x2]);
xticks(x1:xd:x2) ;
ylim([y1,y2]);
yticks(y1:yd:y2) ;
AX(1).Color = [50 0 200]/255 ;
AX(1).LineStyle = '-';
AX(1).LineWidth = LineWidth ;
ax = ancestor(AX(1), 'axes') ;
ax.YAxis.Exponent = 0 ;
xtickformat(xformat)
ytickformat(yformat)
set(gca,'fontsize',FontSize,'ticklabelinterpreter','latex');        
ylabel(sprintf('%s',ytitle),'interpreter','latex','FontSize',FontSize);
xlabel(sprintf('%s',xtitle),'interpreter','latex','FontSize',FontSize);
ax = gca ;
ax.XGrid = 'on' ;
ax.YGrid = 'on' ;
ax.GridColor = [ 0 0 0 ] / 255 ;
ax.GridAlpha = 1;
ax.LineWidth = GridWidth ;
ax.GridLineStyle = ':' ;
ax.TickLabelInterpreter = 'latex' ;
ax.FontSize = FontSize ;    
print([options.SaveGraphs 'MWandEmployment.png' ],'-dpng')
drawnow

% firm size by firm productivity
x1 = 0 ;
x2 = 1 ;
xd = .25 ;
xformat = '%.2f' ;
xtitle = 'Cdf of firm productivity' ;
y1 = -60 ;
y2 = 20 ;
yd = 20 ;
yformat = '%.0f' ;
ytitle = 'Change in size (\%)' ;
figure('visible',options.DisplayFigure,'Pos',[500 , 500 , 500 , 450 ]);
AX = plot(cumsum(NumGrids.gamma.*NumGrids.dz),100*(nansum(Model2.l+Model2.lmw,1)./nansum(Model1.l+Model1.lmw,1)-1)); hold on;
xlim([x1,x2]);
xticks(x1:xd:x2) ;
ylim([y1,y2]);
yticks(y1:yd:y2) ;
AX(1).Color = [50 0 200]/255 ;
AX(1).LineStyle = '-';
AX(1).LineWidth = LineWidth ;
ax = ancestor(AX(1), 'axes') ;
ax.YAxis.Exponent = 0 ;
xtickformat(xformat)
ytickformat(yformat)
set(gca,'fontsize',FontSize,'ticklabelinterpreter','latex');        
ylabel(sprintf('%s',ytitle),'interpreter','latex','FontSize',FontSize);
xlabel(sprintf('%s',xtitle),'interpreter','latex','FontSize',FontSize);
ax = gca ;
ax.XGrid = 'on' ;
ax.YGrid = 'on' ;
ax.GridColor = [ 0 0 0 ] / 255 ;
ax.GridAlpha = 1;
ax.LineWidth = GridWidth ;
ax.GridLineStyle = ':' ;
ax.TickLabelInterpreter = 'latex' ;
ax.FontSize = FontSize ;    
print([options.SaveGraphs 'MWandSize.png' ],'-dpng')
drawnow







% FIGURE 11: DECOMPOSITION OF VACANCY CREATION
% changes in a=a1 market
%           - pay
%           - vacancy creation
%           - fill rate
%           - size
[ ~ , aa ] = min( abs(cumsum( NumGrids.psi.*NumGrids.da )- .01) ) ;
q1 = NumGrids.lambda.^((ExogParams.alpha-1)/ExogParams.alpha) ;
q2 = NumGrids2.lambda.^((ExogParams.alpha-1)/ExogParams.alpha) ;
fill1 = q1 .* ( Model1.u ./ (Model1.u+NumGrids.phi.*Model1.e) + NumGrids.phi .* Model1.e .* Model1.G ./ (Model1.u+NumGrids.phi.*Model1.e) );
fill2 = q2 .* ( Model2.u ./ (Model2.u+NumGrids2.phi.*Model2.e) + NumGrids2.phi .* Model2.e .* Model2.G ./ (Model2.u+NumGrids2.phi.*Model2.e) );
ret1 = 1./(NumGrids.delta+NumGrids.phi.*NumGrids.lambda.*(1-Model.F)) ;
ret2 = 1./(NumGrids2.delta+NumGrids2.phi.*NumGrids2.lambda.*(1-Model2.F)) ;

% panel a
% focus on lowest a market
profit = NumGrids.z-Model1.w(aa,:) ;
P = 1/Params.eta*(log(max(NumGrids2.z-Model2.w(aa,:),0))-log(max(NumGrids.z-Model1.w(aa,:),0))) ;
V = log(Model2.v(aa,:)) - log(Model1.v(aa,:)) ;
Q = 1/Params.eta*(log(fill2(aa,:)) - log(fill1(aa,:))) ;
R = -1/Params.eta*(log(ret2(aa,:)) - log(ret1(aa,:))) ;

% changes within markets
clear y1 yd y2 yformat titles settings y
gKey = { 'Profit' , 'Fill rate' , 'Retention' , 'Total' } ;
settings.x1 = .5 ;
settings.x2 = 1.7 ;
settings.xd = .3 ;
settings.xformat = '%.2f' ;
titles.x = 'Log productivity, $\log z$' ;
y1.left = -12 ;
yd.left = 4 ;
y2.left = 4 ;
y1.right = -.2 ;    
yd.right = .2 ;    
y2.right = .6 ;    
yformat.left = '%.1f' ;
yformat.right = '%.1f' ;
settings.y1 = y1 ;
settings.yd = yd ;
settings.y2 = y2 ;
settings.yformat = yformat ;
y.left = 'Change in profit / total vacancies (log)' ;
y.right = 'Change in fill rate / retention (log)' ;
titles.y = y ;
settings.type = 'twoaxes' ;
settings.size = 49 ;
name = [options.SaveGraphs 'MWandFirmOutcomes.png' ] ;
settings.legendcols = 4 ;
draw.x = log(NumGrids.z) ;
draw.y = [ P' , Q' , R' , V' ] ;
draw.loc = { 'left' , 'right' , 'right' , 'left' } ;
Graphs( draw , titles , gKey , settings , options , name ) ;


% panel b
V = nansum( Model.v .* ( NumGrids.gamma .* NumGrids.dz ) , 2 ) ;
V2 = nansum( Model2.v .* ( NumGrids.gamma .* NumGrids.dz ) , 2 ) ;
% change in e relative to change in p
term1 = (log(Model2.e)-log(Model.e))./(log(NumGrids2.lambda)-log(NumGrids.lambda)) ;
% unstable at end
term1(sum(term1>0)) = term1(sum(term1>0)-1);
term2 = (log(NumGrids2.lambda)-log(NumGrids.lambda)) ./ (log(V2)-log(V) ) ;
term3 = (log(V2)-log(V)) ./ ( MinWageGrid(2)-MinWageGrid(1) ) ;
tot = ( log(Model2.e)-log(Model.e) ) ./ ( MinWageGrid(2)-MinWageGrid(1) ) ;
% numerical error when dividing by something very close to zero ->
% approximate with linear interpolation
term1(term1<0) = 0 ;
term2(term2<0) = 0 ;
gKey = { 'JF' , 'Congestion' , 'Vacancy' , 'Total' } ;
settings.x1 = 0 ;
settings.x2 = 1 ;
settings.xd = .25 ;
settings.xformat = '%.2f' ;
titles.x = 'Cdf of worker ability' ;
settings.y1 = -1 ;
settings.y2 = 1 ;
settings.yd = .5 ;
settings.yformat = '%.1f' ;
titles.y = 'Change (log)' ;
draw.x = cumsum(NumGrids.psi.*NumGrids.da) ;
draw.y = [term1,term2,term3,tot] ;
name = [options.SaveGraphs 'MWandAggregateOutcomes.png' ] ;
settings.type = 'oneaxis' ;
settings.size = 49 ;
settings.legendcols = 4 ;
Graphs( draw , titles , gKey , settings , options , name ) ;


    
























  







fprintf('(%2.0f ) Robustness of estimated effect to variation in parameters \n',step)
step = step+1 ;
fprintf('----------------------------------------------------------------\n\n\n')
load([options.SaveResults 'Jacobian']) ;

% set external parameters
[ ExogParams ] = ExogenousParameters ;

% settings for 0.49 latex width figures
FontSize = 15 ;
LegendSize = 15 ;
GridWidth = .9 ;
LineWidth = 2.5 ;
font = 'Garamond' ;
color1 = [50 0 200]/255 ;
color2 = [230 0 30]/255 ;
color3 = [0 150 0]/255 ;
color4 = [255 150 0]/255 ;
linestyle1 = '-' ;
linestyle2 = '-.' ;
linestyle3 = '--' ;
linestyle4 = ':' ;

X.mu = [ .4 , 1.8 , .35 ] ; 
X.sigma = [ .1 , .5 , .1 ] ; 
X.zeta = [ 2.2 , 9 , 1.7 ] ; 
X.eta = [ .1 , 1.5 , .35 ] ; 
X.error = [ .05 , .65 , .15 ] ; 
X.delta0 = [ .02 , .22 , .05 ] ; 
X.delta1 = [ -2.8 , 0 , .7 ] ; 
X.phi0 = [ .2 , .8 , .15 ] ; 
X.phi1 = [ .4 , 2 , .4 ] ; 
X.r0 = [ -.24 , -.0, .06 ] ; 
X.r1 = [ .4 , 3.6 , .8 ] ; 
X.pi = [ .0 , .06 , .015 ] ;
X.lambda = [ .01 , .15 , .035 ] ;
X.deltaMW = [ .02 , .22 , .05 ] ;
X.alpha = [ .26 , .7 , .11 ] ;
xformat = '%.3f' ;



% FIGURES 43-44: JACOBIAN MATRIX AROUND OPTIMUM
y1 = 0 ;
y2 = .6 ; 
yd = .15 ;
yformat = '%.2f' ;
ytitle = 'Minimum distance' ;
period = 1 ;
gKey = { 'Minimum distance' , 'Parameter estimate' } ;
for i=fieldnames(Jacobian)'

    % pick up relevant object
    x1 = X.(i{1})(1) ;
    x2 = X.(i{1})(2) ;
    xd = X.(i{1})(3) ;

    xaxis = Jacobian.(i{1}).value ;
    Moments = Jacobian.(i{1}).Moments ;
    MomentsByDecile = Jacobian.(i{1}).MomentsByDecile ;
    DIST = zeros( 1 , length(Moments.e) ) ;
    j = 1 ;
    for t=fieldnames(Targets)'
        targets = (Targets.(t{1})) ;
        outcome = [] ;
        outcome_m = [] ;      
        if length(targets{1}) > 0
            for s = targets
                outcome = [ outcome ; MomentsData.(s{1})(MomentsData.period==period) ] ;
                outcome_m = [ outcome_m ; Moments.(s{1}) ] ;
            end
            weight = 1 ; %/ length(outcome) ;
            if strcmp(Targets.(t{1}),{'wage_p50_min'})
                weight = 5 ; %/ length(outcome) ;
            end
            % if outcome is missing, replace with large value
            outcome_m(isnan(outcome_m)) = 1e10 ;
            dist = weight .* sum( ((outcome_m-outcome)./outcome).^2 , 1 ) ;
            DIST = DIST + dist ;
        end
        j=j+1;
    end
    for t=fieldnames(TargetsByDecile)'
        targets = (TargetsByDecile.(t{1})) ;
        outcome = [] ;
        outcome_m = [] ;
        if length(targets{1}) > 0
            for s = targets
                outcome = [ outcome ; MomentsByDecileData.(s{1})(MomentsByDecileData.period==period) ] ;
                outcome_m = [ outcome_m ; MomentsByDecile.(s{1}) ] ;
            end
            weight = 1 / length(outcome) ;
            % this is so close to zero we have to do levels
            outcome_m(isnan(outcome_m)) = 1e10 ;
            if strcmp(targets{1},'wage_p1') || strcmp(targets{1},'wage_p5') || strcmp(targets{1},'wage_p10')
                dist = weight .* sum( ((exp(outcome_m)-exp(outcome))./exp(outcome)).^2 , 1 ) ;
            else
                dist = weight .* sum( ((outcome_m-outcome)./outcome).^2 , 1 ) ;
            end
            DIST = DIST + dist ;            
        end      
    end
    [ ~ , m ] = min( DIST ) ;
    DIST = DIST - DIST(m) ;

    F1 = figure('visible',options.DisplayFigure,'Pos',[500 , 500 , 500 , 450 ]);
    AX = plot(xaxis,DIST); hold on;
    xlim([x1,x2]);
    xticks(x1:xd:x2) ;
    ylim([y1,y2]);
    yticks(y1:yd:y2) ;
    AX(1).Color = color1 ;
    AX(1).LineStyle = linestyle1 ;
    AX(1).LineWidth = LineWidth ;
    xtickformat(xformat)
    ytickformat(yformat)
    set(gca,'fontsize',FontSize,'ticklabelinterpreter','latex');        
    ylabel(sprintf('%s',ytitle),'interpreter','latex','FontSize',FontSize);
    ax = ancestor(AX(1), 'axes') ;
    ax.YAxis.Exponent = 0 ;
    ax = gca ;
    ax.XGrid = 'on' ;
    ax.YGrid = 'on' ;
    ax.GridColor = [ 0 0 0 ] / 255 ;
    ax.GridAlpha = 1;
    ax.LineWidth = GridWidth ;
    ax.GridLineStyle = ':' ;
    ax.TickLabelInterpreter = 'latex' ;
    ax.FontSize = FontSize ;    
    if strcmp(i{1},'alpha') || strcmp(i{1},'lambda')
        xlabel(sprintf('$\\%s$',i{1}),'interpreter','latex','FontSize',FontSize);
        BX = plot([ExogParams.(i{1}),ExogParams.(i{1})],[-500,500]);
    elseif strcmp(i{1},'deltaMW')
        xlabel(sprintf('$\\delta_{MW}$'),'interpreter','latex','FontSize',FontSize);
        BX = plot([ExogParams.(i{1}),ExogParams.(i{1})],[-500,500]) ;
    else
        xlabel(sprintf('%s',ParameterName.(i{1})),'interpreter','latex','FontSize',FontSize);
        BX = plot([Params.(i{1}),Params.(i{1})],[-500,500]);
    end
    BX.LineStyle = linestyle2 ;
    BX.Color = color2 ;
    BX.LineWidth = LineWidth ;        
    legHdl = legend([AX,BX],gKey,'Interpreter','latex') ;
    legHdl.Location = 'NorthWest' ;
    legHdl.FontSize = LegendSize ;
    legHdl.Color = [1,1,1,0] ;
    set(legHdl.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;1]))
    legHdl.Visible = 'on' ;
    set(legHdl,'EdgeColor','none') ;
    print([options.SaveGraphs 'Jacobian_' i{1} '.png' ],'-dpng')
    hold off
    drawnow

end    



% FIGURES 45-46: HOW EACH PARAMETER MOVES EACH MOMENT
load([options.SaveEstimates '.mat']) ;
y1 = 0 ;
y2 = .4 ; 
yd = .1 ;
yformat = '%.3f' ;
period = 1 ;
choicetargets = Targets ;
choicetargets.delta0 = { 'en' } ;
choicetargets.phi0 = { 'ee' } ;
choicetargets.lambda = { 'e' } ;
Y.mu = [ .4 , 2 , .4 ] ; 
Y.zeta = [ 0 , .6 , .15 ] ;
Y.eta = [ 0 , 1 , .25 ] ;
Y.error = [ 0 , .6 , .15 ] ;
Y.delta0 = [ 0 , .2 , .05 ] ;
Y.phi0 = [ 0.005 , .025 , .005 ] ;
Y.pi = [ 0 , .08 , .02 ] ;
Y.lambda = [ 0 , .8 , .2 ] ;
xformat = '%.3f' ;
gKey = { 'Counter-factual value of moment' , 'Parameter estimate' , 'Estimated value of moment' } ;
for i = { 'mu' , 'zeta' , 'eta' , 'error' , 'pi' , 'delta0' , 'phi0' }

    % pick up relevant object
    x1 = X.(i{1})(1) ;
    x2 = X.(i{1})(2) ;
    xd = X.(i{1})(3) ;
    y1 = Y.(i{1})(1) ;
    y2 = Y.(i{1})(2) ;
    yd = Y.(i{1})(3) ;

    xaxis = Jacobian.(i{1}).value ;
    Moments = Jacobian.(i{1}).Moments.(choicetargets.(i{1}){1}) ;
    if strcmp(i{1},'alpha') || strcmp(i{1},'lambda')
        [ ~ , m ] = min( abs(xaxis-ExogParams.(i{1})) ) ;
    else
        [ ~ , m ] = min( abs(xaxis-Params.(i{1})) ) ;
    end
    moment = Moments( m ) ;
    if strcmp(i{1},'delta0')
        Moments(xaxis<.02) = NaN ;
        xaxis(xaxis<.02) = NaN ;            
    end
    if strcmp(i{1},'zeta')
        Moments(xaxis<2.21) = NaN ;
        xaxis(xaxis<2.21) = NaN ;
    end
    if strcmp(i{1},'pi')
        Moments(xaxis<.005) = NaN ;
        xaxis(xaxis<.005) = NaN ;
    end 
    if strcmp(i{1},'error')
        Moments(xaxis<.06) = NaN ;
        xaxis(xaxis<.06) = NaN ;
    end
    if strcmp(i{1},'lambda')
        Moments(xaxis<.015) = NaN ;
        xaxis(xaxis<.015) = NaN ;
    end

    F1 = figure('visible',options.DisplayFigure,'Pos',[500 , 500 , 500 , 450 ]);
    AX = plot(xaxis,Moments); hold on;
    xlim([x1,x2]);
    xticks(x1:xd:x2) ;
    ylim([y1,y2]);
    yticks(y1:yd:y2) ;
    AX(1).Color = color1 ;
    AX(1).LineStyle = linestyle1 ;
    AX(1).LineWidth = LineWidth ;
    xtickformat(xformat)
    ytickformat(yformat)
    set(gca,'fontsize',FontSize,'ticklabelinterpreter','latex');
    ylabel(sprintf('%s',MomentsTitle.(choicetargets.(i{1}){1})),'interpreter','latex','FontSize',FontSize);
    ax = ancestor(AX(1), 'axes') ;
    ax.YAxis.Exponent = 0 ;
    ax = gca ;
    ax.XGrid = 'on' ;
    ax.YGrid = 'on' ;
    ax.GridColor = [ 0 0 0 ] / 255 ;
    ax.GridAlpha = 1;
    ax.LineWidth = GridWidth ;
    ax.GridLineStyle = ':' ;
    ax.TickLabelInterpreter = 'latex' ;
    ax.FontSize = FontSize ;
    if strcmp(i{1},'alpha') || strcmp(i{1},'lambda')
        xlabel(sprintf('$\\%s$',i{1}),'interpreter','latex','FontSize',FontSize);
        BX = plot([ExogParams.(i{1}),ExogParams.(i{1})],[-500,500]) ;
    elseif strcmp(i{1},'deltaMW')
        xlabel(sprintf('$\\delta_{MW}$'),'interpreter','latex','FontSize',FontSize);
        BX = plot([ExogParams.(i{1}),ExogParams.(i{1})],[-500,500]) ;
    else
        xlabel(sprintf('%s',ParameterName.(i{1})),'interpreter','latex','FontSize',FontSize);
        BX = plot([Params.(i{1}),Params.(i{1})],[-500,500]) ;
    end
    BX.LineStyle = linestyle2 ;
    BX.Color = color2 ;
    BX.LineWidth = LineWidth ;        
    CX = plot([-500,500],[moment,moment]) ;
    CX(1).LineStyle = linestyle3 ;
    CX(1).Color = color3 ;
    CX(1).LineWidth = LineWidth ;        
    legHdl = legend([AX,BX,CX],gKey,'Interpreter','latex') ;
    legHdl.Location = 'NorthWest' ;
    legHdl.FontSize = LegendSize ;
    legHdl.Color = [1,1,1,0] ;
    set(legHdl.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;1]))
    legHdl.Visible = 'on' ;
    set(legHdl,'EdgeColor','none');
    print([options.SaveGraphs 'Jacobian_Moment_' i{1} '.png' ],'-dpng')
    hold off
    drawnow

end    








% FIGURES 12 AND 55-56:  changes in inequality against parameters
X.mu = [ .4 , 1.6 , .3 ] ; 
X.sigma = [ .1 , .5 , .1 ] ; 
X.zeta = [ 2.5 , 4.5 , .5 ] ; 
X.eta = [ .1 , .9 , .2 ] ; 
X.error = [ .05 , .65 , .15 ] ; 
X.delta0 = [ .02 , .14 , .03 ] ; 
X.delta1 = [ -2.8 , 0 , .7 ] ; 
X.phi0 = [ .2 , .8 , .15 ] ; 
X.phi1 = [ .4 , 2 , .4 ] ; 
X.r0 = [ -.24 , -.0, .06 ] ; 
X.r1 = [ .4 , 3.6 , .8 ] ; 
X.pi = [ .0 , .06 , .015 ] ;
X.lambda = [ .01 , .09 , .02 ] ;
X.deltaMW = [ .02 , .22 , .05 ] ;
X.alpha = [ .26 , .7 , .11 ] ;
xformat = '%.3f' ;
yformat = '%.3f' ;
ytitle = 'Change in variance of log wages' ;
gKey = { 'Counter-factual change in inequality' , 'Parameter estimate'  , 'Estimated change in inequality' } ;
for i=fieldnames(Jacobian)'

    % pick up relevant object
    x1 = X.(i{1})(1) ;
    x2 = X.(i{1})(2) ;
    xd = X.(i{1})(3) ;
    y1 = -.2 ;
    y2 = 0 ;
    yd = .05 ;        
%         y1 = Y.(i{1})(1) ;
%         y2 = Y.(i{1})(2) ;
%         yd = Y.(i{1})(3) ;

    xaxis = Jacobian.(i{1}).value ;
    yaxis_model = Jacobian.(i{1}).wage_var ;
    yaxis_model = yaxis_model(:,2)-yaxis_model(:,1) ;
    if strcmp(i{1},'zeta')
        yaxis_model(xaxis<2.21) = NaN ;
        xaxis(xaxis<2.21) = NaN ;
    end
%         yaxis_model(isfinite(yaxis_model)) = movmean(yaxis_model(isfinite(yaxis_model)),5) ;
    if strcmp(i{1},'alpha') || strcmp(i{1},'lambda') || strcmp(i{1},'deltaMW')
        [ ~ , m ] = min( abs(xaxis-ExogParams.(i{1})) ) ;
    else
        [ ~ , m ] = min( abs(xaxis-Params.(i{1})) ) ;
    end        
    moment = yaxis_model(m) ;

    F1 = figure('visible',options.DisplayFigure,'Pos',[500 , 500 , 500 , 450 ]);
    AX = plot(xaxis,yaxis_model); hold on;
    xlim([x1,x2]);
    xticks(x1:xd:x2) ;
    ylim([y1,y2]);
    yticks(y1:yd:y2) ;
    AX(1).Color = color1 ;
    AX(1).LineStyle = linestyle1 ;
    AX(1).LineWidth = LineWidth ;
    xtickformat(xformat)
    ytickformat(yformat)
    set(gca,'fontsize',FontSize,'ticklabelinterpreter','latex');        
    ylabel(sprintf('%s',ytitle),'interpreter','latex','FontSize',FontSize);
    ax = ancestor(AX(1), 'axes') ;
    ax.YAxis.Exponent = 0 ;
    ax = gca ;
    ax.XGrid = 'on' ;
    ax.YGrid = 'on' ;
    ax.GridColor = [ 0 0 0 ] / 255 ;
    ax.GridAlpha = 1;
    ax.LineWidth = GridWidth ;
    ax.GridLineStyle = ':' ;
    ax.TickLabelInterpreter = 'latex' ;
    ax.FontSize = FontSize ;    
    if strcmp(i{1},'alpha') || strcmp(i{1},'lambda')
        xlabel(sprintf('$\\%s$',i{1}),'interpreter','latex','FontSize',FontSize);
        BX = plot([ExogParams.(i{1}),ExogParams.(i{1})],[-500,500]) ;
    elseif strcmp(i{1},'deltaMW')
        xlabel(sprintf('$\\delta_{MW}$'),'interpreter','latex','FontSize',FontSize);
        BX = plot([ExogParams.(i{1}),ExogParams.(i{1})],[-500,500]);
    else
        xlabel(sprintf('%s',ParameterName.(i{1})),'interpreter','latex','FontSize',FontSize);
        BX = plot([Params.(i{1}),Params.(i{1})],[-500,500]);
    end
    BX.LineStyle = linestyle2 ;
    BX.Color = color2 ;
    BX.LineWidth = LineWidth ;
    CX = plot([-500,500],[moment,moment]) ;
    CX(1).LineStyle = linestyle3 ;
    CX(1).Color = color3 ;
    CX(1).LineWidth = LineWidth ; 
    legHdl = legend([AX,BX,CX],gKey,'Interpreter','latex') ;
    legHdl.Location = 'NorthWest' ;
    legHdl.FontSize = LegendSize ;
    legHdl.Color = [1,1,1,0] ;
    set(legHdl.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;1]))
    legHdl.Visible = 'on' ;
    set(legHdl,'EdgeColor','none');
    print([options.SaveGraphs 'Robustness_wage_' i{1} '.png' ],'-dpng')
    hold off
    drawnow

end





% FIGURES 51-54: CHANGE IN EMPLOYMENT AGAINST PARAMETERS
xformat = '%.3f' ;
Y.eta = [ -.012 , 0 , .003 ] ; 
Y.alpha = [ -.012 , 0 , .003 ] ; 
Y.mu = [ -.02 , 0 , .005 ] ; 
Y.sigma = [ -.012 , 0 , .003 ] ; 
Y.zeta = [ -.012 , 0 , .003 ] ; 
Y.error = [ -.012 , 0 , .003 ] ; 
Y.delta0 = [ -.012 , 0 , .003 ] ; 
Y.delta1 = [ -.012 , 0 , .003 ] ; 
Y.phi0 = [ -.012 , 0 , .003 ] ; 
Y.phi1 = [ -.012 , 0 , .003 ] ; 
Y.r0 = [ -.012 , 0 , .003 ] ; 
Y.r1 = [ -.012 , 0 , .003 ] ; 
Y.pi = [ -.012 , 0 , .003 ] ; 
Y.lambda = [ -.012 , 0 , .003 ] ; 
Y.deltaMW = [ -.012 , 0 , .003 ] ; 
yformat = '%.3f' ;
ytitle = 'Change in employment (p.p.)' ;
gKey = { 'Counter-factual change in employment' , 'Parameter estimate'  , 'Estimated change in employment' } ;
for i= fieldnames(Jacobian)'

    % pick up relevant object
    x1 = X.(i{1})(1) ;
    x2 = X.(i{1})(2) ;
    xd = X.(i{1})(3) ;
    y1 = Y.(i{1})(1) ;
    y2 = Y.(i{1})(2) ;
    yd = Y.(i{1})(3) ;

    xaxis = Jacobian.(i{1}).value ;
    yaxis_model = Jacobian.(i{1}).emp ;
    yaxis_model = yaxis_model(:,2)-yaxis_model(:,1) ;
    if strcmp(i{1},'zeta')
        yaxis_model(xaxis<2.21) = NaN ;
        xaxis(xaxis<2.21) = NaN ;
    end
%         yaxis_model(isfinite(yaxis_model)) = movmean(yaxis_model(isfinite(yaxis_model)),5) ;
    if strcmp(i{1},'alpha') || strcmp(i{1},'lambda') || strcmp(i{1},'deltaMW')
        [ ~ , m ] = min( abs(xaxis-ExogParams.(i{1})) ) ;
    else
        [ ~ , m ] = min( abs(xaxis-Params.(i{1})) ) ;
    end
    moment = yaxis_model(m) ;

    F1 = figure('visible',options.DisplayFigure,'Pos',[500 , 500 , 500 , 450 ]);
    AX = plot(xaxis,yaxis_model); hold on;
    xlim([x1,x2]);
    xticks(x1:xd:x2) ;
    ylim([y1,y2]);
    yticks(y1:yd:y2) ;
    AX(1).Color = color1 ;
    AX(1).LineStyle = linestyle1 ;
    AX(1).LineWidth = LineWidth ;
    xtickformat(xformat)
    ytickformat(yformat)
    set(gca,'fontsize',FontSize,'ticklabelinterpreter','latex');        
    ylabel(sprintf('%s',ytitle),'interpreter','latex','FontSize',FontSize);
    ax = ancestor(AX(1), 'axes') ;
    ax.YAxis.Exponent = 0 ;
    ax = gca ;
    ax.XGrid = 'on' ;
    ax.YGrid = 'on' ;
    ax.GridColor = [ 0 0 0 ] / 255 ;
    ax.GridAlpha = 1;
    ax.LineWidth = GridWidth ;
    ax.GridLineStyle = ':' ;
    ax.TickLabelInterpreter = 'latex' ;
    ax.FontSize = FontSize ;    
    if strcmp(i{1},'alpha') || strcmp(i{1},'lambda')
        xlabel(sprintf('$\\%s$',i{1}),'interpreter','latex','FontSize',FontSize);
        BX = plot([ExogParams.(i{1}),ExogParams.(i{1})],[-500,500]) ;
    elseif strcmp(i{1},'deltaMW')
        xlabel(sprintf('$\\delta_{MW}$'),'interpreter','latex','FontSize',FontSize);
        BX = plot([ExogParams.(i{1}),ExogParams.(i{1})],[-500,500]) ;
    else
        xlabel(sprintf('%s',ParameterName.(i{1})),'interpreter','latex','FontSize',FontSize);
        BX = plot([Params.(i{1}),Params.(i{1})],[-500,500]) ;
    end
    BX.LineStyle = linestyle2 ;
    BX.Color = color2 ;
    BX.LineWidth = LineWidth ;
    CX = plot([-500,500],[moment,moment]) ;
    CX(1).LineStyle = linestyle3 ;
    CX(1).Color = color3 ;
    CX(1).LineWidth = LineWidth ; 
    legHdl = legend([AX,BX,CX],gKey,'Interpreter','latex') ;
    legHdl.Location = 'NorthEast' ;
    legHdl.FontSize = LegendSize ;
    legHdl.Color = [1,1,1,0] ;
    set(legHdl.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;1]))
    legHdl.Visible = 'on' ;
    set(legHdl,'EdgeColor','none') ;
    print([options.SaveGraphs 'Robustness_employment_' i{1} '.png' ],'-dpng')
    hold off
    drawnow

end







  




fprintf('FINISHED EXECUTION \n\n')
time = datetime ; 
fprintf('End date:        %02.0f/%02.0f/%4.0f\n',month(time),day(time),year(time))
fprintf('End time:        %02.0f:%02.0f \n\n',hour(time),minute(time))
fprintf('*****************************************************************************************************\n')