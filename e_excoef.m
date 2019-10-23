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

%%
function e_excoef(common_folder, basefolder, period, stationsDBFile, requiredStationsFile )
%function e_excoef(common_folder, basefolder , main_path , period, k, offset)
%addpath(main_path)

% common_folder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/com';
% basefolder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/res';
% period = timerange('2006-01-01' , '2006-01-31') ;
% k = 147 ;

addpath(strcat(common_folder , '/UtTools'));
load('ut_constants.mat');
pTides = importPTides('pTides.dat');

%importing measurements and simulations tables
%measurements timetable:
filelist_meas = dir(fullfile(strcat(common_folder , '/measurements') , '*wl.dat' ));
filepath_meas = strcat(filelist_meas(1).folder , '/' , filelist_meas(1).name) ;

Ttmeas = readtable(filepath_meas);
try
    Ttmeas.Time = datetime (Ttmeas.Time , 'InputFormat' , 'dd-MM-yyyy HH:mm:ss' );
catch
    %warning(['Error using datetime (line 602)']);
    Ttmeas.Time = datetime (Ttmeas.Time , 'InputFormat' , 'dd.MM.yyyy HH:mm:ss' );
end
Ttmeas = table2timetable(Ttmeas);

%simulations timetable:
filelist_simul = dir(fullfile(strcat(basefolder , '/telemac_variables/variables_all_stations') , 'free_surface_all_stations.dat' ));
filepath_simul = strcat(filelist_simul(1).folder , '/' , filelist_simul(1).name) ;

Ttsimul = readtable(filepath_simul);
Ttsimul.TimeStep_No = datetime (Ttsimul.TimeStep_No , 'InputFormat' , 'dd/MM/yyyy HH:mm:ss' );
Ttsimul = table2timetable(Ttsimul);

%importing required station names
%requiredStationsFile = strcat(common_folder, '/required_stations.dat');
req_data = textread( requiredStationsFile , '%s', 'delimiter', '\n')';

%importing sattion database
%stationsDBFile = strcat(common_folder , '/info_all_stationsNoDashes.dat');
TstationInfo = readtable(stationsDBFile , 'ReadRowNames' , true);

%intersection of required stations, simulations and measurements:
stations = intersect(intersect(Ttmeas.Properties.VariableNames , Ttsimul.Properties.VariableNames) , req_data );

%% check the availability of coef
try
    ex_path_meas = strcat(common_folder , '/coef_measured/A_meas_all_stations.dat');
    ex_main_t_a_meas = readtable(ex_path_meas , 'ReadRowNames' , true);
    
catch
    disp('no previous meas coef are availale')
    ex_main_t_a_meas = [] ;
end

try
    ex_path_simul = strcat(basefolder , '/coef_simulated/A_simul_all_stations.dat');
    ex_main_t_a_simul = readtable(ex_path_simul , 'ReadRowNames' , true);
    
catch
    disp('no previous simul coef are availale')
    ex_main_t_a_simul = [] ;
end

% case 1 where both meas and simul coef are extracted, but some additional
% stations are added to required stations dat file and need to be extracted
if ~isempty(ex_main_t_a_meas) && ~isempty(ex_main_t_a_simul)
    available_stations = ex_main_t_a_meas.Properties.VariableNames ;
    %new stations to be extracted
    stations(ismember(stations , available_stations)) = [] ;
    %in case there is no new stations, quit the script
    if isempty(stations)
        disp('function stopped, no new locations to be extracted')
        return
    end
    %store the existed all stations data, to be joined to the new stations later
    ex_path_1 = strcat(common_folder , '/coef_measured/A_meas_all_stations.dat');
    ex_path_2 = strcat(common_folder , '/coef_measured/g_meas_all_stations.dat');
    ex_path_3 = strcat(basefolder , '/coef_simulated/A_simul_all_stations.dat');
    ex_path_4 = strcat(basefolder , '/coef_simulated/g_simul_all_stations.dat');
    
    ex_main_t_a_meas = readtable(ex_path_1);
    ex_main_t_g_meas = readtable(ex_path_2);
    ex_main_t_a_simul = readtable(ex_path_3);
    ex_main_t_g_simul = readtable(ex_path_4);
    %used for joining later
    ab = 1;
    %ef = 0;added below
