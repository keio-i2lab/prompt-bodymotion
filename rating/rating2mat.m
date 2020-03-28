clear;clc;

str_patient_visit = strings(0);
mat_HAMD = zeros(0);

for fname = ["Bipolar data 20181217.xlsx","Depression data from 20181217.xlsx","Healthy data 20181217.xlsx"]
    T = readtable(fname);
    col_list = string(T.Properties.VariableDescriptions);
    idx_hamd17 =  find(contains(col_list,"HAMD17"));
    
    str_patient_visit = [str_patient_visit; string(table2cell(T(:,1)))];
    mat_HAMD = [mat_HAMD; double(string(table2cell(T(:,idx_hamd17))))];
end

save("rating_new_181217","mat_HAMD","str_patient_visit");