		


%% i_wavecomp
function i_wavecomp (common_folder , basefolder , date_a , period, offset)

%get information about the stations from the station database file
FileName_info = 'info_all_stations.dat';
PathName_info = strcat(common_folder,'/');
fileID = fopen(fullfile(PathName_info,FileName_info),'r');
info_data = textscan(fileID, '%s%n%n%n%n', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fileID);
Locations_Names={};
RW_HW = [];
Latitudes =[];
num_order = [];

%get required stations names
req_data = textread(strcat(common_folder , '/required_stations.dat') , '%s', 'delimiter', '\n');

data_meas_wave_file_name_with_directory_req = {};
data_simul_wave_file_name_with_directory_req = {};
wave_parameter_abrv = {};
wave_parameter = {} ;

% abrv = { 'swh.' , 'wave_height' ;
%     'mvd.' , 'wave_mean_direction' ;
%     'mwp.' , 'wave_mean_period' ;
%     'pwp.' , 'wave_peak_period';
%     'wave.' , 'wave_height' ;
%     'wave.' , 'wave_mean_direction' ;
%     'wave.' , 'wave_mean_period' ;
%     'wave.' , 'wave_peak_period' } ;

abrv = { 'swh.' , 'wave_height' ;
    'mvd.' , 'wave_mean_direction' ;
    'mwp.' , 'wave_mean_period' ;
    'pwp.' , 'wave_peak_period';
    'wave.' , 'wave_height' ;
    'wave.' , 'wave_mean_period' ;
    'wave.' , 'wave_peak_period' } ;

for abrv_i=1:length(abrv)
    
    listing_basefolder = dir(strcat(basefolder, '/telemac_variables'));
    basefolder_file_name = {};
    for f=1:length(listing_basefolder)
        basefolder_file_name = vertcat(basefolder_file_name , listing_basefolder(f).name) ;
    end
    index_wave_folder = find(ismember(basefolder_file_name , abrv{abrv_i , 2} ));
    
    listing_meas_wave = dir(strcat(common_folder , '/measurements/wave'));
    listing_simul_wave = dir(strcat(basefolder, '/telemac_variables' , '/', basefolder_file_name{index_wave_folder} ));
    
    disp(['measured wave folder directory:' , ' ' , common_folder , '/measurements/wave']);
    disp(['simulated wave folder directory:' , ' ' , basefolder, '/telemac_variables' , '/', basefolder_file_name{index_wave_folder} ]);
    
    data_meas_wave_file_name = {};
    data_simul_wave_file_name = {};
    
    % Find measurement station names
    for u=3:length(listing_meas_wave)
        meas_file_name = listing_meas_wave(u).name ;
        data_meas_wave_file_name  = vertcat(data_meas_wave_file_name  , {meas_file_name(1:end-4)});
    end
    
    % Find simulation station names
    for uu=3:length(listing_simul_wave)
        simulated_file_name = listing_simul_wave(uu).name ;
        data_simul_wave_file_name  = vertcat(data_simul_wave_file_name  , {simulated_file_name(1:end-4)});
    end
    
    
    % go through the list of required stations
    for iui=1:length(req_data)
        
        % find index of required station in measurement files
        expression = [ abrv{abrv_i , 1} , req_data{iui}] ;
        index_meas = regexp(data_meas_wave_file_name , expression);
        isone = cellfun(@(x)isequal(x,1),index_meas);
        index_meas = find(isone);
        % find index of required station in database file
        index_names_info = find(ismember(info_data{1,1} , req_data{iui}));
        % find index of required station in simulated files list
        index_names_simulated = find (ismember(data_simul_wave_file_name, req_data{iui}));
        
        if(isempty(index_names_info) || isempty(index_meas) || isempty(index_names_simulated))
            req_data{iui}
            continue
        else
            % gather file names from measurement files and simulation files
            data_meas_wave_file_name_with_directory_req = vertcat(data_meas_wave_file_name_with_directory_req ,strcat(common_folder , '/measurements/wave/',data_meas_wave_file_name{index_meas},'.dat'));
            
            data_simul_wave_file_name_with_directory_req = vertcat(data_simul_wave_file_name_with_directory_req , strcat(basefolder, '/telemac_variables' , '/', basefolder_file_name{index_wave_folder},'/',info_data{1,1}{index_names_info},'.dat'));
            
            %available locations names (other stations are skipped)
            Locations_Names = vertcat(Locations_Names, info_data{1,1}(index_names_info));
            
            % find coordinates from database file
            % in ETRS89 (or mesh coordinates)
            RW_HW = vertcat(RW_HW, horzcat(info_data{1,2}(index_names_info),info_data{1,3}(index_names_info)));
            
            % in WGS84 (latlon coordinates)
            Latitudes = vertcat(Latitudes, info_data{1,4}(index_names_info));
            
            % find station order number
            num_order = vertcat(num_order, info_data{1,5}(index_names_info) );
            
            % find wave variable abbreviation for measurements
            wave_parameter_abrv = vertcat(wave_parameter_abrv , extractBefore(data_meas_wave_file_name{index_meas},'.'));
            
            % find wave variable
            wave_parameter = vertcat(wave_parameter , basefolder_file_name{index_wave_folder});
            
        end
    end
