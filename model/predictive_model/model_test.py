import pickle
import pandas as pd
import numpy as np
from model import load_model_predict
from sklearn.metrics import precision_score, recall_score, roc_auc_score
from util import binarize_predictions, find_se_cutoff


def specificity_score(y_true, y_pred):
    tn = np.sum((y_true == 0) & (y_pred == 0))
    fp = np.sum((y_true == 0) & (y_pred == 1))
    specificity = tn / (tn + fp)
    return specificity


def confusion_matrix(y_true, y_pred):
    tn = np.sum((y_true == 0) & (y_pred == 0))
    fp = np.sum((y_true == 0) & (y_pred == 1))
    tp = np.sum((y_true == 1) & (y_pred == 1))
    fn = np.sum((y_true == 1) & (y_pred == 0))
    return tp, tn, fp, fn


def get_sub_metirc(y_pre_pro, y_true_label):
    best_cutoff, best_fscore = find_se_cutoff(y_true_label, y_pre_pro, se=0.873)
    y_pre_label = binarize_predictions(y_pre_pro, best_cutoff)
    se = recall_score(y_true_label, y_pre_label)
    sp = specificity_score(y_true_label, y_pre_label)
    ppv = precision_score(y_true_label, y_pre_label)
    auc = roc_auc_score(y_true_label, y_pre_pro)
    result = 'auc: {:.3f}, se: {:.3f}, sp: {:.3f}, ppv: {:.3f}'.format(auc, se, sp, ppv)
    print(result)
    tp, tn, fp, fn = confusion_matrix(y_true_label, y_pre_label)
    print('tp: {:d}, tn: {:d}, fp: {:d}, fn: {:d}'.format(tp, tn, fp, fn))
    point_predciton = np.array([['{:d} ({:.1f})'.format(fp, round(100*fp/(fp+tn), 1)),
                                 '{:d} ({:.1f})'.format(fn, round(100*fn/(fn+tp), 1)),
                                 '{:d} ({:.1f})'.format(fp+fn, round(100*(fp+fn)/(fp+tn+fn+tp), 1))],
                               ['{:d} ({:.1f})'.format(tn, round(100*tn/(fp+tn), 1)),
                                '{:d} ({:.1f})'.format(tp, round(100*tp/(fn+tp), 1)),
                                '{:d} ({:.1f})'.format(tp+tn, round(100*(tp+tn)/(fp+tn+fn+tp), 1))]])
    point_predciton = pd.DataFrame(point_predciton, columns=['Survivors', 'Nonsurvivors', 'Sum'], index=['Error', 'Correct'])
    print(point_predciton)
    return y_pre_label


def metric(all_data, model_type='xgb', external=False):
    print('result of '+ model_type + '...')
    if model_type=='xgb':
        if not external:
            x = all_data['x_test']
        else:
            x = all_data['x_eicu']
    else:
        if not external:
            x = all_data['x_test_process']
        else:
            x = all_data['x_eicu_process']
    if not external:
        y = all_data['y_test']
    else:
        y = all_data['y_eicu']

    y_death = np.array(y)
    path = './model/' + model_type + '_hos_death/all/'
    y_pre_pro = load_model_predict(x, model_type, path=path, set_up='hos_death')

    print('prediction metric of death...')
    y_pre_death = get_sub_metirc(y_pre_pro, y)


all_data = pickle.load(open('./data/hos_death/all/save_data.pkl', 'rb'))

for external in [False, True]:
    print('internal validation...' if not external else 'external validation...')
    for model_type in ['xgb', 'lr', 'rf']:
        metric(all_data, model_type, external=external)
    print()
