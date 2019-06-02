

function zetrioimport(common_folder)

%common_folder = '/Users/amrozeidan/Desktop/EasyGSH/com2305_zeitrio'

folderlist = dir(strcat(common_folder , '/measurements'));

for u=1:length(folderlist)
    
    if string(folderlist(u).name) == string('free_surface')
        filelist = dir(fullfile(strcat(common_folder , '/measurements/free_surface') , '*.dat' ));
        
        for i=1:length(filelist)
            
            filepath = strcat(filelist(i).folder , '/' , filelist(i).name) ;
            
            file_id_meas = fopen(filepath ,'r');
            l = 0;
            while ~feof(file_id_meas)
                st = fgetl(file_id_meas);
                l = l + 1;
                if  ~isempty(strfind(st,'# ------------------------------------------ '))
                    fseek(file_id_meas , 0 , 'bof' );
                    break
                end
            end
            
            meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D %f %f', 'Delimiter', ';', 'HeaderLines', l);
            fclose(file_id_meas);
            meas_dates = meas_data{1,1};
            meas_wl = meas_data{1,2};
            
            Ttmeas = timetable(meas_wl , 'RowTimes' , meas_dates);
            Ttmeas.Properties.VariableNames = { filelist(i).name(1:end-4) } ;
            
            if i ==1
                mainTtmeas = Ttmeas;
            else
                mainTtmeas = synchronize(mainTtmeas , Ttmeas);
            end
        end
        
        %filling the missed values (-9999.00 or -777.0) with NaN
        mainTtmeas = standardizeMissing(mainTtmeas , {-99999.0 , -777.0} , 'DataVariables' , mainTtmeas.Properties.VariableNames);
        
        mkdir(common_folder, 'measurements_prepared')
        path_1 = strcat(common_folder, '/measurements_prepared')
        
        writetable(timetable2table(mainTtmeas) , char( strcat(path_1 , '/' , string(year(mainTtmeas.Time(10))) , '.wl.zeitrio' , '.dat') ))
        
    end
    %later on, the other variables should be added
end
end







