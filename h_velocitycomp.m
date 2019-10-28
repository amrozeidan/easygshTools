


%% h_velocitycomp
% function h_velocitycomp (common_folder , basefolder , period, offset, requiredStationsFile )

% common_folder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/com';
% basefolder = '/Users/amrozeidan/Desktop/EasyGSH/functiontesting/res';
% period = timerange('2006-01-01' , '2006-01-31') ;

common_folder = 'C:\Users\DEAZEID1\Downloads\HIWI\testing\com' ;
basefolder = 'C:\Users\DEAZEID1\Downloads\HIWI\testing\base';
period = timerange('2015-01-01' , '2015-01-08') ;
requiredStationsFile = 'C:\Users\DEAZEID1\Downloads\HIWI\testing\required_stations.dat';

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
%requiredStationsFile = strcat(common_folder, '/required_stations.dat');
req_data = textread( requiredStationsFile , '%s', 'delimiter', '\n')';
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
        ttcomp_noNaN.simul_vc
        %if string(component_plot{:}) == "Velocity Direction"
        %    ttcomp_noNaN.simul_vc = - ttcomp_noNaN.simul_vc + 90
        %    ttcomp_noNaN.simul_vc (ttcomp_noNaN.simul_vc<0) = ttcomp_noNaN.simul_vc(ttcomp_noNaN.simul_vc<0)+360
        %end
        if component == 'dirc'
            %copy read data
            ttcomp_noNaN.simul_vc_math = ttcomp_noNaN.simul_vc;
            ttcomp_noNaN.meas_vc_naut = ttcomp_noNaN.meas_vc;
            %transform to missing direction definition
            ttcomp_noNaN.meas_vc_math = -ttcomp_noNaN.meas_vc_naut + 90;
            ttcomp_noNaN.meas_vc_math(ttcomp_noNaN.meas_vc_math <=0) = ttcomp_noNaN.meas_vc_math (ttcomp_noNaN.meas_vc_math <=0) + 360;
            ttcomp_noNaN.meas_vc_naut(ttcomp_noNaN.meas_vc_naut <=0) = ttcomp_noNaN.meas_vc_naut (ttcomp_noNaN.meas_vc_naut <=0) + 360;
            ttcomp_noNaN.simul_vc_math (ttcomp_noNaN.simul_vc_math <= 0) = ttcomp_noNaN.simul_vc_math (ttcomp_noNaN.simul_vc_math <= 0) + 360;
            ttcomp_noNaN.simul_vc_math_intermed = ttcomp_noNaN.simul_vc_math;
            ttcomp_noNaN.simul_vc_math_intermed (ttcomp_noNaN.simul_vc_math_intermed <=180) = ttcomp_noNaN.simul_vc_math_intermed (ttcomp_noNaN.simul_vc_math_intermed <= 180) +360;
            ttcomp_noNaN.meas_vc_math_intermed = ttcomp_noNaN.meas_vc_math;
            ttcomp_noNaN.meas_vc_math_intermed (ttcomp_noNaN.meas_vc_math_intermed <=180) = ttcomp_noNaN.meas_vc_math_intermed (ttcomp_noNaN.meas_vc_math_intermed <= 180) +360;
            ttcomp_noNaN.simul_vc_naut = -ttcomp_noNaN.simul_vc_math + 90;
            ttcomp_noNaN.simul_vc_naut (ttcomp_noNaN.simul_vc_naut <= 0) = ttcomp_noNaN.simul_vc_naut (ttcomp_noNaN.simul_vc_naut <= 0) + 360;
            
            A = ttcomp_noNaN.simul_vc_math(:) - ttcomp_noNaN.meas_vc_math(:);
            B = ttcomp_noNaN.simul_vc_naut(:) - ttcomp_noNaN.meas_vc_naut(:);
            C = ttcomp_noNaN.simul_vc_math_intermed(:) - ttcomp_noNaN.meas_vc_math_intermed(:);
            ABC = cat (3,A,B,C);
            [~,idx] = min(abs(ABC),[],3);
            vc_diff = A.*(idx==1) +  B.*(idx==2) + C.*(idx==3);

