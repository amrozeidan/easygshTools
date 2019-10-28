%measurement files preparation
%turn any file format into a table, to be imported later in the
%next functions

function measprep(datatype , yearValidationFolder, yearMeasFolder, common_folder)

if string(datatype) == string('nc')
    %for netcdf format
    ncdfimport(yearValidationFolder, yearMeasFolder, common_folder)
    
elseif string(datatype) == string('rio')
    %for bunch of dat files (DATZeitrio format)
    zetrioimport(yearValidationFolder, yearMeasFolder, common_folder)
    
%elseif string(datatype) == string('uk')
    %for data from the british website
end

end