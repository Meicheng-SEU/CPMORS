with vital as
(
  SELECT * 
, CASE
    WHEN nibp_systolic IS NOT NULL
        AND ibp_systolic IS NOT NULL
            THEN ROUND((nibp_systolic + ibp_systolic) / 2, 1)
    WHEN nibp_systolic IS NOT NULL
        AND ibp_systolic IS NULL
            THEN nibp_systolic
    WHEN nibp_systolic IS  NULL
        AND ibp_systolic IS NOT NULL
            THEN ibp_systolic
    ELSE NULL END
  AS sbp
, CASE
    WHEN nibp_diastolic IS NOT NULL
        AND ibp_diastolic IS NOT NULL
            THEN ROUND((nibp_diastolic + ibp_diastolic) / 2, 1)
    WHEN nibp_diastolic IS NOT NULL
        AND ibp_diastolic IS NULL
            THEN nibp_diastolic
    WHEN nibp_diastolic IS  NULL
        AND ibp_diastolic IS NOT NULL
            THEN ibp_diastolic
    ELSE NULL END
  AS dbp
, CASE
    WHEN nibp_mean IS NOT NULL
        AND ibp_mean IS NOT NULL
            THEN ROUND((nibp_mean + ibp_mean) / 2, 1)
    WHEN nibp_mean IS NOT NULL
        AND ibp_mean IS NULL
            THEN nibp_mean
    WHEN nibp_mean IS  NULL
        AND ibp_mean IS NOT NULL
            THEN ibp_mean
    ELSE NULL END
  AS mbp
FROM `physionet-data.eicu_crd_derived.pivoted_vital`
where chartoffset >= 60*(-6) and chartoffset <= 60*24
ORDER BY patientunitstayid, chartoffset
)
, first_day_bg as
(
  select patientunitstayid
  , MIN(pH) AS ph_min, MAX(pH) AS ph_max
  , MIN(baseexcess) AS baseexcess_min, MAX(baseexcess) AS baseexcess_max
  , MIN(pao2) AS po2_min, MAX(pao2) AS po2_max
  , MIN(paco2) AS pco2_min, MAX(paco2) AS pco2_max
  , MIN(fio2) AS fio2_chartevents_min, MAX(fio2) AS fio2_chartevents_max
  , MIN(aniongap) AS aniongap_min, MAX(aniongap) AS aniongap_max
  from `physionet-data.eicu_crd_derived.pivoted_bg` bg
  where bg.chartoffset >= 60*(-12) and bg.chartoffset <= 60*36
  group by patientunitstayid
  order by patientunitstayid
)
, pf as
(
  select patientunitstayid
  , case when bg.pao2 is null THEN NULL
      WHEN bg.fio2 IS NOT NULL and bg.fio2 != 0 then bg.pao2/bg.fio2
      else null end as pao2fio2ratio
  from `physionet-data.eicu_crd_derived.pivoted_bg` bg
  where bg.chartoffset >= 60*(-12) and bg.chartoffset <= 60*36
  order by patientunitstayid
)
, first_day_pf as
(
  select patientunitstayid
  , MIN(pao2fio2ratio) AS pao2fio2ratio_min, MAX(pao2fio2ratio) AS pao2fio2ratio_max
  from pf
  group by patientunitstayid
  order by patientunitstayid
)
, first_day_lab as
(
  select patientunitstayid
  , MIN(lactate) AS lactate_min, MAX(lactate) AS lactate_max
  , MIN(bicarbonate) AS bicarbonate_min, MAX(bicarbonate) AS bicarbonate_max
  , MIN(hematocrit) AS hematocrit_min, MAX(hematocrit) AS hematocrit_max
  , MIN(hemoglobin) AS hemoglobin_min, MAX(hemoglobin) AS hemoglobin_max
  , MIN(platelets) AS platelets_min, MAX(platelets) AS platelets_max
  , MIN(wbc) AS wbc_min, MAX(wbc) AS wbc_max
  , MIN(albumin) AS albumin_min, MAX(albumin) AS albumin_max
  , MIN(BUN) AS bun_min, MAX(BUN) AS bun_max
  , MIN(calcium) AS calcium_min, MAX(calcium) AS calcium_max
  , MIN(chloride) AS chloride_min, MAX(chloride) AS chloride_max
  , MIN(creatinine) AS creatinine_min, MAX(creatinine) AS creatinine_max
  , MIN(glucose) AS glucose_min, MAX(glucose) AS glucose_max
  , MIN(sodium) AS sodium_min, MAX(sodium) AS sodium_max
  , MIN(potassium) AS potassium_min, MAX(potassium) AS potassium_max
  , MIN(INR) AS inr_min, MAX(INR) AS inr_max
  , MIN(pt) AS pt_min, MAX(pt) AS pt_max
  , MIN(ptt) AS ptt_min, MAX(ptt) AS ptt_max
  , MIN(alt) AS alt_min, MAX(alt) AS alt_max
  , MIN(alp) AS alp_min, MAX(alp) AS alp_max
  , MIN(ast) AS ast_min, MAX(ast) AS ast_max
  , MIN(bilirubin) AS bilirubin_total_min, MAX(bilirubin) AS bilirubin_total_max
--   , lactate
--   , bicarbonate
--   , hematocrit
--   , hemoglobin
--   , platelets
--   , wbc
--   , albumin
--   , BUN as bun
--   , calcium
--   , chloride
--   , creatinine
--   , glucose
--   , sodium
--   , potassium
--   , INR as inr
--   , pt
--   , ptt
--   , alt
--   , alp
--   , ast
--   , bilirubin
  from `cpmors.eicu.pivoted_lab` lab
  where lab.chartoffset >= 60*(-12) and lab.chartoffset <= 60*36
  group by patientunitstayid
  order by patientunitstayid
)
, first_day_vital as
(
    select vital.patientunitstayid as stay_id
    , MIN(heartrate) AS heart_rate_min
    , MAX(heartrate) AS heart_rate_max
    , AVG(heartrate) AS heart_rate_mean
    , STDDEV(heartrate) AS heart_rate_std

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

    , MIN(respiratoryrate) AS resp_rate_min
    , MAX(respiratoryrate) AS resp_rate_max
    , AVG(respiratoryrate) AS resp_rate_mean
    , STDDEV(respiratoryrate) AS resp_rate_std

    , MIN(temperature) AS temperature_min
    , MAX(temperature) AS temperature_max
    , AVG(temperature) AS temperature_mean
    , STDDEV(temperature) AS temperature_std

    , MIN(spo2) AS spo2_min
    , MAX(spo2) AS spo2_max
    , AVG(spo2) AS spo2_mean
    , STDDEV(spo2) AS spo2_std
from vital
group by vital.patientunitstayid
order by vital.patientunitstayid
)
select first_day_vital.stay_id
, heart_rate_min, heart_rate_max, heart_rate_mean, heart_rate_std
, sbp_min, sbp_max, sbp_mean, sbp_std
, dbp_min, dbp_max, dbp_mean, dbp_std
, mbp_min, mbp_max, mbp_mean, mbp_std
, resp_rate_min, resp_rate_max, resp_rate_mean, resp_rate_std
, temperature_min, temperature_max, temperature_mean, temperature_std
, spo2_min, spo2_max, spo2_mean, spo2_std
, ph_min, ph_max
, lactate_min, lactate_max
, bicarbonate_min, bicarbonate_max
, baseexcess_min, baseexcess_max
, po2_min, po2_max
, pco2_min, pco2_max
, pao2fio2ratio_min, pao2fio2ratio_max
, fio2_chartevents_min, fio2_chartevents_max
, hematocrit_min, hematocrit_max
, hemoglobin_min, hemoglobin_max
, platelets_min, platelets_max
, wbc_min, wbc_max
, albumin_min, albumin_max
, aniongap_min, aniongap_max
, bun_min, bun_max
, calcium_min, calcium_max
, chloride_min, chloride_max
, creatinine_min, creatinine_max
, glucose_min, glucose_max
, sodium_min, sodium_max
, potassium_min, potassium_max
, inr_min, inr_max
, pt_min, pt_max
, ptt_min, ptt_max
, alt_min, alt_max
, alp_min, alp_max
, ast_min, ast_max
, bilirubin_total_min, bilirubin_total_max
from first_day_vital 
left join first_day_bg
  on first_day_bg.patientunitstayid = first_day_vital.stay_id
left join first_day_pf
  on first_day_pf.patientunitstayid = first_day_vital.stay_id
left join first_day_lab
  on first_day_lab.patientunitstayid = first_day_vital.stay_id
