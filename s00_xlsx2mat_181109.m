% EXTRACT DATA & save it to result folder (NO FILLMISSING YET)
clear;
str_path_csvsource_root = "./Rawdata/";
str_path_matresult_root = "./data_mat/";
mkdir_ifnotexist( str_path_matresult_root );

list_dir_version = dir_fldrs( str_path_csvsource_root );

for idx_version = 1:length(list_dir_version)
    str_curversion = list_dir_version(idx_version).name;
    str_path_files_root = string(strcat( str_path_csvsource_root, str_curversion, '/' ));
    
    %check folder in result
    mkdir_ifnotexist( string(strcat( str_path_matresult_root, str_curversion )) );

    list_csv_files1 = dir( string(strcat( str_path_files_root, "*.csv" )) );
    list_csv_files2 = dir( string(strcat( str_path_files_root, "*.xlsx" )) );
    list_csv_files = [list_csv_files1; list_csv_files2];
    for idx_files = 1:length(list_csv_files)
        str_curfile = list_csv_files(idx_files).name;
        
        if( isfile( strcat(str_path_matresult_root, str_curversion, '/', str_curfile, ".mat") ) )
            continue
        end
        disp(str_curfile);
        str_filepath = strcat( str_path_files_root, str_curfile );
        
        [~,csv_string,~] = xlsread( str_filepath, 'A1:ZZ2' );
        [~,~,csv_data] = xlsread( str_filepath, 'A:A' );
        
        %first row = find ROIs
        str_patterns = [ ...
            ..."spinemid";...
            "spineshoulder";...
            "head";...
            "shoulderleft";...
            "shoulderright";...
            "handleft";...
            "handright";...
            ];
        idx_str_patterns = zeros(size(str_patterns));
       	for idx_pattern = 1:length(str_patterns)
            idx_str_patterns(idx_pattern) = min( find( strcmpi(csv_string(1,:),strcat(str_patterns(idx_pattern))) ) );
        end
        
        %process boundary
        idx_start_row = 3;
        idx_end_row = max(find(~isnan(cell2dblmat(csv_data(3:end))))) +2;
        idx_boundary = idx_start_row:idx_end_row;
        if isempty(idx_boundary)
            fprintf("XLS2MAT SKIPPED: %s\n",str_curfile);
            continue; %bad data
        end
        str_tstamp = "relative time";
        idx_tstamp = min(find( strcmpi( csv_string(2,:),str_tstamp ) ));
        %( idx_boundary, idx_tstamp );
        str_range = string(strcat( ...
            excel_num2col(idx_tstamp), ...
            num2str(idx_start_row), ...
            ':',...
            excel_num2col(idx_tstamp), ...
            num2str(idx_end_row) ));
        [~,~,csv_data] = xlsread( str_filepath, str_range );
        tstamp = cell2dblmat( csv_data ); %relative time
        
        str_tstamp = "absolute time";
        idx_tstamp = min(find( strcmpi( csv_string(2,:),str_tstamp ) ));
        %( idx_boundary, idx_tstamp );
        str_range = string(strcat( ...
            excel_num2col(idx_tstamp), ...
            num2str(idx_start_row), ...
            ':',...
            excel_num2col(idx_tstamp), ...
            num2str(idx_end_row) ));
        [~,~,csv_data] = xlsread( str_filepath, str_range );
        tstamp_abs = cell2mat( csv_data ); %relative time
        
        %cell_X = cell(1,length(str_patterns));
        %cell_Y = cell(1,length(str_patterns));
        %cell_Z = cell(1,length(str_patterns));
        
        mat_coords = zeros(length(idx_boundary),3*length(str_patterns));
        %matcoords
        %[X1 X2 X3 X4, Y1 Y2 Y3 Y4, Z1 Z2 Z3 Z4]
        for idx_pattern = 1:length(str_patterns)
            str_range = string(strcat( ...
            excel_num2col( idx_str_patterns(idx_pattern) ), ... %X
            num2str(idx_start_row), ...
            ':',...
            excel_num2col( idx_str_patterns(idx_pattern)+2 ), ... %Z
            num2str(idx_end_row) ));
        
            [~,~,csv_data] = xlsread( str_filepath, str_range );
            tmp_data = cell2dblmat(csv_data);
            
        	X = tmp_data(:,1);
            Y = tmp_data(:,2);
            Z = tmp_data(:,3);
            
%             X(X == -1) = NaN;
%             Y(Y == -1) = NaN;
%             Z(Z == -1) = NaN;

            mat_coords(:, idx_pattern ) = X;
            mat_coords(:, idx_pattern + length(str_patterns) ) = Y;
            mat_coords(:, idx_pattern + length(str_patterns)*2 ) = Z;
        end
        save( char(strcat(...
        	str_path_matresult_root, ...
            str_curversion, '/', ...
            str_curfile, ...
            ".mat" ...
            ) ),'mat_coords','tstamp','str_patterns','tstamp_abs' );
    end
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

function X = cell2dblmat(X)
    try
        X = cell2mat(X);
    catch
        X = double( string( X ) );
    end
end

function str_colname = excel_num2col(int_colnum)
    int_first = floor((int_colnum-1) / 26);
    int_second = mod(int_colnum-1,26);
    
    str_colname = "";
    if(int_first > 0)
        str_colname = str_colname + char(int_first-1 + 'a');
    end
    str_colname = str_colname + char(int_second + 'a');
end