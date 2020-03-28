clear;clc;
for num_class = fliplr([2.1, 2.01, 2.5, 2.9, 2.001, 2])
    for str_postfix2 = fliplr(["free talk","rating","both"])
        for str_postfix1 = fliplr(["all","noB","noH9-Y2","noB-H9-Y2"])
            load( strcat("./190207_",str_postfix1,"_",str_postfix2,"_COMBINED.mat") );
            
            fnames = combined_fnames;
            durations = combined_durations;
            label_reg = combined_label_reg;
            pred = combined_pred;
            
            clear combined_fnames combined_durations combined_label_reg combined_pred
            
            str_method = "SVM";
            numsem = 1.96; %95 percent = 1.96 sem

            num_test_folds = 10;
            num_validation_folds = 10;
                
            if( isfile(strcat( "190207_nested10fold-",sprintf("%.4f",num_class),"_FwdBkwd_",str_postfix1,"_",str_postfix2,".mat" )))
                continue
            end
            
            %subject = 1 session (pre-segmentation); dataset = 1 segment
            dataset_names = split(fnames,"_");
        
            subject_names = dataset_names(:,1);
            idx_duplicate_subject = find_duplicates(subject_names);
            subject_names(idx_duplicate_subject) = [];
            
            dataset_labels = hamd2class(label_reg, num_class);
            subject_labels = dataset_labels;
            subject_labels(idx_duplicate_subject) = [];
            
            idx_nan_subjects = isnan(subject_labels);
            subject_names(idx_nan_subjects) = [];
            subject_labels(idx_nan_subjects) = [];
            
            num_dataset = length(subject_names);
            
            %create test folds
            test_folds = crossvalind('KFold',subject_labels,num_test_folds);
            
            log_partitions_test = boolean(zeros(size(pred,1),num_test_folds));
            log_partitions_train = boolean(zeros(size(pred,1),num_test_folds,num_validation_folds));
            log_partitions_validation = boolean(zeros(size(pred,1),num_test_folds,num_validation_folds));
            
            clear struct_result_validation;
            for idx_test_folds = 1:num_test_folds
                for idx_validation_folds = 1:num_validation_folds
                    struct_result_validation(idx_test_folds,idx_validation_folds) = struct();
                end
            end
            
            %dataset outer layer: Testing
            for idx_test_folds = 1:num_test_folds
                test_subject = find(test_folds == idx_test_folds);
                trainval_subject = find(test_folds ~= idx_test_folds);
                
                test_dataset = subject2dataset(test_subject, subject_names, dataset_names);
                log_partitions_test(:,idx_test_folds) = test_dataset;
                
                trainval_subject_labels = subject_labels(trainval_subject);
                validation_folds = crossvalind('KFold',trainval_subject_labels,num_validation_folds);
                
                %dataset inner layer: Validation
                for idx_validation_folds = 1:num_validation_folds
                    validation_subject = find(validation_folds == idx_validation_folds);
                    train_subject = find(validation_folds ~= idx_validation_folds);
                    
                    if(length(train_subject) + length(validation_subject) ~= length(trainval_subject))
                        disp("ERROR IN VALIDATION FOLD: DATA ASSIGNMENT");
                    end
                    
                    validation_dataset = subject2dataset( trainval_subject(validation_subject) , subject_names, dataset_names);
                    train_dataset = subject2dataset( trainval_subject(train_subject) , subject_names, dataset_names);
                    
                    log_partitions_validation(:,idx_test_folds,idx_validation_folds) = validation_dataset;
                    log_partitions_train(:,idx_test_folds,idx_validation_folds) = train_dataset;
                    
                    %build and optimize model here
                    %feature selection: forward and backward
                    best_features = boolean(zeros(1,size(pred,2)));
                    best_features(1) = true;
                    [best_model, best_struct_acc] = get_optimized_RBFSVM(...
                                        pred(train_dataset,best_features), dataset_labels(train_dataset), ...
                                        pred(validation_dataset,best_features), dataset_labels(validation_dataset) ...
                                        );
                    best_acc = best_struct_acc.accuracy;
                    best_kappa = best_struct_acc.cohens_k;
                    for idx_forwardtest_feature = 2:size(pred,2)
                        evaluate_features = best_features;
                        evaluate_features(idx_forwardtest_feature) = ~evaluate_features(idx_forwardtest_feature);
                        
                        %evaluate feature (front)
                        [evaluate_model, validation_struct_acc] = get_optimized_RBFSVM(...
                                        pred(train_dataset,evaluate_features), dataset_labels(train_dataset), ...
                                        pred(validation_dataset,evaluate_features), dataset_labels(validation_dataset) ...
                                        );
                        evaluate_acc = validation_struct_acc.accuracy;
                        evaluate_kappa = validation_struct_acc.cohens_k;
                        
                        %front-backward stepwise feature selection
                        if evaluate_kappa < best_kappa
                            for idx_backwardtest_feature = idx_forwardtest_feature-1:1
                                evaluate_features(idx_backwardtest_feature) = ~evaluate_features(idx_backwardtest_feature);
                                
                                %evaluate feature (backward)
                                [evaluate_model, validation_struct_acc] = get_optimized_RBFSVM(...
                                        pred(train_dataset,evaluate_features), dataset_labels(train_dataset), ...
                                        pred(validation_dataset,evaluate_features), dataset_labels(validation_dataset) ...
                                        );
                                evaluate_acc = validation_struct_acc.accuracy;
                                evaluate_kappa = validation_struct_acc.cohens_k;
                                if evaluate_kappa > best_kappa
                                    best_model = evaluate_model;
                                    best_acc = evaluate_acc;
                                    best_kappa = evaluate_kappa;
                                    best_features = evaluate_features;
                                else
                                    evaluate_features(idx_backwardtest_feature) = ~evaluate_features(idx_backwardtest_feature);
                                end
                            end
                        else
                            best_model = evaluate_model;
                            best_acc = evaluate_acc;
                            best_kappa = evaluate_kappa;
                            best_features = evaluate_features;
                        end
                        
                        %final backward check
                        if idx_forwardtest_feature == size(pred,2)
                            for idx_backwardtest_feature = idx_forwardtest_feature-1:1
                                evaluate_features(idx_backwardtest_feature) = ~evaluate_features(idx_backwardtest_feature);
                                
                                %evaluate feature (backward)
                                [evaluate_model, validation_struct_acc] = get_optimized_RBFSVM(...
                                        pred(train_dataset,evaluate_features), dataset_labels(train_dataset), ...
                                        pred(validation_dataset,evaluate_features), dataset_labels(validation_dataset) ...
                                        );
                                evaluate_acc = validation_struct_acc.accuracy;
                                evaluate_kappa = validation_struct_acc.cohens_k;
                                if evaluate_kappa > best_kappa
                                    best_model = evaluate_model;
                                    best_acc = evaluate_acc;
                                    best_kappa = evaluate_kappa;
                                    best_features = evaluate_features;
                                else
                                    evaluate_features(idx_backwardtest_feature) = ~evaluate_features(idx_backwardtest_feature);
                                end
                            end
                        end
                    end
                    
                    %struct_result_validation is the training result
                    struct_result_validation(idx_test_folds,idx_validation_folds).best_model = best_model;
                    struct_result_validation(idx_test_folds,idx_validation_folds).best_acc = best_acc;
                    struct_result_validation(idx_test_folds,idx_validation_folds).best_kappa = best_kappa;
                    struct_result_validation(idx_test_folds,idx_validation_folds).best_features = best_features;
                    struct_result_validation(idx_test_folds,idx_validation_folds).best_struct_acc = best_struct_acc;
                    
                    %evaluate model accuracy here (test)
                    test_struct_acc = compute_accuracy_metrics( best_model.predict( pred(test_dataset,best_features) ),dataset_labels(test_dataset) );
                    test_kappa = test_struct_acc.cohens_k;
                    test_acc = test_struct_acc.accuracy;
                    struct_result_validation(idx_test_folds,idx_validation_folds).test_acc = test_acc;
                    struct_result_validation(idx_test_folds,idx_validation_folds).test_kappa = test_kappa;
                    struct_result_validation(idx_test_folds,idx_validation_folds).test_struct_acc = test_struct_acc;
                end                
            end
            %save training, validation, and test result
            save( ...
                    strcat( "190207_nested10fold-",sprintf("%.4f",num_class),"_FwdBkwd_",str_postfix1,"_",str_postfix2,".mat" ) ...
                    ,"num_class", "str_method", "num_test_folds", "num_validation_folds" ...
                    ,"train_dataset", "test_dataset", "validation_dataset", "label_reg", "dataset_names", "dataset_labels", "pred" ...
                    ,"log_partitions_test", "log_partitions_train", "log_partitions_validation" ...
                    ,"struct_result_validation" ...
                    );
        end
    end
