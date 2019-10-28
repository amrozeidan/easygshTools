
function ncdfimport(yearValidationFolder, yearMeasFolder, common_folder)

%common_folder = '/Users/amrozeidan/Desktop/EasyGSH/com2305_ncdfrev03';


stationSL =  strcat(common_folder , '/LongShortInfo.dat');
stationInfo = strcat(common_folder , '/info_all_stations.dat');
TstationSL = readtable(stationSL);
TstationSL.Properties.RowNames = TstationSL.kuerzel ;
TstationInfo = readtable(stationInfo , 'ReadRowNames' , true);


ncdflist = dir(fullfile(yearMeasFolder , '*.nc'));

%output directory
mkdir(yearValidationFolder, 'prepared_data_ncdf');
path_1 = strcat(yearValidationFolder, '/prepared_data_ncdf');

for u=1:length(ncdflist)
    
    filename = split(ncdflist(u).name , '.') ;
    prefix = filename(2) ;
    
    filepath = strcat(ncdflist(u).folder , '/' , ncdflist(u).name) ;
    
    info = ncinfo(filepath);
    
    %time determination
    time_start = split(info.Attributes(5).Value , {'T' , '+'});
    date_time_ref = datetime(strcat(time_start{1}," ",time_start{2}) , 'Format' , 'yyyy-MM-dd HH:mm:ss') ;
    time = ncread(filepath , 'time')';
    timestep = seconds(time(2) - time(1)); %in seconds
    
    date_time = NaT(length(time),1,'Format','dd-MM-yyyy HH:mm:ss');
    
    for i=1:length(time)
        date_time(i) = date_time_ref + (i-1)*timestep ;
    end
    
    %determination of depths
    depths = ncread(filepath , 'z')';
    
    %station names determination
    no_station = info.Dimensions(2).Length ;
    
    station_names = ncread(filepath , 'station_name')';
    stations = cell(no_station , 1);
    for i=1:no_station
        stations{i} = strtrim(station_names(i,:));
    end
    
    stationsl = cell(length(stations),1) ;
    for i=1:length(stations)
        %in case there is a depth attached to ncdf short naming
        station_comp = split(stations(i) , '_') ;
        %check if name is ending with 3 numbers
        if ~isnan(str2double(station_comp(end)))  && strlength(station_comp(end))==3
            depth = station_comp(end);
            station_start = stations{i}(1:end-4) ;
            try
                stationsl_start = TstationSL{ station_start , 'name'} ;
                stationsl(i) = cellstr(strcat(stationsl_start , '_' , depth)) ;
            catch
                warning(['Unrecognized row name ',stations{i}]);
                stationsl(i) = stations(i);
            end
        else
            try
                stationsl(i) = TstationSL{stations(i) , 'name'} ;
            catch
                warning(['Unrecognized row name ',stations{i}]);
                stationsl(i) = stations(i);
            end
            %add the avaialble depth in case the name has not a depth, when
            %it comes to velocity and salinity only
            if prefix == string('sa') || prefix == string('cu')
                stationsl(i) = cellstr(strcat( stationsl(i) , '_' , num2str(depths(i)*10 , '%03.f') )) ;
            end
        end
    end
    stationsl = replace(stationsl , '-' , '_') ;
    
    %variable extraction
    %water level , mean wave period , peak wave period , salinity , wave
    %height and temperatue :
    if prefix == string('wl')
        var_param = ncread(filepath , 'water_level')';
    elseif prefix == string('mwp')
        var_param = ncread(filepath , 'mean_wave_period')';
        stationsl = cellfun(@(x) strcat(x , '_mwp') , stationsl , 'Uniformoutput', 0) ;
    elseif prefix == string('pwp')
        var_param = ncread(filepath , 'peak_wave_period')';
        stationsl = cellfun(@(x) strcat(x , '_pwp') , stationsl , 'Uniformoutput', 0) ;
    elseif prefix == string('mwd')
        var_param = ncread(filepath , 'mean_wave_direction')';
        stationsl = cellfun(@(x) strcat(x , '_mwd') , stationsl , 'Uniformoutput', 0) ;
    elseif prefix == string('sa')
        var_param = ncread(filepath , 'salinity')';
    elseif prefix == string('swh')
        var_param = ncread(filepath , 'significant_wave_height')';
        stationsl = cellfun(@(x) strcat(x , '_swh') , stationsl , 'Uniformoutput', 0) ;
    elseif prefix == string('te')
        var_param = ncread(filepath , 'temperature')';
    else
        var_param = [];
    end
    
    %write in timetable , save as table
    if ~isempty(var_param)
        T =  array2table(var_param' , 'VariableNames' , stationsl' );
        Tt = table2timetable(T ,'RowTimes' , date_time);
               
        writetable(timetable2table(Tt) , char( strcat(path_1 , '/' , ncdflist(u).name(1:end-3) , '.dat') ))
        
        %variable extraction
        %velocity: magnitude , direction , x component and y component :
    elseif prefix == string('cu')
        current_v = ncread(filepath , 'current_velocity')' ;
        current_v_dir = ncread(filepath , 'direction_of_current_velocity')' ;
        current_v_x = ncread(filepath , 'current_velocity__x_dir__')' ;
        current_v_y = ncread(filepath , 'current_velocity__y_dir__')' ;
        
        [row , col] = size(current_v');
        current_all_var = zeros(row , 4*numel(stationsl)) ;
        a=1;
        b=4;
        for c=1:length(stationsl)
            %allocate variables in stations order in one array
            current_all_var( : , a:b) = [current_v(c , :)' , current_v_dir(c , :)' , current_v_x(c , :)' , current_v_y(c , :)'] ;
            a= a+4;
            b= b+4;
        end
        
        %creation of header line of main velocity array
        add_name = {'_magn' , '_dirc'  , '_velv' , '_velu'} ;
        stationsl_cu = cellfun(@(x) strcat(x , add_name) , stationsl , 'Uniformoutput', 0) ;
        stationsl_cu_all= [] ;
        for cu=1:numel(stationsl)
            stationsl_cu_all = [stationsl_cu_all , stationsl_cu{cu}] ;
        end
        
        %write in timetable, save as table
        T =  array2table( current_all_var , 'VariableNames' , stationsl_cu_all );
        Tt = table2timetable(T ,'RowTimes' , date_time);

        writetable(timetable2table(Tt) , char( strcat(path_1 , '/' , ncdflist(u).name(1:end-3) , '.dat') ))
    end
   
end

%concatenate wave components in one table
ncdfwavelist = [dir(fullfile(strcat(common_folder , '/measurements_prepared') , '*mwp*.dat' )) ; ...
    dir(fullfile(strcat(common_folder , '/measurements_prepared') , '*pwp*.dat' )) ; ...
    dir(fullfile(strcat(common_folder , '/measurements_prepared') , '*swh*.dat' )) ; ...
    dir(fullfile(strcat(common_folder , '/measurements_prepared') , '*mwd*.dat' ))] ;
if ~isempty(ncdfwavelist)
    for cn=1:length(ncdfwavelist)
        filepath_cn = strcat(ncdfwavelist(1).folder , '/' , ncdfwavelist(cn).name) ;
        
        Ttwave = readtable(filepath_cn , 'Delimiter' , ',' , 'ReadVariableNames' , true);
        Ttwave.Time = datetime (Ttwave.Time , 'InputFormat' , 'dd-MM-yyyy HH:mm:ss' );
        Ttwave = table2timetable(Ttwave);
        if cn == 1
            Ttwavemain = Ttwave ;
        else
            Ttwavemain = synchronize(Ttwavemain, Ttwave);
        end
    end
    
    writetable(timetable2table(Ttwavemain) , char( strcat(path_1 , '/' ,  string(year(Ttwavemain.Time(10))) , '.wv.DB.meas' , '.dat') ))
end

end

