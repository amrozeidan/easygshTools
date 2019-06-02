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
% d) date_a (starting date, give as 'datenum(YYYY,MM,DD,hh,mm,ss)')
% e) period (days)
% f) k moving average steps

function d_wlcomp( common_folder , basefolder , main_path , date_a , period , k, offset)

addpath(main_path)

%% checking if required_stations_data.dat file is available, if not run 'wlfileprep' function to generate it
listing_common_folder = dir(common_folder);
common_folder_file_name = {};
for f=1:length(listing_common_folder)
    common_folder_file_name = vertcat(common_folder_file_name , listing_common_folder(f).name) ;
end
indi = find(ismember(common_folder_file_name , 'required_stations_data_free_surface.dat' ));

if isempty(indi)
    c_wlfileprep (common_folder , basefolder )
else
end


%% comparison of water levels based on stations------------------------------

%reading data directories to be compared
file_id = fopen( strcat(common_folder , '/required_stations_data_free_surface.dat') ,'r');
data = textscan(file_id, '%s%s%s%n%n%n%n', 'Delimiter', ',', 'HeaderLines', 1);
fclose(file_id);
data_meas_file_name_with_directory_req = data{1,2};
data_wl_simulated_file_name_with_directory_req = data{1,3};
Locations_Names = data{1,1};

data_nrmse = [];
data_rmse = [];
data_mae = [];

%creating folders for results storage
mkdir(basefolder, 'wl_comparison')
path_3 = strcat(basefolder, '/wl_comparison') ;

mkdir(strcat(common_folder, '/measurements') , 'free_surface_cropped')
path_meas_up = strcat(common_folder , '/measurements/free_surface_cropped');

mkdir(strcat(basefolder,'/telemac_variables') , 'free_surface_cropped')
path_simul_up = strcat(basefolder , '/telemac_variables/free_surface_cropped');

mkdir(strcat(common_folder, '/measurements') , 'variables_all_stations')
path_meas_all_var_sta = strcat(common_folder , '/measurements/variables_all_stations');

mkdir(strcat(basefolder,'/telemac_variables') , 'variables_all_stations')
path_simul_all_var_sta = strcat(basefolder , '/telemac_variables/variables_all_stations');

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

TT_main_wl_meas_for_comp = timetable(date_a,0);
TT_main_wl_simul_for_comp = timetable(date_a,0);

TT_main_wl_diff = timetable(date_a,0);
TT_main_mov_avg = timetable(date_a,0);

