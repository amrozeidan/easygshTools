%% descripion of 'b_extelemac' function
%aims to extract variables of telemac file (here focusing on water level,
%and other variables like velocity, pressure, salinity, water depth, etc..)
%referring to the locations provided from info_all_stations.dat in the
%common_folder

%usage: arguments:
%a)common_folder (path)
%b)basefolder (path)
%c)slfFile (path of the seraphin file)
%d)argument_var_telemac ('ONLY_WL' for free surface extraction only,
%'ALL_VAR' for all variables extraction)
%e)indate (optional, incase the initial date in tlemeac file is empty, it
%will be substituted by indate, format: datetime(yyyy,MM,dd,HH,mm,ss))
%f) telemac_module (defines which telemac dictionary to be used based on the module)

%% b_extelemac
function b_extelemac (common_folder , basefolder , slfFile , argument_var_telemac , telemac_module, stationsDBFile)

% common_folder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/com';
% basefolder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/res';
% slfFile = '/Users/amrozeidan/Documents/hiwi/scripts/allcomp/t2d___res1207_NSea_rev03a.4_y2006_conf00.slf';
% argument_var_telemac = {'U' , 'V' , 'S' , 'SLNT' , 'W' ,  'A' , 'G'};
% telemac_module = '2D' ;


telemac_dict = pick_dict(telemac_module)

disp('%%starting time:')
datetime('now')
%% telemac data extraction --------------------------------------------

%stationsDBFile = 'info_all_stationsNoDashes.dat'; %stations should be arranged in order here
%PathName_info = strcat(common_folder,'/');
%addpath(strcat(common_folder , '/TelemacTools'));

slfFile
mFile = telheadr(slfFile)
variables = mFile.RECV;

t_initial = datetime(mFile.IDATE)

t_initial.Format = 'dd/MM/yyyy HH:mm:ss';
dt = (mFile.DT)/3600;
%dt = 3600/3600;
t_initial = t_initial - 1*hours(dt);%as ii couldnt be 0 (Cell contents indices must be greater than 0)
nSteps = mFile.NSTEPS;
for ii=1:(nSteps)
    my_time_ii = t_initial + ii*hours(dt);
    my_time{ii} = my_time_ii;
end

%names of variables that could be in a telemac file
names_variables = telemac_dict ;

var_req_id = [] ;
for vc=1:length(argument_var_telemac)
    [~,indexC] = ismember(names_variables(:,3), argument_var_telemac(vc));
    index = find(indexC);
    var_req_id = vertcat(var_req_id , index);
end
var_req_id = var_req_id' ;

%extract of coordinates and names of locations/stations from the info
%text file; to get later data for all te stations, afterwards the
%required are picked for comparison
fileID = fopen(stationsDBFile,'r');
info_data = textscan(fileID, '%s%n%n%n%n', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fileID);

name_all = info_data{1,1}(:);
east_all = info_data{1,2}(:);
north_all = info_data{1,3}(:);


RW_HW_all = [east_all,north_all];
Locations_Names_all = name_all;

% defining the indices of the locations/stations in the telemac file by
% taking the min distance when comparing coordinates of telemac and the
% required locations
D = pdist2replace(mFile.XYZ(:,1:2),RW_HW_all);
[values, indx]=min(D);
% saving indices values and station names
names_and_indices = cell(length(indx) , 2);
for iu=1:length(indx)
    names_and_indices{iu,1} = Locations_Names_all(iu);
    names_and_indices{iu,2} = indx(iu);
end
T = cell2table(names_and_indices,'VariableNames',{'Name' , 'Index'});
saving_name = strcat(basefolder,'/station_names_and_indices' , '.dat');
writetable(T,char(saving_name));

