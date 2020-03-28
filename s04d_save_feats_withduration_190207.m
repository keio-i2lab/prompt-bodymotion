clear;clc;
str_path_matsource_root = "./result_mat/feat_190307/";
list_dir_version = dir_fldrs( str_path_matsource_root );

th_maxhealthy = 7;

cell_feats = cell(1,2);
load('./rating/rating_new_181217.mat');
file_log = fopen("logs04.txt","wt");
for idx_version = 1:length(list_dir_version)
    idx_h = 0;
    idx_d = 0;

    H = zeros(0,4,26);
    D = zeros(0,4,26);

    H_score = zeros(0);
    D_score = zeros(0);

    H_angle = zeros(0,6,5);
    D_angle = zeros(0,6,5);

    H_additional = zeros(0,1,3);
    D_additional = zeros(0,1,3);
    
    H_duration = zeros(0);
    D_duration = zeros(0);

    H_namelist = cell(0);
    D_namelist = cell(0);
    
    str_curversion = list_dir_version(idx_version).name;
    str_path_files_root = string(strcat( str_path_matsource_root, str_curversion, '/' ));
    
    list_mat_files = dir( string(strcat( str_path_files_root, "*.mat" )) );
    if(isempty(list_mat_files))
        continue
    end
    
    load( strcat( str_path_files_root, list_mat_files(1).name ) );
    for idx_files = 1:length(list_mat_files)
        str_curfile = list_mat_files(idx_files).name;
%         disp(str_curfile);
        str_filepath = strcat( str_path_files_root, str_curfile );
        
        str_subject_visit = strsplit(str_curfile,'_');
        str_subject_visit = str_subject_visit{1};
        str_subject_visit = strsplit(str_subject_visit,'-');
        idx_visit   = str2double(str_subject_visit{2});
        str_subject = str_subject_visit{1};
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
        load(str_filepath);
        
        if(mat_HAMD(idx_subject)<= th_maxhealthy) %healthy
            idx_h = idx_h+1;
            H(idx_h,:,:) = mat_feats';
            H_angle(idx_h,:,:) = mat_angle_feats';
            H_additional(idx_h,:,:) = mat_additional_feats';
            H_namelist{idx_h} = str_curfile;
            H_score(idx_h) = mat_HAMD(idx_subject);
            
            H_duration(idx_h) = size(mat_angle,1) / 30;
        else
            idx_d = idx_d+1;
            D(idx_d,:,:) = mat_feats';
            D_angle(idx_d,:,:) = mat_angle_feats';
            D_additional(idx_d,:,:) = mat_additional_feats';
            D_namelist{idx_d} = str_curfile;
            D_score(idx_d) = mat_HAMD(idx_subject);
            
            D_duration(idx_d) = size(mat_angle,1) / 30;
        end
    end
    mat_ALL_feats = D;
    mat_ALL_ANGLE_feats = D_angle;
    mat_ALL_ADD_feats = D_additional;
    cell_namelist = D_namelist;
    mat_score = D_score;
    mat_duration = D_duration;
    save( strcat("190207_D_",str_curversion),"mat_score","cell_namelist","mat_ALL_ANGLE_feats","mat_ALL_feats","mat_ALL_ADD_feats","mat_feats_explanation","mat_duration");
    mat_ALL_feats = H;
    mat_ALL_ANGLE_feats = H_angle;
    mat_ALL_ADD_feats = H_additional;
    cell_namelist = H_namelist;
    mat_score = H_score;
    mat_duration = H_duration;
    save( strcat("190207_H_",str_curversion),"mat_score","cell_namelist","mat_ALL_ANGLE_feats","mat_ALL_feats","mat_ALL_ADD_feats","mat_feats_explanation","mat_duration");
end
fclose(file_log);

function list_dirs = dir_fldrs( str_path )
    list_dirs = dir( str_path );
    dir_flags = [list_dirs.isdir] & ~strcmp({list_dirs.name},'.') & ~strcmp({list_dirs.name},'..');
    list_dirs = list_dirs(dir_flags);
end
