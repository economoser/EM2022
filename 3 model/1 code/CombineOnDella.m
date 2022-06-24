% -------------------------------------------------------------------------
% Combined server results into one big file for download
% -------------------------------------------------------------------------
options.ReadResults = '/scratch/network/nengbom/brazil/tempfiles/SobolLoop' ;
options.SaveResults = '/scratch/network/nengbom/brazil/Results' ;
options.NumLoops = 30000 ;

version = 1 ;
SOBOLSTART  = 1 ;
SOBOLEND    = 33 ;
nparams     = 12 ;
nmoments1   = 35 ;
nmoments2   = 40 ;

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

save([options.SaveResults 'Final' num2str(version) '.mat'],'Params','Moments','MomentsByDecile');
