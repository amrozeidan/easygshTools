


%% h_velocitycomp
function h_velocitycomp (common_folder , basefolder , date_a , period )

FileName_info = 'info_all_stations.dat';
PathName_info = strcat(common_folder,'/');

req_data = textread(strcat(common_folder , '/required_stations.dat') , '%s', 'delimiter', '\n');

listing_basefolder = dir(strcat(basefolder, '/telemac_variables'));
basefolder_file_name = {};
for f=1:length(listing_basefolder)
    basefolder_file_name = vertcat(basefolder_file_name , listing_basefolder(f).name) ;
end
index_velocity_folder = find(ismember(basefolder_file_name , 'velocity_uv' ));

listing_meas_velocity = dir(strcat(common_folder , '/measurements/velocity'));
listing_simul_velocity = dir(strcat(basefolder, '/telemac_variables' , '/', basefolder_file_name{index_velocity_folder} ));

disp(['measured velocity folder directory:' , ' ' , common_folder , '/measurements/velocity']);
disp(['simulated velocity folder directory:' , ' ' , basefolder, '/telemac_variables' , '/', basefolder_file_name{index_velocity_folder} ]);

data_meas_velocity_file_name = {};
data_simul_velocity_file_name = {};

% Find measurement station names
for u=3:length(listing_meas_velocity)
    meas_file_name = listing_meas_velocity(u).name ;
    data_meas_velocity_file_name  = vertcat(data_meas_velocity_file_name  , {meas_file_name(1:end-4)});
end

% Find simulation station names
for uu=3:length(listing_simul_velocity)
    simulated_file_name = listing_simul_velocity(uu).name ;
    data_simul_velocity_file_name  = vertcat(data_simul_velocity_file_name  , {simulated_file_name(1:end-4)});
end

data_meas_velocity_file_name_with_directory_req = {};
data_simul_velocity_file_name_with_directory_req = {};

%get information about the stations from the station database file
fileID = fopen(fullfile(PathName_info,FileName_info),'r');
info_data = textscan(fileID, '%s%n%n%n%n', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fileID);

Locations_Names={};
RW_HW = [];
Latitudes =[];
num_order = [];
depth_meas = [];
    
% go through the list of required stations
for iui=1:length(req_data)
    
    % find index of required station in measurement files
    expression = [req_data{iui}, '+\d*'] ;
    index_meas = regexp(data_meas_velocity_file_name , expression);
    isone = cellfun(@(x)isequal(x,1),index_meas);
    index_meas = find(isone);
    %index_meas = find(ismember(data_meas_velocity_file_name, req_data{iui}));
    % find index of required station in database file
    index_names_info = find(ismember(info_data{1,1} , req_data{iui}));
    % find index of required station in simulated files list
    index_names_simulated = find (ismember(data_simul_velocity_file_name, req_data{iui}));
    
    if(isempty(index_names_info) || isempty(index_meas) || isempty(index_names_simulated))
        req_data{iui}
        continue
    else
        for im=index_meas'
        % gather file names from measurement files and simulation files    
        data_meas_velocity_file_name_with_directory_req = vertcat(data_meas_velocity_file_name_with_directory_req ,strcat(common_folder , '/measurements/velocity/',data_meas_velocity_file_name{im},'.dat'));
        
        data_simul_velocity_file_name_with_directory_req = vertcat(data_simul_velocity_file_name_with_directory_req , strcat(basefolder, '/telemac_variables' , '/', basefolder_file_name{index_velocity_folder},'/',info_data{1,1}{index_names_info},'.dat'));
        
        %available locations names (other stations are skipped)
        Locations_Names = vertcat(Locations_Names, info_data{1,1}(index_names_info));
        
        % find coordinates from database file
        % in ETRS89 (or mesh coordinates)
        RW_HW = vertcat(RW_HW, horzcat(info_data{1,2}(index_names_info),info_data{1,3}(index_names_info)));
        
        % in WGS84 (latlon coordinates)
        Latitudes = vertcat(Latitudes, info_data{1,4}(index_names_info));
        
        % find station order number
        num_order = vertcat(num_order, info_data{1,5}(index_names_info) );
        
         % find depth for measurements
        depth_meas = vertcat(depth_meas , str2double(extractAfter(data_meas_velocity_file_name{im},'.'))/10 );
        
        end
    end
