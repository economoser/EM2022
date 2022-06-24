function [data] = csv2mat_numeric(filename)


%
% S. HSIANG
% SMH2137@COLUMBIA.EDU
% 5/10
%
% ----------------------------
%
% [data] = csv2mat_numeric(filename)
%
% CSV2MAT_NUMERIC reads in the data from the CSV file FILENAME and formats
% it as a structure named DATA with elements that are the header names in
% CSV file FILENAME.  FILENAME should have the ending '.csv' if that is
% part of the actual file name, but can have an arbitrary ending. FILENAME
% is a string and must be in single quotes.
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
numbers = textscan(fid, line, N, 'delimiter',',');
vars = names{1};
fclose(fid);


%checking to make sure that observations in the last line are not omitted
%if they are, it is because there was a missing value, so add NaN

for i = 1:C 
    if length(numbers{i})<N
        numbers{i} = [numbers{i}; nan];
    end
end
    
    
%formatting output into a single structure

line = ['data = struct('];
for i = 1:C
    line = [line 'vars{' num2str(i) '}, numbers{' num2str(i) '},'];
end
line = [line(1:end-1) ');'];

eval(line);


return