end

function mat_HAMD_class = hamd2class(vector_HAMD, num_class)
        mat_HAMD_class = vector_HAMD;
        if num_class == 2.100
            mat_HAMD_class( vector_HAMD < 8 ) = 0; %not depressed
            mat_HAMD_class( vector_HAMD >= 8 ) = 1; %depressed
        elseif num_class == 2.010
            mat_HAMD_class = ones(size(vector_HAMD)) .* NaN;
            mat_HAMD_class( vector_HAMD < 8 ) = 0; %not depressed
            mat_HAMD_class( vector_HAMD >= 14 ) = 1; %depressed
        elseif num_class == 2.001
            mat_HAMD_class = ones(size(vector_HAMD)) .* NaN;
            mat_HAMD_class( vector_HAMD < 8 ) = 0; %not depressed
            mat_HAMD_class( vector_HAMD >= 19 ) = 1; %depressed
        elseif num_class == 2.5
            mat_HAMD_class( vector_HAMD < 14 ) = 0; %not depressed
            mat_HAMD_class( vector_HAMD >= 14 ) = 1; %depressed
        elseif num_class == 2.9
            mat_HAMD_class( vector_HAMD < 19 ) = 0; %not depressed
            mat_HAMD_class( vector_HAMD >= 19 ) = 1; %depressed
        elseif num_class == 2.0
            mat_HAMD_class( vector_HAMD < 5 ) = 0; %not depressed
            mat_HAMD_class( vector_HAMD >= 5 ) = 1; %depressed
        end