end
%end

disp('%% Stations in common between measurements,simulated data and the required stations:');
Locations_Names

disp('%%and this/these station/s has/have missed data in either measurements or simulations');
setdiff(req_data , Locations_Names)

disp('%%hence the files to be compared are from measurements and simulations consecutively:');
data_meas_velocity_file_name_with_directory_req
data_simul_velocity_file_name_with_directory_req

disp('%%these data are saved into this dat file:');

my_data_prep = cell (length(Locations_Names) , 8);
RW = RW_HW(:,1);
HW = RW_HW(:,2);

for k = 1:length(Locations_Names)
    my_data_prep{k,1} = Locations_Names(k);
    my_data_prep{k,2} = data_meas_velocity_file_name_with_directory_req(k);
    my_data_prep{k,3} = data_simul_velocity_file_name_with_directory_req(k);
    my_data_prep{k,4} = RW(k);
    my_data_prep{k,5} = HW(k);
    my_data_prep{k,6} = Latitudes(k);
    my_data_prep{k,7} = num_order(k);
    my_data_prep{k,8} = depth_meas(k);
end

%sort order of the prepared data based on the sorting order
my_data_prep = sortrows(my_data_prep,[7]);

% T = cell2table(my_data_prep,'VariableNames',{'Location_Names', 'Meas_dir' , 'Simul_dir' , 'RW' , 'HW' , 'Latitudes' , 'Station_No' , 'z'});
% saving_name = strcat(common_folder,'/', 'required_stations_data' , '.dat')
% writetable(T,char(saving_name));


%% velocity comparison 

%creating folders for results storage
mkdir(basefolder, 'velocity_comparison')
path_3 = strcat(basefolder, '/velocity_comparison') ;

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


[row , col] = size(my_data_prep);

for cwl=1:row
    %reading measurements data
    file_id_meas = fopen(my_data_prep{cwl,2}{1} ,'r');
    my_data_prep{cwl,2}{1}
    depth = 100 * my_data_prep{cwl,8};
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
    meas_magnitude = meas_data{1,2};
    meas_direction = meas_data{1,3};
    meas_velocity_v = meas_data{1,4};
    meas_velocity_u = meas_data{1,5};
    
    %reading simulated data
    file_id_simul = fopen(my_data_prep{cwl,3}{1} ,'r');
    my_data_prep{cwl,3}{1} 
    simul_data = textscan(file_id_simul, '%{dd/MM/yyyy HH:mm:ss}D%n%n%n%n', 'Delimiter', ',', 'HeaderLines', 1);
    fclose(file_id_simul);
    simul_dates = simul_data{1,1};
    simul_magnitude = simul_data{1,2};
    simul_direction = simul_data{1,3};
    simul_velocity_v = simul_data{1,4};
    simul_velocity_u = simul_data{1,5};

    
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
    meas_magnitude_for_comp = meas_magnitude(idx_meas);
    simul_magnitude_for_comp = simul_magnitude(idx_simul);
    %and direction values
    meas_direction_for_comp = meas_direction(idx_meas);
    simul_directiion_for_comp = simul_direction(idx_simul);
    %ignoring the replaced value -777.0 for the missed data generated by
    %zeitrio for measurements
    %TODO: Read the no value entry from the zeitrio file
