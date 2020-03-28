% EXTRACT FEATURE
clear;clc;
str_path_matsource_root = "./result_mat/src_190307/";
str_path_matresult_root = "./result_mat/feat_190307/";
mkdir_ifnotexist( str_path_matresult_root );

load('./rating/rating_new_181217.mat');

list_dir_version = dir_fldrs( str_path_matsource_root );
list_test=[];
for idx_version = 1:length(list_dir_version)
    str_curversion = list_dir_version(idx_version).name;
    str_path_files_root = string(strcat( str_path_matsource_root, str_curversion, '/' ));
    
    %check folder in result
    mkdir_ifnotexist( string(strcat( str_path_matresult_root, str_curversion )) );

    list_mat_files = dir( string(strcat( str_path_files_root, "*.mat" )) );
    file_log = fopen("logs03.txt","wt");
    for idx_files = 1:length(list_mat_files)
        str_curfile = list_mat_files(idx_files).name;
        
        str_subject_visit = strsplit(str_curfile,'_');
        str_subject_visit = str_subject_visit{1};
        str_subject_visit = strsplit(str_subject_visit,'-');
        idx_visit   = str2double(str_subject_visit{2});
        str_subject = str_subject_visit{1};
        %idx_subject = find(mat_ID == str_subject);
        idx_subject = find(strcat(str_subject,'-',num2str(idx_visit)) == str_patient_visit);
        if( isempty(idx_subject) )
            %fprintf("ERROR: HAMD score not found; %s-%d\n",str_subject,idx_visit);
            fprintf(file_log,"ERROR: HAMD score not found; %s-%d\n",str_subject,idx_visit);
            continue;
        end
        if( isnan(mat_HAMD(idx_subject)) )
            %fprintf("ERROR: HAMD score ISNAN; %s-%d\n",str_subject,idx_visit);
            fprintf(file_log,"ERROR: HAMD score ISNAN; %s-%d\n",str_subject,idx_visit);
            continue;
        end
        
        str_filepath = strcat( str_path_files_root, str_curfile );
        load(str_filepath);
        idx_segment_file = 1;
        str_patterns_bak = str_patterns;
        str_patterns(5:6) = [];
        fps = 1/tstamp(1);
        
        for idx_segment = 1:size(idx_segments,1)
            idx_segment_file = idx_segment_file+1;
            mat_coords = cell_coords_info{idx_segment,1};
            mat_tstamp = cell_coords_info{idx_segment,2};
            mat_coords = mat_coords(1:end -mod(size(mat_coords,1),fps),:);
            
            if(size(mat_coords,1) < fps * 60 ) %if segment length is less than 1 minute
                %fprintf("FILETOOSHORT SKIPPED: %%s-%s_%s\n",str_subject_visit{1},str_subject_visit{2},sprintf("%03d",idx_segment_file));
                fprintf(file_log,"FILETOOSHORT SKIPPED: %s-%s_%s\n",str_subject_visit{1},str_subject_visit{2},sprintf("%03d",idx_segment_file));
                continue;
            end
            
            mat_hand_coords = mat_coords(:,reshape([5;6] + [0:2].*length(str_patterns_bak),[],1));
            mat_coords(:,reshape([5;6] + [0:2].*length(str_patterns_bak),[],1)) = [];
            int_debug = sum(isnan(mat_coords(:)));
            %speed per points - euclidean distance (1/30s)
            mat_pos_eucdist = zeros(size(mat_coords,1),length(str_patterns)); 
            for idx_pattern = 1:length(str_patterns)
                mat_pos_eucdist(:,idx_pattern) = ...
                    sqrt(sum( mat_coords(:,idx_pattern:length(str_patterns):end).^2,2 ));
            end
            
            mat_coords_per1sec = reshape(mat_coords,fps,[],size(mat_coords,2));
            mat_speed = diff(mat_coords); %speed per coordinates (1/30s)
            mat_speed_per1sec = diff(mat_coords_per1sec);
            mat_speed_per1sec = reshape(sum(mat_speed_per1sec),[],length(str_patterns)*3);
            %speed per points - euclidean distance (1/30s)
            mat_speed_eucdist = zeros(size(mat_speed,1),length(str_patterns)); 
            for idx_pattern = 1:length(str_patterns)
                mat_speed_eucdist(:,idx_pattern) = ...
                    sqrt(sum( mat_speed(:,idx_pattern:length(str_patterns):end).^2,2 ));
            end

            %speed per points - euclidean distance (1 second)
            mat_speed_eucdist_per1sec = zeros(size(mat_speed_per1sec,1),length(str_patterns));
            for idx_pattern = 1:length(str_patterns)
                mat_speed_eucdist_per1sec(:,idx_pattern) = ...
                    sqrt(sum( mat_speed_per1sec(:,idx_pattern:length(str_patterns):end).^2,2 ));
            end

            %speed: prctiles, average, std
            mat_speed_prctiles = prctile(mat_speed_eucdist_per1sec,[5,50,95]);
            speed_std = sqrt(var(mat_speed_eucdist_per1sec));
            speed_avg = mean(mat_speed_eucdist_per1sec);

            %acceleration: prctiles, average, std
            mat_acc_eucdist_per1sec = diff(mat_speed_eucdist_per1sec);
            mat_acc_prctiles = prctile(mat_acc_eucdist_per1sec,[5,50,95]);
            acc_std = sqrt(var(mat_acc_eucdist_per1sec));
            acc_avg = mean(mat_acc_eucdist_per1sec);

            %position: prctiles, average, std
            mat_pos_prctiles = prctile(mat_pos_eucdist,[5,50,95]);
            pos_std = sqrt(var(mat_pos_eucdist));
            pos_avg = mean(mat_pos_eucdist);

            %jerk: prctiles, average, std
            mat_jerk_eucdist_per1sec = diff(mat_acc_eucdist_per1sec);
            mat_jerk_prctiles = prctile(mat_jerk_eucdist_per1sec,[5,50,95]);
            jerk_std = sqrt(var(mat_jerk_eucdist_per1sec));
            jerk_avg = mean(mat_jerk_eucdist_per1sec);

            total_distance_travelled = sum(mat_speed_eucdist_per1sec);

            % Distance from starting point
            mat_distance = mat_coords(2:end,:) - mat_coords(1,:);
            mat_distance_eucdist = zeros(size(mat_distance,1),length(str_patterns)); 
            for idx_pattern = 1:length(str_patterns)
                mat_distance_eucdist(:,idx_pattern) = ...
                    sqrt(sum( mat_distance(:,idx_pattern:length(str_patterns):end).^2,2 ));
            end
            max_distance_eucdist = max( mat_distance_eucdist );

            %correlation
            mat_corr_speed_per1sec = zeros(length(str_patterns));
            for idx_pattern = 1:length(str_patterns)
                mat_corr_speed_per1sec(idx_pattern,:) = corr(mat_speed_eucdist_per1sec(:,idx_pattern),mat_speed_eucdist_per1sec);
            end
            
            mat_feats = [...
            mat_pos_prctiles;...
            pos_std;...
            pos_avg;...
            mat_speed_prctiles;...
            speed_std;...
            speed_avg;...
            mat_acc_prctiles;...
            acc_std;...
            acc_avg;...
            mat_jerk_prctiles;...
            jerk_std;...
            jerk_avg;...
            mat_corr_speed_per1sec;...
            total_distance_travelled;...
            max_distance_eucdist;...
            ];
        mat_feats_explanation = [...
            ["Position - Percentiles (5)";"Position - Percentiles (50)";"Position - Percentiles (95)"];...
            "Position - Standard Deviation";...
            "Position - Average";...
            ["Speed - Percentiles (5)";"Speed - Percentiles (50)";"Speed - Percentiles (95)"];...
            "Speed - Standard Deviation";...
            "Speed - Average";...
            ["Acceleration - Percentiles (5)";"Acceleration - Percentiles (50)";"Acceleration - Percentiles (95)"];...
            "Acceleration - Standard Deviation";...
            "Acceleration - Average";...
            ["Jerk - Percentiles (5)";"Acceleration - Percentiles (50)";"Acceleration - Percentiles (95)"];...
            "Jerk - Standard Deviation";...
            "Jerk - Average";...
            "Correlation (Speed): "+str_patterns;...
            "Total Distance Travelled"; ...
            "Max Distance (Euclidean)"; ...
            ];

            %body angle 1&2, 3&4
            angle1_spinehead = get_angles(mat_coords(:,2:length(str_patterns):end),mat_coords(:,1:length(str_patterns):end));
            angle2_shoulderlr = get_angles(mat_coords(:,4:length(str_patterns):end),mat_coords(:,3:length(str_patterns):end));
            
            mat_angle = [angle1_spinehead, angle2_shoulderlr];
            mat_angle_feats = [...
                prctile(mat_angle,[5,50,95]); ...
                std(mat_angle); ...
                mean(mat_angle); ...
                ];
            
            %additional features
            %Forward Slouching: angle1, YZ
            slouch_angle = 110; %180 - 70 deg
            ratio_forwardslouch = sum(angle1_spinehead(:,2) >= slouch_angle) / length(angle1_spinehead(:,2));
            %shoulder moving (shoulder) angle2, XZ
            stdev_shoulders = std(cosd(angle2_shoulderlr(:,3)));
            
            %ratio hand approaches head (both left and right hand)
            distance_hand_head = zeros(size(mat_hand_coords,1),2);
            distance_hand_head(:,1) = sqrt(sum((mat_hand_coords(:,1:2:end)-mat_coords(:,2+[0:2].*length(str_patterns))).^2,2));
            distance_hand_head(:,2) = sqrt(sum((mat_hand_coords(:,2:2:end)-mat_coords(:,2+[0:2].*length(str_patterns))).^2,2));
            th_hand2head = 0.175;
            ratio_hand2head = sum(distance_hand_head(:) < th_hand2head) / sum(~isnan(distance_hand_head(:)));
            
            mat_additional_feats = [...
                ratio_hand2head;    ...
                ratio_forwardslouch; ...
                stdev_shoulders; ...
                ];
            while( isfile(...
                    char(strcat(...
                    str_path_matresult_root, ...
                    str_curversion, '/', ...
                    str_subject_visit{1},"-",str_subject_visit{2},"_",char(idx_segment_file + 'A'), ...
                    ".mat" ...
                    ) ) ) )
                idx_segment_file = idx_segment_file + 1;
            end
            save( char(strcat(...
                str_path_matresult_root, ...
                str_curversion, '/', ...
                str_subject_visit{1},"-",str_subject_visit{2},"_",sprintf("%03d",idx_segment_file), ...
                ".mat" ...
                ) ), 'mat_feats', 'mat_feats_explanation', 'mat_angle', 'mat_angle_feats', 'mat_additional_feats', 'mat_coords', 'mat_tstamp');
        end
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

function xyz_angles = get_angles(pts,ref)
    dcoords = pts-ref;
    X = dcoords(:,1);
    Y = dcoords(:,2);
    Z = dcoords(:,3);
    xyz_angles = [...
        atan2d(Y , X), ...
        atan2d(Y , Z), ...
        atan2d(Z , X), ...
        ];
    
    %YX <90 tilt to left (patient), >90 tilt to right (patient)
    %YZ <90 slouch back, >90 slouch front
    %ZX +   right shoulder forward, - left shoulder forward
end