var_name = { 'wl'  'sa' 'cu' 'wv' } ;

stationNames = []
for year = 1996 : 2016
    for var = 1 : length(var_name)
        filename = strcat('D:\7_Projekte\2017_EasyGSH\03_Arbeitspakete\2_Hydraulik\4_ValidationData\',string(year),'_validationData\prepared_data_zeitrio\',string(year),'.',var_name(var),'.zeitrio.dat')
        if exist (filename,'file')
            iJustWantToHaveTheHeaders = readtable(filename);
            newNames = iJustWantToHaveTheHeaders.Properties.VariableNames
            if ~isempty(stationNames)
                commonNames = intersect(newNames, stationNames)
                newNames = removevars(newNames, removeVars)
                stationNames = mergevars (newNames, stationNames)
            else
                stationNames = newNames
            end
        end
    end
end
stationNamesTable=table(stationNames);
writetable(stationNamesTable,'D:\temp\wrongStationNames.txt');
