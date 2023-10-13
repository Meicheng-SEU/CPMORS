import pickle
import pandas as pd
import numpy as np
import xgboost as xgb


lite = False
feature_selection = 'all' if not lite else 'lite'
all_data = pickle.load(open('./data/hos_death/' + feature_selection + '/save_data.pkl', 'rb'))


def create_calibration_data(lite):
    model = xgb.XGBClassifier()
    path = './model/xgb_hos_death/' + feature_selection + '/'
    model.load_model(fname=path + 'model.json')
    calibset = pd.DataFrame(np.concatenate((all_data['y_val'].reshape(-1, 1),
                            model.predict_proba(all_data['x_val'])), axis=1), columns=['cx', 'pr_ben', 'pr_cx'])
    testset = pd.DataFrame(np.concatenate((all_data['y_test'].reshape(-1, 1),
                            model.predict_proba(all_data['x_test'])), axis=1), columns=['cx', 'pr_ben', 'pr_cx'])
    externalset = pd.DataFrame(np.concatenate((all_data['y_eicu'].reshape(-1, 1),
                            model.predict_proba(all_data['x_eicu'])), axis=1), columns=['cx', 'pr_ben', 'pr_cx'])
    if not lite:
        calibset.to_csv('../R/Data/Demo/calibset.csv', index=False)
        testset.to_csv('../R/Data/Demo/testset.csv', index=False)
        externalset.to_csv('../R/Data/Demo/externalset.csv', index=False)
    else:
        calibset.to_csv('../R/Data/DemoLite/calibset.csv', index=False)
        testset.to_csv('../R/Data/DemoLite/testset.csv', index=False)
        externalset.to_csv('../R/Data/DemoLite/externalset.csv', index=False)
create_calibration_data(lite)
