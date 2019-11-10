
function e2_getPeaks(common_folder , basefolder, stationsDBFile)

% common_folder = '/Users/amrozeidan/Downloads/EAZYgsh tools/testing_for_nico/com';
% basefolder = '/Users/amrozeidan/Downloads/EAZYgsh tools/testing_for_nico/base';
% stationsDBFile = '/Users/amrozeidan/Downloads/EAZYgsh tools/EasyGSH_az/3_functions_revGIT_matlab/info_all_stations.dat';

%add UtTools
addpath('UtTools')

%import pTides
p = importPTides('pTides.dat');

%read the meas and simul dat files as tables
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

%read sations database file
TstationInfo = readtable(stationsDBFile , 'ReadRowNames' , true);

%check available extracted coefficients
try
    filelist_coef_meas = dir(fullfile(strcat(common_folder , '/coef_measured') , 'coef_of_meas*.mat' ));
    name_coef_meas = {filelist_coef_meas(:).name} ;
    name_coef_meas = cellfun(@(x) x(14:end-4) , name_coef_meas , 'UniformOutput' , 0) ;
    
    filelist_coef_simul = dir(fullfile(strcat(basefolder , '/coef_simulated') , 'coef_of_simulation*.mat' ));
    name_coef_simul = {filelist_coef_simul(:).name} ;
    name_coef_simul = cellfun(@(x) x(20:end-4) , name_coef_simul , 'UniformOutput' , 0) ;
    
catch
    disp('no previous coef are availale, please run e_excoef.m')
    return 
end

%stations in common
station = intersect(name_coef_meas , name_coef_simul);

%dates
measdates = Ttmeas.Time ;
simuldates = Ttsimul.TimeStep_No ;

%min peak distance
e = hours(7) ;

%for low tides peaks are detected for the negative values (coef= -1)
tide = table({'HighTides' ; 'LowTides'} , [1 ; -1] , 'RowNames' , {'h' ; 'l'} , 'VariableNames' , {'type' 'coef'});

mkdir(basefolder, 'peaks_comparison')
path_5 = strcat(basefolder, '/peaks_comparison');

