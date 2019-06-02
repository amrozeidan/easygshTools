

filename = '/Users/amrozeidan/Documents/hiwi/data18052019/processed/1995CRO.txt' ;
outputfolder = '/Users/amrozeidan/Desktop/output';

T = readtable(filename);
T.Var2 = datetime(T.Var2 , 'InputFormat' , 'yyyy/MM/dd');
T.Var3 = datetime(T.Var3 , 'InputFormat' , 'HH:mm:ss');
T.Var1 = T.Var2 + timeofday(T.Var3);
T.Var2 = [];
T.Var3 = [];
T.Var6 = [];
T.Properties.VariableNames = {'Datetime' , 'SeaLevel' , 'Residual' } ; 

fid = fopen(filename , 'r');
text = cell(9 , 1);
for i=1:9
    text(i) = {fgetl(fid)};
end
fclose(fid);
stationname = split(text{2} , ':' );
stationname = strtrim(stationname(2));

filepatho = strcat(outputfolder , '/', stationname{:} , '.dat') ; 
writetable(T , filepatho);

formatSpec = '%s%s%s';
fid = fopen(filepatho , 'r');
A = fscanf(fid , formatSpec );
fclose(fid);

filepath = '/Users/amrozeidan/Desktop/somefile.dat';
fid = fopen(filepath , 'a+');
for l=1:numel(text)
    fprintf(fid , '%s\n' , text{l});
end
fclose(fid);
dlmwrite(filepath , x , '-append' , 'newline' , 'pc');

writetable(T , filepath);

