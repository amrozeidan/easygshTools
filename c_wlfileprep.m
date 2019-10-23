%% description of 'c_wlfileprep' function
%aims to prepare informations for water level comparison, for coefficient
%extraction and for partial tides parameters comparison. basically the
%names of stations are extracted from the required_stations.dat and their
%data are exracted from info_all_stations.dat, and the measured and simulated
%data directories are added to form required_stations_data_free_surface.dat
%required_stations_data_free_surface.dat contains: datations names, measurements
%directories, simulations directories, easting, northing, latitudes and
%station order number

%usage: arguments:
%a)common_folder
%b)basefolder


%% c_wlfileprep

function c_wlfileprep (common_folder , basefolder, requiredStationsFile )

FileName_info = 'info_all_stations.dat';
PathName_info = strcat(common_folder,'/');

req_data = textread(requiredStationsFile , '%s', 'delimiter', '\n');

listing_basefolder = dir(strcat(basefolder, '/telemac_variables'));
basefolder_file_name = {};
for f=1:length(listing_basefolder)
    basefolder_file_name = vertcat(basefolder_file_name , listing_basefolder(f).name) ;
end
index_wl_simul_folder = find(ismember(basefolder_file_name , 'free_surface' ));

listing_meas = dir(strcat(common_folder , '/measurements/free_surface'));
listing_wl_simulated = dir(strcat(basefolder, '/telemac_variables' , '/', basefolder_file_name{index_wl_simul_folder} ));

disp(['measured wl folder directory:' , ' ' , common_folder , '/measurements/free_surface']);
disp(['simulated wl folder directory:' , ' ' , basefolder, '/telemac_variables' , '/', basefolder_file_name{index_wl_simul_folder} ]);

data_meas_file_name = {};
data_wl_simulated_file_name = {};

% Find measurement station names
for u=3:length(listing_meas)
    meas_file_name = listing_meas(u).name ;
    data_meas_file_name  = vertcat(data_meas_file_name  , {meas_file_name(1:end-4)});
end

% Find simulation station names
for uu=3:length(listing_wl_simulated)
    wl_simulated_file_name = listing_wl_simulated(uu).name ;
    data_wl_simulated_file_name  = vertcat(data_wl_simulated_file_name  , {wl_simulated_file_name(1:end-4)});
end

data_meas_file_name_with_directory_req = {};
data_wl_simulated_file_name_with_directory_req = {};

%get information about the stations from the station database file
%
fileID = fopen(fullfile(PathName_info,FileName_info),'r');
info_data = textscan(fileID, '%s%n%n%n%n', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fileID);

Locations_Names={};
RW_HW = [];
Latitudes =[];
num_order = [];
    
% go through the list of required stations
for iui=1:length(req_data)
    
    % find index of required station in measurement files
    index_meas = find(ismember(data_meas_file_name, req_data{iui}));
    % find index of required station in database file
    index_names_info = find(ismember(info_data{1,1} , req_data{iui}));
    % find index of required station in simulated files list
    index_names_simulated = find (ismember(data_wl_simulated_file_name, req_data{iui}));
    
    if(isempty(index_names_info) || isempty(index_meas) || isempty(index_names_simulated))
        req_data{iui}
        continue
    else
        % gather file names from measurement files and simulation files
        data_meas_file_name_with_directory_req = vertcat(data_meas_file_name_with_directory_req , strcat(common_folder , '/measurements/free_surface','/',data_meas_file_name{index_meas},'.dat'));
        data_wl_simulated_file_name_with_directory_req = vertcat(data_wl_simulated_file_name_with_directory_req , strcat(basefolder, '/telemac_variables' , '/', basefolder_file_name{index_wl_simul_folder},'/',info_data{1,1}{index_names_info},'.dat'));

        %available locations names (other stations are skipped)
        Locations_Names = vertcat(Locations_Names, info_data{1,1}(index_names_info));
        % find coordinates from database file
        % in ETRS89 (or mesh coordinates)
        RW_HW = vertcat(RW_HW, horzcat(info_data{1,2}(index_names_info),info_data{1,3}(index_names_info)));
        % in WGS84 (latlon coordinates)
        Latitudes = vertcat(Latitudes, info_data{1,4}(index_names_info));
        % find station order number
        num_order = vertcat(num_order, info_data{1,5}(index_names_info) );
    end
end
%end

disp('%% Stations in common between measurements,simulated data and the required stations:');
Locations_Names

disp('%%and this/these station/s has/have missed data in either measurements or simulations');
setdiff(req_data , Locations_Names)

disp('%%hence the files to be compared are from measurements and simulations consecutively:');
data_meas_file_name_with_directory_req
data_wl_simulated_file_name_with_directory_req

disp('%%these data are saved into this dat file:');

my_data_prep = cell (length(Locations_Names) , 7);
RW = RW_HW(:,1);
HW = RW_HW(:,2);

for k = 1:length(Locations_Names)
    my_data_prep{k,1} = Locations_Names(k);
    my_data_prep{k,2} = data_meas_file_name_with_directory_req(k);
    my_data_prep{k,3} = data_wl_simulated_file_name_with_directory_req(k);
    my_data_prep{k,4} = RW(k);
    my_data_prep{k,5} = HW(k);
    my_data_prep{k,6} = Latitudes(k);
    my_data_prep{k,7} = num_order(k);
end

%sort order of the prepared data based on the sorting order
my_data_prep = sortrows(my_data_prep,[7]);

T = cell2table(my_data_prep,'VariableNames',{'Location_Names', 'Meas_dir' , 'Simul_dir' , 'RW' , 'HW' , 'Latitudes' , 'Station_No'});
saving_name = strcat(common_folder,'/', 'required_stations_data_free_surface' , '.dat');
writetable(T,char(saving_name));