end

disp('%% Stations in common between measurements,simulated data and the required stations:');
Locations_Names

disp('%%and this/these station/s has/have missed data in either measurements or simulations');
setdiff(req_data , Locations_Names)

disp('%%hence the files to be compared are from measurements and simulations consecutively:');
data_meas_wave_file_name_with_directory_req
data_simul_wave_file_name_with_directory_req

disp('%%these data are saved into this dat file:');

my_data_prep = cell (length(Locations_Names) , 9);
RW = RW_HW(:,1);
HW = RW_HW(:,2);

for k = 1:length(Locations_Names)
    my_data_prep{k,1} = Locations_Names(k);
    my_data_prep{k,2} = data_meas_wave_file_name_with_directory_req(k);
    my_data_prep{k,3} = data_simul_wave_file_name_with_directory_req(k);
    my_data_prep{k,4} = RW(k);
    my_data_prep{k,5} = HW(k);
    my_data_prep{k,6} = Latitudes(k);
    my_data_prep{k,7} = num_order(k);
    my_data_prep{k,8} = wave_parameter_abrv(k);
    my_data_prep{k,9} = wave_parameter(k);
end

%sort order of the prepared data based on the sorting order
my_data_prep = sortrows(my_data_prep,[7]);

% T = cell2table(my_data_prep,'VariableNames',{'Location_Names', 'Meas_dir' , 'Simul_dir' , 'RW' , 'HW' , 'Latitudes' , 'Station_No' , 'z'});
% saving_name = strcat(common_folder,'/', 'required_stations_data' , '.dat')
% writetable(T,char(saving_name));


%% wave comparison

%creating folders for results storage
mkdir(basefolder, 'wave_comparison')
path_1 = strcat(basefolder, '/wave_comparison') ;

mkdir(path_1, 'wave_height_comparison')
mkdir(path_1, 'wave_mean_direction_comparison')
mkdir(path_1, 'wave_mean_period_comparison')
mkdir(path_1, 'wave_peak_period_comparison')


%%%%%%%%%%%%%%%dates addition%%%%%%%%%%%%%%%%%%%%
%required period: from date_a up to 31 days for example
req_time_initial = date_a;
for i=1:period
    req_time{i} = req_time_initial + (i-1)*days(1);
end
%then converting to yyyymmdd
for i=1:length(req_time)
    req_time_as_ymd(i) = yyyymmdd(req_time{i});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


units_par = { '[m]' , 'wave_height' ;
    '[degree]' , 'wave_mean_direction' ;
    '[s]' , 'wave_mean_period' ;
    '[s]' , 'wave_peak_period'};

% wave_dat_file = { '2' , 'wave_height' ;
%     '3' , 'wave_mean_direction' ; % convert direction in wave dat file from rad to degree
%     '4' , 'wave_mean_period' ;
%     '5' , 'wave_peak_period'};% check the format of wave.dat

wave_dat_file = { '2' , 'wave_height' ;
    '3' , 'wave_peak_period' ;
    '4' , 'wave_mean_period'};

[row , col] = size(my_data_prep);