%     index_99999_mag = find(meas_magnitude_for_comp < -100.00);
%     meas_magnitude_for_comp(index_99999_mag) = NaN ;
%     
%     index_99999_dir = find(meas_direction_for_comp < -100.00);
%     meas_direction_for_comp(index_99999_dir) = NaN ;

    index_99999 = find(meas_magnitude_for_comp < -100.00);
    meas_magnitude_for_comp(index_99999) = NaN ;
    meas_direction_for_comp(index_99999) = NaN ;

    %constructing timetables
    TT_meas_magnitude = timetable(meas_dates_for_comp , meas_magnitude_for_comp);
    TT_simul_magnitude = timetable(simul_dates_for_comp , simul_magnitude_for_comp);
    %synchronising
    TT_meas_simul_sync = synchronize(TT_meas_magnitude,TT_simul_magnitude);
    %removing NaN (missing data) from timetable for both measured and simulated data(just in case)
    TT_meas_simul_sync_no_NaN = rmmissing(TT_meas_simul_sync);
    %taking back the data from timetable
    date_sync_no_NaN_mag = timetable2table(TT_meas_simul_sync_no_NaN);
    date_sync_no_NaN_mag = table2array(date_sync_no_NaN_mag(:,1));
    TT_meas_simul_sync_no_NaN_c_mag = table2cell(timetable2table(TT_meas_simul_sync_no_NaN));
    magnitude_meas_sync_no_NaN = cell2mat(TT_meas_simul_sync_no_NaN_c_mag(:,2));
    magnitude_simul_sync_no_NaN = cell2mat(TT_meas_simul_sync_no_NaN_c_mag(:,3)) ;
    %magnitude difference
    magnitude_diff = magnitude_simul_sync_no_NaN - magnitude_meas_sync_no_NaN ;
    
    %constructing timetables
    TT_meas_direction = timetable(meas_dates_for_comp , meas_direction_for_comp);
    TT_simul_direction = timetable(simul_dates_for_comp , simul_directiion_for_comp);
    %synchronising
    TT_meas_simul_sync = synchronize(TT_meas_direction,TT_simul_direction);
    %removing NaN (missing data) from timetable for both measured and simulated data(just in case)
    TT_meas_simul_sync_no_NaN = rmmissing(TT_meas_simul_sync);
    %taking back the data from timetable
    date_sync_no_NaN_dir = timetable2table(TT_meas_simul_sync_no_NaN);
    date_sync_no_NaN_dir = table2array(date_sync_no_NaN_dir(:,1));
    TT_meas_simul_sync_no_NaN_c_dir = table2cell(timetable2table(TT_meas_simul_sync_no_NaN));
    direction_meas_sync_no_NaN = cell2mat(TT_meas_simul_sync_no_NaN_c_dir(:,2));
    direction_simul_sync_no_NaN = cell2mat(TT_meas_simul_sync_no_NaN_c_dir(:,3)) ;
    %magnitude difference
    direction_diff = direction_simul_sync_no_NaN - direction_meas_sync_no_NaN ;
    
