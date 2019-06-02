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

function f_ptcomp(common_folder , basefolder)

listing_common_folder = dir(common_folder);
common_folder_file_name = {};
for f=1:length(listing_common_folder)
    common_folder_file_name = vertcat(common_folder_file_name , listing_common_folder(f).name) ;
end

indu = find(ismember(common_folder_file_name , 'A_g_measured' ));

%% Storing
%storing the Amplitudes and phase shifts for the required stations based
%on tides types------------------------------------------------------------
file_id = fopen( strcat(common_folder , '/required_stations_data_free_surface_cropped.dat') ,'r');
data = textscan(file_id, '%s%s%s%n%n%n%n', 'Delimiter', ',', 'HeaderLines', 1);
fclose(file_id);
Locations_Names = data{1,1};

pTides = importPTides('pTides.dat');

path_4 = strcat(basefolder, '/coef');
path_5 = strcat(path_4 , '/coef_measured');
path_6 = strcat(path_4 , '/coef_simulated');
path_add = strcat(common_folder, '/coef_measured');

if isempty(indu)
    mkdir(basefolder, 'A_g')
    path_4_ag = strcat(basefolder, '/A_g');
    mkdir (path_4_ag, 'A_g_measured')
    path_5_ag = strcat(path_4_ag , '/A_g_measured');
    mkdir (path_4_ag, 'A_g_simulated')
    path_6_ag = strcat(path_4_ag , '/A_g_simulated');
    
    mkdir(common_folder, 'A_g_measured')
    path_add_ag = strcat(common_folder, '/A_g_measured');
else
    mkdir(basefolder, 'A_g')
    path_4_ag = strcat(basefolder, '/A_g')
    mkdir (path_4_ag, 'A_g_simulated')
    path_6_ag = strcat(path_4_ag , '/A_g_simulated')
end


name_nn{1,1}='Station';
name_nn{1,2}='A';
name_nm{1,1}='Station';
name_nm{1,2}='g';
name_nt{1,1}='Tide name';


