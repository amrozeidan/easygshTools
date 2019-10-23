%% description of 'f_ptcomp' function
% aims to store he amplitudes and pahe shifts for the required stations
% based on ides ypes for both measurements and simulations (A and g are
%extracted from the 'excoef' extracted coefficients), and then compares
% and plots them.

%usage: arguments:
%a)common_folder
%b)basefolder

%ptcomp has no third argument like the previous version ptcomp,it will
%automatically check if A_g_measured folder is already created in the
%common folder (which means that the sorted parameters of the measurements are
%already extracted), in case A_g_measured exists  the function will
%extract the sorted parameters of the simulations only, in case it does not
%exist both sorted parameters for measurements and simulations are extracted.

function f_ptcomp(common_folder , basefolder, stationsDBFile)

% common_folder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/com';
% basefolder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/res';

%import station database
%stationsDBFile = strcat(common_folder , '/info_all_stationsNoDashes.dat');
TstationInfo = readtable(stationsDBFile , 'ReadRowNames' , true);

%import tables of A and g for all stations
T_a_meas = readtable(strcat(common_folder , '/coef_measured/A_meas_all_stations.dat') , 'ReadRowNames' , true);
T_g_meas = readtable(strcat(common_folder , '/coef_measured/g_meas_all_stations.dat') , 'ReadRowNames' , true);
T_a_simul = readtable(strcat(basefolder , '/coef_simulated/A_simul_all_stations.dat') , 'ReadRowNames' , true);
T_g_simul = readtable(strcat(basefolder , '/coef_simulated/g_simul_all_stations.dat') , 'ReadRowNames' , true);

%get tides and stations from any table
tides = T_a_meas.Properties.RowNames ;
stations = T_a_meas.Properties.VariableNames ;

%sort stations referring to database order
stations_no = cellfun(@(x) TstationInfo{ x, 'StationNo'} , stations) ; 
stations_no_sorted = sort(stations_no) ;
stations_sorted = TstationInfo.Properties.RowNames(stations_no_sorted)' ;

%adjust tables
T_a_meas = T_a_meas(: , stations_sorted);
T_g_meas = T_g_meas(: , stations_sorted);
T_a_simul = T_a_simul(: , stations_sorted);
T_g_simul = T_g_simul(: , stations_sorted);

%output directory
mkdir(basefolder, 'pt_comparison')
path_1 = strcat(basefolder, '/pt_comparison');

%comparison
for t=1:length(tides)
    
    meas_A = T_a_meas{tides(t) , :} ;
    meas_g = T_g_meas{tides(t) , :} ;
    simul_A = T_a_simul{tides(t) , :} ;
    simul_g = T_g_simul{tides(t) , :} ;
    
    axisFontSize = 6;
    %A plots
    h = figure('visible','off');
    ax1 = subplot(2,1,1);
    plot(meas_A,'rx')
    hold on
    plot(simul_A,'bx')
    legend('Measured','Simulated');
    set(gca, 'XTick', 1:length(stations_sorted))
    set(gca,'XtickLabel',stations_sorted)
    set(gca,'FontSize',axisFontSize);
    xlim([0 length(stations_sorted)]);
    title(strcat('Amplitude comparison', ' for tide : ', tides{t}));
    ylabel('Amplitude [m]');
    ylim([0 3]);
    length(stations_sorted)
    
    dff = simul_A - meas_A;
    
    ax2 = subplot(2,1,2);
    plot(dff, 'kx')
    set(gca, 'XTick', 1:length(stations_sorted))
    set(gca,'XtickLabel',stations_sorted)
    set(gca,'FontSize',axisFontSize);
    xlim([0 length(stations_sorted)]);
    title(strcat('Amplitude difference', ' for tide : ', tides{t}));
    xlabel('Stations');
    ylabel('Amplitude Difference [m]');
    ylim([-0.3 0.3]);
    
    linkaxes([ax1 , ax2] , 'x');
    
    grid(ax1,'on');
    grid(ax2,'on');
    pbaspect(ax1 , 'auto') %or [x y z]
    pbaspect(ax2 , 'auto')
    
    %set(ax1,'position',[.1 .4 .8 .5])
    %set(ax2,'position',[.1 .1 .8 .3])
    
    xtickangle(ax1,45);
    xtickangle(ax2,45);
    
    save_name_A = strcat(path_1, '/','A_comparison_tide_', tides{t});
    saveas(gca, save_name_A , 'jpeg');
    clf
    close(h)
   
    %g plots
    h = figure('visible','off');
    ax1 = subplot(2,1,1);
    plot(meas_g,'rx')
    hold on
    plot(simul_g,'bx')
    legend('Measured','Simulated');
    set(gca, 'XTick', 1:length(stations_sorted))
    set(gca,'XtickLabel',stations_sorted)
    set(gca,'FontSize',axisFontSize);
    xlim([0 length(stations_sorted)]);
    title(strcat('Phase comparison', ' for tide : ', tides{t}));
    ylabel('Phase [°]');
    ylim([0 360])
    
    dff = simul_g - meas_g;
    
    ax2 = subplot(2,1,2);
    plot(dff, 'kx')
    set(gca, 'XTick', 1:length(stations_sorted))
    set(gca,'XtickLabel',stations_sorted)
    set(gca,'FontSize',axisFontSize);
    xlim([0 length(stations_sorted)]);
    xlabel('Stations');
    ylabel('Phase shift [°]');
    ylim([-30 30])
    
    linkaxes([ax1 , ax2] , 'x');
    
    grid(ax1,'on');
    grid(ax2,'on');
    pbaspect(ax1 , 'auto') %or [x y z]
    pbaspect(ax2 , 'auto')
    
    %set(ax1,'position',[.1 .4 .8 .5])
    %set(ax2,'position',[.1 .1 .8 .3])
    
    xtickangle(ax1,45);
    xtickangle(ax2,45);
    
    save_name_g = strcat(path_1, '/','g_comparison_tide_', tides{t});
    saveas(gca, save_name_g , 'jpeg');
    clf
    close(h)
    
end

end