TT_main_swh_meas_for_comp = timetable(date_a,0);
TT_main_mvd_meas_for_comp = timetable(date_a,0);
TT_main_mwp_meas_for_comp = timetable(date_a,0);
TT_main_pwp_meas_for_comp = timetable(date_a,0);
header_swh = {};
header_mvd = {};
header_mwp = {};
header_pwp = {};
TT_main_swh_simul_for_comp = timetable(date_a,0);
TT_main_mvd_simul_for_comp = timetable(date_a,0);
TT_main_mwp_simul_for_comp = timetable(date_a,0);
TT_main_pwp_simul_for_comp = timetable(date_a,0);


for cwl=1:row
    %reading measurements data
    if string(my_data_prep{cwl , 8}) == 'wave' % wave.dat file type
    % index_wave_parameter = regexp(my_data_prep{cwl , 8} , 'wave');
        file_id_meas = fopen(my_data_prep{cwl,2}{1} ,'r');
        my_data_prep{cwl,2}{1}
        parameter = my_data_prep{cwl,9}{1}
        
        index_extract = regexp(wave_dat_file(:,2) , my_data_prep{cwl,9}{1});
        isone = cellfun(@(x)isequal(x,1),index_extract);
        index_extract = find(isone);
        wave_dat_file{index_extract , 1}
        ie = str2double(wave_dat_file{index_extract , 1});
        
        %%%for measurements dat files with zeitrio format
        %looking for '# ------------------------------------------' ,when
        %when reading dat files in dat_zeitrio folders
        l = 0;
        while ~feof(file_id_meas)
            st = fgetl(file_id_meas);
            l = l + 1;
            if  ~isempty(strfind(st,'# ------------------------------------------ '))
                fseek(file_id_meas , 0 , 'bof' ); % to reset the file pointer to the beginning or frewind(fid)
                break
            end
        end
        
        meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D %f %f %f %f', 'Delimiter', ';', 'HeaderLines', l);
        fclose(file_id_meas);
        meas_dates = meas_data{1,1};
        if ie==3 %if it is wave peak frequency
            meas_parameter =  1./ meas_data{1,ie};
        else
            meas_parameter = meas_data{1,ie};
        end
        
        %reading simulated data (to be updated: date format and rows format)
        file_id_simul = fopen(my_data_prep{cwl,3}{1} ,'r');
        my_data_prep{cwl,3}{1}
        % % %                 simul_data = textscan(file_id_simul, '%{dd.MM.yyyy HH:mm:ss}D %f', 'Delimiter', ',', 'HeaderLines', 1);
        simul_data = textscan(file_id_simul, '%{dd/MM/yyyy HH:mm:ss}D%n', 'Delimiter', ',', 'HeaderLines', 1);
        fclose(file_id_simul);
        simul_dates = simul_data{1,1};
        simul_parameter = simul_data{1,2};
        
        
        %%%%%%%%%%%%%%%dates addition%%%%%%%%%%%%%%%%%%%%%
        %converting meas_dates and wl_simulated_dates to yyyymmdd
        for i=1:length(meas_dates)
            meas_dates_as_ymd(i) = yyyymmdd(meas_dates(i));
        end
        for i=1:length(simul_dates)
            simul_dates_as_ymd(i) = yyyymmdd(simul_dates(i));
        end
        
        %find indices of the required period
        [~ ,idx_meas] = find(ismember(meas_dates_as_ymd, req_time_as_ymd));
        [~ ,idx_simul] = find(ismember(simul_dates_as_ymd, req_time_as_ymd));
        %extract final time from my_time
        meas_dates_for_comp = meas_dates(idx_meas);
        simul_dates_for_comp = simul_dates(idx_simul);
        %and magnitude values
        meas_parameter_for_comp = meas_parameter(idx_meas);
        simul_parameter_for_comp = simul_parameter(idx_simul);
        %ignoring the replaced value -777.0 for the missed data generated by
        %zeitrio for measurements
        %TODO: Read the no value entry from the zeitrio file
        index_99999 = find(meas_parameter_for_comp < -100.00);
        meas_parameter_for_comp(index_99999) = NaN ;
        % % %                 index_99999 = find(simul_parameter_for_comp < -100.00); % used with fake simulations only
        % % %                 simul_parameter_for_comp(index_99999) = NaN ; % used with fake simulations only
        
        %constructing timetables
        TT_meas_parameter = timetable(meas_dates_for_comp , meas_parameter_for_comp);
        TT_simul_parameter = timetable(simul_dates_for_comp , simul_parameter_for_comp);
        %synchronising
        TT_meas_simul_sync = synchronize(TT_meas_parameter,TT_simul_parameter);
        %removing NaN (missing data) from timetable for both measured and simulated data(just in case)
        TT_meas_simul_sync_no_NaN = rmmissing(TT_meas_simul_sync);
        %taking back the data from timetable
        date_sync_no_NaN_par = timetable2table(TT_meas_simul_sync_no_NaN);
        date_sync_no_NaN_par = table2array(date_sync_no_NaN_par(:,1));
        TT_meas_simul_sync_no_NaN_c_par = table2cell(timetable2table(TT_meas_simul_sync_no_NaN));
        parameter_meas_sync_no_NaN = cell2mat(TT_meas_simul_sync_no_NaN_c_par(:,2));
        parameter_simul_sync_no_NaN = cell2mat(TT_meas_simul_sync_no_NaN_c_par(:,3)) ;
        %magnitude difference
        parameter_diff = parameter_simul_sync_no_NaN - parameter_meas_sync_no_NaN ;
        
        %storing parameters with all stations
        if isequal(parameter , 'wave_height')
            TT_main_swh_meas_for_comp = synchronize(TT_main_swh_meas_for_comp,TT_meas_parameter);
            TT_main_swh_simul_for_comp = synchronize(TT_main_swh_simul_for_comp,TT_simul_parameter);
            header_swh = horzcat(header_swh , my_data_prep{cwl,1}{1});
        elseif isequal(parameter , 'wave_mean_direction')
            TT_main_mvd_meas_for_comp = synchronize(TT_main_mvd_meas_for_comp,TT_meas_parameter);
            TT_main_mvd_simul_for_comp = synchronize(TT_main_mvd_simul_for_comp,TT_simul_parameter);
            header_mvd = horzcat(header_mvd , my_data_prep{cwl,1}{1});
        elseif isequal(parameter , 'wave_mean_period')
            TT_main_mwp_meas_for_comp = synchronize(TT_main_mwp_meas_for_comp,TT_meas_parameter);
            TT_main_mwp_simul_for_comp = synchronize(TT_main_mwp_simul_for_comp,TT_simul_parameter);
            header_mwp = horzcat(header_mwp , my_data_prep{cwl,1}{1});
        elseif isequal(parameter , 'wave_peak_period')
            TT_main_pwp_meas_for_comp = synchronize(TT_main_pwp_meas_for_comp,TT_meas_parameter);
            TT_main_pwp_simul_for_comp = synchronize(TT_main_pwp_simul_for_comp,TT_simul_parameter);
            header_pwp = horzcat(header_pwp , my_data_prep{cwl,1}{1});
        end
        
        
        %parameter naming and unit for plots
        parameter_plot = regexprep(my_data_prep{cwl,9}{1},'_','\v'); %removing _ from the parameter name
        parameter_plot = regexprep(parameter_plot,'(\<[a-z])','${upper($1)}'); % capitalizing the first letter of each string
        
        index_unit = regexp(units_par(:,2) , my_data_prep{cwl,9}{1});
        isone = cellfun(@(x)isequal(x,1),index_unit);
        index_unit = find(isone);
        unit = units_par(index_unit , 1);
        
        %plot parameter and parameter diffferences
        h = figure('visible','off');
        
        ax1 = subplot(2,1,1);
        plot(meas_dates_for_comp,meas_parameter_for_comp,'-b');
        hold on
        plot(simul_dates_for_comp,simul_parameter_for_comp,'-r');
        title(strcat( parameter_plot , ' comparison,', ' Station : ', my_data_prep{cwl,1}{1}));
        legend('Measurements','Simulations');
        ylabel(strcat(parameter_plot,{' '}, unit));
        
        ax2 = subplot(2,1,2);
        plot(date_sync_no_NaN_par,parameter_diff);
        title(strcat( parameter_plot ,  ' difference,', ' Station : ', my_data_prep{cwl,1}{1}));
        xlabel('Date/Time');
        ylabel(strcat(parameter_plot,{' '}, unit));
        
        if ~isempty(parameter_diff)
            linkaxes([ax1 , ax2] , 'x');
        end
        
        grid(ax1,'on');
        grid(ax2,'on');
        ax1.FontSize = 10.5;
        ax2.FontSize = 10.5;
        pbaspect(ax1 , 'auto') %[x y z]
        pbaspect(ax2 , 'auto')
        
        %set(ax1,'position',[.1 .4 .8 .5])
        %set(ax2,'position',[.1 .1 .8 .3])
        
        save_name = strcat(path_1 , '/' , my_data_prep{cwl,9}{1}, '_comparison' , '/', my_data_prep{cwl,9}{1} , '_comparison', '_Station_', my_data_prep{cwl,1}{1});
        % savefig(h, save_name, 'compact');
        saveas(gca, save_name , 'jpeg');
        clf
        close(h)
        
    
    else
    %if isempty(index_wave_parameter) % mvd.dat , swh.dat, pwp.dat and mwp.dat file types
        file_id_meas = fopen(my_data_prep{cwl,2}{1} ,'r');
        my_data_prep{cwl,2}{1}
        parameter = my_data_prep{cwl,9}{1}
        %%%for measurements dat files with zeitrio format
        %looking for '# ------------------------------------------' ,when
        %when reading dat files in dat_zeitrio folders
        l = 0;
        while ~feof(file_id_meas)
            st = fgetl(file_id_meas);
            l = l + 1;
            if  ~isempty(strfind(st,'# ------------------------------------------ '))
                fseek(file_id_meas , 0 , 'bof' ); % to reset the file pointer to the beginning or frewind(fid)
                break
            end
        end
        
        meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D %f ', 'Delimiter', ';', 'HeaderLines', l);
        fclose(file_id_meas);
        meas_dates = meas_data{1,1};
        meas_parameter = meas_data{1,2};
        
        
        %reading simulated data %(to be updated: date format and rows format, like the simulated data format)
        file_id_simul = fopen(my_data_prep{cwl,3}{1} ,'r');
        my_data_prep{cwl,3}{1}
        % % %                 simul_data = textscan(file_id_simul, '%{dd.MM.yyyy HH:mm:ss}D %f', 'Delimiter', ',', 'HeaderLines', 1);
        simul_data = textscan(file_id_simul, '%{dd/MM/yyyy HH:mm:ss}D%n', 'Delimiter', ',', 'HeaderLines', 1);
        fclose(file_id_simul);
        simul_dates = simul_data{1,1};
        simul_dates = simul_dates + hours (offset);
        simul_parameter = simul_data{1,2};
        
        
        %%%%%%%%%%%%%%%dates addition%%%%%%%%%%%%%%%%%%%%%
        %converting meas_dates and wl_simulated_dates to yyyymmdd
        for i=1:length(meas_dates)
            meas_dates_as_ymd(i) = yyyymmdd(meas_dates(i));
        end
        for i=1:length(simul_dates)
            simul_dates_as_ymd(i) = yyyymmdd(simul_dates(i));
        end
        
        %find indices of the required period
        [~ ,idx_meas] = find(ismember(meas_dates_as_ymd, req_time_as_ymd));
        [~ ,idx_simul] = find(ismember(simul_dates_as_ymd, req_time_as_ymd));
        %extract final time from my_time
        meas_dates_for_comp = meas_dates(idx_meas);
        simul_dates_for_comp = simul_dates(idx_simul);
        %and magnitude values
        meas_parameter_for_comp = meas_parameter(idx_meas);
        simul_parameter_for_comp = simul_parameter(idx_simul);
        %ignoring the replaced value -777.0 for the missed data generated by
        %zeitrio for measurements
        %TODO: Read the no value entry from the zeitrio file
        index_99999 = find(meas_parameter_for_comp < -100.00);
        meas_parameter_for_comp(index_99999) = NaN ;
        % %                 index_99999 = find(simul_parameter_for_comp < -100.00); % used with fake simulations only
        % %                 simul_parameter_for_comp(index_99999) = NaN ; % used with fake simulations only
        
        %constructing timetables
        TT_meas_parameter = timetable(meas_dates_for_comp , meas_parameter_for_comp);
        TT_simul_parameter = timetable(simul_dates_for_comp , simul_parameter_for_comp);
        %synchronising
        TT_meas_simul_sync = synchronize(TT_meas_parameter,TT_simul_parameter);
        %removing NaN (missing data) from timetable for both measured and simulated data(just in case)
        TT_meas_simul_sync_no_NaN = rmmissing(TT_meas_simul_sync);
        %taking back the data from timetable
        date_sync_no_NaN_par = timetable2table(TT_meas_simul_sync_no_NaN);
        date_sync_no_NaN_par = table2array(date_sync_no_NaN_par(:,1));
        TT_meas_simul_sync_no_NaN_c_par = table2cell(timetable2table(TT_meas_simul_sync_no_NaN));
        parameter_meas_sync_no_NaN = cell2mat(TT_meas_simul_sync_no_NaN_c_par(:,2));
        parameter_simul_sync_no_NaN = cell2mat(TT_meas_simul_sync_no_NaN_c_par(:,3)) ;
        %magnitude difference
        parameter_diff = parameter_simul_sync_no_NaN - parameter_meas_sync_no_NaN ;
        
        %storing parameters with all stations
        if isequal(parameter , 'wave_height')
            TT_main_swh_meas_for_comp = synchronize(TT_main_swh_meas_for_comp,TT_meas_parameter);
            TT_main_swh_simul_for_comp = synchronize(TT_main_swh_simul_for_comp,TT_simul_parameter);
            header_swh = horzcat(header_swh , my_data_prep{cwl,1}{1});
        elseif isequal(parameter , 'wave_mean_direction')
            TT_main_mvd_meas_for_comp = synchronize(TT_main_mvd_meas_for_comp,TT_meas_parameter);
            TT_main_mvd_simul_for_comp = synchronize(TT_main_mvd_simul_for_comp,TT_simul_parameter);
            header_mvd = horzcat(header_mvd , my_data_prep{cwl,1}{1});
        elseif isequal(parameter , 'wave_mean_period')
            TT_main_mwp_meas_for_comp = synchronize(TT_main_mwp_meas_for_comp,TT_meas_parameter);
            TT_main_mwp_simul_for_comp = synchronize(TT_main_mwp_simul_for_comp,TT_simul_parameter);
            header_mwp = horzcat(header_mwp , my_data_prep{cwl,1}{1});
        elseif isequal(parameter , 'wave_peak_period')
            TT_main_pwp_meas_for_comp = synchronize(TT_main_pwp_meas_for_comp,TT_meas_parameter);
            TT_main_pwp_simul_for_comp = synchronize(TT_main_pwp_simul_for_comp,TT_simul_parameter);
            header_pwp = horzcat(header_pwp , my_data_prep{cwl,1}{1});
        end
        
        
        
        %parameter naming and unit for plots
        parameter_plot = regexprep(my_data_prep{cwl,9}{1},'_','\v'); %removing _ from the parameter name
        parameter_plot = regexprep(parameter_plot,'(\<[a-z])','${upper($1)}'); % capitalizing the first letter of each string
        
        index_unit = regexp(units_par(:,2) , my_data_prep{cwl,9}{1});
        isone = cellfun(@(x)isequal(x,1),index_unit);
        index_unit = find(isone);
        unit = units_par(index_unit , 1);
        
        %plot parameter and parameter diffferences
        h = figure('visible','off');
        
        ax1 = subplot(2,1,1);
        plot(meas_dates_for_comp,meas_parameter_for_comp,'-b');
        hold on
        plot(simul_dates_for_comp,simul_parameter_for_comp,'-r');
        title(strcat( parameter_plot , ' comparison,', ' Station : ', my_data_prep{cwl,1}{1}));
        legend('Measurements','Simulations');
        ylabel(strcat(parameter_plot,{' '}, unit));
        
        ax2 = subplot(2,1,2);
        plot(date_sync_no_NaN_par,parameter_diff);
        title(strcat( parameter_plot ,  ' difference,', ' Station : ', my_data_prep{cwl,1}{1}));
        xlabel('Date/Time');
        ylabel(strcat(parameter_plot,{' '}, unit));
        
        if ~isempty(parameter_diff)
            linkaxes([ax1 , ax2] , 'x');
        end
        
        grid(ax1,'on');
        grid(ax2,'on');
        ax1.FontSize = 10.5;
        ax2.FontSize = 10.5;
        pbaspect(ax1 , 'auto') %[x y z]
        pbaspect(ax2 , 'auto')
        
        %set(ax1,'position',[.1 .4 .8 .5])
        %set(ax2,'position',[.1 .1 .8 .3])
        
        save_name = strcat(path_1 , '/' , my_data_prep{cwl,9}{1}, '_comparison' , '/', my_data_prep{cwl,9}{1} , '_comparison', '_Station_', my_data_prep{cwl,1}{1});
        % savefig(h, save_name, 'compact');
        saveas(gca, save_name , 'jpeg');
        clf
        close(h)
        
        
    %else % wave.dat file type

    end
