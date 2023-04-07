# MorganStanley-QuantChallenge <img src="logo.png" align="right" width="120" height="140"/>

### Files of the repository

    ├── 00-utils.R

Prior to evaluating any other scripts, it is recommended to execute this particular script, which is responsible for loading the necessary packages and options.

    ├── 00-board.R

The enclosed data was loaded and exported into a private OneDrive folder. Additionally, all intermediate results were saved in the same folder using the [{pins}](https://pins.rstudio.com) package. If you would like access to the folder, please email [granat.marcell\@uni-neumann.hu](mailto:granat.marcell@uni-neumann.hu). There is a chance that you do not have access to the folder, or that you have but in another way. In this case, it may be necessary that the `.board` object created in the script must be modified accordingly. Similarly to the utils file, it is recommended to execute this script prior to any other.

    ├── 01-data-setup.R

We store the enclosed raw data in a private OneDrive folder. This script reads the raw data, evaluates some initial cleaning steps.

    ├── 02-station-to-county.R

Calculates the difference between each county (coordinates of the counties were given, so we used that instead of calculating the centroids).


    ├── 03-design.R

Data manipulation steps to prepare the data for modelling: imputating (MICE), joining & transforming.

    ├── 04-model-setup.R

We applied Tidymodels to evaluate the efficiency of many models. This script creates the `rset` and the `recipe` for modelling.

    ├── 05-linear_reg_glmnet.R
    ├── 05-linear_reg_lm.R
    ├── 05-rand_forest_randomForest.R
    ├── 05-svm_linear_LiblineaR.R
    ├── ...
    

These codes set up and train base learner models for a regression task, utilizing parallel processing to speed up the training process, and save the resulted final workflow. 


    ├── 06-ensemble-tuning.R

We make prediction with base learners on the training set, that we will use for stacking.

    ├── 07-testing_no_wts.R
    ├── 07-testing_rs75.R
    ├── 07-testing_rs90.R
    ├── 07-testing_rs95.R
    ├── 07-testing-ensemble.R
    ├── 07-oats&soybeans-testing.R

We evaluate all the base learners and ensembles on the testing set.

    ├── 08-prediction_targets_impute.R

MICE imputation on the dataset that we predict with models.

    ├── 09-prediction-setup.R

Data manipulation steps for predictions.

    ├── 10-prediction.R

Prediction.
