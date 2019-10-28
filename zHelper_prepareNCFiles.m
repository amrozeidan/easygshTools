
centralFolder = 'D:\7_Projekte\2017_EasyGSH\03_Arbeitspakete\2_Hydraulik\4_ValidationData';
measBaseFolder = 'D:\7_Projekte\2017_EasyGSH\03_Arbeitspakete\2_Hydraulik\4_ValidationData\origData_netcdf'
for year = 2002 : 2002
    year
    yearMeasFolder = strcat(measBaseFolder,'\',string(year));
    yearValidDataFolder = strcat(centralFolder,'\',string(year),'_validationData');
    if exist(yearMeasFolder)
        measprep('nc', yearValidDataFolder, yearMeasFolder, centralFolder);
    end
end