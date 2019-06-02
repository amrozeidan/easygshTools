

function zetrioimport(common_folder)

common_folder = '/Users/amrozeidan/Desktop/EasyGSH/com2305_zeitriorev02' ;

mkdir(common_folder, 'measurements_prepared')
path_1 = strcat(common_folder, '/measurements_prepared')

folderlist = dir(strcat(common_folder , '/measurements'));

for u=1:length(folderlist)
    
    if string(folderlist(u).name) == string('free_surface')
        filelist = dir(fullfile(strcat(common_folder , '/measurements/free_surface') , '*.dat' ));
        if ~isempty(filelist)
            
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
            
            writetable(timetable2table(mainTtmeas) , char( strcat(path_1 , '/' , string(year(mainTtmeas.Time(10))) , '.wl.zeitrio' , '.dat') ))
        end
    end
    
    if string(folderlist(u).name) == string('salinity')
        filelist = dir(fullfile(strcat(common_folder , '/measurements/salinity') , '*.dat' ));
        if ~isempty(filelist)
            
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
                
                try
                    meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D %f %f' , 'Delimiter', ';', 'HeaderLines', l);
                catch
                    meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D %f' , 'Delimiter', ';', 'HeaderLines', l);
                end
                fclose(file_id_meas);
                meas_dates = meas_data{1,1};
                meas_sal = meas_data{1,2};
                
                Ttmeas = timetable(meas_sal , 'RowTimes' , meas_dates);
                table_name = strrep(filelist(i).name(1:end-4) , '.' , '_');
                Ttmeas.Properties.VariableNames = { table_name } ;
                
                if i ==1
                    mainTtmeas = Ttmeas;
                else
                    mainTtmeas = synchronize(mainTtmeas , Ttmeas);
                end
            end
            
            %filling the missed values (-9999.00 or -777.0) with NaN
            mainTtmeas = standardizeMissing(mainTtmeas , {-99999.0 , -777.0} , 'DataVariables' , mainTtmeas.Properties.VariableNames);
            
            writetable(timetable2table(mainTtmeas) , char( strcat(path_1 , '/' , string(year(mainTtmeas.Time(10))) , '.sa.zeitrio' , '.dat') ))
        end
    end
    if string(folderlist(u).name) == string('velocity')
        filelist = dir(fullfile(strcat(common_folder , '/measurements/velocity') , '*.dat' ));
        if ~isempty(filelist)
            
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
                
                try
                    meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D %f %f %f %f %f' , 'Delimiter', ';', 'HeaderLines', l);
                catch
                    meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D %f %f %f %f' , 'Delimiter', ';', 'HeaderLines', l);
                end
                fclose(file_id_meas);
                meas_dates = meas_data{1,1};
                meas_magnitude = meas_data{1,2};
                meas_direction = meas_data{1,3};
                meas_velocity_v = meas_data{1,4};
                meas_velocity_u = meas_data{1,5};
                
                name_table = strrep(filelist(i).name(1:end-4) , '.' , '_');
                Ttmeas = timetable(meas_magnitude , meas_direction , meas_velocity_v , meas_velocity_u , ...
                    'RowTimes' , meas_dates , 'VariableNames', {strcat(name_table ,'_magn')  strcat(name_table,'_dirc') ...
                    strcat(name_table,'_velv')  strcat(name_table,'_velu')} );
                
                %multi indexing, available on 2018 version, to be checked later
                %                                 Ttmeas = timetable(meas_magnitude , meas_direction , meas_velocity_v , meas_velocity_u , 'RowTimes' , meas_dates , 'VariableNames', {'magn'  'dirc'   'velv'  'velu'} );
                %                                 Ttmeas = standardizeMissing(Ttmeas , {-99999.0 , -777.0} , 'DataVariables' , Ttmeas.Properties.VariableNames);
                %                                 Ttmeas = mergevars( Ttmeas , {'magn' , 'dirc'  , 'velv' , 'velu'} , 'NewVariableName' , ...
                %                                     strrep(filelist(i).name(1:end-4) , '.' , '_') , 'MergeAsTable' , true);
                %                 Ttmeas.Properties.VariableNames = { table_name_l2 } ;
                
                if i ==1
                    mainTtmeas = Ttmeas;
                else
                    mainTtmeas = synchronize(mainTtmeas , Ttmeas);
                end
            end
            
            %filling the missed values (-9999.00 or -777.0) with NaN
            mainTtmeas = standardizeMissing(mainTtmeas , {-99999.0 , -777.0} , 'DataVariables' , mainTtmeas.Properties.VariableNames);
            
            writetable(timetable2table(mainTtmeas) , char( strcat(path_1 , '/' , string(year(mainTtmeas.Time(10))) , '.cu.zeitrio' , '.dat') ))
        end
    end
    if string(folderlist(u).name) == string('wave')
        filelist = dir(fullfile(strcat(common_folder , '/measurements/wave') , '*.dat' ));
        if ~isempty(filelist)
            
            for i=1:length(filelist)
                
                filename = split(filelist(i).name , '.') ;
                prefix_filename = filename(1) ;
                
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
                
                if prefix_filename == string('wave')
                    meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D %f %f %f %f' , 'Delimiter', ';', 'HeaderLines', l);
                    fclose(file_id_meas);
                    meas_dates = meas_data{1,1};
                    meas_height = meas_data{1,2};
                    meas_peak_period = 1./meas_data{1,3};
                    meas_mean_period = meas_data{1,4};
                    
                    name_station = filename{2};
                    Ttmeas = timetable(meas_height , meas_peak_period , meas_mean_period  , 'RowTimes' , meas_dates , 'VariableNames', {strcat(name_station ,'_swh')  strcat(name_station,'_pwp')   strcat(name_station,'_mwp') } );
                    
                    if i ==1
                        mainTtmeas = Ttmeas;
                    else
                        mainTtmeas = synchronize(mainTtmeas , Ttmeas);
                    end
                else
                    try
                        meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D %f %f' , 'Delimiter', ';', 'HeaderLines', l);
                    catch
                        meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D %f' , 'Delimiter', ';', 'HeaderLines', l);
                    end
                    fclose(file_id_meas);
                    meas_dates = meas_data{1,1};
                    % if prefix_filename == string('pwp')
                    %   meas_param = 1./meas_data{1,2};
                    %else
                    meas_param = meas_data{1,2};
                    % end
                    
                    
                    name_station = filename{2};
                    Ttmeas = timetable(meas_param , 'RowTimes' , meas_dates , 'VariableNames', {strcat(name_station ,'_' , char(prefix_filename))} );
                    
                    if i ==1
                        mainTtmeas = Ttmeas;
                    else
                        mainTtmeas = synchronize(mainTtmeas , Ttmeas);
                    end
                end
            end
            
            %filling the missed values (-9999.00 or -777.0) with NaN
            mainTtmeas = standardizeMissing(mainTtmeas , {-99999.0 , -777.0 , -1/777 , -1/9999} , 'DataVariables' , mainTtmeas.Properties.VariableNames);
            
            writetable(timetable2table(mainTtmeas) , char( strcat(path_1 , '/' , string(year(mainTtmeas.Time(10))) , '.wv.zeitrio' , '.dat') ))
        end
    end
    
end
end







