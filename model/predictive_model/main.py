import os
import numpy as np
import xgboost as xgb
import pickle
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from collections import Counter
from sklearn.model_selection import StratifiedShuffleSplit
from sklearn.utils.class_weight import compute_sample_weight
import joblib
from model import BO_TPE_XGB, BO_TPE_LR, BO_TPE_RF
from util import impute_scale, load_database, preprocess
import warnings
warnings.filterwarnings('ignore')

########################################################################################################################
# load data
lite = False
c = ['Genitourinary_infection', 'input_total',
     'sofa_respiration', 'sofa_coagulation', 'sofa_liver', 'sofa_cardiovascular', 'sofa_cns', 'sofa_renal']

mimic = load_database('mimic_sepsis', remove_missing_ratio=0.3, drop_columns=c )
eicu = load_database('eicu_sepsis', remove_missing_ratio=0.3, drop_columns=c)

x, y = preprocess(mimic, 'hos_death', lite=lite)
eicu_x, eicu_y = preprocess(eicu, 'hos_death', lite=lite)
set_up = 'hos_death'
feature_selection = 'all' if not lite else 'lite'

########################################################################################################################
# split in train and test set
sss = StratifiedShuffleSplit(n_splits=1, test_size=0.2, random_state=None)
for train_index, test_index in sss.split(x, y):
    train_x = x.iloc[train_index, :]
    train_y = y.iloc[train_index]
    print('train set: ')
    print(Counter(train_y))

    test_x = x.iloc[test_index, :]
    test_y = y.iloc[test_index]
    print('internal test set: ')
    print(Counter(test_y))

x_test = np.array(test_x); y_test = np.array(test_y)
x_eicu = np.array(eicu_x); y_eicu = np.array(eicu_y)

train_x_process, test_x_process, eicu_x_process = impute_scale(train_x, test_x, external_flag=True, external_x=eicu_x)
test_x_process_copy = test_x_process
eicu_x_process_copy = eicu_x_process

########################################################################################################################
# train the model
xgb_path = './model/xgb_' + set_up + '/' + feature_selection + '/'
lr_path = './model/lr_' + set_up + '/' + feature_selection + '/'
rf_path = './model/rf_' + set_up + '/' + feature_selection + '/'
for dir in [xgb_path, lr_path, rf_path]:
    if not os.path.isdir(dir):
        os.makedirs(dir)

sss = StratifiedShuffleSplit(n_splits=1, test_size=0.2, random_state=None)
for train_index, val_index in sss.split(train_x, train_y):
    x_train = np.array(train_x.iloc[train_index, :])
    y_train = np.array(train_y.iloc[train_index])

    x_val = np.array(train_x.iloc[val_index, :])
    y_val = np.array(train_y.iloc[val_index])

    # compared model data used
    x_train_process = train_x_process[train_index]
    x_val_process = train_x_process[val_index]

    # train model
    sample_weights = compute_sample_weight(class_weight='balanced', y=y_train)

    print('XGBoost...')
    best_param = BO_TPE_XGB(x_train, y_train, x_val, y_val, sample_weights, set_up)
    xgb_model = xgb.XGBClassifier(max_depth=best_param['max_depth'],
                                  eta=best_param['learning_rate'],
                                  n_estimators=1000,
                                  subsample=best_param['subsample'],
                                  colsample_bytree=best_param['colsample_bytree'],
                                  reg_alpha=best_param['reg_alpha'],
                                  reg_lambda=best_param['reg_lambda'],
                                  objective="binary:logistic"
                                  )

    es = xgb.callback.EarlyStopping(
        rounds=50,
        save_best=True,
        maximize=True,
        metric_name='auc',
    )

    xgb_model = xgb_model.fit(x_train, y_train, eval_set=[(x_val, y_val)], verbose=False,
                              eval_metric='auc', callbacks=[es], sample_weight=sample_weights)
    save_model_path = xgb_path + 'model.json'
    xgb_model.save_model(save_model_path)

    # RandomForest
    print('RandomForest...')
    best_rf_parm = BO_TPE_RF(x_train_process, y_train, x_val_process, y_val)
    rf_model = RandomForestClassifier(
                                   max_depth=best_rf_parm['max_depth'],
                                   min_samples_leaf=best_rf_parm['min_samples_leaf'],
                                   min_samples_split=best_rf_parm['min_samples_split'],
                                   n_estimators=best_rf_parm['n_estimators'],
                                   class_weight='balanced'
                                   )
    rf_model.fit(x_train_process, y_train)
    joblib.dump(rf_model, rf_path +'model.joblib')

    # lr model
    print('LogisticRegression...')
    best_lr_parm = BO_TPE_LR(x_train_process, y_train, x_val_process, y_val, set_up)
    log_model = LogisticRegression(solver=best_lr_parm['solver'], C=best_lr_parm['C'], class_weight='balanced')
    log_model.fit(x_train_process, y_train)
    joblib.dump(log_model, lr_path +'model.joblib')
    print('*************************************************************\n')

    save_data = {
        'x_train': x_train,
        'x_train_process': x_train_process,
        'x_val': x_val,
        'x_val_process': x_val_process,
        'y_val': y_val,
        'x_test': x_test,
        'x_test_process': test_x_process ,
        'x_eicu': x_eicu ,
        'x_eicu_process': eicu_x_process,
        'y_train': y_train,
        'y_test': y_test,
        'y_eicu': y_eicu,
        'test_index': test_index
    }

    save_path = './data/' + set_up + '/' + feature_selection + '/'
    if not os.path.isdir(save_path):
        os.makedirs(save_path)
    pickle.dump(save_data, open((save_path+'save_data.pkl'), 'wb'))


