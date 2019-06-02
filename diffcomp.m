
%plots, water level
h = figure('visible','off');
plot(meas_dates_for_comp,meas_wl_for_comp,wl_simulated_dates_for_comp,wl_simulated_wl_for_comp);
title(strcat('Water Level comparison,', ' Station : ', Locations_Names(cwl)));
legend('Measurments','Simulations');
xlabel('Date/Time');
ylabel('Water Level [m]');
save_name = strcat(path_3, '/','Water Level comparison', '_Station_', Locations_Names{cwl});
savefig(h, save_name, 'compact');
saveas(gca, save_name , 'jpeg');
clf
close(h)

%water level difference
wl_diff = abs(wl_meas_sync_no_NaN - wl_simul_sync_no_NaN) ;

%plots, water level difference
h = figure('visible','off');
bar(date_sync_no_NaN, wl_diff);
title(strcat('Water Level difference,', ' Station : ', Locations_Names(cwl)));
xlabel('Date/Time');
ylabel('Water Level [m]');
save_name = strcat(path_3, '/','Water Level difference', '_Station_', Locations_Names{cwl});
savefig(h, save_name, 'compact');
saveas(gca, save_name , 'jpeg');
clf
close(h)

% combination of line and bar plot
h = figure('visible','on');
yyaxis left
plot(meas_dates_for_comp,meas_wl_for_comp,'-b');
hold on
plot(wl_simulated_dates_for_comp,wl_simulated_wl_for_comp,'-r');
yyaxis right 
bar(date_sync_no_NaN, wl_diff);

set(gca,'ylim',[0 15])
set(gca, 'YDir','reverse')

title(strcat('Water Level comparison and difference,', ' Station : ', Locations_Names(cwl)));
xlabel('Date/Time');
yyaxis left
ylabel('Water Level [m]');
yyaxis right 
ylabel('Water Level Difference [m]');
legend('Measurments','Simulations','Difference');

save_name = strcat(path_3, '/','Water Level comparison and difference', '_Station_', Locations_Names{cwl});
savefig(h, save_name, 'compact');
saveas(gca, save_name , 'jpeg');
clf
close(h)

%subplots 
h = figure('visible','on');
ax1 = subplot(2,1,1);
plot(meas_dates_for_comp,meas_wl_for_comp,'-b');
hold on
plot(wl_simulated_dates_for_comp,wl_simulated_wl_for_comp,'-r');
title(strcat('Water Level comparison,', ' Station : ', Locations_Names(cwl)));
legend('Measurments','Simulations');
ylabel('Water Level [m]');
set(gca, 'XTick',[])

ax2 = subplot(2,1,2);
bar(date_sync_no_NaN, wl_diff);
xlabel('Date/Time');
ylabel('Water Level Difference [m]');

linkaxes([ax1 , ax2] , 'x');

set(ax1,'position',[.1 .4 .8 .5])
set(ax2,'position',[.1 .1 .8 .3])

ax1.FontSize = 13;
ax2.FontSize = 12;

save_name = strcat(path_3, '/','Water Level comparison and difference', '_Station_', Locations_Names{cwl});
savefig(h, save_name, 'compact');
saveas(gca, save_name , 'jpeg');
clf
close(h)

%suptitle(strcat('Water Level comparison,', ' Station : ', Locations_Names(cwl)));

%plot A meas and A simul of stations for each tide
h = figure('visible','on');
ax1 = subplot(2,1,1);
plot(meas_A,'rx')
hold on
plot(simul_A,'bx')
legend('Measured','Simulated');
set(gca, 'XTick', 1:length(meas_st))
set(gca,'XtickLabel',meas_st)
title(strcat('"A" comparison', ' for tide : ', pTides{kj}));
ylabel('Amplitude');
set(gca, 'XTick',[])

dff = abs(simul_A - meas_A);

ax2 = subplot(2,1,2);
yyaxis right
bar(dff , 0.01 , 'b')
for i1=1:length(dff)
    text(i1 , dff(i1) , num2str(dff(i1),'%0.2f'), 'HorizontalAlignment','center','VerticalAlignment','bottom' )
end
set(gca, 'XTick', 1:length(meas_st))
set(gca,'XtickLabel',meas_st)
xlabel('Stations');
yyaxis right
ylabel('Amplitude Diffrence');
yyaxis left
set(gca, 'YTick',[])

linkaxes([ax1 , ax2] , 'x');

set(ax1,'position',[.1 .4 .8 .5])
set(ax2,'position',[.1 .1 .8 .3])

xtickangle(ax2,45);

save_name_A = strcat(path_7, '/','A comparison', ' for tide ', pTides{kj});
savefig(save_name_A);
saveas(gca, save_name_A , 'jpeg');
clf
close(h)












