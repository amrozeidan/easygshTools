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
function b_extelemac (common_folder , basefolder , slfFile , argument_var_telemac , indate, telemac_module)

telemac_dict = pick_dict(telemac_module)

disp('%%starting time:')
datetime('now')
%% telemac data extraction --------------------------------------------

FileName_info = 'info_all_stations.dat';
PathName_info = strcat(common_folder,'/');

addpath(strcat(common_folder , '/TelemacTools'));
mFile = telheadr(slfFile)
variables = mFile.RECV;

t_initial = datetime(mFile.IDATE)
if isempty(t_initial)
    t_initial = indate ;
else
end

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
fileID = fopen(strcat(PathName_info,FileName_info),'r');
info_data = textscan(fileID, '%s%n%n%n%n', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fileID);

name_all = info_data{1,1}(:);
east_all = info_data{1,2}(:);
north_all = info_data{1,3}(:);


RW_HW_all = [east_all,north_all];
Locations_Names_all = name_all;

%defining the indices of the locations/stations in the telemac file by
%taking the min distance when comparing coordinates of telemac and the
%required locations
D = pdist2(mFile.XYZ(:,1:2),RW_HW_all);
[values, indx]=min(D);
%saving indices values and station names
names_and_indices = cell(length(indx) , 2);
for iu=1:length(indx)
    names_and_indices{iu,1} = Locations_Names_all(iu);
    names_and_indices{iu,2} = indx(iu);
end
T = cell2table(names_and_indices,'VariableNames',{'Name' , 'Index'});
saving_name = strcat(basefolder,'/station_names_and_indices' , '.dat');
writetable(T,char(saving_name));

%preparation of array containing 3 dimensions
nStations = length(RW_HW_all);
nSteps = mFile.NSTEPS
nVariables = mFile.NBV;
%1st: time series nodes (aka stations)
%2nd: time step
%3rd: variable (e.g. U, V, H, etc; depending on what is stored to file
results = zeros (nStations, nSteps, nVariables);
results_test = zeros (nStations, nSteps, nVariables); %testing and comparing between using 1 or the time step number

%get all the values from the results file (which must be single precision)
for j=1:nSteps
    if j/250 == floor (j/250)
        fprintf('%d steps processed.',j);
    end
    
    %Don't know why, but it always has to be one, obviously it is an
    %increment from the current position in that file
    mResult = telstepr(mFile,1) ; %j instead of 1 is not woking properly
    %interpolate all values for all nodes
    results (:,j,:) = mResult.RESULT(indx,:) ;
end


mkdir(basefolder, 'telemac_variables')
path_1 = strcat(basefolder, '/telemac_variables')
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
    for i = 1: nStations
        %through time steps
        my_data = cell(nSteps,2);
        
        for k = 1:nSteps
            my_data{k,1} = my_time(k);
            my_data{k,2} = results(i,k,index_variable);
        end
        T = cell2table(my_data,'VariableNames',{'TimeStep_No', name_naming});
        saving_name = strcat(path_2 , '/', Locations_Names_all(i) , '.dat');
        writetable(T,char(saving_name));
        %file is saved referring to the telemac file name,
        %the variable extracted and the station name
        clear my_data;
        
    end
end

disp('%%finishing time:')
datetime('now')

%% merging velocity components and getting vector magnitudes and directions

indu = find(ismember(extracted_var , 'velocity_u' ));
indv = find(ismember(extracted_var , 'velocity_v' ));

if (~isempty(indu) && ~isempty(indv))
    
    mkdir([basefolder , '/telemac_variables'], 'velocity_uv');
    path_uv = strcat(basefolder, '/telemac_variables/velocity_uv');
    
    for locn=1:length(Locations_Names_all)
        %read velocity u data
        file_id_u = fopen([basefolder , '/telemac_variables/velocity_u/' , Locations_Names_all{locn} , '.dat'] ,'r');
        u_data = textscan(file_id_u, '%{dd/MM/yyyy HH:mm:ss}D%n', 'Delimiter', ',', 'HeaderLines', 1);
        fclose(file_id_u);
        u_dates = u_data{1,1};
        u_velocity = u_data{1,2};
       
        %read velocity u data
        file_id_v = fopen([basefolder , '/telemac_variables/velocity_v/' , Locations_Names_all{locn} , '.dat'] ,'r');
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
        
        %save
        T = cell2table(data_uv,'VariableNames',{'TimeStep_No', 'magnitude' , 'direction' , 'velocity_v' , 'velocity_u'});
        saving_name = strcat(path_uv , '/', Locations_Names_all(locn) , '.dat');
        writetable(T,char(saving_name));
        
        clear data_uv 

    end    
end
