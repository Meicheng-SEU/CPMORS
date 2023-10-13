import xgboost as xgb
from hyperopt import STATUS_OK, hp, fmin, tpe
from sklearn.metrics import accuracy_score, roc_auc_score
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
import joblib
from tensorflow.keras.models import load_model


def BO_TPE_XGB(x_train, y_train, x_val, y_val, sample_weights):
    def objective(params):
        xgb_model = xgb.XGBClassifier(max_depth=params['max_depth'],
                                      eta=params['learning_rate'],
                                      n_estimators=1000,
                                      subsample=params['subsample'],
                                      colsample_bytree=params['colsample_bytree'],
                                      reg_alpha=params['reg_alpha'],
                                      reg_lambda=params['reg_lambda'],
                                      objective="binary:logistic"
                                      )

        es = xgb.callback.EarlyStopping(
            rounds=20,
            save_best=True,
            maximize=True,
            metric_name='auc',
        )
        xgb_model = xgb_model.fit(x_train, y_train, eval_set=[(x_val, y_val)], verbose=False,
                                  eval_metric='auc',
                                  callbacks=[es], sample_weight=sample_weights)

        y_vd_pred = xgb_model.predict(x_val, ntree_limit=xgb_model.best_ntree_limit)
        metric = roc_auc_score(y_val, xgb_model.predict_proba(x_val, ntree_limit=xgb_model.best_ntree_limit)[:, 1])
        loss = 1 - metric

        return {'loss': loss, 'params': params, 'status': STATUS_OK}

    max_depths = [2, 3, 4, 5, 6, 7, 8, 9, 10]
    learning_rates = [0.001, 0.01, 0.02, 0.04, 0.06, 0.08, 0.1, 0.15, 0.2, 0.3]
    subsamples = [0.5, 0.6, 0.7, 0.8, 0.9, 1]
    colsample_bytrees = [0.5, 0.6, 0.7, 0.8, 0.9, 1]
    reg_alphas = [0.0, 0.005, 0.01, 0.05, 0.1]
    reg_lambdas = [0.8, 1, 1.5, 2, 4]

    space = {
        'max_depth': hp.choice('max_depth', max_depths),
        'learning_rate': hp.choice('learning_rate', learning_rates),
        'subsample': hp.choice('subsample', subsamples),
        'colsample_bytree': hp.choice('colsample_bytree', colsample_bytrees),
        'reg_alpha': hp.choice('reg_alpha', reg_alphas),
        'reg_lambda': hp.choice('reg_lambda', reg_lambdas),
    }

    best = fmin(fn=objective, space=space, verbose=True, algo=tpe.suggest, max_evals=20)

    best_param = {'max_depth': max_depths[(best['max_depth'])],
                  'learning_rate': learning_rates[(best['learning_rate'])],
                  'subsample': subsamples[(best['subsample'])],
                  'colsample_bytree': colsample_bytrees[(best['colsample_bytree'])],
                  'reg_alpha': reg_alphas[(best['reg_alpha'])],
                  'reg_lambda': reg_lambdas[(best['reg_lambda'])]
                  }

    return best_param


def BO_TPE_RF(x_train, y_train, x_val, y_val):
    def objective(space):
        model = RandomForestClassifier(
                                       max_depth=space['max_depth'],
                                       min_samples_leaf=space['min_samples_leaf'],
                                       min_samples_split=space['min_samples_split'],
                                       n_estimators=1000,
                                       class_weight='balanced'
                                       )

        model.fit(x_train, y_train)
        y_vd_pred = model.predict(x_val)
        acc = accuracy_score(y_val, y_vd_pred)
        loss = 1 - acc

        return {'loss': loss, 'status': STATUS_OK}

    max_depths = [2, 4, 6, 8, 10, 15, 20]
    n_estimators = [10, 50, 75, 100, 300, 750]
    space = {
             'max_depth': hp.choice('max_depth', max_depths),
             'min_samples_leaf': hp.uniform('min_samples_leaf', 0, 1),
             'min_samples_split': hp.uniform('min_samples_split', 0, 1),
             'n_estimators': hp.choice('n_estimators', n_estimators)
             }

    best = fmin(fn=objective, space=space, verbose=True, algo=tpe.suggest, max_evals=20)

    best_param = {
                  'max_depth': max_depths[best['max_depth']],
                  'min_samples_leaf': best['min_samples_leaf'],
                  'min_samples_split': best['min_samples_split'],
                  'n_estimators': n_estimators[best['n_estimators']]
    }

    return best_param


def BO_TPE_LR(x_train, y_train, x_val, y_val):
    def objective(space):
        log_model = LogisticRegression(solver=space['solver'],
                                       C=space['C'],
                                       class_weight='balanced')
        log_model.fit(x_train, y_train)
        lr_y_pre = log_model.predict(x_val)
        metric = roc_auc_score(y_val, log_model.predict_proba(x_val)[:, 1])
        loss = 1 - metric

        return {'loss': loss, 'status': STATUS_OK}

    solvers = ['newton-cg', 'sag', 'saga', 'lbfgs']
    space = {
        'C': hp.lognormal('C', 0, 1.0),
        'solver': hp.choice('solver', solvers)
    }

    best = fmin(fn=objective, space=space, verbose=True, algo=tpe.suggest, max_evals=20)
    best_param = {'C': best['C'],
                  'solver': solvers[best['solver']]}

    return best_param


def load_model_predict(x_test, model_type, path, set_up):
    if model_type == 'xgb':
        model = xgb.XGBClassifier()
        model.load_model(fname=path + 'model.json')
        y_test_pred = model.predict_proba(x_test)
    elif model_type == 'ndf':
        model = load_model(path)
        y_test_pred = model.predict(x_test)
    else:
        model = joblib.load(path + 'model.joblib')
        y_test_pred = model.predict_proba(x_test)

    return y_test_pred[:, 1]