for cwl=1:length(data_meas_file_name_with_directory_req)
    %reading measurements data
    file_id_meas = fopen(data_meas_file_name_with_directory_req{cwl} ,'r');
    data_meas_file_name_with_directory_req{cwl}
    %%%%for standard format of measurments dat files
    %     meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D%n', 'Delimiter', ';', 'HeaderLines', 12);
    %     fclose(file_id_meas);
    %     meas_dates = meas_data{1,1};
    %     meas_wl = meas_data{1,2};
    
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
    
    meas_data = textscan(file_id_meas, '%{dd.MM.yyyy HH:mm:ss}D %f %f', 'Delimiter', ';', 'HeaderLines', l);
    fclose(file_id_meas);
    meas_dates = meas_data{1,1};
    meas_wl = meas_data{1,2};
    
    %reading simulated data
    file_id_wl_simulated = fopen(data_wl_simulated_file_name_with_directory_req{cwl} ,'r');
    data_wl_simulated_file_name_with_directory_req{cwl}
    wl_simulated_data = textscan(file_id_wl_simulated, '%{dd/MM/yyyy HH:mm:ss}D%n', 'Delimiter', ',', 'HeaderLines', 1);
    fclose(file_id_wl_simulated);
    wl_simulated_dates = wl_simulated_data{1,1};
    wl_simulated_dates = wl_simulated_dates + hours(offset);
    wl_simulated_wl = wl_simulated_data{1,2};
    
    %%%%%%%%%%%%%%%dates addition%%%%%%%%%%%%%%%%%%%%%
    %converting meas_dates and wl_simulated_dates to yyyymmdd
    for i=1:length(meas_dates)
        meas_dates_as_ymd(i) = yyyymmdd(meas_dates(i));
    end
    for i=1:length(wl_simulated_dates)
        wl_simulated_dates_as_ymd(i) = yyyymmdd(wl_simulated_dates(i));
    end
    
    %find indices of the required period
    [~ ,idx_meas] = find(ismember(meas_dates_as_ymd, req_time_as_ymd));
    [~ ,idx_simul] = find(ismember(wl_simulated_dates_as_ymd, req_time_as_ymd));
    %extract final time from my_time
    meas_dates_for_comp = meas_dates(idx_meas);
    wl_simulated_dates_for_comp = wl_simulated_dates(idx_simul);
    %and water level values
    meas_wl_for_comp = meas_wl(idx_meas);
    wl_simulated_wl_for_comp = wl_simulated_wl(idx_simul);
    %ignoring the replaced value -777.0 for the missed data generated by
    %zeitrio for measurements
    %TODO: Read the no value entry from the zeitrio file
    index_777 = find(meas_wl_for_comp < -100.00);
    meas_wl_for_comp(index_777) = NaN ;

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
% %     %plots, water level
% %     h = figure('visible','on');
% %     plot(meas_dates_for_comp,meas_wl_for_comp,wl_simulated_dates_for_comp,wl_simulated_wl_for_comp);
% %     title(strcat('Water Level comparison,', ' Station : ', Locations_Names(cwl)));
% %     legend('Measurements','Simulations');
% %     xlabel('Date/Time');
% %     ylabel('Water Level [m]');
% %     save_name = strcat(path_3, '/','Water Level comparison', '_Station_', Locations_Names{cwl});
% %     savefig(h, save_name, 'compact');
% %     saveas(gca, save_name , 'jpeg');
% %     clf
% %     close(h)
    
    %%%%%%%%%%%%%%%%%%%%%
    %constructing timetables
    TT_meas = timetable(meas_dates_for_comp , meas_wl_for_comp);
    TT_simul = timetable(wl_simulated_dates_for_comp , wl_simulated_wl_for_comp);
    %synchronising
    TT_meas_simul_sync = synchronize(TT_meas,TT_simul);
    %removing NaN (missing data) from timetable for both measured and simulated data(just in case)
    TT_meas_simul_sync_no_NaN = rmmissing(TT_meas_simul_sync);
    %taking back the data from timetable
    date_sync_no_NaN = timetable2table(TT_meas_simul_sync_no_NaN);
    date_sync_no_NaN = table2array(date_sync_no_NaN(:,1));
    TT_meas_simul_sync_no_NaN_c = table2cell(timetable2table(TT_meas_simul_sync_no_NaN));
    wl_meas_sync_no_NaN = cell2mat(TT_meas_simul_sync_no_NaN_c(:,2));
    wl_simul_sync_no_NaN = cell2mat(TT_meas_simul_sync_no_NaN_c(:,3)) ;
    %for saving
    my_data_1 = cell(length(date_sync_no_NaN),2);
    my_data_2 = cell(length(date_sync_no_NaN),2);
    for d=1:length(date_sync_no_NaN)
        my_data_1{d,1} = date_sync_no_NaN(d);
        my_data_1{d,2} = wl_meas_sync_no_NaN(d);
        my_data_2{d,1} = date_sync_no_NaN(d);
        my_data_2{d,2} = wl_simul_sync_no_NaN(d);
    end
    
    %saving wl for all stations in the same dat file; measured and
    %simulated 
    TT_main_wl_meas_for_comp = synchronize(TT_main_wl_meas_for_comp,TT_meas);
    TT_main_wl_simul_for_comp = synchronize(TT_main_wl_simul_for_comp,TT_simul);
    
    %saving adjusted dates and values into tables, to be used in e_excoef
    %function
    T_1 = cell2table(my_data_1,'VariableNames',{'TimeStep', 'WaterLevel'});
    saving_name = strcat(path_meas_up , '/', Locations_Names{cwl} , '.dat');
    writetable(T_1,char(saving_name));
    T_2 = cell2table(my_data_2,'VariableNames',{'TimeStep', 'WaterLevel'});
    saving_name = strcat(path_simul_up , '/', Locations_Names{cwl} , '.dat');
    writetable(T_2,char(saving_name));
    
    %water level difference
    wl_diff = wl_simul_sync_no_NaN - wl_meas_sync_no_NaN ;
    TT_wl_diff = timetable(date_sync_no_NaN , wl_diff ); 
    % wl diff timetable, to synchronize all differences together, in case
    % the array are not having similar sizes
    TT_main_wl_diff = synchronize(TT_main_wl_diff,TT_wl_diff);
    
    %moving average
    mov_avg = movmean(wl_diff , k);
    TT_mov_avg = timetable(date_sync_no_NaN , mov_avg );
    TT_main_mov_avg = synchronize(TT_main_mov_avg , TT_mov_avg);
    
