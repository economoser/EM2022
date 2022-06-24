% -------------------------------------------------------------------------
% Combined server results into one big file for download
% -------------------------------------------------------------------------
options.ReadResults     = '/scratch/ne466/brazil/tempfiles/SobolLoop' ;
options.SaveResults     = '/scratch/ne466/brazil/Results' ;
options.NumLoops        = 50000 ;

version     = SOBOLSTART ;
SOBOLSTART  = mod( SOBOLSTART-1 , 25 ) + 1 ;
SOBOLSTART  = 20*(SOBOLSTART-1)+1 ;
SOBOLEND    = SOBOLSTART+19 ;
nparams     = 12 ;
nmoments1   = 35 ;
nmoments2   = 40 ;

for mainloop = 1:70

    TicMain = tic ;
    Time = toc(TicMain) ;
    % wait for an hour
    while Time < 60*30
        Time = toc(TicMain) ;
        disp('pausing for five minutes')
        pause(60*5)
    end
    disp('moving on to next iteration')
    
    % look for the first iteration that has converged to obtain field names
    i = SOBOLSTART ;
    ii = 1 ;
    Iteration = options.NumLoops * ( i - 1 ) + ii ;
    while exist([options.ReadResults num2str(Iteration) '.mat']) == 0 && i <= SOBOLEND
        ii = ii + 1 ;
        if ii >= options.NumLoops
            ii = 1 ;
            i = i+1;
        end
        Iteration = options.NumLoops * ( i - 1 ) + ii ;
    end
    load([options.ReadResults num2str(Iteration) '.mat']);
    parameternames = fieldnames( Params ) ;
    momentnames1 = fieldnames( Moments ) ;
    momentnames2 = fieldnames( MomentsByDecile ) ;

    parfor i = SOBOLSTART:SOBOLEND
        parcombine( i , options.ReadResults , options.SaveResults , options.NumLoops , nparams , nmoments1 , nmoments2 ) ;
    end

    % combine across nodes
    Parameters          = [] ;
    SimulatedMoments1   = [] ;
    SimulatedMoments2   = [] ;
    for i = SOBOLSTART : SOBOLEND
        try
            load([options.SaveResults num2str(i) '.mat']) ;
            Parameters = [ Parameters ; params ] ;
            SimulatedMoments1 = [ SimulatedMoments1 ; moments1 ] ;
            SimulatedMoments2 = [ SimulatedMoments2 ; moments2 ] ;
            delete([options.SaveResults num2str(i) '.mat'])
        catch
            disp('no file')
        end
    end
    % need to reshape this to life-cycle outcomes
    SimulatedMoments2 = SimulatedMoments2' ;
    SimulatedMoments2 = reshape( SimulatedMoments2(:) , 10 , size(SimulatedMoments2,1)/10 , size(SimulatedMoments2,2) ) ;
    SimulatedMoments2 = permute( SimulatedMoments2  , [ 1 3 2 ] ) ;

    j = 1 ;
    for i=parameternames'
        Params.(i{1}) = Parameters(:,j)' ;
        j = j+1;
    end

    j = 1 ;
    for i=momentnames1'
        Moments.(i{1}) = SimulatedMoments1(:,j)' ;
        j = j+1;
    end

    j = 1 ;
    for i=momentnames2'
        MomentsByDecile.(i{1}) = SimulatedMoments2(:,:,j) ;
        j = j+1;
    end

    storenr = 1000*(mainloop-1) + version ;
    save([options.SaveResults 'Final' num2str(storenr) '.mat'],'Params','Moments','MomentsByDecile');
    
end

% % combine all files into one for download
% for mainloop = 1:55
%     for version=13:25
% 
%         dd = 1000*(mainloop-1)+version ;
% 
%         if mainloop == 1 && version == 13
% 
%             load([options.SaveResults 'Final' num2str(dd) '.mat']) ;
%             temp1 = Params ;
%             temp2 = Moments ;
%             temp3 = MomentsByDecile ;
% 
%         else
% 
%             try
%                 load([options.SaveResults 'Final' num2str(dd) '.mat']) ;
%                 names = fieldnames( Params ) ;
%                 for mm = names'
%                     temp1.(mm{1}) = [ temp1.(mm{1}) , Params.(mm{1}) ] ;
%                 end
%                 names = fieldnames( Moments ) ;
%                 for mm = names'
%                     temp2.(mm{1}) = [ temp2.(mm{1}) , Moments.(mm{1}) ] ;
%                 end
%                 names = fieldnames( MomentsByDecile ) ;
%                 for mm = names'
%                     temp3.(mm{1}) = [ temp3.(mm{1}) , MomentsByDecile.(mm{1}) ] ;
%                 end
%             catch
%                 fprintf('could not read %6i \n',dd)
%             end
% 
%         end
%     end
% end
% Params = temp1 ;
% Moments = temp2 ;
% MomentsByDecile = temp3 ;
% clear temp1 temp2 temp3 names
% save([options.SaveResults 'DownloadMe.mat'],'Params','Moments','MomentsByDecile','-v7.3');    
% 