end

function [best_mdl, best_struct_acc] = get_optimized_RBFSVM(train_pred, train_label, test_pred, test_label)
    %hyperparameters: RBF_Sigma and SVM_Gamma
	hyperparams_boundary = 10.^[-5:5];
    
    flag_first = true;
    best_mdl = [];
    best_struct_acc = [];
    best_acc = 0;
    best_k = -1;
    
	for RBF_Sigma = hyperparams_boundary
        for SVM_Gamma = hyperparams_boundary
            evaluate_model = fitcsvm( train_pred, train_label ...
                ,'KernelFunction','RBF','Standardize',true ...
                ,'KernelScale',RBF_Sigma,'BoxConstraint',SVM_Gamma ...
                ,'HyperparameterOptimizationOptions',struct('UseParallel',true,'Verbose',0,'ShowPlots',false) ...
                );
            
            test_result = evaluate_model.predict(test_pred);
            struct_acc  = compute_accuracy_metrics(test_result, test_label);
            k = struct_acc.cohens_k;
            acc = struct_acc.accuracy;
            
            if( flag_first || k > best_k )
                best_mdl = evaluate_model;
                best_acc = acc;
                best_k = k;
                best_struct_acc = struct_acc;
                flag_first = false;
            end
        end
    end
end

function idxs_dataset = subject2dataset(idxs_subject, subject_names, dataset_names)
    idxs_dataset = boolean(zeros(size(dataset_names(:,1))));
    for idx_subject = reshape(idxs_subject,1,[])
        for idx_dataset = 1:length(idxs_dataset)
            if(dataset_names(idx_dataset,1) == subject_names(idx_subject))
                idxs_dataset(idx_dataset) = true;
            end
        end
    end
end

function indexToDupes = find_duplicates(A)
    [~, idx_uniques, ~] = unique(A,'first');
    indexToDupes = find(not(ismember(1:numel(A),idx_uniques)));
end

function struct_acc = compute_accuracy_metrics(Prediction, Truth)
    true_pos = sum(and((Prediction == 1) , (Truth == 1)));
    true_neg = sum(and((Prediction == 0) , (Truth == 0)));
    false_pos = sum(and((Prediction == 1) , (Truth == 0)));
    false_neg = sum(and((Prediction == 0) , (Truth == 1)));
    expected_accuracy = ((true_pos + false_pos) / (true_pos + true_neg + false_pos + false_neg)...
                        * ...
                        (true_pos + false_neg) / (true_pos + true_neg + false_pos + false_neg))...
                        + ...
                        ((true_neg + false_pos) / (true_pos + true_neg + false_pos + false_neg)...
                        * ...
                        (true_neg + false_neg) / (true_pos + true_neg + false_pos + false_neg))...
                        ;
    
    struct_acc.accuracy = (true_pos + true_neg) / (true_pos + true_neg + false_pos + false_neg);
    struct_acc.tpr = true_pos / (true_pos + false_neg); %Sensitivity
    struct_acc.tfr = true_neg / (true_neg + false_pos); %Specificity
    struct_acc.ppv = true_pos / (true_pos + false_pos);
    struct_acc.npv = true_neg / (true_neg + false_neg);
    struct_acc.f1  = 2 * (struct_acc.ppv * struct_acc.tpr)/(struct_acc.ppv + struct_acc.tpr);
    struct_acc.cohens_k = (struct_acc.accuracy - expected_accuracy)/(1-expected_accuracy);
    
    %matthews corr. coeff.
    struct_acc.mcc = (true_pos * true_neg - false_pos * false_neg) ...
                     / ...
                     sqrt( (true_pos+false_pos)*(true_pos+false_neg)*(true_neg+false_pos)*(true_neg+false_neg) );
end