% %     %plots, water level difference
% %     h = figure('visible','on');
% %     bar(date_sync_no_NaN, wl_diff);
% %     title(strcat('Water Level difference,', ' Station : ', Locations_Names(cwl)));
% %     xlabel('Date/Time');
% %     ylabel('Water Level [m]');
% %     save_name = strcat(path_3, '/','Water Level difference', '_Station_', Locations_Names{cwl});
% %     savefig(h, save_name, 'compact');
% %     saveas(gca, save_name , 'jpeg');
% %     clf
% %     close(h)
    
% %     % water level comparison and difference (same plot different axes)
% %     h = figure('visible','on');
% %     
% %     yyaxis left
% %     plot(meas_dates_for_comp,meas_wl_for_comp,'-b');
% %     hold on
% %     plot(wl_simulated_dates_for_comp,wl_simulated_wl_for_comp,'-r');
% %     
% %     yyaxis right
% %     bar(date_sync_no_NaN, wl_diff);
% %     
% %     set(gca,'ylim',[0 15])
% %     set(gca, 'YDir','reverse')
% %     
% %     title(strcat('Water Level comparison and difference,', ' Station : ', Locations_Names(cwl)));
% %     xlabel('Date/Time');
% %     yyaxis left
% %     ylabel('Water Level [m]');
% %     yyaxis right
% %     ylabel('Water Level Difference [m]');
% %     legend('Measurements','Simulations','Difference');
% %     
% %     save_name = strcat(path_3, '/','Water Level comparison and difference', '_Station_', Locations_Names{cwl});
% %     savefig(h, save_name, 'compact');
% %     saveas(gca, save_name , 'jpeg');
% %     clf
% %     close(h)
    %subplots of water level comparison and difference
    h = figure('visible','off');
    
    ax1 = subplot(2,1,1);
    plot(meas_dates_for_comp,meas_wl_for_comp,'-b');
    hold on
    plot(wl_simulated_dates_for_comp,wl_simulated_wl_for_comp,'-r');
    hold on
    plot(date_sync_no_NaN, wl_diff);
    title(strcat('Water Level comparison,', ' Station : ', Locations_Names(cwl)));
    legend('Measurements','Simulations','Differences');
    lgd.NumColumns = 3;
    ylabel('Water Level [m+NHN]/ Differences [m]');
    set(gca,'FontSize',6)
    ylim([-5 5])
    
    ax2 = subplot(2,1,2);
    plot(date_sync_no_NaN, wl_diff);
    title(strcat('Water Level difference,', ' Station : ', Locations_Names(cwl)));
    xlabel('Date/Time');
    ylabel('Water Level Difference [m]');
    set(gca,'FontSize',6)
    ylim([-0.75 0.75])
    
    if ~isempty(date_sync_no_NaN)
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
    
    save_name = strcat(path_3, '/','Water Level comparison and difference', '_Station_', Locations_Names{cwl});
