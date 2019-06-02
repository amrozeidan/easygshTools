
%add UtTools path
addpath('/Users/amrozeidan/Desktop/comparison_functions_20191604/comforpycomp/UtTools')

%import pTides
p = importPTides('pTides.dat');

%add directories of meas and simul wl dat files of all stations after being
%cropped
measfile = '/Users/amrozeidan/Desktop/comparison_functions_20191604/comforpycomp/measurements/variables_all_stations/free_surface_all_stations_cropped.dat';
simulfile = '/Users/amrozeidan/Desktop/comparison_functions_20191604/resforpycomp/telemac_variables/variables_all_stations/free_surface_stations_cropped.dat';
%and the database of stations
info = '/Users/amrozeidan/Desktop/comparison_functions_20191604/com/info_all_stations.dat';

%reading
Tmeast = readtable(measfile);
Tsimult = readtable(simulfile);
Tinfo = readtable(info , 'ReadRowNames', true);

%stations in common
a = Tmeast.Properties.VariableNames;
b = Tsimult.Properties.VariableNames;
station = intersect(a(1,2:end),b(1,2:end));

%dates
measdates = Tmeast.Date ;
simuldates = Tsimult.Date ;

%min peak distance
% c = datetime(2006,01,01,00,00,00);
% d = datetime(2006,01,02,00,25,00);
% e = hours(d-c)/2 ; %half of 24:25:00
% e = 0.38;
e = hours(7);

%for low tides peaks are detected for the negative values (coef= -1)
tide = table({'HighTides' ; 'LowTides'} , [1 ; -1] , 'RowNames' , {'h' ; 'l'} , 'VariableNames' , {'type' 'coef'});

for u = tide.Row'
    data_nrmse = [];
    for i = station
        lat = Tinfo{i , 'Latitude'};
        measvalue = tide.coef(u) * Tmeast.(i{1}) ;
        simulvalue = tide.coef(u) * Tsimult.(i{1}) ;
        
        %peak values and locations before reconstruction
        [pksmeas , lcsmeas] = findpeaks(measvalue ,measdates ,'MinPeakDistance', e);
        [pkssimul , lcssimul] = findpeaks(simulvalue ,simuldates , 'MinPeakDistance', e);
        
        %getting coef and reconstructed wl 
        % !reconstructing the simulated values too to get the same indexing
        % when calculating errors later
        coefmeas = ut_solv(datenum(measdates) , measvalue , [], lat , p );
        wlmeas = ut_reconstr(datenum(measdates) , coefmeas );
        coefsimul = ut_solv(datenum(simuldates) , simulvalue , [], lat , p );
        wlsimul = ut_reconstr(datenum(simuldates) , coefsimul );
        
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
    
    savename = strcat('nrmse' , tide.type(u));
    savefig(h, char(savename), 'compact');
    saveas(gca, char(savename) , 'jpeg');
    clf
    close(h)
    
end




