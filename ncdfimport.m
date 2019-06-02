
function ncdfimport(common_folder)

%commonfolder = '/Users/amrozeidan/Desktop/EasyGSH/com2305_ncdf';

folderlist = dir(strcat(common_folder , '/measurements'));

for u=1:length(folderlist)
    
    if string(folderlist(u).name) == string('free_surface')
        
        filelist = dir(fullfile(strcat(common_folder , '/measurements/free_surface') , '*.nc' ));
        filename = strcat(filelist.folder , '/' , filelist.name) ;
        stationSL =  strcat(common_folder , '/LongShortinfoNoDashes.dat');
        stationInfo = strcat(common_folder , '/info_all_stationsNoDashes.dat');
        
        % filename = '/Users/amrozeidan/Desktop/EasyGSH/20190521_uebergabe_messdaten/2010/2010.wl.DB.meas.nc';
        % stationSL = '/Users/amrozeidan/Desktop/EasyGSH/LongShortinfoNoDashes.dat';
        % stationInfo = '/Users/amrozeidan/Desktop/EasyGSH/info_all_stationsNoDashes.dat';
        
        TstationSL = readtable(stationSL);
        TstationSL.Properties.RowNames = TstationSL.kuerzel ;
        TstationInfo = readtable(stationInfo , 'ReadRowNames' , true);
        
        info = ncinfo(filename);
        
        time_start = split(info.Attributes(5).Value , {'T' , '+'});
        date_time_ref = datetime(time_start(1)+' '+time_start(2) , 'Format' , 'yyyy-MM-dd HH:mm:ss') ;
        time = ncread(filename , 'time')';
        timestep = seconds(time(2) - time(1)); %in seconds
        
        date_time = NaT(length(time),1,'Format','dd-MM-yyyy HH:mm:ss');
        
        for i=1:length(time)
            date_time(i) = date_time_ref + (i-1)*timestep ;
        end
        
        no_station = info.Dimensions(2).Length ;
        
        station_names = ncread(filename , 'station_name')';
        stations = cell(no_station , 1);
        for i=1:no_station
            stations{i} = strtrim(station_names(i,:));
        end
        water_level = ncread(filename , 'water_level')';
        
        lons = ncread(filename , 'lon')';
        lats = ncread(filename , 'lat')';
        xs = ncread(filename , 'x')';
        ys = ncread(filename , 'y')';
        zs = ncread(filename , 'z')';
        
        stationsl = cell(length(stations),1) ;
        for i=1:length(stations)
            try
                stationsl(i) = TstationSL{stations(i) , 'name'} ;
            catch
                warning(['Unrecognized row name ',stations{i}]);
                stationsl(i) = stations(i);
            end
        end
        
        
        Twl =  array2table(water_level' , 'VariableNames' , stationsl' );
        %Tothers  = table(lons' , lats' , xs' , ys' , zs' , 'RowNames' , stations' , 'VariableNames' , {'lon' 'lat' 'x' 'y' 'z'});
        Twlt = table2timetable(Twl ,'RowTimes' , date_time);
        
        mkdir(common_folder, 'measurements_prepared');
        path_1 = strcat(common_folder, '/measurements_prepared');
        
        writetable(timetable2table(Twlt) , char( strcat(path_1 , '/' , filelist.name(1:end-3) , '.dat') ))
        
    end
    % later on, add the other variables
end
end



















