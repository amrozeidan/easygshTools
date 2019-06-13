%% description of 'd_wlcomp' function
%************************************
%aims to compare measured and simulated water levels of the required
%stations referring to required_stations_data_free_surface.dat information.
%plots:
%
% a) measured vs simulated data, their difference based on the required locations
% b) water level scatter diagram based on required locations
% c) Normalised Root Mean Square Error based on required locations

%stores all the previous plots as .fig and .jpeg

%usage: argumets:
%****************
% a) common_folder
% b) basefolder
% c) main_path (path of functions)
% d) period , has to be defined as timerange :
%    for example: timerange('2006-01-01' , '2006-03-01')
%    covering Jan and Feb
% e) k moving average steps

function d_wlcomp( common_folder , basefolder , period , k, offset)

% main_path = '/Users/amrozeidan/Desktop/EasyGSH/3_functions_rev16c_20190523';
% addpath(main_path)

% common_folder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/com';
% basefolder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/res';
% period = timerange('2006-01-01' , '2006-01-31') ;
% k = 147 ;

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
%done in measprep.m already
% %filling the missed values (-9999.00) with NaN
% Ttmeas = standardizeMissing(Ttmeas , {-99999.0} , 'DataVariables' , Ttmeas.Properties.VariableNames);

%simulations timetable:
filelist_simul = dir(fullfile(strcat(basefolder , '/telemac_variables/variables_all_stations') , 'free_surface_all_stations.dat' ));
filepath_simul = strcat(filelist_simul(1).folder , '/' , filelist_simul(1).name) ;

Ttsimul = readtable(filepath_simul);
Ttsimul.TimeStep_No = datetime (Ttsimul.TimeStep_No , 'InputFormat' , 'dd/MM/yyyy HH:mm:ss' );
Ttsimul = table2timetable(Ttsimul);

%importing required station names
filepath_req = strcat(common_folder, '/required_stations.dat');
req_data = textread( filepath_req , '%s', 'delimiter', '\n')';

%intersection of required stations, simulations and measurements:
stations = intersect(intersect(Ttmeas.Properties.VariableNames , Ttsimul.Properties.VariableNames) , req_data );

%%

data_nrmse = [];
data_rmse = [];
data_mae = [];

%creating folders for results storage
mkdir(basefolder, 'wl_comparison')
path_3 = strcat(basefolder, '/wl_comparison') ;

path_4 = strcat(common_folder , '/measurements') ;
path_5 = strcat(basefolder , '/telemac_variables/variables_all_stations') ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %updating timetables for all stations
% % Ttmeas_crop = Ttmeas(period , :);
% % Ttmeas_crop_noNaN = rmmissing(Ttmeas_crop);
% % 
% % Ttsimul_crop = Ttsimul(period , :);
% % Ttsimul_crop_noNaN = rmmissing(Ttsimul_crop);
% % 
% % %then saving
% % T_5 = timetable2table(Ttmeas_crop_noNaN);
% % saving_name = strcat( path_4 , '/', filelist_meas(1).name(1:4) ,'.wl.crop' , '.dat');
% % writetable(T_5,char(saving_name));
% % 
% % T_6 = timetable2table(Ttsimul_crop_noNaN);
% % saving_name = strcat(path_5 , '/', 'free_surface_all_stations_cropped' , '.dat');
% % writetable(T_6,char(saving_name));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for cwl=1:length(stations)
    %reading measurements data
    meas_dates = Ttmeas.Time;
    meas_wl = Ttmeas.(stations{cwl});
    
    %reading simulated data
    simul_dates = Ttsimul.TimeStep_No;
    %simul_dates = simul_dates + hours(offset);
    simul_wl = Ttsimul.(stations{cwl});
    
    %constructing timetables
    ttmeas = timetable(meas_dates , meas_wl);
    ttsimul = timetable(simul_dates , simul_wl);
    
    %timetables covering the required period for comparison
    ttmeas = ttmeas(period , :);
    ttsimul = ttsimul(period , :);
    
    %synchronizing tables
    tt = synchronize(ttmeas , ttsimul);
    
    %synchronized table without NaN for comparison (differences)
    ttcomp_noNaN = rmmissing(tt);
    
    %water level difference
    wl_diff = ttcomp_noNaN.simul_wl - ttcomp_noNaN.meas_wl ;
    TT_wl_diff = timetable(ttcomp_noNaN.meas_dates , wl_diff );
    %wl difference main table containing all stations
    if cwl ==1
        TT_wl_diff_main = TT_wl_diff;
    else
        TT_wl_diff_main = synchronize(TT_wl_diff_main , TT_wl_diff);
    end
    
    %moving average
    mov_avg = movmean(wl_diff , k);
    TT_mov_avg = timetable(ttcomp_noNaN.meas_dates , mov_avg );
    %moving average main table , all stations
    if cwl ==1
        TT_mov_avg_main = TT_mov_avg;
    else
        TT_mov_avg_main = synchronize(TT_mov_avg_main , TT_mov_avg);
    end
    
    %subplots of water level comparison and difference
    h = figure('visible','off');
    
    ax1 = subplot(2,1,1);
    plot(ttmeas.meas_dates , ttmeas.meas_wl ,'-b');
    hold on
    plot(ttsimul.simul_dates , ttsimul.simul_wl ,'-r');
    hold on
    plot(ttcomp_noNaN.meas_dates , wl_diff);
    title(strcat('Water Level comparison,', ' Station : ', stations(cwl)));
    legend('Measurements','Simulations','Differences');
    lgd.NumColumns = 3;
    ylabel('Water Level [m+NHN]/ Differences [m]');
    set(gca,'FontSize',6)
    ylim([-5 5])
    
    ax2 = subplot(2,1,2);
    plot(ttcomp_noNaN.meas_dates, wl_diff);
    title(strcat('Water Level difference,', ' Station : ', stations(cwl)));
    xlabel('Date/Time');
    ylabel('Water Level Difference [m]');
    set(gca,'FontSize',6)
    ylim([-0.75 0.75])
    
    if ~isempty(ttcomp_noNaN.meas_dates)
        linkaxes([ax1 , ax2] , 'x');
    end
    
    grid(ax1,'on');
    grid(ax2,'on');
    ax1.FontSize = 6;
    ax2.FontSize = 6;
    pbaspect(ax1 , 'auto') %[x y z]
    pbaspect(ax2 , 'auto')
    
    %set(ax1,'position',[.1 .4 .8 .5])
    %set(ax2,'position',[.1 .1 .8 .3])
    
    save_name = strcat(path_3, '/','Water Level comparison and difference', '_Station_', stations{cwl});
    %    savefig(h, save_name, 'compact');
    saveas(gca, save_name , 'jpeg');
    clf
    close(h)
    
    
    %plotting scatter diagram
    h = figure('visible','off');
    scatter(ttcomp_noNaN.simul_wl , ttcomp_noNaN.meas_wl ,'k')
    refline(1,0)
    title(strcat('Water Level comparison,', ' Station : ', stations(cwl)));
    xlabel('Simulated WL [m]');
    ylabel('Measured WL [m]');
    save_name_scatter = strcat(path_3, '/','Water Level Scatter', '_Station_', stations{cwl});
    %    savefig(save_name_scatter);
    saveas(gca, save_name_scatter , 'jpeg');
    clf
    close (h)
    
    %normalized root mean square error
    rmse = sqrt(sum((ttcomp_noNaN.simul_wl(:)-ttcomp_noNaN.meas_wl(:)).^2)/numel(ttcomp_noNaN.meas_wl));
    mae = sum((ttcomp_noNaN.simul_wl(:)-ttcomp_noNaN.meas_wl(:))/numel(ttcomp_noNaN.meas_wl));
    
    if isnan(rmse)
        nrmse = NaN
    else
        nrmse=(rmse/((max(ttcomp_noNaN.meas_wl(:))-(min(ttcomp_noNaN.meas_wl(:))))));
    end
    data_nrmse = vertcat(data_nrmse ,horzcat(stations(cwl), nrmse));
    data_rmse = vertcat(data_rmse ,horzcat(stations(cwl), rmse));
    data_mae = vertcat (data_mae ,horzcat (stations(cwl), mae));
