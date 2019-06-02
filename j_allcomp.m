%% main aim
%**********
% these functions are built in order to compare water level and/or partial tides parameters
% between a set of measured data and an extracted set of simulated data from a telemac file
% (aka seraphin file).
% each function is a part of the whole process, depending on the required output different
% combination of functions can be done (switch case)
% functions sequence:
% - a_precomp
% - b_extelemac
% - c_wlfilepep
% - d_wlcomp
% - e_excoef
% - f_ptcomp
% - g_salinitycomp
% - h_velocitycomp
% - i_wavecomp


function j_allcomp(varsToEval , telemac_module , common_folder , basefolder , slfFile ,main_path , date_a , period , k , doA, doB, doC, doD, doE, doF, doG, doH, doI, offset)

        % a_precomp
        % *********
        % Check available measurements for gaps!
        % Based on stations database (info_all_stations.dat') the stations
        %          ******************************************
        % are selected to work on. Precomp generates list of stations
        % containing valid data.
        %
        % Alternatively, user can specify the file 'required_stations.dat'
        %                                           *********************
        % in this folder, just containing a list of station names to be
        % considered.
        %
        if doA
			a_precomp (common_folder, date_a , period )
		end
        
        % b_extelemac
        % ***********
        % Extracts time series from Telemac results file according to the
        % setting of which variables. The stations to extract from come
        % from the station databse file 'info_all_stations.dat'
        %                                *********************
        % varsToEval, available:
        % check telemac variables dictionaries
        % define it as string cell of abbreviation :
        % for example {'U','V','S'}
        % salinity is added as SLNT
        %
        % telemac_module, '2D' or '3D' (others to be added later)
        % telemac_module will define which dictionary has to be used when
        % extracting telemac variables

        if doB
			b_extelemac (common_folder , basefolder , slfFile , varsToEval , ' ' , telemac_module)
		end
        
        % c_wlfileprep
        % ************
        % routine compares available time series from
        % - measurements
        % - simulations
        % - database (This could be already an issue in the previous
        % routine b_extelemac. There, the points are already excluded. As
        % this routine can be called seperately, an additional check is
        % wise to do)
        if doC
			c_wlfileprep (common_folder , basefolder )
		end
        
        % comparing water levels by generating plots
        %
        if doD
			d_wlcomp( common_folder , basefolder , main_path , date_a , period , k, offset)
		end
        
        % carrying out tidal analysis
        %
        if doE
			e_excoef(common_folder, basefolder , main_path, date_a , period, k, offset)
		end
        
        %comparing parameters from tidal analysis
        %
        if doF
			f_ptcomp(common_folder , basefolder )
        end
        
        %salinity comparison
        %
        if doG
            g_salinitycomp (common_folder , basefolder , date_a , period, offset )
        end
        
        %velocity comparison
        %
        if doH
            h_velocitycomp (common_folder , basefolder , date_a , period, offset )
        end
        
        %wave comparison
        %
        if doI
            i_wavecomp (common_folder , basefolder , date_a , period, offset )
        end
end



