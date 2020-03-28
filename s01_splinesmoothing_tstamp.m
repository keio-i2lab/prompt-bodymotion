% EXTRACT FEATURE: extract speed - quartiles and standard deviation
clear;
fps = 30;
segment_threshold = 5; %5 sec
smoothingparam = 0.995; 

str_path_matsource_root = "./data_mat/";
str_path_matresult_root = "./result_mat/src_181222/";
mkdir_ifnotexist( str_path_matresult_root );

list_dir_version = dir_fldrs( str_path_matsource_root );

for idx_version = 1:length(list_dir_version)
    str_curversion = list_dir_version(idx_version).name;
    str_path_files_root = string(strcat( str_path_matsource_root, str_curversion, '/' ));
    
    %check folder in result
    mkdir_ifnotexist( string(strcat( str_path_matresult_root, str_curversion )) );

    list_mat_files = dir( string(strcat( str_path_files_root, "*.mat" )) );
    %list_mat_files = dir( string(strcat( str_path_files_root, "*csv.mat" )) );
    %for idx_files = 1:length(list_mat_files)
    file_log = fopen("logs01_v2.txt","wt");
	for idx_files = 1:length(list_mat_files)
        str_curfile = list_mat_files(idx_files).name;
        str_filepath = strcat( str_path_files_root, str_curfile );
        if( isfile( strcat(str_path_matresult_root,str_curversion,"/",str_curfile) ) )
            continue
        end
        load(str_filepath);
        %NaN check
        bool_nanflag = false;
        for idx_col = 1:size(mat_coords,2)
            if( sum(isnan(mat_coords(:,idx_col))) == size(mat_coords,1) )
                bool_nanflag = true;
                break;
            end
        end
        if(bool_nanflag)
            %fprintf("FEAT_EXT SKIPPED: %s\n",str_curfile);
            fprintf(file_log,"COORDS-ALLNAN SKIPPED: %s\n",str_curfile);
            continue;
        end
        
        %pow10 = 10 ^ ceil( log10(tstamp(1)) - log10(tstamp_abs(1)) );
        %tstamp = tstamp_abs .* pow10;
        tstamp = [1:size(mat_coords,1)]' ./ fps;
        
        cell_coords_info = cell(0);
        cell_tstamp = cell(0,size(mat_coords,2));
        %get timestamp of segments
        for idx_col = 1:length(str_patterns) -2
            %get start indexes
            idx_split = [0;find(diff(isnan(mat_coords(:,idx_col))) ~= 0);size(mat_coords,1)];
            if( isnan(mat_coords(1,idx_col)) )
                idx_split(1) = [];
            end
            if( isnan(mat_coords(end,idx_col)) )
                idx_split(end) = [];
            end
            idx_segments = reshape(idx_split,2,[])';
            idx_segments(:,1) = idx_segments(:,1)+1;
            
            idx_segment = 1;
            while idx_segment < size(idx_segments,1)-1
                while( ...
                        idx_segments(idx_segment+1,1) - idx_segments(idx_segment,2)...
                        < segment_threshold * fps )
                        idx_segments(idx_segment,2) = idx_segments(idx_segment+1,2);
                        idx_segments(idx_segment+1,:) = [];
                        if( idx_segment == size(idx_segments,1) )
                            break
                        end
                end
                idx_segment = idx_segment + 1;
            end
            
            %check segment length
            length_idx_segments = idx_segments(:,2) - idx_segments(:,1) + 1;
            idx_segments( length_idx_segments < fps, : ) = [];
            
            for idx_segment = 1:size(idx_segments,1)
                idx_tmp = idx_segments(idx_segment,1):idx_segments(idx_segment,2);

                cell_tstamp{idx_segment,idx_col} = tstamp(idx_tmp);
                cell_tstamp{idx_segment,idx_col+length(str_patterns)} = tstamp(idx_tmp);
                cell_tstamp{idx_segment,idx_col+2*length(str_patterns)} = tstamp(idx_tmp);
            end
        end
        
        %process timestamp to segments (use the largest number of segments)
        flag_tstamp = zeros(size(tstamp));
        for idx_col = 1:length(str_patterns) -2
            for idx_segment = 1:size(cell_tstamp,1)
                if( isempty(cell_tstamp{idx_segment,idx_col}) )
                    continue
                end
                flag_tstamp( ismember(tstamp,cell_tstamp{idx_segment,idx_col}) ) = ...
                flag_tstamp( ismember(tstamp,cell_tstamp{idx_segment,idx_col}) ) + 1;
            end
        end
        
        %get indexes here
        segment_tstamp = flag_tstamp == length(str_patterns) -2;
        idx_segments  = [...
            [0;find(diff(segment_tstamp) ~= 0)]+1, ...
            [find(diff(segment_tstamp) ~= 0);length(tstamp)] ];
        
        %remove nan segments
        segment_toremove = boolean(zeros(size(idx_segments,1),1));
        for idx_segment = 1:length(segment_toremove)
            if( all(segment_tstamp(idx_segments(idx_segment,1):idx_segments(idx_segment,2)) ==0 ) ) 
                segment_toremove(idx_segment) = true;
            end
        end
        idx_segments(segment_toremove,:) = [];
        
        %remove short segments
        segment_toremove = boolean(zeros(size(idx_segments,1),1));
        for idx_segment = 1:length(segment_toremove)
            if( length(segment_tstamp(idx_segments(idx_segment,1):idx_segments(idx_segment,2))) < 2 ) 
                segment_toremove(idx_segment) = true;
            end
            if( any(sum(~isnan(mat_coords(idx_segments(idx_segment,1):idx_segments(idx_segment,2),:))) <= 2) )
                segment_toremove(idx_segment) = true;
            end
        end
        idx_segments(segment_toremove,:) = [];
        if(isempty(idx_segments))
            %fprintf("FEAT_EXT SKIPPED: %s\n",str_curfile);
            fprintf(file_log,"NOSEGMENTS SKIPPED: %s\n",str_curfile);
            continue;
        end
        %segment here (according to timestamp)
        for idx_segment = 1:size(idx_segments,1)
        	idx_tmp = idx_segments(idx_segment,1):idx_segments(idx_segment,2);
            idx_col_exception = reshape([5;6]+[0,1,2].*length(str_patterns),[],1);
            coords_tmp = spline_smoothing(...
            	mat_coords(idx_tmp,setdiff(1:end,idx_col_exception)), ...
                tstamp(idx_tmp),...
                smoothingparam);
            mat_coords(idx_tmp,setdiff(1:end,idx_col_exception)) = coords_tmp;
            cell_coords_info{idx_segment,1} = mat_coords(idx_tmp,:);
            cell_coords_info{idx_segment,2} = tstamp(idx_tmp);
        end
        
        save( char(strcat(...
        	str_path_matresult_root, ...
            str_curversion, '/', ...
            str_curfile ...
            ) ),'fps','cell_coords_info','tstamp','idx_segments','str_patterns' );
        
        %{
        mat_coords_ss = spline_smoothing(mat_coords,tstamp, smoothingparam); %use time / fps
        save( char(strcat(...
        	str_path_matresult_root, ...
            str_curversion, '/', ...
            str_curfile ...
            ) ),'fps','mat_coords','mat_coords_ss','tstamp','str_patterns' );
        %}
    end
    fclose(file_log);
end

function list_dirs = dir_fldrs( str_path )
    list_dirs = dir( str_path );
    dir_flags = [list_dirs.isdir] & ~strcmp({list_dirs.name},'.') & ~strcmp({list_dirs.name},'..');
    list_dirs = list_dirs(dir_flags);
end

function mkdir_ifnotexist( str_path )
    if ~exist(str_path,'dir')
        mkdir(str_path);
    end
end

function Y = spline_smoothing(X,t,smoothingparam)
    Y = X;
    for idx_col = 1:size(X,2)
        idx_notnan = ~isnan(X(:,idx_col));
        if isempty(smoothingparam)
            f = fit( ...
                t(idx_notnan),...
                X(idx_notnan,idx_col),...
                'smoothingspline');
        else
            f = fit( ...
                t(idx_notnan),...
                X(idx_notnan,idx_col),...
                'smoothingspline','SmoothingParam',smoothingparam);
        end
        Y(:,idx_col) = f(t);
    end
end