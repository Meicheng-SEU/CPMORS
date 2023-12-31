-- This query pivots vital signs and aggregates them
-- for the first 24 hours of a patient's stay.
SELECT
    ie.subject_id
    , ie.stay_id
    , MIN(heart_rate) AS heart_rate_min
    , MAX(heart_rate) AS heart_rate_max
    , AVG(heart_rate) AS heart_rate_mean
    , STDDEV(heart_rate) AS heart_rate_std

    , MIN(sbp) AS sbp_min
    , MAX(sbp) AS sbp_max
    , AVG(sbp) AS sbp_mean
    , STDDEV(sbp) AS sbp_std

    , MIN(dbp) AS dbp_min
    , MAX(dbp) AS dbp_max
    , AVG(dbp) AS dbp_mean
    , STDDEV(dbp) AS dbp_std

    , MIN(mbp) AS mbp_min
    , MAX(mbp) AS mbp_max
    , AVG(mbp) AS mbp_mean
    , STDDEV(mbp) AS mbp_std

    , MIN(resp_rate) AS resp_rate_min
    , MAX(resp_rate) AS resp_rate_max
    , AVG(resp_rate) AS resp_rate_mean
    , STDDEV(resp_rate) AS resp_rate_std

    , MIN(temperature) AS temperature_min
    , MAX(temperature) AS temperature_max
    , AVG(temperature) AS temperature_mean
    , STDDEV(temperature) AS temperature_std

    , MIN(spo2) AS spo2_min
    , MAX(spo2) AS spo2_max
    , AVG(spo2) AS spo2_mean
    , STDDEV(spo2) AS spo2_std
    
    , MIN(glucose) AS glucose_min
    , MAX(glucose) AS glucose_max
    , AVG(glucose) AS glucose_mean
    , STDDEV(glucose) AS glucose_std
FROM `physionet-data.mimiciv_icu.icustays` ie
LEFT JOIN `physionet-data.mimiciv_derived.vitalsign` ce
    ON ie.stay_id = ce.stay_id
        AND ce.charttime >= DATETIME_SUB(ie.intime, INTERVAL '6' HOUR)
        AND ce.charttime <= DATETIME_ADD(ie.intime, INTERVAL '1' DAY)
GROUP BY ie.subject_id, ie.stay_id;