for u = tide.Row'
    data_nrmse = [];
    
    for i = station
        lat = TstationInfo{i , 'Latitude'};
        measvalue = tide.coef(u) * Ttmeas.(i{1}) ;
        simulvalue = tide.coef(u) * Ttsimul.(i{1}) ;
        
        %peak values and locations before reconstruction
        [pksmeas , lcsmeas] = findpeaks(measvalue ,measdates ,'MinPeakDistance', e);
        [pkssimul , lcssimul] = findpeaks(simulvalue ,simuldates , 'MinPeakDistance', e);
        
        %getting coef and reconstructed wl
        %coef are already extracted in e_excoef.m, they are just loaded
        % !reconstructing the simulated values too to get the same indexing
        % when calculating errors later
        if u{1} == 'h'
            coefmeas = load(strcat(common_folder , '/coef_measured/coef_of_meas_' , i{1} , '.mat'));
            wlmeas = ut_reconstr(datenum(measdates) , coefmeas.tidalcoef_meas );
            coefsimul = load(strcat(basefolder , '/coef_simulated/coef_of_simulation_' , i{1} , '.mat'));
            wlsimul = ut_reconstr(datenum(simuldates) , coefsimul.tidalcoef_simul );
        elseif u{1} == 'l'
            wlmeas = tide.coef(u) * wlmeas;
            wlsimul = tide.coef(u) * wlsimul;
        end
        
        %peak values and locations after reconstruction
        [pksmeasr , lcsmeasr] = findpeaks(wlmeas ,measdates , 'MinPeakDistance', e);
        [pkssimulr , lcssimulr] = findpeaks(wlsimul ,simuldates , 'MinPeakDistance', e);
        
        %getting indices peaks; meas
        Dmeas = pdist2(datenum(lcsmeasr) , datenum(lcsmeas));
        [valuesm, indxmeas]=min(Dmeas);
        Dsimul = pdist2(datenum(lcssimulr) , datenum(lcssimul));
        [valuess, indxsimul]=min(Dsimul);
        
        %             %Plots
        %             h1 = figure('visible','on');
        %             plot(measdates , measvalue)
        %             findpeaks(measvalue ,measdates , 'MinPeakDistance', e)
        %             hold on
        %             plot(measdates , wlmeas ,lcsmeasr,pksmeasr,'o')
        %             legend('measwl' , 'measpeaks' , 'rmeaswl' , 'rmeaspeaks')
        %
        %             h2 = figure('visible','on');
        %             plot(simuldates , simulvalue)
        %             findpeaks(simulvalue ,simuldates , 'MinPeakDistance', e)
        %             hold on
        %             plot(simuldates , wlsimul ,lcssimulr,pkssimulr,'o')
        %             legend('simulwl' , 'simulpeaks' , 'rsimulwl' , 'rsimulpeaks')
        %
        %             h3 = figure('visible','on');
        %             plot(measdates , wlmeas ,lcsmeasr,pksmeasr,'o')
        %             hold on
        %             plot(simuldates , wlsimul ,lcssimulr,pkssimulr,'o')
        %             legend('rmeaswl' , 'rmeaspeaks', 'rsimulwl' , 'rsimulpeaks')
        %
        %             h4 = figure('visible','on');
        %             plot(measdates , measvalue ,lcsmeas ,pksmeas,'o')
        %             hold on
        %             plot(simuldates , simulvalue ,lcssimul ,pkssimul ,'o')
        %             legend('measwl' , 'measpeaks', 'simulwl' , 'simulpeaks')
        
        %tables of indices/numbering of peaks and their values
        Tmeas =  table(indxmeas' , pksmeas , datenum(lcsmeas) ,  'VariableNames' , {'Index' 'Peaksmeas' 'Lcsmeas'});
        %Tsimul =  table((1:1:length(lcssimul))' , pkssimul , datenum(lcssimul) , 'VariableNames' , {'Index' 'Peakssimul' 'Lcssimul'});
        Tsimul =  table(indxsimul' , pkssimul , datenum(lcssimul) ,  'VariableNames' , {'Index' 'Peakssimul' 'Lcssimul'});
        
        %remove duplicates with lowest peak values(just in case)
        [~,~,rows] = unique(Tsimul.Index , 'rows');
        todelete = arrayfun(@(r) rows == r & Tsimul.Peakssimul < max(Tsimul.Peakssimul(rows==r)) , 1:max(rows) , 'UniformOutput' , false);
        Tsimul(any(cell2mat(todelete) , 2) , :) = [] ;
        
        [~,~,rows] = unique(Tmeas.Index , 'rows');
        todelete = arrayfun(@(r) rows == r & Tmeas.Peaksmeas < max(Tmeas.Peaksmeas(rows==r)) , 1:max(rows) , 'UniformOutput' , false);
        Tmeas(any(cell2mat(todelete) , 2) , :) = [] ;
        
        %join and remove NaNs
        Tall = innerjoin(Tmeas , Tsimul);
        
        %vertical and horizontal nrmse
        rmse_v =sqrt(sum((Tall.Peakssimul - Tall.Peaksmeas).^2)/numel(Tall.Peaksmeas));
        nrmse_v=(rmse_v/((max(Tall.Peaksmeas(:))-(min(Tall.Peaksmeas(:))))));
        rmse_h =sqrt(sum((Tall.Lcssimul - Tall.Lcsmeas).^2)/numel(Tall.Peaksmeas));
        nrmse_h=(rmse_h/((max(Tall.Lcsmeas(:))-(min(Tall.Lcsmeas(:))))));
        
        data_nrmse = vertcat(data_nrmse ,horzcat(i , nrmse_v , nrmse_h));
        
        clf
        close all
    end
    
    nrmse = cell2table(data_nrmse(: , 2:end) ,'RowNames' , data_nrmse(:,1) , 'VariableNames',{'nrmsev' 'nrmseh' })
    
    %plot nrmse
    h = figure('visible','on');
    
    ax1 = subplot(2,1,1);
    plot(nrmse.nrmsev,'rx');
    set(gca, 'XTick', 1:length(nrmse.nrmsev))
    set(gca,'XtickLabel',nrmse.Row)
    xtickangle(45);
    ylabel('NRMSE');
    title( strcat('NRMSE of peak values-' , tide.type(u)))
    
    ax2 = subplot(2,1,2);
    plot(nrmse.nrmseh,'bx');
    set(gca, 'XTick', 1:length(nrmse.nrmsev))
    set(gca,'XtickLabel',nrmse.Row)
    ylabel('NRMSE');
    title( strcat('NRMSE of peak locations-' , tide.type(u)))
    xtickangle(45);
    
    linkaxes([ax1 , ax2] , 'x');
    
    grid(ax1,'on');
    grid(ax2,'on');
    ax1.FontSize = 10.5;
    ax2.FontSize = 10.5;
    pbaspect(ax1 , 'auto')
    pbaspect(ax2 , 'auto')
    
    savename = strcat(path_5 , '/' , 'nrmse' , tide.type(u));
    savefig(h, char(savename), 'compact');
    saveas(gca, char(savename) , 'jpeg');
    clf
    close(h)
    
end

end

