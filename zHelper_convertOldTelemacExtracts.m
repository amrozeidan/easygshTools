for year = 1996 : 2016
    baseNames = {'D:\7_Projekte\2017_EasyGSH\03_Arbeitspakete\2_Hydraulik\5_Auswertungen\rev04u_20190509___Produktivlaeufe\2212___T2D_GenRestSalt___y',...
                 'D:\7_Projekte\2017_EasyGSH\03_Arbeitspakete\2_Hydraulik\5_Auswertungen\rev04u_20190509___Produktivlaeufe\2214___T2D_AstroWind___y'}
    for baseName = 2, 2
        basefolder = strcat(baseNames(baseName),string(year),'\eval\telemac_variables')
    
        if exist (basefolder,'dir')
            %extracting and saving velocity components, magnitude and direction for
            %all stations in one dat file, using the uv folder dat files
            
            uvlist = dir(fullfile(strcat(basefolder , '/velocity_uv') , '*.dat'));
            for uv=1:length(uvlist)
                stname = uvlist(uv).name(1:end-4)
                
                %read as table
                filepath = strcat(uvlist(uv).folder , '/' , uvlist(uv).name) ;
                T = readtable(filepath , 'Delimiter' , ',' , 'ReadVariableNames' , true);
                T.TimeStep_No = datetime (T.TimeStep_No , 'InputFormat' , 'dd-MM-yyyy HH:mm:ss' );
                T = table2timetable(T);
                %create new naming
                add_name = {'_magn' , '_dirc'  , '_velv' , '_velu'} ;
                stname_table = cellfun(@(x) strcat(x , add_name) , cellstr(stname) , 'Uniformoutput', 0) ;
                stname_table_all = [] ;
                for cu=1:numel(stname_table)
                    stname_table_all = [stname_table_all , stname_table{cu}] ;
                end
                %create new table
                T.Properties.VariableNames(:) = stname_table_all ;
                %and main table
                if uv ==1
                    mainT = T;
                else
                    mainT = synchronize(mainT , T);
                end
                    
            end
            %save table
            writetable(timetable2table(mainT) , char( strcat(basefolder , '/variables_all_stations/velocity_all_stations.dat') ))
        end
    end
end
