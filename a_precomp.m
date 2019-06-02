

%% folder organization
%*********************
%the following functions are connected to two folders and one file; which
%are arranged as followed:
%%a) common_folder, and contains:
%
%main folders and files:
% 1) TelemacTools   (!subfolder!)
% 2) UtTools (UTide, !subfolder!)
% 3) info_all_stations.dat (contains data of stations including stations names, easting, northing, latitude, station number)
% 4) folder_meas (set of measured data)
% 5) required_stations.dat (this file includes the concerned stations names, it could be generated by 'a_precomp' function,


% or could be added directly to the common folder)
%automatically added folders and files:
%6 + required_stations_data.dat(this file is generated auomatically after running 'c_wlfileprep', and includes station names,
%measurements data directories, simulaions data directories, easting, northing, latitudes)
%7 + coef_measured (this folder will be added automatically after running 'e_excoef' function; it contains the coefficients of the
%the measurements)
%8 + A_g_measured (this folder will be added automatically after running 'f_ptcomp' function; it contains Amplitude and phase shift
%of different types of tides (listed in pTides under UtTools) based on required locations/stations)
%9 + required_stations_data_updated.dat (this file is generated after updating the measured and simulated data to cover the required
%period, and it is stating the directories of the updated data(folder no#10))
%10 + folder_meas_updated (this folder contains the updated measured data as mentioned in #9 above)

%%b) basefolder, and contains:
%1 + telemac_variables (includes variables subfolder like free_surface extracted from telemac file using function 'b_extelemac')
% free_surface_updated, a folder containing the updated simulated data as mentioned above in #9)
%2 + wl_compaison (includes all plots generated from function 'd_wlcomp')
%3 + coef (generated by 'e_excoef' function; includes coef_measured and coef_simulated folders, and each contains
%the coefficients of the the measurements/simulations)
%4 + A_g ( generated by 'f_ptcomp' function; includes A_g_measured and A_g_simulated folders and each contains
%Amplitude and phase shift of different types of tides (listed in pTides under UtTools) based on required locations/stations)
%5 + pt_comparison (partial tides parameters comparison, amplitude and phase shift, based on different types
%6 + station_names_and_indices.dat (generated and contains the indices of the stations inside the telemac file and their names)
%of tides for the required stations)

%%c) slfFile, which is the seraphin file


%% description of 'a_precomp' function
%this function aims to list (saved in .dat file named 'required_stations.dat') the names of stations wich are fulfilling
%specific requirements amongst the set of measurements data (data under /common_folder/folder_meas).
%in this script it is required that the measurements have no gaps,
%have reasonable water level range (ranging fron min_wl to max_wl) and are covering a
%specific period (from date_a to date_b).
%'required_stations.dat' could be added from the user directly to the common_folder, and 'precomp' function has to be skipped

%usage: arguments:
%a) common_folder (path of the common folder)
%b) date_a (starting date)
%date_a format as arguments inside the function: datetime(yyyy,MM,dd,HH,mm,ss)
%c)period (period of comparison)

%% a_precomp
function a_precomp (common_folder, date_a , period )

%listing measurements folder
listing_meas = dir(strcat(common_folder , '/folder_meas'));

data_meas_file_name = {};
data_meas_file_name_with_directory = {};
head{1,1} = 'station_name';
head{1,2} = 'directory';
my_data = {};

for u=3:length(listing_meas)
    meas_file_name = listing_meas(u).name ;
    data_meas_file_name = vertcat(data_meas_file_name , meas_file_name);
    my_data = vertcat(my_data , {meas_file_name(1:end-4),strcat(common_folder , '/folder_meas' ,'/',meas_file_name)});
end

my_data = vertcat(head, my_data);
station_no_gaps = {};

%defining time range
%required period: from date_a up to 31 days for example
req_time_initial = date_a;
for i=1:period
    req_time{i} = req_time_initial + (i-1)*days(1);
end
%then converting to yyyymmdd
for i=1:length(req_time)
    req_time_as_ymd(i) = yyyymmdd(req_time{i});
end
req_time_as_ymd = (req_time_as_ymd)';

for u=2:length(my_data)
    %reading measurements data
    file_id_meas = fopen(char(my_data(u,2)) ,'r');
    
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
    
    meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D%n', 'Delimiter', ';', 'HeaderLines', l);
    fclose(file_id_meas);
    meas_dates = meas_data{1,1};
    meas_dates(isnat(meas_dates)) = [];
    meas_wl = meas_data{1,2};
    meas_wl(isnan(meas_wl)) = [];
    
    %converting meas_dates to yyyymmdd format
    for f=1:length(meas_dates)
        meas_dates_as_ymd(f) = yyyymmdd(meas_dates(f));
    end
    
    %find indices of the required period
    [~ , idx] = find(ismember(meas_dates_as_ymd, req_time_as_ymd));
    
    %extract final time from my_time
    meas_dates_final = meas_dates(idx);
    meas_wl_final = meas_wl(idx);
    
    %finding gaps along the required period
    station_name = char(my_data(u,1))
    threshold = meas_dates_final(2) - meas_dates_final(1);
    gap = diff(meas_dates_final);
    idx_g = find(gap > threshold);
    
    %filling the requirements, reasonable range, specific period, no gaps
%     if (max(meas_wl_final)<15 && min(meas_wl_final)>-15)
        if (isempty(idx_g))
            station_no_gaps = vertcat(station_no_gaps , station_name);
        else strcat(station_name,' has gaps')
            continue
        end
%     else strcat(station_name,' has no reasonable WL measurements')
%         continue
%     end
end

%saving the names of the required stations (fulfilling the requirements)
%into a .dat file
datfilepath = strcat(common_folder , '/required_stations.dat');
empty = {};
save(datfilepath, 'empty');

fileID = fopen(datfilepath ,'wt');
for u=1:length(station_no_gaps)
    fprintf(fileID,'%s\n' , station_no_gaps{u});
end
fclose(fileID);







