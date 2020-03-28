clear;clc;

str_patient_visit = strings(0);
mat_agitation = zeros(0);
fnames_list = dir("agitation*.xlsx");
for fname_idx = 1:length(fnames_list)
    fname = fnames_list(fname_idx).name;
    T = readtable(fname);
    col_list = string(T.Properties.VariableDescriptions);
    idx_cols =  [2,4,3,5]; %HAMD, YMRS, MADRS, BDI
    
    str_patient_visit = [str_patient_visit; string(table2cell(T(:,1)))];
    mat_agitation = [mat_agitation; double(string(table2cell(T(:,idx_cols))))];
end

save("rating_agitation_181217","mat_agitation","str_patient_visit");