end


%% saving wl differences and wl differences moving averages for all stations

TT_wl_diff_main.Properties.VariableNames = stations' ;
TT_mov_avg_main.Properties.VariableNames = stations' ;

T_3 = timetable2table(TT_wl_diff_main);
saving_name = strcat(path_3 , '/', 'WL_Difference_all_stations' , '.dat');
writetable(T_3,char(saving_name));
T_4 = timetable2table(TT_mov_avg_main);
saving_name = strcat(path_3 , '/', 'WL_DifferenceMovingAvg_all_stations' , '.dat');
writetable(T_4,char(saving_name));

%% plot nrmse for locations--------------------------------------------------
h = figure('visible','on');
plot(cell2mat(data_nrmse(:,2)),'rx')
set(gca, 'XTick', 1:length(data_nrmse))
set(gca,'XtickLabel',data_nrmse(:,1))
set(gca,'FontSize',6)
ylim([0 0.5])
title('NRMSE of WL on the required locations');
xlabel('Stations');
ylabel('NRMSE');
xtickangle(45);
save_name_NRMSE = strcat(path_3, '/','NRMSE of WL on the required locations');
% savefig(save_name_NRMSE);
saveas(gca, save_name_NRMSE , 'jpeg');
clf
close(h)

% plot rmse for locations--------------------------------------------------
h = figure('visible','on');
ax1 = subplot(2,1,1);
plot(cell2mat(data_rmse(:,2)),'rx')
set(gca, 'XTick', 1:length(data_rmse))
set(gca,'XtickLabel',data_rmse(:,1))
set(gca,'FontSize',6)
ylim([0 0.5])
title('RMSE of water level [m]');
% xlabel('Stations');
ylabel('RMSE');
xtickangle(45);
%save_name_RMSE = strcat(path_3, '/','RMSE of WL on the required locations');
% savefig(save_name_RMSE);
%saveas(gca, save_name_RMSE , 'jpeg');

ax2 = subplot(2,1,2);
plot(cell2mat(data_mae(:,2)),'rx')
set(gca, 'XTick', 1:length(data_mae))
set(gca,'XtickLabel',data_mae(:,1))
set(gca,'FontSize',6)
ylim([-0.2 0.2])
title('MAE of water level [m]');
xlabel('Stations');
ylabel('MAE');
xtickangle(45);

grid(ax1,'on');
grid(ax2,'on');
ax1.FontSize = 6;
ax2.FontSize = 6;
pbaspect(ax1 , 'auto') %[x y z]
pbaspect(ax2 , 'auto')

save_name_RMSE = strcat(path_3, '/','RMSE of WL on the required locations');
% savefig(save_name_RMSE);
saveas(gca, save_name_RMSE , 'jpeg');
clf
close(h)

close all

end