for a=1:length(pTides)
    name_nt{1,2}=pTides{a};
    my_data_amplitude_meas=vertcat(horzcat(name_nt),horzcat(name_nn));
    my_data_phaseshift_meas=vertcat(horzcat(name_nt),horzcat(name_nm));
    
    my_data_amplitude_simul=vertcat(horzcat(name_nt),horzcat(name_nn));
    my_data_phaseshift_simul=vertcat(horzcat(name_nt),horzcat(name_nm));
    
    %if isequal(run_no , '1ST')
    if isempty(indu)
        
        for aa=1:length(Locations_Names)
            stationtable_meas=load(strcat(path_5,'/','coef_of_meas_',Locations_Names{aa},'.mat'));
            index_tidename_meas=find(strcmp(stationtable_meas.my_data_coef_meas(:,1),pTides{a}));
            amplitude_meas=stationtable_meas.my_data_coef_meas(index_tidename_meas,2);
            phaseshift_meas=stationtable_meas.my_data_coef_meas(index_tidename_meas,3);
            
            stationtable_simul=load(strcat(path_6, '/' ,'coef_of_simulation_',Locations_Names{aa},'.mat'));
            index_tidename_simul=find(strcmp(stationtable_simul.my_data_coef_wl_simulated(:,1),pTides{a}));
            amplitude_simul=stationtable_simul.my_data_coef_wl_simulated(index_tidename_simul,2);
            phaseshift_simul=stationtable_simul.my_data_coef_wl_simulated(index_tidename_simul,3);
            
            my_data_amplitude_meas_new_line= horzcat(Locations_Names{aa},amplitude_meas);
            my_data_amplitude_meas=vertcat(my_data_amplitude_meas, my_data_amplitude_meas_new_line);
            
            my_data_amplitude_simul_new_line= horzcat(Locations_Names{aa},amplitude_simul);
            my_data_amplitude_simul=vertcat(my_data_amplitude_simul, my_data_amplitude_simul_new_line);
            
            my_data_phaseshift_meas_new_line= horzcat(Locations_Names{aa},phaseshift_meas);
            my_data_phaseshift_meas=vertcat(my_data_phaseshift_meas, my_data_phaseshift_meas_new_line);
            
            my_data_phaseshift_simul_new_line= horzcat(Locations_Names{aa},phaseshift_simul);
            my_data_phaseshift_simul=vertcat(my_data_phaseshift_simul, my_data_phaseshift_simul_new_line);
        end
        
        T1 = cell2table(my_data_amplitude_meas);
        saving_name_1_a = strcat(path_5_ag, '/' , 'measured_A_' , pTides{a}, '.dat');
        saving_name_1_b = strcat(path_add_ag, '/' , 'measured_A_' , pTides{a}, '.dat');
        writetable(T1,saving_name_1_a);
        writetable(T1,saving_name_1_b);
        
        T2 = cell2table(my_data_phaseshift_meas);
        saving_name_2_a = strcat(path_5_ag, '/' , 'measured_g_' , pTides{a}, '.dat');
        saving_name_2_b = strcat(path_add_ag, '/' , 'measured_g_' , pTides{a}, '.dat');
        writetable(T2,saving_name_2_a);
        writetable(T2,saving_name_2_b);
        
        T3 = cell2table(my_data_amplitude_simul);
        saving_name_3 = strcat(path_6_ag, '/' , 'simulated_A_' , pTides{a}, '.dat');
        writetable(T3,saving_name_3);
        
        T4 = cell2table(my_data_phaseshift_simul);
        saving_name_4 = strcat(path_6_ag, '/' , 'simulated_g_' , pTides{a}, '.dat');
        writetable(T4,saving_name_4);
        
        %elseif isequal(run_no , '2PLUS')
    else
        
        for aa=1:length(Locations_Names)
            stationtable_simul=load(strcat(path_6, '/' ,'coef_of_simulation_',Locations_Names{aa},'.mat'));
            index_tidename_simul=find(strcmp(stationtable_simul.my_data_coef_wl_simulated(:,1),pTides{a}));
            amplitude_simul=stationtable_simul.my_data_coef_wl_simulated(index_tidename_simul,2);
            phaseshift_simul=stationtable_simul.my_data_coef_wl_simulated(index_tidename_simul,3);
            
            my_data_amplitude_simul_new_line= horzcat(Locations_Names{aa},amplitude_simul);
            my_data_amplitude_simul=vertcat(my_data_amplitude_simul, my_data_amplitude_simul_new_line);
            
            my_data_phaseshift_simul_new_line= horzcat(Locations_Names{aa},phaseshift_simul);
            my_data_phaseshift_simul=vertcat(my_data_phaseshift_simul, my_data_phaseshift_simul_new_line);
        end
        
        T3 = cell2table(my_data_amplitude_simul);
        saving_name_3 = strcat(path_6_ag , '/' , 'simulated_A_' , pTides{a}, '.dat');
        writetable(T3,saving_name_3);
        
        T4 = cell2table(my_data_phaseshift_simul);
        saving_name_4 = strcat(path_6_ag , '/' , 'simulated_g_' , pTides{a}, '.dat');
        writetable(T4,saving_name_4);
    end
end


%% A and g plots
%plot A meas and A simul for the required stations based on tides types
%plot g meas and g simul for the required stations based on tides types
%--------------------------------------------------------------------------
mkdir(basefolder, 'pt_comparison')
path_7 = strcat(basefolder, '/pt_comparison')
path_4_ag = strcat(basefolder, '/A_g')
path_5_ag = strcat(path_4_ag , '/A_g_measured');
path_6_ag = strcat(path_4_ag , '/A_g_simulated');
path_add_ag = strcat(common_folder, '/A_g_measured');