end

%case 2 when we are using the measured extracted coef for the second time
%within a new simulation, so the folder of coef is not yet created in the
%basefolder (output folder)
if ~isempty(ex_main_t_a_meas) && isempty(ex_main_t_a_simul)
    %just extract simul coef
    ef = 1;
else
    ef = 0;
end

%%
%cropping tables
Ttmeas_crop = Ttmeas(period , :);
Ttsimul_crop = Ttsimul(period , :);

%creating empty tables
t_empty = cell2table( horzcat(pTides , num2cell(zeros(24,0)) ));
t_empty.Properties.VariableNames = {'tide'} ;

main_t_a_meas = t_empty;
main_t_g_meas = t_empty;
main_t_a_simul = t_empty;
main_t_g_simul = t_empty;

%creating output directories
mkdir(common_folder, 'coef_measured')
path_4 = strcat(common_folder, '/coef_measured');

mkdir(basefolder, 'coef_simulated')
path_5 = strcat(basefolder, '/coef_simulated');

%%
%extracting coef and saving
for cwl=1:length(stations)
    %reading measurements data
    meas_dates = Ttmeas_crop.Time;
    meas_wl = Ttmeas_crop.(stations{cwl});
    
    %checking the amount of NaN in measurements
    TF = ismissing(meas_wl);
    num_NaN = sum(TF) ;
    %if 40% of meas is NaN ignore the station and jump to the next one
    if num_NaN >= 0.4*length(meas_wl)
        X = sprintf('%s is not considered for this period because of high NaNs amount' , string(stations{cwl}) );
        disp(X)
        continue
    end
    
    %reading simulated data
    simul_dates = Ttsimul_crop.TimeStep_No;
    %simul_dates = simul_dates + hours(offset);
    simul_wl = Ttsimul_crop.(stations{cwl});
    
    %constructing timetables
    ttmeas = timetable(meas_dates , meas_wl);
    ttsimul = timetable(simul_dates , simul_wl);
    
    %synchronizing tables
    tt = synchronize(ttmeas , ttsimul);
    
    %removing NaN
    tt_noNaN = rmmissing(tt);
    
    %getting latitude
    lat = TstationInfo{ stations{cwl} , 'Latitude'} ;
    
    %extracting tidal coef
    if ef==0
        tidalcoef_meas = ut_solv(datenum(tt_noNaN.meas_dates),tt_noNaN.meas_wl,[],lat,pTides);
        tidalcoef_simul = ut_solv(datenum(tt_noNaN.meas_dates),tt_noNaN.simul_wl,[],lat,pTides);
        
        %save Amplitude and phasse shift from coef into tables
        t_ag_meas = cell2table(horzcat(tidalcoef_meas.name,num2cell(tidalcoef_meas.A),num2cell(tidalcoef_meas.g)));
        t_ag_meas.Properties.VariableNames = { 'tide' 'A' 'g'} ;
        
        t_a_meas = cell2table(horzcat(tidalcoef_meas.name,num2cell(tidalcoef_meas.A)));
        t_a_meas.Properties.VariableNames = { 'tide' stations{cwl}  } ;
        t_g_meas = cell2table(horzcat(tidalcoef_meas.name,num2cell(tidalcoef_meas.g)));
        t_g_meas.Properties.VariableNames = { 'tide' stations{cwl}  } ;
        
        t_ag_simul = cell2table(horzcat(tidalcoef_simul.name,num2cell(tidalcoef_simul.A),num2cell(tidalcoef_simul.g)));
        t_ag_simul.Properties.VariableNames = { 'tide' 'A' 'g'} ;
        
        t_a_simul = cell2table(horzcat(tidalcoef_simul.name,num2cell(tidalcoef_simul.A)));
        t_a_simul.Properties.VariableNames = { 'tide' stations{cwl}  } ;
        t_g_simul = cell2table(horzcat(tidalcoef_simul.name,num2cell(tidalcoef_simul.g)));
        t_g_simul.Properties.VariableNames = { 'tide' stations{cwl} } ;
        
        main_t_a_meas = join(t_a_meas , main_t_a_meas);
        main_t_g_meas = join(t_g_meas , main_t_g_meas);
        main_t_a_simul = join(t_a_simul , main_t_a_simul);
        main_t_g_simul = join(t_g_simul , main_t_g_simul);
        
        %save coef structure as mat file
        save(strcat(path_4 , '/' ,'coef_of_meas_',stations{cwl}),'tidalcoef_meas');
        save(strcat(path_5 ,  '/' ,'coef_of_simulation_',stations{cwl}),'tidalcoef_simul');
        
        %save A and g for each station
        writetable( t_ag_meas , char( strcat(path_4 , '/' , 'A_g_meas_' ,stations{cwl} , '.dat') ))
        writetable( t_ag_simul , char( strcat(path_5 , '/' , 'A_g_simul_' , stations{cwl} , '.dat') ))
        
        %save A for all stations
        writetable( main_t_a_meas , char( strcat(path_4 , '/' , 'A_meas_all_stations' , '.dat') ))
        writetable( main_t_a_simul , char( strcat(path_5 , '/' , 'A_simul_all_stations' , '.dat') ))
        
        %save g for all stations
        writetable( main_t_g_meas , char( strcat(path_4 , '/' , 'g_meas_all_stations' , '.dat') ))
        writetable( main_t_g_simul , char( strcat(path_5 , '/' , 'g_simul_all_stations' , '.dat') ))
        
    elseif ef==1
        tidalcoef_simul = ut_solv(datenum(tt_noNaN.meas_dates),tt_noNaN.simul_wl,[],lat,pTides);
        
        %save Amplitude and phasse shift from coef into tables
        t_ag_simul = cell2table(horzcat(tidalcoef_simul.name,num2cell(tidalcoef_simul.A),num2cell(tidalcoef_simul.g)));
        t_ag_simul.Properties.VariableNames = { 'tide' 'A' 'g'} ;
        
        t_a_simul = cell2table(horzcat(tidalcoef_simul.name,num2cell(tidalcoef_simul.A)));
        t_a_simul.Properties.VariableNames = { 'tide' stations{cwl}  } ;
        t_g_simul = cell2table(horzcat(tidalcoef_simul.name,num2cell(tidalcoef_simul.g)));
        t_g_simul.Properties.VariableNames = { 'tide' stations{cwl} } ;
        
        main_t_a_simul = join(t_a_simul , main_t_a_simul);
        main_t_g_simul = join(t_g_simul , main_t_g_simul);
        
        %save coef structure as mat file
        save(strcat(path_5 ,  '/' ,'coef_of_simulation_',stations{cwl}),'tidalcoef_simul');
        
        %save A and g for each station
        writetable( t_ag_simul , char( strcat(path_5 , '/' , 'A_g_simul_' , stations{cwl} , '.dat') ))
        
        %save A for all stations
        writetable( main_t_a_simul , char( strcat(path_5 , '/' , 'A_simul_all_stations' , '.dat') ))
        
        %save g for all stations
        writetable( main_t_g_simul , char( strcat(path_5 , '/' , 'g_simul_all_stations' , '.dat') ))
    end
    clear('tidalcoef_meas');
    clear('tidalcoef_simul');
end

try
    if ab==1
        %save A for all stations
        writetable( join(ex_main_t_a_meas , main_t_a_meas ) , char( strcat(path_4 , '/' , 'A_meas_all_stations' , '.dat') ))
        writetable( join(ex_main_t_a_simul , main_t_a_simul ) , char( strcat(path_5 , '/' , 'A_simul_all_stations' , '.dat') ))
        
        %save g for all stations
        writetable( join(ex_main_t_g_meas , main_t_g_meas ) , char( strcat(path_4 , '/' , 'g_meas_all_stations' , '.dat') ))
        writetable( join(ex_main_t_g_simul , main_t_g_simul ) , char( strcat(path_5 , '/' , 'g_simul_all_stations' , '.dat') ))
    end
catch
    disp('no previous coef')
end

end