% preparation of array containing 3 dimensions
nStations = length(RW_HW_all);
nSteps = mFile.NSTEPS
nVariables = mFile.NBV;
% 1st: time series nodes (aka stations)
% 2nd: time step
% 3rd: variable (e.g. U, V, H, etc; depending on what is stored to file
results = zeros (nStations, nSteps, nVariables);
results_test = zeros (nStations, nSteps, nVariables); %testing and comparing between using 1 or the time step number

% get all the values from the results file (which must be single precision)
for j=1:nSteps
    if j/250 == floor (j/250)
        fprintf('%d steps processed.',j);
    end
    
    %     Don't know why, but it always has to be one, obviously it is an
    %     increment from the current position in that file
    mResult = telstepr(mFile,1) ; %j instead of 1 is not woking properly
    %     interpolate all values for all nodes
    results (:,j,:) = mResult.RESULT(indx,:) ;
end


mkdir(basefolder, 'telemac_variables')
path_1 = strcat(basefolder, '/telemac_variables')

mkdir (path_1, 'variables_all_stations')
path_3 = strcat(path_1, '/variables_all_stations')

extracted_var = {};
for y= var_req_id
    index_variable = find(contains(mFile.RECV,names_variables{y,1}));
    name_naming = names_variables{y,2}
    if(isempty(index_variable))
        continue
    end
    extracted_var = vertcat(extracted_var , name_naming);
    mkdir (path_1, name_naming)
    path_2 = strcat(basefolder, '/telemac_variables/' , name_naming)
    
    %go through stations
    my_data_tot = cell(nSteps , nStations+1);
    for i = 1: nStations
        %through time steps
        my_data = cell(nSteps,2);
        
        for k = 1:nSteps
            my_data{k,1} = my_time(k);
            my_data{k,2} = results(i,k,index_variable);
            my_data_tot{k,1} = my_time(k);
            my_data_tot{k,i+1} = results(i,k,index_variable);
        end
        T = cell2table(my_data,'VariableNames',{'TimeStep_No', name_naming});
        saving_name = strcat(path_2 , '/', Locations_Names_all(i) , '.dat');
        writetable(T,char(saving_name));
        %file is saved referring to the telemac file name,
        %the variable extracted and the station name
        clear my_data;
        
    end
    Tt = cell2table(my_data_tot,'VariableNames',['TimeStep_No', strrep(Locations_Names_all, '-', '_')']);
    saving_name = strcat(path_3 , '/', name_naming ,'_all_stations' , '.dat');
    writetable(Tt,char(saving_name));
    clear my_data_tot;
end

disp('%%finishing time:')
datetime('now')

%% merging velocity components and getting vector magnitudes and directions

indu = find(ismember(extracted_var , 'velocity_u' ));
indv = find(ismember(extracted_var , 'velocity_v' ));

if (~isempty(indu) && ~isempty(indv))
    
    mkdir(strcat(basefolder , '/telemac_variables'), 'velocity_uv');
    path_uv = strcat(basefolder, '/telemac_variables/velocity_uv');
    
    mag_all_stations = cell(nSteps , length(Locations_Names_all));
    dir_all_stations = cell(nSteps , length(Locations_Names_all));
    for locn=1:length(Locations_Names_all)
        %read velocity u data
        file_id_u = fopen(strcat(basefolder , '/telemac_variables/velocity_u/' , Locations_Names_all{locn} , '.dat') ,'r');
        u_data = textscan(file_id_u, '%{dd/MM/yyyy HH:mm:ss}D%n', 'Delimiter', ',', 'HeaderLines', 1);
        fclose(file_id_u);
        u_dates = u_data{1,1};
        u_velocity = u_data{1,2};
        
        %read velocity u data
        file_id_v = fopen(strcat(basefolder , '/telemac_variables/velocity_v/' , Locations_Names_all{locn} , '.dat') ,'r');
        v_data = textscan(file_id_v, '%{dd/MM/yyyy HH:mm:ss}D%n', 'Delimiter', ',', 'HeaderLines', 1);
        fclose(file_id_v);
        v_dates = v_data{1,1};
        v_velocity = v_data{1,2};
        
        %merge u and v data
        data_uv = cell(length(u_dates),5);
        for k = 1:length(u_dates)
            data_uv{k,1} = u_dates(k);
            data_uv{k,2} = hypot(u_velocity(k),v_velocity(k));
            data_uv{k,3} = atan2d(v_velocity(k),u_velocity(k)) + 360*(v_velocity(k)<0);
            data_uv{k,4} = v_velocity(k);
            data_uv{k,5} = u_velocity(k);
        end
        
        %store all stations together in a dat file
        %magnitude
        mag_all_stations(:,locn) = data_uv(:,2);
        %direction
        dir_all_stations(:,locn) = data_uv(:,3);
        
        %save
        T = cell2table(data_uv,'VariableNames',{'TimeStep_No', 'magnitude' , 'direction' , 'velocity_v' , 'velocity_u'});
        saving_name = strcat(path_uv , '/', Locations_Names_all(locn) , '.dat');
        writetable(T,char(saving_name));
        
        clear data_uv
        
    end
    
    %extracting and saving velocity components, magnitude and direction for
    %all stations in one dat file, using the uv folder dat files
    
    uvlist = dir(fullfile(strcat(basefolder , '/telemac_variables/velocity_uv') , '*.dat'));
    for uv=1:length(uvlist)
        
        stname = uvlist(uv).name(1:end-4) ;
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
    writetable(timetable2table(mainT) , char( strcat(path_3 , '/' , 'velocity_all_stations' ,  '.dat') ))
    
    %save
    mag_all_stations = horzcat(my_time' , mag_all_stations );
    T = cell2table(mag_all_stations,'VariableNames',['Date' , Locations_Names_all']);
    saving_name = strcat(path_3 , '/', 'velocity_magnitude_all_stations' , '.dat');
    writetable(T,char(saving_name));
    
    dir_all_stations = horzcat(my_time' , dir_all_stations );
    T = cell2table(dir_all_stations,'VariableNames',['Date' , Locations_Names_all']);
    saving_name = strcat(path_3 , '/', 'velocity_direction_all_stations' , '.dat');
    writetable(T,char(saving_name));
end


%% merging wave components
%assuming that these are the components to focus on
indh = find(ismember(extracted_var , 'wave_height'));
indd = find(ismember(extracted_var , 'wave_mean_direction'));
indm = find(ismember(extracted_var , 'wave_mean_period_two'));
indp = find(ismember(extracted_var , 'wave_peak_period'));

if (~isempty(indh) && ~isempty(indd) && ~isempty(indm) && ~isempty(indp))
    
    hlist = dir(fullfile(strcat(basefolder , '/telemac_variables/wave_height') , '*.dat'));
    dlist = dir(fullfile(strcat(basefolder , '/telemac_variables/wave_mean_direction') , '*.dat'));
    mlist = dir(fullfile(strcat(basefolder , '/telemac_variables/wave_mean_period_two') , '*.dat'));
    plist = dir(fullfile(strcat(basefolder , '/telemac_variables/wave_peak_period') , '*.dat'));
    
    for w=1:length(hlist) %as all folders should contain the same stations
        
        stname = hlist(w).name(1:end-4) ;
        %read as table
        filepath = strcat(hlist(w).folder , '/' , hlist(w).name) ;
        T1 = readtable(filepath , 'Delimiter' , ',' , 'ReadVariableNames' , true);
        T1 = table2timetable(T1);
        %create new naming
        stname_table = strcat(stname , {'_swh'});
        T1.Properties.VariableNames(:) = stname_table ;
        
        %read as table
        filepath = strcat(dlist(w).folder , '/' , dlist(w).name) ;
        T2 = readtable(filepath , 'Delimiter' , ',' , 'ReadVariableNames' , true);
        T2 = table2timetable(T2);
        %create new naming
        stname_table = strcat(stname , {'_mwd'});
        T2.Properties.VariableNames(:) = stname_table ;
        
        %read as table
        filepath = strcat(mlist(w).folder , '/' , mlist(w).name) ;
        T3 = readtable(filepath , 'Delimiter' , ',' , 'ReadVariableNames' , true);
        T3 = table2timetable(T3);
        %create new naming
        stname_table = strcat(stname , {'_mwp'});
        T3.Properties.VariableNames(:) = stname_table ;
        
        %read as table
        filepath = strcat(plist(w).folder , '/' , plist(w).name) ;
        T4 = readtable(filepath , 'Delimiter' , ',' , 'ReadVariableNames' , true);
        T4 = table2timetable(T4);
        %create new naming
        stname_table = strcat(stname , {'_pwp'});
        T4.Properties.VariableNames(:) = stname_table ;
        
        T = synchronize(T1,T2,T3,T4);
        if w ==1
            mainT = T;
        else
            mainT = synchronize(mainT , T);
        end
        
    end
    %save table
    writetable(timetable2table(mainT) , char( strcat(path_3 , '/' , 'wave_all_stations' ,  '.dat') ))
    
end
end
