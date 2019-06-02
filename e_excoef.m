%% description of 'e_excoef' function
%aims to extract coeffitients of partial tides (including amplitude and
%phase shift) using ut_solv function (a part of UtTools) for the required
%stations for both measurements and simulations.

%usage: arguments:
%a)common_folder
%b)basefolder
%c)main_path (of functions)

%excoef has no third argument like the previous version excoef,it will
%automatically check if coef_measured folder is already created in the
%common folder (which means that the coefficients of the measurements are
%already extracted), in case coef_measured exists  the function will
%extract the coeffitients of the simulations only, in case it does not
%exist both coefficients for measurements and simulations are extracted.

function e_excoef(common_folder, basefolder , main_path)
addpath(main_path)

%% checking if required_stations_data.dat file is available, if not run 'wlfileprep' function to generate it
listing_common_folder = dir(common_folder);
common_folder_file_name = {};
for f=1:length(listing_common_folder)
    common_folder_file_name = vertcat(common_folder_file_name , listing_common_folder(f).name) ;
end
indi = find(ismember(common_folder_file_name , 'required_stations_data_free_surface.dat' ));
indo = find(ismember(common_folder_file_name , 'required_stations_data_free_surface_cropped.dat' ));

if isempty(indi)
    c_wlfileprep (common_folder , basefolder )
else
end

if isempty(indo)
    c_wlfileprep (common_folder , basefolder )
    d_wlcomp( common_folder , basefolder , main_path)
else
end

%% Exporting coefficients using ut_solv
file_id = fopen( strcat(common_folder , '/required_stations_data_free_surface_cropped.dat') ,'r');
data = textscan(file_id, '%s%s%s%n%n%n%n', 'Delimiter', ',', 'HeaderLines', 1);
fclose(file_id);
data_meas_file_name_with_directory_req = data{1,2};
data_wl_simulated_file_name_with_directory_req = data{1,3};
Locations_Names = data{1,1};
Latitudes = data{1,6};

%exporting A and g from measurements and simulations
%addpath('./UtTools');
addpath(strcat(common_folder , '/UtTools'));
load('ut_constants.mat');
pTides = importPTides('pTides.dat');

% indicate whether analysis of the measurement data is already supplied
indu = find(ismember(common_folder_file_name , 'coef_measured' ));

mkdir(basefolder, 'coef')
path_4 = strcat(basefolder, '/coef')

if isempty(indu)
    
    mkdir (path_4, 'coef_measured')
    path_5 = strcat(path_4 , '/coef_measured')
    
    mkdir(common_folder, 'coef_measured')
    path_add = strcat(common_folder, '/coef_measured')
    
    % examine parameters for measurements
    % ***********************************
    for cwl=1:length(data_meas_file_name_with_directory_req)
        % reading measurements data
        % *************************
        cwl
		data_meas_file_name_with_directory_req{cwl}
		file_id_meas = fopen(data_meas_file_name_with_directory_req{cwl} ,'r')
        meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D%n', 'Delimiter', ',', 'HeaderLines', 1);
        fclose(file_id_meas);
        % transfer to sepate cells
        meas_dates = meas_data{1,1};
        meas_wl = meas_data{1,2};
        
        latitude = Latitudes(cwl);
        
        %%%adjusting time for ut_solv%%%
        %note: using the merged timeseries is
        %exceding the maximum array size preference, and this may take longer
        %time and cause MATLAB to become unresponsive
        %Transform dates to numbers for interpolation
        meas_dates_num = datenum(meas_dates);

        % eliminating NaN
        meas_dates_num (isnan(meas_wl)) = [];
        meas_wl(isnan(meas_wl)) = [];
        
        % eliminating outliers
        meanWL = mean (meas_wl);
        sigma = std(meas_wl-meanWL);
        
%         meas_dates_num (isoutlier(meas_wl)) = [];
%         meas_wl (isoutlier(meas_wl)) = [];
        

        %exporting coefficients using ut_solv
        tidalcoef_meas = ut_solv(meas_dates_num,meas_wl,[],latitude,pTides);
        my_data_coef_meas = horzcat(tidalcoef_meas.name,num2cell(tidalcoef_meas.A),num2cell(tidalcoef_meas.g));
        save(strcat(path_5 , '/' ,'coef_of_meas_',Locations_Names{cwl}),'my_data_coef_meas');
        save(strcat(path_add , '/' ,'coef_of_meas_',Locations_Names{cwl}),'my_data_coef_meas');
        
        clear('tidalcoef_meas');
        clear('my_data_coef_meas');
    end
end

mkdir (path_4, 'coef_simulated')
path_6 = strcat(path_4 , '/coef_simulated')

for cwl=1:length(data_meas_file_name_with_directory_req)
    %reading simulated data
    file_id_sim = fopen(data_wl_simulated_file_name_with_directory_req{cwl} ,'r');
    sim_data = textscan(file_id_sim, '%{dd.MM.yyyy HH:mm:ss}D%n', 'Delimiter', ',', 'HeaderLines', 1);
    fclose(file_id_sim);
    % transfer to sepate cells
    sim_dates = sim_data{1,1};
    sim_wl = sim_data{1,2};
        
    latitude = Latitudes(cwl);
        
    %%%adjusting time for ut_solv%%%
    %note: using the merged timeseries is
    %exceding the maximum array size preference, and this may take longer
    %time and cause MATLAB to become unresponsive
    %Transform dates to numbers for interpolation
    sim_dates_num  = datenum(sim_dates);

    % eliminating NaN
    sim_dates_num(isnan(sim_wl)) = [];
    sim_wl(isnan(sim_wl)) = [];
        
    %exporting coefficients using ut_solv
    tidalcoef_sim = ut_solv(sim_dates_num,sim_wl,[],latitude,pTides);
    my_data_coef_wl_simulated = horzcat(tidalcoef_sim.name,num2cell(tidalcoef_sim.A),num2cell(tidalcoef_sim.g));
    save(strcat(path_6 ,  '/' ,'coef_of_simulation_',Locations_Names{cwl}),'my_data_coef_wl_simulated');
        
    clear('tidalcoef_wl_simulated');
    clear('my_data_coef_wl_simulated');
end

disp('%%finishing time:')
datetime('now')