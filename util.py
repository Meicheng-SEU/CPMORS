import pandas as pd
import numpy as np
import xgboost as xgb
from sklearn.impute import KNNImputer
from sklearn.preprocessing import OneHotEncoder, LabelEncoder, StandardScaler, LabelBinarizer
from sklearn.metrics import recall_score, roc_auc_score, roc_curve, auc, ConfusionMatrixDisplay, fbeta_score
from pickle import dump
from utils.return_feature_name import return_var_name_2
from collections import Counter


def round_data(data):
    return np.array([round(x, 3) for x in data])


def median_value(data):
    # data = data.drop(columns=['stay_id'])
    median = np.nanmedian(data, axis=0)
    median_series = pd.Series(data=median, index=data.columns.values)
    return median_series


def Standardise(data):
    scaler = StandardScaler()
    scaler.fit(data)
    return scaler


def save_test_data(train_x, train_y, x_test, y_test, save_path='./data/'):
    np.save(save_path + "train_x.npy", train_x)
    np.save(save_path + "train_y.npy", train_y)

    np.save(save_path + "test_x.npy", x_test)
    np.save(save_path + "test_y.npy", y_test)


########################################################################################################################
# impute and standarise the data
def impute_knn(x, mimic):
    imputer_ts = KNNImputer(n_neighbors=10)
    x = imputer_ts.fit_transform(x)
    x = pd.DataFrame(data=x, columns=mimic.columns.values[1:-1])
    dump(imputer_ts, open(('./data/imputer_ts.pkl'), 'wb'))
    return x


def impute_mean(train_x, test_x, external_flag=False, external_x=None):
    mean = np.nanmean(train_x, axis=0)
    train_mean = pd.Series(data=mean, index=train_x.columns.values)
    train_x_fillna = train_x.fillna(train_mean, inplace=False)
    test_x_fillna = test_x.fillna(train_mean, inplace=False)
    dump(train_mean, open(('./data/train_mean.pkl'), 'wb'))

    if external_flag:
        external_x_fillna = external_x.fillna(train_mean, inplace=False)
        return train_x_fillna, test_x_fillna, external_x_fillna
    else:
        return train_x_fillna, test_x_fillna


def scale_data(train_x_fillna, test_x_fillna, external_flag=False, external_x_fillna=None):
    scaler = Standardise(train_x_fillna)
    train_x_process = scaler.transform(train_x_fillna)
    test_x_process = scaler.transform(test_x_fillna)
    if external_flag:
        external_x_process = scaler.transform(external_x_fillna)
        return train_x_process, test_x_process, external_x_process
    else:
        return train_x_process, test_x_process


def impute_scale(train_x, test_x, external_flag=False, external_x=None):
    if external_flag:
        train_x_fillna, test_x_fillna, external_x_fillna = impute_mean(train_x, test_x, external_flag, external_x)
        train_x_process, test_x_process, external_x_process = scale_data(train_x_fillna, test_x_fillna, external_flag, external_x_fillna)
        return train_x_process, test_x_process, external_x_process
    else:
        train_x_fillna, test_x_fillna = impute_mean(train_x, test_x)
        train_x_process, test_x_process = scale_data(train_x_fillna, test_x_fillna)
        return train_x_process, test_x_process


def load_database(database_name, remove_missing_ratio, drop_columns):
    database = pd.read_csv('./data/finaldata_' + database_name + '.csv')
    x = database.loc[:, 'male':'bilirubin_total_max']
    remove_nan_id = np.where(x.isna().sum(axis = 1) / x.shape[1] >= remove_missing_ratio)[0]
    database.drop(remove_nan_id, axis=0, inplace = True)
    database.drop(drop_columns, axis=1, inplace=True)
    return database


def preprocess(database, label_name, lite):
    print(Counter(database[label_name]))
    imputer = KNNImputer(n_neighbors=10)  # impute height and weight
    if lite==False:
        d0 = imputer.fit_transform(database[['male', 'white', 'black', 'asian', 'ethni_other', 'age', 'height', 'weight']])
    else:
        d0 = imputer.fit_transform(database[['male', 'age', 'height', 'weight']])
    database['height'] = d0[:, -2]
    database['weight'] = d0[:, -1]
    database.insert(loc=database.columns.get_loc('weight') + 1, column='bmi',
                    value=database['weight'] / (database['height'] ** 2 / 10000))
    # database['bmi'] = database['weight'] / (database['height'] ** 2 / 10000)
    database = database.drop(['height', 'weight'], axis=1)

    x = database.loc[:, 'male':'bilirubin_total_max']
    x = x.replace(np.inf, np.nan)
    # missing_ratio = x.isna().mean()
    # remove nan data that more than 30%
    # remove_nan_id = np.where(x.isna().sum(axis = 1) / x.shape[1] >= 0.30)[0]
    # x.drop(remove_nan_id, axis=0, inplace = True)
    y = database[label_name]
    # y.drop(remove_nan_id, inplace = True)

    return x, y


def transform_y(y, set_up='multiclass'):
    if set_up == 'multiclass':
        return np.array(y)
    elif set_up == 'two-way':
        bin_y = y.replace(['recovery', 'Raipd_death'], 'short_stay')
        le = LabelEncoder()
        le.classes_ = ['short_stay', 'persistent_ill']
        return le.transform(bin_y)
    elif set_up == 'nested_aki':
        bin_y = y.replace([2, 3], 1)
        # le = LabelEncoder()
        # le.classes_ = ['alive', 'Raipd_death']
        # return le.transform(bin_y)
        return np.array(bin_y)
    elif set_up == 'hos_death':
        # bin_y = y.replace([2, 3], 1)
        # le = LabelEncoder()
        # le.classes_ = ['alive', 'Raipd_death']
        # return le.transform(bin_y)
        return np.array(y)
    elif set_up == 'nested_stage':
        le = LabelEncoder()
        le.classes_ = ['recovery', 'persistent_ill']
        return le.transform(y)
    elif set_up == 'nested_longstay_test':
        bin_y = y.replace(['Raipd_death'], 'recovery')
        le = LabelEncoder()
        le.classes_ = ['recovery', 'persistent_ill']
        return le.transform(bin_y)


def binarize_predictions(y_pred_proba, cutoff):
    return (y_pred_proba >= cutoff).astype(int)


def find_best_cutoff(y_true, y_pred_proba):
    best_cutoff, best_fscore = None, -1
    for cutoff in np.arange(0, 1.01, 0.01):
        y_pred = binarize_predictions(y_pred_proba, cutoff)
        fscore = fbeta_score(y_true, y_pred, beta=2)
        if fscore > best_fscore:
            best_cutoff, best_fscore = cutoff, fscore
    return best_cutoff, best_fscore


def find_se_cutoff(y_true, y_pred_proba, se=0.9):
    recall = []
    cutoff_list = np.arange(0, 1.001, 0.001)
    for cutoff in cutoff_list:
        y_pred = binarize_predictions(y_pred_proba, cutoff)
        recall.append(recall_score(y_true, y_pred))
    recall = np.array(recall)
    index = np.abs(recall - se).argmin()
    best_cutoff = cutoff_list[index]

    return best_cutoff, recall[index]