%    savefig(h, save_name, 'compact');
    saveas(gca, save_name , 'jpeg');
    clf
    close(h)
    
    
    %plotting scatter diagram
    h = figure('visible','off');
    scatter(wl_simul_sync_no_NaN,wl_meas_sync_no_NaN,'k')
    refline(1,0)
    title(strcat('Water Level comparison,', ' Station : ', Locations_Names(cwl)));
    xlabel('Simulated WL [m]');
    ylabel('Measured WL [m]');
    save_name_scatter = strcat(path_3, '/','Water Level Scatter', '_Station_', Locations_Names{cwl});
%    savefig(save_name_scatter);
    saveas(gca, save_name_scatter , 'jpeg');
    clf
    close (h)
    
    %normalized root mean square error
    rmse = sqrt(sum((wl_simul_sync_no_NaN(:)-wl_meas_sync_no_NaN(:)).^2)/numel(wl_meas_sync_no_NaN));
    mae = sum((wl_simul_sync_no_NaN(:)-wl_meas_sync_no_NaN(:))/numel(wl_meas_sync_no_NaN));
    
    if isnan(rmse)
        nrmse = NaN
    else
		nrmse=(rmse/((max(wl_meas_sync_no_NaN(:))-(min(wl_meas_sync_no_NaN(:))))));
	end
	data_nrmse = vertcat(data_nrmse ,horzcat(Locations_Names(cwl), nrmse));
	data_rmse = vertcat(data_rmse ,horzcat(Locations_Names(cwl), rmse));
    data_mae = vertcat (data_mae ,horzcat (Locations_Names(cwl), mae));
end


%% extracting wl differences and wl differences moving averages for all stations 
header_main = ['Date' , Locations_Names'];

%transferring to cell and removing the second column, which is a NaN
%column used for concatination only
main_wl_diff_c = table2cell(timetable2table(TT_main_wl_diff));
main_wl_diff_c(:,2) = [];
main_mov_avg_c = table2cell(timetable2table(TT_main_mov_avg));
main_mov_avg_c(:,2) = [];
%saving
T_3 = cell2table(main_wl_diff_c,'VariableNames', header_main);
saving_name = strcat(path_3 , '/', 'WL_Difference_all_stations' , '.dat');
writetable(T_3,char(saving_name));
T_4 = cell2table(main_mov_avg_c,'VariableNames',header_main);
saving_name = strcat(path_3 , '/', 'WL_DifferenceMovingAvg_all_stations' , '.dat');
writetable(T_4,char(saving_name));

%% extracting measured and simulated wl for all stations (for comparison)
main_wl_meas_for_comp_c = table2cell(timetable2table(TT_main_wl_meas_for_comp ));
main_wl_meas_for_comp_c(:,2) = [];

main_wl_simul_for_comp_c = table2cell(timetable2table(TT_main_wl_simul_for_comp));
main_wl_simul_for_comp_c(:,2) = [];

T_5 = cell2table(main_wl_meas_for_comp_c,'VariableNames', header_main);
saving_name = strcat(path_meas_all_var_sta , '/', 'free_surface_all_stations_cropped' , '.dat');
writetable(T_5,char(saving_name));

T_6 = cell2table(main_wl_simul_for_comp_c,'VariableNames',header_main);
saving_name = strcat(path_simul_all_var_sta , '/', 'free_surface_stations_cropped' , '.dat');
writetable(T_6,char(saving_name));


%% plot nrmse for locations--------------------------------------------------
h = figure('visible','off');
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
h = figure('visible','off');
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
%end

%save the new paths to an updated dat file
fid  = fopen( strcat(common_folder , '/required_stations_data_free_surface.dat') ,'r');
f=fread(fid,'*char')';
fclose(fid);
%f = strrep(f,'folder_meas','folder_meas_updated');
f = strrep(f,'free_surface','free_surface_cropped');
fid  = fopen( strcat(common_folder ,'/required_stations_data_free_surface_cropped.dat'),'w');
fprintf(fid,'%s',f);
fclose(fid);