end

%saving dat file for variables with all stations
mkdir(basefolder, 'telemac_variables')
path_1 = strcat(basefolder, '/telemac_variables')

mkdir(strcat(common_folder, '/measurements') , 'variables_all_stations')
path_5 = strcat(common_folder , '/measurements/variables_all_stations')

mkdir (path_1, 'variables_all_stations')
path_6 = strcat(path_1, '/variables_all_stations')



TT_main_swh_meas_for_comp_c = table2cell(timetable2table(TT_main_swh_meas_for_comp));
TT_main_swh_meas_for_comp_c(:,2) = [];
TT_main_swh_simul_for_comp_c = table2cell(timetable2table(TT_main_swh_simul_for_comp));
TT_main_swh_simul_for_comp_c(:,2) = [];

TT_main_mvd_meas_for_comp_c = table2cell(timetable2table(TT_main_mvd_meas_for_comp));
TT_main_mvd_meas_for_comp_c(:,2) = [];
TT_main_mvd_simul_for_comp_c = table2cell(timetable2table(TT_main_mvd_simul_for_comp));
TT_main_mvd_simul_for_comp_c(:,2) = [];

TT_main_mwp_meas_for_comp_c = table2cell(timetable2table(TT_main_mwp_meas_for_comp));
TT_main_mwp_meas_for_comp_c(:,2) = [];
TT_main_mwp_simul_for_comp_c = table2cell(timetable2table(TT_main_mwp_simul_for_comp));
TT_main_mwp_simul_for_comp_c(:,2) = [];

