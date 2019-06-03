


%% g_salinitycomp
function g_salinitycomp (common_folder , basefolder , date_a , period, offset )

% common_folder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/com';
% basefolder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/res';
% period = timerange('2006-01-01' , '2006-01-31') ;


%importing measurements and simulations tables
%measurements timetable:
filelist_meas = dir(fullfile(strcat(common_folder , '/measurements') , '*sa.dat' ));
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
filelist_simul = dir(fullfile(strcat(basefolder , '/telemac_variables/variables_all_stations') , 'salinity_all_stations.dat' ));
filepath_simul = strcat(filelist_simul(1).folder , '/' , filelist_simul(1).name) ;

Ttsimul = readtable(filepath_simul);
Ttsimul.TimeStep_No = datetime (Ttsimul.TimeStep_No , 'InputFormat' , 'dd/MM/yyyy HH:mm:ss' );
Ttsimul = table2timetable(Ttsimul);

%importing required station names
filepath_req = strcat(common_folder, '/required_stations.dat');
req_data = textread( filepath_req , '%s', 'delimiter', '\n')';

%intersection of required stations, simulations and measurements:
%station names from meas timetable without the depth
stations_meas = Ttmeas.Properties.VariableNames ;
stations_meas_no_z = cellfun(@(x) x(1:end-4) , stations_meas , 'UniformOutput' , false ) ;
stations_simul = Ttsimul.Properties.VariableNames ;
stations = intersect(intersect( stations_meas_no_z , stations_simul) , req_data );

mkdir(basefolder, 'salinity_comparison')
path_3 = strcat(basefolder, '/salinity_comparison') ;

for cwl=1:length(stations)
    
    idx_meas = find(contains(stations_meas_no_z , stations{cwl}));
    
    for kl=1:length(idx_meas)
        
        %getting depth of measured salinity
        fullname = stations_meas{idx_meas(kl)} ;
        depth = string(str2double(fullname(end-2:end))/10);
        
        %reading measurements data
        meas_dates = Ttmeas.Time;
        meas_sa = Ttmeas.(fullname);
        
        %reading simulated data
        simul_dates = Ttsimul.TimeStep_No;
        %simul_dates = simul_dates + hours(offset);
        simul_sa = Ttsimul.(stations{cwl});
        
        %constructing timetables
        ttmeas = timetable(meas_dates , meas_sa);
        ttsimul = timetable(simul_dates , simul_sa);
        
        %synchronizing tables
        tt = synchronize(ttmeas , ttsimul);
        
        %tables covering the required period for comparison
        ttcomp = tt(period , :);
        ttcomp_noNaN = rmmissing(ttcomp);
        
        %salinity difference
        sa_diff = ttcomp_noNaN.simul_sa - ttcomp_noNaN.meas_sa ;
        TT_sa_diff = timetable(ttcomp_noNaN.meas_dates , sa_diff );
        %salinity difference main table containing all stations
        if cwl ==1
            TT_sa_diff_main = TT_sa_diff;
        else
            TT_sa_diff_main = synchronize(TT_sa_diff_main , TT_sa_diff);
        end
        
        %subplots of salinity comparison and difference
        h = figure('visible','on');
        
        ax1 = subplot(2,1,1);
        plot(ttcomp.meas_dates , ttcomp.meas_sa ,'-b');
        hold on
        plot(ttcomp.meas_dates , ttcomp.simul_sa,'-r');
        hold on
        plot(ttcomp_noNaN.meas_dates , sa_diff);
        title(strcat('Salinity comparison,', ' Station : ', stations(cwl) , ', depth=' , depth));
        legend('Measurements','Simulations','Differences');
        lgd.NumColumns = 3;
        ylabel('Salinity');
        set(gca,'FontSize',6)
        %ylim([-5 5])
        
        ax2 = subplot(2,1,2);
        plot(ttcomp_noNaN.meas_dates, sa_diff);
        title(strcat('Salinity difference,', ' Station : ', stations(cwl) , ', depth=' , depth));
        xlabel('Date/Time');
        ylabel('Salinity Difference');
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
        
        save_name = strcat(path_3, '/','salinity_comparison_difference', '_Station_', stations{cwl} ,'_' , fullname(end-2:end));
        %    savefig(h, save_name, 'compact');
        saveas(gca, save_name , 'jpeg');
        clf
        close(h)
        
        
    end
end

end




