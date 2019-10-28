
centralFolder = 'D:/7_Projekte/2017_EasyGSH/03_Arbeitspakete/2_Hydraulik/4_ValidationData' ;

var_name = { '*wl*'  '*sa*' '*cu*' '*wv*' } ;

for year = 2001 : 2001
    year
    for v=1:length(var_name)
        var_name(v)
        riolist = dir(fullfile(strcat(centralFolder ,'/', string(year),'_validationData/prepared_data_zeitrio/'), var_name{v}));
        if ~isempty(riolist)
            riofilepath = strcat(riolist(1).folder , '/' , riolist(1).name) ;
        end
                
        ncdflist = dir(fullfile(strcat(centralFolder ,'/', string(year),'_validationData/prepared_data_ncdf/' ),var_name{v}));
        if ~isempty(ncdflist)
            ncdffilepath = strcat(ncdflist(1).folder , '/' , ncdflist(1).name) ;
        end
        
        commonNames={};
        if ~isempty(riolist)
            Trio = readtable(riofilepath , 'Delimiter' , ',' , 'ReadVariableNames' , true);
            Trio.Time = datetime (Trio.Time , 'InputFormat' , 'dd.MM.yyyy HH:mm:ss' );
            Trio = table2timetable(Trio);
            rioNames = Trio.Properties.VariableNames ;
            commonNames = rioNames;
        end
        
        if ~isempty(ncdflist)
            Tncdf = readtable(ncdffilepath , 'Delimiter' , ',' , 'ReadVariableNames' , true);
            Tncdf.Time = datetime (Tncdf.Time , 'InputFormat' , 'dd-MM-yyyy HH:mm:ss' );
            Tncdf = table2timetable(Tncdf);
            ncdfNames = Tncdf.Properties.VariableNames ;
            if ~isempty(riolist)
                commonNames = intersect(rioNames , ncdfNames)';
            else
                commonNames = ncdfNames;
            end
        end
        
        if ~isempty(commonNames)
            if ~isempty(riolist) && ~isempty(ncdflist)

                if length(rioNames) > length(ncdfNames)
                    Trio = removevars(Trio, commonNames);
                elseif length(rioNames) < length(ncdfNames)
                    Tncdf=removevars(Tncdf, commonNames);
                else
                    if length (rioNames) == length(commonNames)
                        riolist = {};
                    else
                        Trio = removevars(Trio, commonNames);
                    end
                end
            end
        end
            
            S = timerange (datetime(year,1,1,0,0,0),datetime(year,12,31,23,50,0),'closed');
            if ~isempty(riolist) && isempty (ncdflist)
                Trioncdf = Trio(S,:) ;
            elseif ~isempty(ncdflist) && isempty (riolist)
                Trioncdf = Tncdf(S,:) ;
            else
                Trioncdf = join(Trio(S,:) , Tncdf(S,:));
            end
            
            mkdir (strcat(centralFolder, '/', string(year),'_validationData/measurements'))
            writetable(timetable2table(Trioncdf) , char( strcat(centralFolder, '/', string(year),'_validationData/measurements/' , string(year) , '.' , replace(var_name{v} , '*' , '') , '.dat') ))
    end
end







