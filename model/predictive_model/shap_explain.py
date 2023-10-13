import numpy as np
import pandas as pd
import shap
import xgboost as xgb
import warnings
import pickle
from util import preprocess, load_database
import matplotlib.pyplot as plt
warnings.filterwarnings('ignore')


lite = False
c = ['Genitourinary_infection', 'input_total', 'uo_max', 'uo_min', 'uo_mean', 'uo_std',
     'sofa_respiration', 'sofa_coagulation', 'sofa_liver', 'sofa_cardiovascular', 'sofa_cns', 'sofa_renal']

mimic = load_database('mimic_sepsis', remove_missing_ratio=0.3, drop_columns=c)
x, y = preprocess(mimic, 'hos_death', lite=lite)
col_name = pd.read_csv('result/variable_name.csv')
x.columns = list(col_name['var_name'])
feature_selection = 'all' if not lite else 'lite'
all_data = pickle.load(open('data/hos_death/' + feature_selection + '/save_data.pkl', 'rb'))
feature_name = x.columns.tolist()
shap_x = np.array(x.iloc[all_data['test_index'], :])
shap_label_y = np.array(y.iloc[all_data['test_index']])


def shap_value(input_data, model_path):
    shap.initjs()
    model = xgb.XGBClassifier()
    model.load_model(fname=model_path + 'model{}.json')
    y_test_pred = model.predict_proba(input_data)
    explainer = shap.TreeExplainer(model)
    expected_value = explainer.expected_value
    shap_values = explainer.shap_values(input_data)

    return shap_values, expected_value, y_test_pred[:, 1]


xgb_path = 'model/xgb_hos_death/' + feature_selection + '/'
shap_data, expected_value, y_pred_pro = shap_value(shap_x, model_path=xgb_path)

plt.figure(num=1, dpi=300)
shap.summary_plot(shap_data, shap_x, max_display=15, plot_type="dot", alpha=0.5, feature_names=feature_name,
                  title='Individual interpretability summary')
plt.show()