TT_main_pwp_meas_for_comp_c = table2cell(timetable2table(TT_main_pwp_meas_for_comp));
TT_main_pwp_meas_for_comp_c(:,2) = [];
TT_main_pwp_simul_for_comp_c = table2cell(timetable2table(TT_main_pwp_simul_for_comp));
TT_main_pwp_simul_for_comp_c(:,2) = [];


T_5 = cell2table(TT_main_swh_meas_for_comp_c , 'VariableNames',['Date' , header_swh]);
saving_name = strcat(path_5, '/', 'wave_height_all_stations_cropped' , '.dat');
writetable(T_5,char(saving_name));
T_5 = cell2table(TT_main_mvd_meas_for_comp_c , 'VariableNames',['Date' , header_mvd]);
saving_name = strcat(path_5, '/', 'wave_mean_direction_all_stations_cropped' , '.dat');
writetable(T_5,char(saving_name));
T_5 = cell2table(TT_main_mwp_meas_for_comp_c , 'VariableNames',['Date' , header_mwp]);
saving_name = strcat(path_5, '/', 'wave_mean_period_all_stations_cropped' , '.dat');
writetable(T_5,char(saving_name));
T_5 = cell2table(TT_main_pwp_meas_for_comp_c , 'VariableNames',['Date' , header_pwp]);
saving_name = strcat(path_5, '/', 'wave_peak_period_all_stations_cropped' , '.dat');
writetable(T_5,char(saving_name));


T_6 = cell2table(TT_main_swh_simul_for_comp_c , 'VariableNames',['Date' , header_swh]);
saving_name = strcat(path_6, '/', 'wave_height_all_stations_cropped' , '.dat');
writetable(T_6,char(saving_name));
T_6 = cell2table(TT_main_mvd_simul_for_comp_c , 'VariableNames',['Date' , header_mvd]);
saving_name = strcat(path_6, '/', 'wave_mean_direction_all_stations_cropped' , '.dat');
writetable(T_6,char(saving_name));
T_6 = cell2table(TT_main_mwp_simul_for_comp_c , 'VariableNames',['Date' , header_mwp]);
saving_name = strcat(path_6, '/', 'wave_mean_period_all_stations_cropped' , '.dat');
writetable(T_6,char(saving_name));
T_6 = cell2table(TT_main_pwp_simul_for_comp_c , 'VariableNames',['Date' , header_pwp]);
saving_name = strcat(path_6, '/', 'wave_peak_period_all_stations_cropped' , '.dat');
writetable(T_6,char(saving_name));


