


%% h_velocitycomp
function h_velocitycomp (common_folder , basefolder , period, offset )

% common_folder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/com';
% basefolder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/res';
% period = timerange('2006-01-01' , '2006-01-31') ;


%importing measurements and simulations tables
%measurements timetable:
filelist_meas = dir(fullfile(strcat(common_folder , '/measurements') , '*cu.dat' ));
filepath_meas = strcat(filelist_meas(1).folder , '/' , filelist_meas(1).name) ;

Ttmeas = readtable(filepath_meas);
try
    Ttmeas.Time = datetime (Ttmeas.Time , 'InputFormat' , 'dd-MM-yyyy HH:mm:ss' );
catch
    %warning(['Error using datetime (line 602)']);
    Ttmeas.Time = datetime (Ttmeas.Time , 'InputFormat' , 'dd.MM.yyyy HH:mm:ss' );
end
Ttmeas = table2timetable(Ttmeas);
%change VariableNames of Tmeas from station_depth_component to station_component_depth 
stations_meas = cellfun(@(x) [x(1:end-9) , x(end-4:end) , x(end-8:end-5)] , Ttmeas.Properties.VariableNames , 'UniformOutput' , false ) ;
Ttmeas.Properties.VariableNames = stations_meas ;


%simulations timetable:
filelist_simul = dir(fullfile(strcat(basefolder , '/telemac_variables/variables_all_stations') , 'velocity_all_stations.dat' ));
filepath_simul = strcat(filelist_simul(1).folder , '/' , filelist_simul(1).name) ;

Ttsimul = readtable(filepath_simul);
Ttsimul.TimeStep_No = datetime (Ttsimul.TimeStep_No , 'InputFormat' , 'dd/MM/yyyy HH:mm:ss' );
Ttsimul = table2timetable(Ttsimul);

%importing required station names
filepath_req = strcat(common_folder, '/required_stations.dat');
req_data = textread( filepath_req , '%s', 'delimiter', '\n')';
%add velocity components to required stations names
add_name = {'_magn' , '_dirc' } ;
req_data_n = cellfun(@(x) strcat(x , add_name) , cellstr(req_data) , 'Uniformoutput', 0) ;
req_data_n_all = [] ;
for cu=1:numel(req_data_n)
    req_data_n_all = [req_data_n_all , req_data_n{cu}] ;
end
        
%intersection of required stations, simulations and measurements:
%station names from meas timetable without the depth
stations_meas_no_z = cellfun(@(x) x(1:end-4) , Ttmeas.Properties.VariableNames , 'UniformOutput' , false ) ;
stations_simul = Ttsimul.Properties.VariableNames  ;
stations = intersect(intersect( stations_meas_no_z , stations_simul) , req_data_n_all );



mkdir(basefolder, 'velocity_comparison')
path_3 = strcat(basefolder, '/velocity_comparison') ;

velocity_comp_shrt = {'magn' 'dirc' 'velv' 'velu'}';
velocity_comp = {'Velocity Magnitude' 'Velocity Direction' 'Velocity_v' 'Velocity_u'}';
Tvc = table( velocity_comp , 'RowNames' , velocity_comp_shrt );


for cwl=1:length(stations)
    
    idx_meas = find(contains(stations_meas_no_z , stations{cwl}));
    
    for kl=1:length(idx_meas)
        
        %getting depth of measured velocity
        fullname_meas = Ttmeas.Properties.VariableNames{idx_meas(kl)} ;
        depth = string(str2double(fullname_meas(end-2:end))/10);
        component = fullname_meas(end-7:end-4);
        component_plot = Tvc.velocity_comp(component);
        station_plot = fullname_meas(1:end-9);
        
        %reading measurements data
        meas_dates = Ttmeas.Time;
        meas_vc = Ttmeas.(fullname_meas);
        
        %reading simulated data
        simul_dates = Ttsimul.TimeStep_No;
        %simul_dates = simul_dates + hours(offset);
        simul_vc = Ttsimul.(stations{cwl});
        
        %constructing timetables
        ttmeas = timetable(meas_dates , meas_vc);
        ttsimul = timetable(simul_dates , simul_vc);
        
        %timetables covering the required period for comparison
        ttmeas = ttmeas(period , :);
        ttsimul = ttsimul(period , :);
        
        %synchronizing tables
        tt = synchronize(ttmeas , ttsimul);
        
        %synchronized table without NaN for comparison (differences)
        ttcomp_noNaN = rmmissing(tt);
        
        %magnitude/direction difference
        vc_diff = ttcomp_noNaN.simul_vc - ttcomp_noNaN.meas_vc ;
        TT_vc_diff = timetable(ttcomp_noNaN.meas_dates , vc_diff );
        %salinity difference main table containing all stations
        if cwl ==1
            TT_vc_diff_main = TT_vc_diff;
        else
            TT_vc_diff_main = synchronize(TT_vc_diff_main , TT_vc_diff);
        end
        
        %subplots of velocity components comparison and difference
        h = figure('visible','off');
        
        ax1 = subplot(2,1,1);
        plot(ttmeas.meas_dates , ttmeas.meas_vc ,'-b');
        hold on
        plot(ttsimul.simul_dates , ttsimul.simul_vc,'-r');
        hold on
        plot(ttcomp_noNaN.meas_dates , vc_diff);
        title(strcat( component_plot{:} , ' comparison,', ' Station : ', station_plot , ', depth=' , depth));
        legend('Measurements','Simulations','Differences');
        lgd.NumColumns = 3;
        ylabel(component_plot{:});
        set(gca,'FontSize',6)
        %ylim([-5 5])
        
        ax2 = subplot(2,1,2);
        plot(ttcomp_noNaN.meas_dates, vc_diff);
        title(strcat(component_plot{:} , ' difference,', ' Station : ',  station_plot , ', depth=' , depth));
        xlabel('Date/Time');
        ylabel(strcat(component_plot{:} , ' Difference'));
        set(gca,'FontSize',6)
        %ylim([-0.75 0.75])
        
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
        
        save_name = strcat(path_3, '/',component_plot{:}, '_Station_', station_plot ,'_' , fullname_meas(end-2:end));
        %    savefig(h, save_name, 'compact');
        saveas(gca, save_name , 'jpeg');
        clf
        close(h)
        
        
    end
end
