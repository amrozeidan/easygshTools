

folder = '/Users/amrozeidan/Desktop/EasyGSH/merge_rio_ncdf' ;

riofilepath = dir(strcat(folder , '/prepared_data_zeitrio'));
ncdf = dir(strcat(folder , '/prepared_data_ncdf'));

rioyears = {riofilepath(:).name} ;
ncdfyears = {ncdf(:).name} ;
inter = intersect(rioyears , ncdfyears) ;
years =inter(~isnan(str2double(inter))) ;

var_name = { '*wl*'  '*sa*' '*cu*' '*wv*' } ;

for y=1:length(years)
    
    for v=1:length(var_name)
        riolist = dir(fullfile(strcat(folder , '/prepared_data_zeitrio/' , years{y} ) , var_name{v}));
        riofilepath = strcat(riolist(1).folder , '/' , riolist(1).name) ;
        
        ncdflist = dir(fullfile(strcat(folder , '/prepared_data_ncdf/' , years{y} ) , var_name{v}));
        ncdffilepath = strcat(ncdflist(1).folder , '/' , ncdflist(1).name) ;
        
        
        Trio = readtable(riofilepath , 'Delimiter' , ',' , 'ReadVariableNames' , true);
        Trio.Time = datetime (Trio.Time , 'InputFormat' , 'dd.MM.yyyy HH:mm:ss' );
        Trio = table2timetable(Trio);
        
        Tncdf = readtable(ncdffilepath , 'Delimiter' , ',' , 'ReadVariableNames' , true);
        Tncdf.Time = datetime (Tncdf.Time , 'InputFormat' , 'dd-MM-yyyy HH:mm:ss' );
        Tncdf = table2timetable(Tncdf);
        
        rionames = Trio.Properties.VariableNames ;
        ncdfnames = Tncdf.Properties.VariableNames ;
        
        commonnames = intersect(rionames , ncdfnames)';
        
        if length(commonnames) ~= length(ncdfnames)
            Tncdf_new = removevars(Tncdf , commonnames);
            Trioncdf = join(Trio , Tncdf_new);
        else
            Trioncdf = Trio ;
        end
        
        writetable(timetable2table(Trioncdf) , char( strcat(folder , '/prepared_data_merged_zeitrio_ncdf/' , years{y} , '.' , replace(var_name{v} , '*' , '') , '.dat') ))
        
    end
    
    
end







