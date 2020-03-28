clear; clc;
for str_postfix1 = ["all", "noB", "noH9-Y2", "noB-H9-Y2"]
    for str_postfix2 = ["free talk", "rating"]
        load( strcat("./190207_",str_postfix1,"_",str_postfix2,".mat") );
        [combined_fnames,combined_pred,combined_label_reg,combined_durations] = combinesessions(fnames,pred,label_reg,durations);
        save( strcat("./result_mat/training_190307/190207_",str_postfix1,"_",str_postfix2,"_COMBINED.mat"),...
            "combined_fnames","combined_pred","combined_label_reg","combined_durations");
    end
end
for str_postfix1 = ["all", "noB", "noH9-Y2", "noB-H9-Y2"]
    str_postfix2 = ["free talk", "rating"];
        f = load( strcat("./190207_",str_postfix1,"_",str_postfix2(1),".mat") );
        r = load( strcat("./190207_",str_postfix1,"_",str_postfix2(2),".mat") );
        fnames = [f.fnames;r.fnames];
        pred = [f.pred;r.pred];
        label_reg = [f.label_reg;r.label_reg];
        durations = [f.durations;r.durations];
        [combined_fnames,combined_pred,combined_label_reg,combined_durations] = combinesessions(fnames,pred,label_reg,durations);
        save( strcat("./result_mat/training_190307/190207_",str_postfix1,"_both_COMBINED.mat"),...
            "combined_fnames","combined_pred","combined_label_reg","combined_durations");
end

function [combined_fnames,combined_pred,combined_label_reg,combined_durations] = combinesessions(fnames,pred,label_reg,durations)
    fnames = split(fnames,"_");
    
    combined_fnames = unique(fnames(:,1));
	combined_pred = zeros(size(combined_fnames,1),size(pred,2));
	combined_label_reg = zeros(size(combined_fnames,1),size(label_reg,2));
    combined_durations = zeros(size(combined_fnames,1),size(durations,2));
    
    for idx_unique_fname = 1:length(combined_fnames)
        sum_durations = 0;
        for idx_fname = 1:length(fnames(:,1))
            if(fnames(idx_fname,1) == combined_fnames(idx_unique_fname))
                sum_durations = sum_durations + durations(idx_fname);
                combined_pred(idx_unique_fname,:) = combined_pred(idx_unique_fname) + ...
                    pred(idx_fname,:) .* durations(idx_fname);
                combined_label_reg(idx_unique_fname) = combined_label_reg(idx_unique_fname) + ...
                    label_reg(idx_fname,:) .* durations(idx_fname);
            end
        end
        combined_pred(idx_unique_fname,:) = combined_pred(idx_unique_fname,:) ./ sum_durations;
        combined_label_reg(idx_unique_fname,:) = combined_label_reg(idx_unique_fname,:) ./ sum_durations;
        combined_durations(idx_unique_fname) = sum_durations;
    end
end