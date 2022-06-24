function [data, varlist] = csv2mat_block(filename)


%
% S. HSIANG
% SMH2137@COLUMBIA.EDU
% 5/10
%
% ----------------------------
%
% [data, varlist] = csv2mat_block(filename)
%
% CSV2MAT_BLOCK reads in the data from the CSV file FILENAME and formats
% it as a block matrix named DATA.  FILENAME should have the ending '.csv' 
% if that is part of the actual file name, but can have an arbitrary 
% ending. FILENAME is a string and must be in single quotes.
%
% If VARLIST is specified as an output, a cell vector with the titles of 
% the variables imported, in correct order, is assigned to it.
%
% Missing observations are recorded as NaN.
%
% This function will give an error if any elements below the header line
% are not either numeric values or missing values.
%
% CSV means "comma seperated values" and is any text file that looks like
% the following:
%
% header line ->        age, height, weight
% data lines ->         13, 2, 150
%                       35, , 163
%                       ...
%
% CSV files are output from STATA in the correct format using the
% "OUTSHEET" command with the option "COMMA" specified.
%



%reading the data in with csvread, but not using this because missing
%observations are just 
data0=csvread(filename,1,0);
N = size(data0, 1);
C = size(data0, 2);


%creating the string command to read in N variables per line
line = [];
for i = 1:C
    line = [line ' %f'];
end

%opening file and reading the names and data
fid = fopen(filename);
names = textscan(fid,'%s',C,'delimiter',',');
numbers = textscan(fid, line, N, 'delimiter',',','CollectOutput',1);
vars = names{1};
fclose(fid);

varlist = vars;

data = numbers{1};

disp(' ')
disp('==========================================')
disp('IMPORTED VARIABLES')
disp(' ')
disp(vars)
disp('==========================================')


return