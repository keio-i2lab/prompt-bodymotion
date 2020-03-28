clear;clc;
for num_class = [2.1, 2, 2.5, 2.01, 2.001, 2.9]
    fprintf("==================================================\n");
    for str_postfix2 = ["free talk","rating"]
        for str_postfix1 = ["all","noB","noH9-Y2","noB-H9-Y2"]
            fprintf("Class: %.4f\tDataset: %s\tSession: %s\n",num_class,str_postfix1,str_postfix2);
            %for test_perc = [5:5:95]
            load( strcat( "190207_nested10fold-",sprintf("%.4f",num_class),"_FwdBkwd_",str_postfix1,"_",str_postfix2,".mat" ) );
            
            test_acc = zeros(1,num_test_folds);
            test_k   = zeros(1,num_test_folds);
            test_f1   = zeros(1,num_test_folds);
            for idx_test = 1:num_test_folds    
                %get new features, chosen over all models
                score_features = zeros( 1, size(pred,2) );
                for idx_validation = 1:num_validation_folds
                    
                    if(isnan(struct_result_validation(idx_test,idx_validation).best_kappa ))
                        struct_result_validation(idx_test,idx_validation).best_kappa = 0;
                    end
                    
                    score_features = score_features + ...
                        struct_result_validation(idx_test,idx_validation).best_features .* ...
                        ... 1 ...
                        ... 1./sum(struct_result_validation(idx_test,idx_validation).best_features) ...
                        struct_result_validation(idx_test,idx_validation).best_kappa ...
                        ... struct_result_validation(idx_test,idx_validation).test_acc ...
                        ... struct_result_validation(idx_test,idx_validation).test_kappa ...
                        ;
                end
                chosen_features = boolean( zeros(1, size(pred,2)) );
                test_perc = 75;
                chosen_features( score_features >= prctile(score_features, test_perc) ) = true;
                
                [testfold_mdl, testfold_acc, testfold_k, testfold_f1] = get_optimized_RBFSVM(...
                    pred(~log_partitions_test(:,idx_test),chosen_features), dataset_labels(~log_partitions_test(:,idx_test)),...
                    pred(log_partitions_test(:,idx_test),chosen_features), dataset_labels(log_partitions_test(:,idx_test)));
                if(isnan(testfold_k))
                    testfold_k = 0;
                end
                if(isnan(testfold_f1))
                    testfold_f1 = 0;
                end
                test_acc(idx_test) = testfold_acc;
                test_k(idx_test)   = testfold_k;
                test_f1(idx_test)   = testfold_f1;
            end
            fprintf("Percentiles: %d\tAvg. acc: %.2f±%.2f\tAvg. k: %.2f±%.2f\tAvg. f1: %.2f±%.2f\n",test_perc,mean(test_acc),std(test_acc),mean(test_k),std(test_k),mean(test_f1),std(test_f1));
            %end
        end
    end
end

function [best_mdl, best_acc, best_k, best_f1] = get_optimized_RBFSVM(train_pred, train_label, test_pred, test_label)
    %hyperparameters: RBF_Sigma and SVM_Gamma
	hyperparams_boundary = 10.^[-5:5];
    
    flag_first = true;
    best_mdl = [];
    best_acc = 0;
    best_k = -1;
    best_f1 = 0;
    
	for RBF_Sigma = hyperparams_boundary
        for SVM_Gamma = hyperparams_boundary
            evaluate_model = fitcsvm( train_pred, train_label ...
                ,'KernelFunction','RBF','Standardize',true ...
                ,'KernelScale',RBF_Sigma,'BoxConstraint',SVM_Gamma ...
                ,'HyperparameterOptimizationOptions',struct('UseParallel',true,'Verbose',0,'ShowPlots',false) ...
                );
            
            test_result = evaluate_model.predict(test_pred);
            struct_acc = evaluate_acc(test_result, test_label);
            k = struct_acc.cohens_k;
            acc = struct_acc.accuracy;
            f1 = struct_acc.f1;
            
            if( flag_first || k > best_k )
                best_mdl = evaluate_model;
                best_acc = acc;
                best_k = k;
                best_f1 = f1;
                flag_first = false;
            end
        end
    end
end

function struct_acc = evaluate_acc(Prediction, Truth)
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