for  kj=1:length(pTides)
    
    %if isequal(run_no , '1ST')
    if isempty(indu)
        %reading measured A  data
        file_id_A_meas = fopen(strcat(path_5_ag , '/','measured_A_', pTides{kj}, '.dat') ,'r');
        meas_A_data = textscan(file_id_A_meas, '%s%n', 'Delimiter', ',', 'HeaderLines', 3);
        fclose(file_id_A_meas);
        meas_st = meas_A_data{1,1};
        meas_A = meas_A_data{1,2};
        
        %reading simulated A  data
        file_id_A_simul = fopen(strcat(path_6_ag , '/','simulated_A_', pTides{kj}, '.dat') ,'r');
        simul_A_data = textscan(file_id_A_simul, '%s%n', 'Delimiter', ',', 'HeaderLines', 3);
        fclose(file_id_A_simul);
        simul_st = simul_A_data{1,1};
        simul_A = simul_A_data{1,2};
        
        %reading measured g  data
        file_id_g_meas = fopen(strcat(path_5_ag , '/','measured_g_', pTides{kj}, '.dat') ,'r');
        meas_g_data = textscan(file_id_g_meas, '%s%n', 'Delimiter', ',', 'HeaderLines', 3);
        fclose(file_id_g_meas);
        meas_st = meas_g_data{1,1};
        meas_g = meas_g_data{1,2};
        
        %reading simulated g  data
        file_id_g_simul = fopen(strcat(path_6_ag , '/','simulated_g_', pTides{kj}, '.dat') ,'r');
        simul_g_data = textscan(file_id_g_simul, '%s%n', 'Delimiter', ',', 'HeaderLines', 3);
        fclose(file_id_g_simul);
        simul_st = simul_g_data{1,1};
        simul_g = simul_g_data{1,2};
        
        %plot A meas and A simul of stations for each tide
        %         h = figure('visible','on');
        %         plot(meas_A,'rx')
        %         hold on
        %         plot(simul_A,'bx')
        %         set(gca, 'XTick', 1:length(meas_st))
        %         set(gca,'XtickLabel',meas_st)
        %         title(strcat('"A" comparison', ' for tide : ', pTides{kj}));
        %         legend('Measured','Simulated');
        %         xlabel('Stations');
        %         ylabel('Amplitude');
        %         xtickangle(45);
        %         save_name_A = strcat(path_7, '/','A comparison', ' for tide ', pTides{kj});
        %         savefig(save_name_A);
        %         saveas(gca, save_name_A , 'jpeg');
        %         clf
        %         close(h)
        h = figure('visible','off');
        ax1 = subplot(2,1,1);
        plot(meas_A,'rx')
        hold on
        plot(simul_A,'bx')
        legend('Measured','Simulated');
        set(gca, 'XTick', 1:length(meas_st))
        set(gca,'XtickLabel',meas_st)
        title(strcat('Amplitude comparison', ' for tide : ', pTides{kj}));
        ylabel('Amplitude');
		ylim([0 inf]);
        
        dff = simul_A - meas_A;
        
        ax2 = subplot(2,1,2);
        plot(dff, 'kx')
        set(gca, 'XTick', 1:length(meas_st))
        set(gca,'XtickLabel',meas_st)
        title(strcat('Amplitude difference', ' for tide : ', pTides{kj}));
        xlabel('Stations');
        ylabel('Amplitude Diffrence');
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
        
        save_name_A = strcat(path_7, '/','A comparison', ' for tide ', pTides{kj});
        %savefig(save_name_A);
        saveas(gca, save_name_A , 'jpeg');
        clf
        close(h)
        
        %plot g meas and g simul of stations for each tide
        %         h = figure('visible','on');
        %         plot(meas_g,'rx')
        %         hold on
        %         plot(simul_g,'bx')
        %         set(gca, 'XTick', 1:length(meas_st))
        %         set(gca,'XtickLabel',meas_st)
        %         title(strcat('"g" comparison', ' for tide : ', pTides{kj}));
        %         legend('Measured','Simulated');
        %         xlabel('Stations');
        %         ylabel('Phase shift');
        %         xtickangle(45);
        %         save_name_g = strcat(path_7, '/','g comparison', ' for tide ', pTides{kj});
        %         savefig(save_name_g);
        %         saveas(gca, save_name_g , 'jpeg');
        %         clf
        %         close(h)
        h = figure('visible','off');
        ax1 = subplot(2,1,1);
        plot(meas_g,'rx')
        hold on
        plot(simul_g,'bx')
        legend('Measured','Simulated');
        set(gca, 'XTick', 1:length(meas_st))
        set(gca,'XtickLabel',meas_st)
        title(strcat('Phase shift comparison', ' for tide : ', pTides{kj}));
        ylabel('Phase shift');
		ylim([0 360])
        
        dff = simul_g - meas_g;
        
        ax2 = subplot(2,1,2);
        plot(dff, 'kx')
        set(gca, 'XTick', 1:length(meas_st))
        set(gca,'XtickLabel',meas_st)
        xlabel('Stations');
        ylabel('Phase shift Diffrence');
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
        
        save_name_g = strcat(path_7, '/','g comparison', ' for tide ', pTides{kj});
        %savefig(save_name_g);
        saveas(gca, save_name_g , 'jpeg');
        clf
        close(h)
        
        %elseif isequal(run_no , '2PLUS')
    else
        %reading measured A  data
        file_id_A_meas = fopen(strcat(path_add_ag, '/','measured_A_', pTides{kj}, '.dat') ,'r');
        meas_A_data = textscan(file_id_A_meas, '%s%n', 'Delimiter', ',', 'HeaderLines', 3);
        fclose(file_id_A_meas);
        meas_st = meas_A_data{1,1};
        meas_A = meas_A_data{1,2};
        
        %reading simulated A  data
        file_id_A_simul = fopen(strcat(path_6_ag, '/','simulated_A_', pTides{kj}, '.dat') ,'r');
        simul_A_data = textscan(file_id_A_simul, '%s%n', 'Delimiter', ',', 'HeaderLines', 3);
        fclose(file_id_A_simul);
        simul_st = simul_A_data{1,1};
        simul_A = simul_A_data{1,2};
        
        %reading measured g  data
        file_id_g_meas = fopen(strcat(path_add_ag, '/','measured_g_', pTides{kj}, '.dat') ,'r');
        meas_g_data = textscan(file_id_g_meas, '%s%n', 'Delimiter', ',', 'HeaderLines', 3);
        fclose(file_id_g_meas);
        meas_st = meas_g_data{1,1};
        meas_g = meas_g_data{1,2};
        
        %reading simulated g  data
        file_id_g_simul = fopen(strcat(path_6_ag, '/','simulated_g_', pTides{kj}, '.dat') ,'r');
        simul_g_data = textscan(file_id_g_simul, '%s%n', 'Delimiter', ',', 'HeaderLines', 3);
        fclose(file_id_g_simul);
        simul_st = simul_g_data{1,1};
        simul_g = simul_g_data{1,2};
        
        % % % plot A meas and A simul of stations for each tide
        % % % plot(meas_A,'rx')
        % % % hold on
        % % % plot(simul_A,'bx')
        % % % dff = abs(simul_A - meas_A);
        % % % plot(dff ,'+g')
        % % % set(gca, 'XTick', 1:length(meas_st))
        % % % set(gca,'XtickLabel',meas_st)
        % % % title(strcat('"A" comparison', ' for tide : ', pTides{kj}));
        % % % legend('Measured','Simulated','Difference');
        % % % xlabel('Stations');
        % % % ylabel('Amplitude');
        % % % xtickangle(45);
        % % % strValues = strtrim(cellstr(num2str([dff],'(%d)')));
        % % % text(yyy,dff,strValues,'VerticalAlignment','bottom');
        % % % save_name_A = strcat(path_7, '/','A comparison', ' for tide ', pTides{kj});
        % % % savefig(save_name_A);
        % % % saveas(gca, save_name_A , 'jpeg');
        % % % clf
        % % % close
        
        %plot A meas and A simul of stations for each tide
        %         h = figure('visible','on');
        %         plot(meas_A,'rx')
        %         hold on
        %         plot(simul_A,'bx')
        %         set(gca, 'XTick', 1:length(meas_st))
        %         set(gca,'XtickLabel',meas_st)
        %         title(strcat('"A" comparison', ' for tide : ', pTides{kj}));
        %         legend('Measured','Simulated');
        %         xlabel('Stations');
        %         ylabel('Amplitude');
        %         xtickangle(45);
        %         save_name_A = strcat(path_7 , '/','A comparison', ' for tide ', pTides{kj});
        %         savefig(save_name_A);
        %         saveas(gca, save_name_A , 'jpeg');
        %         clf
        %         close(h)
        h = figure('visible','off');
        ax1 = subplot(2,1,1);
        plot(meas_A,'rx')
        hold on
        plot(simul_A,'bx')
        legend('Measured','Simulated');
        set(gca, 'XTick', 1:length(meas_st))
        set(gca,'XtickLabel',meas_st)
        title(strcat('Amplitude comparison', ' for tide : ', pTides{kj}));
        ylabel('Amplitude');
		ylim([0 inf]);

        
        dff = simul_A - meas_A;
        
        ax2 = subplot(2,1,2);
        plot(dff, 'kx')
        set(gca, 'XTick', 1:length(meas_st))
        set(gca,'XtickLabel',meas_st)
        title(strcat('Amplitude difference', ' for tide : ', pTides{kj}));
        xlabel('Stations');
        ylabel('Amplitude Diffrence');
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
        
        save_name_A = strcat(path_7, '/','A comparison', ' for tide ', pTides{kj});
        %savefig(save_name_A);
        saveas(gca, save_name_A , 'jpeg');
        clf
        close(h)
        
        %plot g meas and g simul of stations for each tide
        %         h = figure('visible','on');
        %         plot(meas_g,'rx')
        %         hold on
        %         plot(simul_g,'bx')
        %         set(gca, 'XTick', 1:length(meas_st))
        %         set(gca,'XtickLabel',meas_st)
        %         title(strcat('"g" comparison', ' for tide : ', pTides{kj}));
        %         legend('Measured','Simulated');
        %         xlabel('Stations');
        %         ylabel('Phase shift');
        %         xtickangle(45);
        %         save_name_g = strcat(path_7 , '/','g comparison', ' for tide ', pTides{kj});
        %         savefig(save_name_g);
        %         saveas(gca, save_name_g , 'jpeg');
        %         clf
        %         close(h)
        h = figure('visible','off');
        ax1 = subplot(2,1,1);
        plot(meas_g,'rx')
        hold on
        plot(simul_g,'bx')
        legend('Measured','Simulated');
        set(gca, 'XTick', 1:length(meas_st))
        set(gca,'XtickLabel',meas_st)
        title(strcat('Phase shift comparison', ' for tide : ', pTides{kj}));
        ylabel('Phase shift');
		ylim([0 360]);
        
        dff = simul_g - meas_g;
        
        ax2 = subplot(2,1,2);
        plot(dff ,'kx')
        set(gca, 'XTick', 1:length(meas_st))
        set(gca,'XtickLabel',meas_st)
        xlabel('Stations');
        ylabel('Phase shift Diffrence');
		ylim([-30 30]);
        
        linkaxes([ax1 , ax2] , 'x');
        
        grid(ax1,'on');
        grid(ax2,'on');
        pbaspect(ax1 , 'auto') %or [x y z]
        pbaspect(ax2 , 'auto')
        
        %set(ax1,'position',[.1 .4 .8 .5])
        %set(ax2,'position',[.1 .1 .8 .3])
        
        xtickangle(ax1,45);
        xtickangle(ax2,45);
        
        save_name_g = strcat(path_7, '/','g comparison', ' for tide ', pTides{kj});
        %savefig(save_name_g);
        saveas(gca, save_name_g , 'jpeg');
        clf
        close(h)
        
    end
end
close all