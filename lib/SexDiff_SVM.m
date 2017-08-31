function [Xroc,Yroc,VA,AUC,OptROC,trainedSVM] = SexDiff_SVM(x,kFoldval,NumPermut,predictorNames)
% train a SVM classifier on outputs of FreeSurfer
% it uses a linear kernel SVM
% with SMO solver 

% inputs are: 
%   a matrix of all features and the response, all in one matrix 
%       (label is the last column)
%   k of k-fold cross validation 
%   number of permutation 

% ouputs are: 
%   x and y of ROC curve
%   validation accuracy after k-fold cross validation (predication accuracy)
%   area under ROC curve
%   optimum point on ROC curve
%   trained classifier

% author: Farshid Sepehrband - farshid.sepehrband@loni.usc.edu

inputTable = x;
for i = 1:NumPermut
    
    predictors = inputTable(:, 1:end-1);
    response = inputTable(:,end);
    isCategoricalPredictor = false(1,size(predictors,2));
    
    % Train a classifier
    classificationSVM = fitcsvm(...
        predictors, ...
        response, ...
        'KernelFunction', 'linear', ...
        'PolynomialOrder', [], ...
        'KernelScale', 'auto', ...
        'BoxConstraint', 1, ...
        'Standardize', true, ...
        'ClassNames', [0; 1]);
    
    % Create the result struct with predict function
    predictorExtractionFcn = @(t) t(:);
    svmPredictFcn = @(x) predict(classificationSVM, x);
    trainedSVM(i).predictFcn = @(x) svmPredictFcn(predictorExtractionFcn(x));
    
    % Add additional fields to the result struct
    trainedSVM(i).ClassificationSVM = classificationSVM;
    
    % Perform cross-validation
    partitionedModel = crossval(trainedSVM(i).ClassificationSVM, ...
        'KFold', kFoldval);
    
    % Compute validation accuracy
    VA(i) = 1 - kfoldLoss(partitionedModel, ...
        'LossFun', 'ClassifError');
    
    % Compute validation predictions and scores
    [~, validationScores] = kfoldPredict(partitionedModel);
    
    % Perform receiver operating characteristic analysis
    [Xroc(:,i),Yroc(:,i),~,AUC(i),OptROC(:,i)] = ...
        perfcurve(trainedSVM(i).ClassificationSVM.Y,validationScores(:,2),1);
end