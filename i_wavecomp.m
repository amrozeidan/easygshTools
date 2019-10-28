


%% i_wavecomp
function i_wavecomp (common_folder , basefolder , period, offset, requiredStationsFile )

% common_folder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/com';
% basefolder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/res';
% period = timerange('2006-01-01' , '2006-01-31') ;


%importing measurements and simulations tables
%measurements timetable:
filelist_meas = dir(fullfile(strcat(common_folder , '/measurements') , '*wv.dat' ));
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
filelist_simul = dir(fullfile(strcat(basefolder , '/telemac_variables/variables_all_stations') , 'wave_all_stations.dat' ));
filepath_simul = strcat(filelist_simul(1).folder , '/' , filelist_simul(1).name) ;

Ttsimul = readtable(filepath_simul);
% Ttsimul.TimeStep_No = datetime (Ttsimul.TimeStep_No , 'InputFormat' , 'dd/MM/yyyy HH:mm:ss' );
% Ttsimul = table2timetable(Ttsimul);
Ttsimul.TimeStep_No = datetime (Ttsimul.TimeStep_No, 'InputFormat' , 'dd/MM/yyyy HH:mm:ss' );
Ttsimul = table2timetable(Ttsimul);

%importing required station names
%requiredStationsFile = strcat(common_folder, '/required_stations.dat');
req_data = textread( requiredStationsFile , '%s', 'delimiter', '\n')';
%add wave components to required stations names
add_name = {'_mvd' , '_pwp' , '_mwp' , '_swh' } ;
req_data_n = cellfun(@(x) strcat(x , add_name) , cellstr(req_data) , 'Uniformoutput', 0) ;
req_data_n_all = [] ;
for cu=1:numel(req_data_n)
    req_data_n_all = [req_data_n_all , req_data_n{cu}] ;
end

%intersection of required stations, simulations and measurements:
%station names from meas timetable without the depth
stations_meas = Ttmeas.Properties.VariableNames ;
stations_simul = Ttsimul.Properties.VariableNames  ;
stations = intersect(intersect( stations_meas , stations_simul) , req_data_n_all );



mkdir(basefolder, 'wave_comparison')
path_3 = strcat(basefolder, '/wave_comparison') ;

wave_comp_shrt = {'mvd' 'swh' 'pwp' 'mwp'}';
wave_comp = {'Mean wave direction' 'Wave height' 'Peak wave period' 'Mean wave period'}';
Twc = table( wave_comp , 'RowNames' , wave_comp_shrt );


for cwl=1:length(stations)
    
    %getting depth of measured velocity
    fullname_meas = Ttmeas.Properties.VariableNames{stations{cwl}} ;
    component = fullname_meas(end-2:end);
    component_plot = Twc.wave_comp(component);
    station_plot = fullname_meas(1:end-4);
    
    %reading measurements data
    meas_dates = Ttmeas.Time;
    meas_wc = Ttmeas.(stations{cwl});
    
    %reading simulated data
%     simul_dates = Ttsimul.TimeStep_No;
    simul_dates = Ttsimul.TimeStep_No;
    %simul_dates = simul_dates + hours(offset);
    simul_wc = Ttsimul.(stations{cwl});
    
    %constructing timetables
    ttmeas = timetable(meas_dates , meas_wc);
    ttsimul = timetable(simul_dates , simul_wc);
    
    %timetables covering the required period for comparison
    ttmeas = ttmeas(period , :);
    ttsimul = ttsimul(period , :);
    
    %synchronizing tables
    tt = synchronize(ttmeas , ttsimul);
    
    %synchronized table without NaN for comparison (differences)
    ttcomp_noNaN = rmmissing(tt);
    
    %magnitude/direction difference
    vc_diff = ttcomp_noNaN.simul_wc - ttcomp_noNaN.meas_wc ;
    TT_vc_diff = timetable(ttcomp_noNaN.meas_dates , vc_diff );
    %salinity difference main table containing all stations
    if cwl ==1
        TT_vc_diff_main = TT_vc_diff;
    else
        TT_vc_diff_main = synchronize(TT_vc_diff_main , TT_vc_diff);
    end
    
    %normalized root mean square error
    rmse = sqrt(sum((ttcomp_noNaN.simul_wc(:)-ttcomp_noNaN.meas_wc(:)).^2)/numel(ttcomp_noNaN.simul_wc))
    mae = sum((ttcomp_noNaN.simul_wc(:)-ttcomp_noNaN.meas_wc(:))/numel(ttcomp_noNaN.simul_wc))

    
    %subplots of velocity components comparison and difference
    h = figure('visible','off');
    
    ax1 = subplot(2,1,1);
    plot(ttmeas.meas_dates , ttmeas.meas_wc ,'-b');
    hold on
    plot(ttsimul.simul_dates , ttsimul.simul_wc,'-r');
    %hold on
    %plot(ttcomp_noNaN.meas_dates , vc_diff);
    title(strcat( component_plot{:} , ' comparison,', ' Station : ', station_plot ));
    legend('Measurements','Simulations');
    lgd.NumColumns = 2;
    ylabel(component_plot{:});
    set(gca,'FontSize',6)
    componentPlot = component_plot{:}
    if string(componentPlot) == string('Wave height')
        ylim([0 10])
        annotation('textbox', [0.2, 0.1, 0.1, 0.1], 'String', "MAE = "+ string(mae)+ " RMSE = "+ string(rmse));
    end
    
    ax2 = subplot(2,1,2);
    plot(ttcomp_noNaN.meas_dates, vc_diff);
    title(strcat(component_plot{:} , ' difference,', ' Station : ',  station_plot));
    xlabel('Date/Time');
    ylabel(strcat(component_plot{:} , ' Difference'));
    set(gca,'FontSize',6)
    if string(componentPlot) == string('Wave height')
        ylim([-2 2])
    end
    
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
    
    save_name = strcat(path_3, '/',component_plot{:}, '_Station_', station_plot );
    %    savefig(h, save_name, 'compact');
    saveas(gca, save_name , 'jpeg');
    clf
    close(h)
    
    
end

end
