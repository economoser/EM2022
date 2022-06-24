function [] = Graphs( draw , titles , gKey , settings , options , name )

font = 'Garamond' ;
color1 = [50 0 200]/255 ;
color2 = [230 0 30]/255 ;
color3 = [0 150 0]/255 ;
color4 = [255 150 0]/255 ;
linestyle1 = '-' ;
linestyle2 = '-.' ;
linestyle3 = '--' ;
linestyle4 = ':' ;

if settings.size == 0.25
    % settings for 0.25 latex width figures
    FontSize = 25 ;
    LegendSize = 20 ;
    GridWidth = 1.5 ;
    LineWidth = 5 ;
elseif settings.size == 33
    % settings for 0.33 latex width figures
    FontSize = 18 ;
    LegendSize = 18 ;
    GridWidth = 1 ;
    LineWidth = 3 ;
elseif settings.size == 49
    % settings for 0.49 latex width figures
    FontSize = 15 ;
    LegendSize = 15 ;
    GridWidth = .9 ;
    LineWidth = 2.5 ;
elseif settings.size == 85
    % font size for 0.85 latex width figures
    FontSize = 9 ;
    LegendSize = 9 ;
    GridWidth = .5 ;
    LineWidth = 1.8 ;
else
    error('size is not well defined in function Graphs.m')
end


figure('visible',options.DisplayFigure,'units','pixels','InnerPosition',[500 , 500 , 500 , 450 ])
set(gcf,'color','w');

%% one axis
if strcmp(settings.type,'oneaxis')
    
    AX = plot(draw.x,draw.y); hold on;
    xlim([settings.x1,settings.x2]);
    xticks(settings.x1:settings.xd:settings.x2) ;        
    ylim([settings.y1,settings.y2]);
    yticks(settings.y1:settings.yd:settings.y2) ;
    AX(1).Color = color1 ;
    AX(1).LineStyle = linestyle1 ;
    AX(1).LineWidth = LineWidth ;
    if min(size(draw.y)) >= 2
        AX(2).Color = color2 ;
        AX(2).LineStyle = linestyle2 ;
        AX(2).LineWidth = LineWidth ;
    end
    if min(size(draw.y)) >= 3
        AX(3).Color = color3 ;
        AX(3).LineStyle = linestyle3 ;
        AX(3).LineWidth = LineWidth ;
    end
    if min(size(draw.y)) >= 4
        AX(4).Color = color4 ;
        AX(4).LineStyle = linestyle4 ;
        AX(4).LineWidth = LineWidth ;
    end
    ax = ancestor(AX(1), 'axes') ;
    ax.YAxis.Exponent = 0 ;
    xtickformat(settings.xformat)
    ytickformat(settings.yformat)
    set(gca,'fontsize',FontSize,'ticklabelinterpreter','latex');
    set(gca,'FontName',font);
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
    if min(size(draw.y)) >= 2
        legHdl = legend(AX,gKey,'Interpreter','latex') ;
        if min(size(draw.y)) >= 4 && settings.legendcols >= 4
            legHdl.Location = 'South' ;
            legHdl.NumColumns = settings.legendcols ;
        elseif min(size(draw.y)) >= 4
            legHdl.Location = 'North' ;
            legHdl.NumColumns = settings.legendcols ;            
        else
            legHdl.Location = 'NorthWest' ;
        end
        legHdl.FontSize = LegendSize ;
        legHdl.Color = [1,1,1,0] ;
        set(legHdl.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;1]))
        legHdl.Visible = 'on' ;
        set(legHdl,'EdgeColor','none');
    end
    print(name,'-dpng')
    drawnow
    hold off
    
end