%     %plot magnitudes and directions
%     h = figure('visible','off');
%     
%     ax1 = subplot(2,1,1);
%     plot(meas_dates_for_comp,meas_magnitude_for_comp,'-b');
%     hold on
%     plot(simul_dates_for_comp,simul_magnitude_for_comp,'-r');
%     title(strcat('Velocity magnitude comparison,', ' Station : ', my_data_prep{cwl,1}{1}  , ',z=' , num2str(depth) , 'cm'));
%     legend('Measurments','Simulations');
%     ylabel('Velocity magnitude');
%     
%     ax2 = subplot(2,1,2);
%     plot(meas_dates_for_comp,meas_direction_for_comp,'-b');
%     hold on
%     plot(simul_dates_for_comp,simul_directiion_for_comp,'-r');
%     title(strcat('Velocity direction comparison,', ' Station : ', my_data_prep{cwl,1}{1}  , ',z=' , num2str(depth) , 'cm'));
%     legend('Measurments','Simulations');
%     xlabel('Date/Time');
%     ylabel('Direction [Degrees]');
%     
%     linkaxes([ax1 , ax2] , 'x');
%     
%     grid(ax1,'on');
%     grid(ax2,'on');
%     ax1.FontSize = 10.5;
%     ax2.FontSize = 10.5;
%     pbaspect(ax1 , 'auto') %[x y z]
%     pbaspect(ax2 , 'auto')
%     
%     %set(ax1,'position',[.1 .4 .8 .5])
%     %set(ax2,'position',[.1 .1 .8 .3])
%     
%     save_name = strcat(path_3, '/','Velocity comparison', '_Station_', my_data_prep{cwl,1}{1}  , '_z' , num2str(depth));
%     savefig(h, save_name, 'compact');
%     saveas(gca, save_name , 'jpeg');
%     clf
%     close(h)

    %plot magnitudes and magnitude diffferences
    h = figure('visible','off');
    
    ax1 = subplot(2,1,1);
    plot(meas_dates_for_comp,meas_magnitude_for_comp,'-b');
    hold on
    plot(simul_dates_for_comp,simul_magnitude_for_comp,'-r');
    title(strcat('Velocity magnitude comparison,', ' Station : ', my_data_prep{cwl,1}{1}  , ',z=' , num2str(depth) , 'cm'));
    legend('Measurments','Simulations');
    ylabel('Velocity magnitude');
    
    ax2 = subplot(2,1,2);
    plot(date_sync_no_NaN_mag,magnitude_diff);
    title(strcat('Velocity magnitude difference,', ' Station : ', my_data_prep{cwl,1}{1}  , ',z=' , num2str(depth) , 'cm'));
    xlabel('Date/Time');
    ylabel('Velocity magnitude');
    
    linkaxes([ax1 , ax2] , 'x');
    
    grid(ax1,'on');
    grid(ax2,'on');
    ax1.FontSize = 10.5;
    ax2.FontSize = 10.5;
    pbaspect(ax1 , 'auto') %[x y z]
    pbaspect(ax2 , 'auto')
    
    %set(ax1,'position',[.1 .4 .8 .5])
    %set(ax2,'position',[.1 .1 .8 .3])
    
    save_name = strcat(path_3, '/','MagnitueComparison', '_Station_', my_data_prep{cwl,1}{1}  , '_z' , num2str(depth));
    savefig(h, save_name, 'compact');
    saveas(gca, save_name , 'jpeg');
    clf
    close(h)
    
    %plot direction and direction diffferences
    h = figure('visible','off');
    
    ax1 = subplot(2,1,1);
    plot(meas_dates_for_comp,meas_direction_for_comp,'-b');
    hold on
    plot(simul_dates_for_comp,simul_directiion_for_comp,'-r');
    title(strcat('Velocity direction comparison,', ' Station : ', my_data_prep{cwl,1}{1}  , ',z=' , num2str(depth) , 'cm'));
    legend('Measurments','Simulations');
    ylabel('Velocity direction');
    
    ax2 = subplot(2,1,2);
    plot(date_sync_no_NaN_dir,direction_diff);
    title(strcat('Velocity direction difference,', ' Station : ', my_data_prep{cwl,1}{1}  , ',z=' , num2str(depth) , 'cm'));
    xlabel('Date/Time');
    ylabel('Velocity direction');
    
    linkaxes([ax1 , ax2] , 'x');
    
    grid(ax1,'on');
    grid(ax2,'on');
    ax1.FontSize = 10.5;
    ax2.FontSize = 10.5;
    pbaspect(ax1 , 'auto') %[x y z]
    pbaspect(ax2 , 'auto')
    
    %set(ax1,'position',[.1 .4 .8 .5])
    %set(ax2,'position',[.1 .1 .8 .3])
    
    save_name = strcat(path_3, '/','DirectionComparison', '_Station_', my_data_prep{cwl,1}{1}  , '_z' , num2str(depth));
    savefig(h, save_name, 'compact');
    saveas(gca, save_name , 'jpeg');
    clf
    close(h)

end

