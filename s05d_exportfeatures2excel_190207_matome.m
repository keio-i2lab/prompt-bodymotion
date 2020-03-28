clear; clc;

%target:
%4 dataset - all, noB, noH9-Y2, noB-H9-Y2
%3 session - free talk, rating, both

clear; clc;

str_path_matsource_root = "./result_mat/feat_190307/";
list_dir_version = dir_fldrs( str_path_matsource_root );

for idx_version = 1:length(list_dir_version)
    str_curversion = list_dir_version(idx_version).name;
    load(strcat("190207_D_",str_curversion));
    mat_ALL_feats = mat_ALL_feats(:,:,[1:26]);
    D_feats = zeros(size(mat_ALL_ANGLE_feats,1), ...
        size(mat_ALL_ANGLE_feats,2) * size(mat_ALL_ANGLE_feats,3) + ...
        size(mat_ALL_ADD_feats,2) * size(mat_ALL_ADD_feats,3)+ ...
        size(mat_ALL_feats,2) * size(mat_ALL_feats,3));
    D_score = mat_score';
    D_names = cell_namelist;
    for idx_data = 1:size(mat_ALL_ANGLE_feats,1)
        %feat1 (pt1, pt2, pt3, pt4) ... feat94 (pt1 pt2 pt3 pt4)
        D_feats(idx_data,:) = [...
            reshape(mat_ALL_feats(idx_data,:,:),1,[]),...
            reshape(mat_ALL_ANGLE_feats(idx_data,:,:),1,[]),...
            reshape(mat_ALL_ADD_feats(idx_data,:,:),1,[]),...
            ];
    end
    D_duration = mat_duration;
    
    
    load(strcat("190207_H_",str_curversion));
    mat_ALL_feats = mat_ALL_feats(:,:,[1:26]);
    H_feats = zeros(size(mat_ALL_ANGLE_feats,1), ...
        size(mat_ALL_ANGLE_feats,2) * size(mat_ALL_ANGLE_feats,3) + ...
        size(mat_ALL_ADD_feats,2) * size(mat_ALL_ADD_feats,3)+ ...
        size(mat_ALL_feats,2) * size(mat_ALL_feats,3));
    H_score = mat_score';
    H_names = cell_namelist;
    for idx_data = 1:size(mat_ALL_ANGLE_feats,1)
        %feat1 (pt1, pt2, pt3, pt4) ... feat16 (pt1 pt2 pt3 pt4), angles...
        H_feats(idx_data,:) = [...
            reshape(mat_ALL_feats(idx_data,:,:),1,[]),...
            reshape(mat_ALL_ANGLE_feats(idx_data,:,:),1,[]),...
            reshape(mat_ALL_ADD_feats(idx_data,:,:),1,[]),...
            ];
    end
    H_duration = mat_duration;

    durations = [D_duration'; H_duration'];
    pred = [D_feats;H_feats];

    label_reg = [D_score;H_score];
    label_class = label_reg < 8; 
    fnames = string([D_names,H_names]');

%     for idx_fnames = 1:length(fnames)
%         C = strsplit(fnames(idx_fnames),'_');
%         fnames(idx_fnames) = C(1);
%     end
    
    str_points = ["Spine Shoulder","Head","Shoulder Left","Shoulder Right"];
    str_angles = ["Spine Shoulder - Head","Shoulder Left - Shoulder Right"];
    str_angles_dim = ["XY","ZY","XZ"]; 
    
    save( strcat("190207_all_",str_curversion),...
        "pred","label_reg","durations",... ,"scale_min","scale_max"
        "mat_feats_explanation","str_points","str_angles","str_angles_dim","fnames");
    
    %delete bipolar
    durations(contains(fnames,'B0')) = [];
    pred(contains(fnames,'B0'),:) = [];
    label_reg(contains(fnames,'B0')) = [];
    fnames(contains(fnames,'B0')) = [];

    save( strcat("190207_noB_",str_curversion),...
        "pred","label_reg","durations",... ,"scale_min","scale_max"
        "mat_feats_explanation","str_points","str_angles","str_angles_dim","fnames");
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;
load("./rating/rating_agitation_181217.mat");
for str_curversion = ["free talk","rating"]
    all_filenames = strcat("190207_all_",str_curversion);
    load(all_filenames);
    
    fnames_patient_visit = split(fnames,"_");
    fnames_patient_visit = fnames_patient_visit(:,1);
    idx_col_evals = [1,2]; %HAMD YMRS
    bool_fnames_isagitation = boolean(ones(size(fnames)));
    for idx_fnames = 1:length(bool_fnames_isagitation)
        idx_patient_visit = find(str_patient_visit == fnames_patient_visit(idx_fnames));
        
        %fillmissing
        if(any(isnan(mat_agitation(idx_patient_visit,idx_col_evals))))
            mat_agitation(idx_patient_visit,idx_col_evals) = fillmissing(mat_agitation(idx_patient_visit,idx_col_evals),'constant',1);
        end
        bool_fnames_isagitation(idx_fnames) = boolean( sum(mat_agitation(idx_patient_visit,idx_col_evals)) );
    end
    
    fnames(bool_fnames_isagitation,:) = [];
    pred(bool_fnames_isagitation,:) = [];
    label_reg(bool_fnames_isagitation,:) = [];
    durations(bool_fnames_isagitation,:) = [];

    save( strcat("190207_noH9-Y2_",str_curversion),...
        "pred","label_reg","durations",... ,"scale_min","scale_max"
        "mat_feats_explanation","str_points","str_angles","str_angles_dim","fnames");
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;
load("./rating/rating_agitation_181217.mat");
for str_curversion = ["free talk","rating"]
    all_filenames = strcat("190207_noB_",str_curversion);
    load(all_filenames);
    
    fnames_patient_visit = split(fnames,"_");
    fnames_patient_visit = fnames_patient_visit(:,1);
    idx_col_evals = [1,2]; %HAMD YMRS
    bool_fnames_isagitation = boolean(ones(size(fnames)));
    for idx_fnames = 1:length(bool_fnames_isagitation)
        idx_patient_visit = find(str_patient_visit == fnames_patient_visit(idx_fnames));
        %fillmissing
        if(any(isnan(mat_agitation(idx_patient_visit,idx_col_evals))))
            mat_agitation(idx_patient_visit,idx_col_evals) = fillmissing(mat_agitation(idx_patient_visit,idx_col_evals),'constant',1);
        end
        bool_fnames_isagitation(idx_fnames) = boolean( sum(mat_agitation(idx_patient_visit,idx_col_evals)) );
    end
    
    fnames(bool_fnames_isagitation,:) = [];
    pred(bool_fnames_isagitation,:) = [];
    label_reg(bool_fnames_isagitation,:) = [];
    durations(bool_fnames_isagitation,:) = [];

    save( strcat("190207_noB-H9-Y2_",str_curversion),...
        "pred","label_reg","durations",... ,"scale_min","scale_max"
        "mat_feats_explanation","str_points","str_angles","str_angles_dim","fnames");
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function list_dirs = dir_fldrs( str_path )
    list_dirs = dir( str_path );
    dir_flags = [list_dirs.isdir] & ~strcmp({list_dirs.name},'.') & ~strcmp({list_dirs.name},'..');
    list_dirs = list_dirs(dir_flags);
end