%% two axes
if strcmp(settings.type,'twoaxes_thiny2')
    
    left_color = [0 0 0];
    right_color = [0 0 0];
    set(gcf,'defaultAxesColorOrder',[left_color; right_color]);
    yyaxis left        
    AX = plot(draw.x,draw.y1); hold on;
    xlim([settings.x1,settings.x2]);
    xticks(settings.x1:settings.xd:settings.x2) ;
    ylim([settings.y1_a1,settings.y2_a1]);
    yticks(settings.y1_a1:settings.yd_a1:settings.y2_a1) ;
    AX(1).Color = color1 ;
    AX(1).LineStyle = linestyle1 ;
    AX(1).LineWidth = LineWidth ;
    xtickformat(settings.xformat)
    ytickformat(settings.yformat_a1)
    set(gca,'fontsize',FontSize,'ticklabelinterpreter','latex');        
    ylabel(sprintf('%s',titles.y1),'interpreter','latex','FontSize',FontSize);
    xlabel(sprintf('%s',titles.x),'interpreter','latex','FontSize',FontSize);
    
    yyaxis right
    BX = plot(draw.x,draw.y2); hold on;
    xlim([settings.x1,settings.x2]);
    xticks(settings.x1:settings.xd:settings.x2) ;
    ylim([settings.y1_a2,settings.y2_a2]);
    yticks(settings.y1_a2:settings.yd_a2:settings.y2_a2) ;
    BX(1).Color = color2 ;
    BX(1).LineStyle = linestyle2;
    BX(1).LineWidth = .5*LineWidth ;
    xtickformat(settings.xformat)
    ytickformat(settings.yformat_a2)
    set(gca,'fontsize',FontSize,'ticklabelinterpreter','latex');        
    ylabel(sprintf('%s',titles.y2),'interpreter','latex','FontSize',FontSize);
    xlabel(sprintf('%s',titles.x),'interpreter','latex','FontSize',FontSize);
    ax = gca ;
    ax.XGrid = 'on' ;
    ax.YGrid = 'on' ;
    ax.GridColor = [ 0 0 0 ] / 255 ;
    ax.GridAlpha = 1;
    ax.LineWidth = GridWidth ;
    ax.GridLineStyle = ':' ;
    ax.TickLabelInterpreter = 'latex' ;
    ax.FontSize = FontSize ;    
    legHdl = legend([AX;BX],gKey,'Interpreter','latex') ;
    legHdl.Location = 'SouthEast' ;
    legHdl.FontSize = LegendSize ;
    legHdl.Color = [1,1,1,0] ;
    set(legHdl.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;1]))
    legHdl.Visible = 'on' ;
    set(legHdl,'EdgeColor','none');
    print(name,'-dpng')
    drawnow
        
end








%% two axes
if strcmp(settings.type,'twoaxes')
    
    left_color = [0 0 0];
    right_color = [0 0 0];
    set(gcf,'defaultAxesColorOrder',[left_color; right_color]);
    for i=1:4
        plotside = char(draw.loc(i)) ;
        eval(['yyaxis ' plotside])
        eval([ 'X' num2str(i) '= plot(draw.x,draw.y(:,i)); hold on;'])
        xlim([settings.x1,settings.x2]);
        xticks(settings.x1:settings.xd:settings.x2) ;
        ylim([settings.y1.(plotside),settings.y2.(plotside)]);
        yticks(settings.y1.(plotside):settings.yd.(plotside):settings.y2.(plotside)) ;
        eval(['color = color' num2str(i) ';'])
        eval(['linestyle = linestyle' num2str(i) ';'])
        eval([ 'X' num2str(i) '(1).Color = color;'])
        eval([ 'X' num2str(i) '(1).LineStyle = linestyle;'])
        eval([ 'X' num2str(i) '(1).LineWidth = LineWidth;'])
        xtickformat(settings.xformat)
        ytickformat(settings.yformat.(plotside))
        ax = gca ;
        ax.FontName = font ;
        ax.FontSize = FontSize ;
        ax.TickLabelInterpreter = 'latex' ;
        ax.YLabel.Interpreter = 'latex' ;
        ax.YLabel.FontName = font ;
        ax.YLabel.String = sprintf('%s',titles.y.(plotside)) ;
        ax.XLabel.Interpreter = 'latex' ;
        ax.XLabel.FontName = font ;
        ax.XLabel.String = sprintf('%s',titles.x) ;
    end
    ax.XGrid = 'on' ;
    ax.YGrid = 'on' ;
    ax.GridColor = [ 0 0 0 ] / 255 ;
    ax.GridAlpha = 1;
    ax.LineWidth = GridWidth ;
    ax.GridLineStyle = ':' ; 
    legHdl = legend([X1,X2,X3,X4],gKey,'Interpreter','latex') ;
    if length(gKey) >= 4 && settings.legendcols >= 4
        legHdl.Location = 'South' ;
        legHdl.NumColumns = settings.legendcols ;
    elseif length(gKey) >= 4
        legHdl.Location = 'North' ;
        legHdl.NumColumns = settings.legendcols ;        
    else
        legHdl.Location = 'NorthWest' ;
    end
    legHdl.FontSize = LegendSize ;
    legHdl.Color = [1,1,1,0] ;
    set(legHdl.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;1]))
    legHdl.Visible = 'on' ;
    set(legHdl,'EdgeColor','none');
    print(name,'-dpng')
    drawnow
        
end