%             ttcomp_noNaN.meas_vc = ttcomp_noNaN.meas_vc_math;
%             ttcomp_noNaN.simul_vc = ttcomp_noNaN.simul_vc_math;
            ttcomp_noNaN.meas_vc = ttcomp_noNaN.meas_vc_naut;
            ttcomp_noNaN.simul_vc = ttcomp_noNaN.simul_vc_naut;
            
            ttcomp_noNaN.meas_vc_naut = [];
            ttcomp_noNaN.meas_vc_math = [];
            ttcomp_noNaN.simul_vc_naut = [];
            ttcomp_noNaN.simul_vc_math = [];
            
            %displaying mathemtical units
%             ttmeas.meas_vc = -ttmeas.meas_vc + 90
%             ttmeas.meas_vc(ttmeas.meas_vc <= 0) = ttmeas.meas_vc(ttmeas.meas_vc <= 0) + 360;
            %displaying nautical units
            ttsimul.simul_vc = -ttsimul.simul_vc + 90;
            ttsimul.simul_vc(ttsimul.simul_vc <= 0) = ttsimul.simul_vc(ttsimul.simul_vc <= 0) + 360;
            
        else
            vc_diff = ttcomp_noNaN.simul_vc - ttcomp_noNaN.meas_vc ;
        end
        
        TT_vc_diff = timetable(ttcomp_noNaN.meas_dates , vc_diff );
        %salinity difference main table containing all stations
        if cwl ==1
            TT_vc_diff_main = TT_vc_diff;
        else
            TT_vc_diff_main = synchronize(TT_vc_diff_main , TT_vc_diff);
        end
        
        %normalized root mean square error
        rmse = sqrt(sum((vc_diff(:)).^2)/numel(ttcomp_noNaN.simul_vc));
        me = sum((vc_diff(:))/numel(ttcomp_noNaN.simul_vc));
        mae = sum(abs((vc_diff(:)))/numel(ttcomp_noNaN.simul_vc));
        
        if component == 'dirc'
            unit = '[°] (naut)';
        else
            unit = '[m/s]';
        end
        
        %subplots of velocity components comparison and difference
        h = figure('visible','off');
        
        ax1 = subplot(2,1,1);
        plot(ttmeas.meas_dates , ttmeas.meas_vc ,'-b');
        hold on
        plot(ttsimul.simul_dates , ttsimul.simul_vc,'-r');
        hold on
        %plot(ttcomp_noNaN.meas_dates , vc_diff);
        title(strcat( strcat(component_plot{:}, ' ', unit) , ' comparison,', ' Station : ', station_plot , ', depth=' , depth));
        legend('Measurements','Simulations');
        lgd.NumColumns = 2;
        ylabel(component_plot{:});
        set(gca,'FontSize',6)
        if component == 'dirc'
            ylim([0 360]);
            yticks(0:60:360);
        else
            ylim([0 2.5]);
            yticks(0:0.5:2.5);
        end

        
        ax2 = subplot(2,1,2);
        plot(ttcomp_noNaN.meas_dates, vc_diff);
        title(strcat(component_plot{:} , ' difference,', ' Station : ',  station_plot , ', depth=' , depth));
        xlabel('Date [UTC]');
        ylabel(strcat(component_plot{:} , ' Difference', unit));
        set(gca,'FontSize',6)
        if component == 'dirc'
            ylim([-180 180]);
            yticks(-180:60:180);
        else
            ylim([-1.0 1.0]);
            yticks(-1:0.2:1);
        end
        xi = 0.85;
        eta = 0.15;
        text(xi,eta,sprintf('RMSE=%6.3f\n MAE=%6.3f\n  ME=%6.3f\nje in %s',rmse,mae,me,unit),'Units','normalized','FontSize',6,'HorizontalAlignment','left');
        %ylim([-5 5])
        
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
