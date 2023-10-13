-- Highest/lowest blood gas values for arterial blood specimens
with bg_1day as
(
    SELECT
        ie.subject_id
        , ie.stay_id
        , MIN(lactate) AS lactate_min, MAX(lactate) AS lactate_max
        , MIN(ph) AS ph_min, MAX(ph) AS ph_max
        , MIN(po2) AS po2_min, MAX(po2) AS po2_max
        , MIN(pco2) AS pco2_min, MAX(pco2) AS pco2_max
        , MIN(pao2fio2ratio) AS pao2fio2ratio_min, MAX(pao2fio2ratio) AS pao2fio2ratio_max
        , MIN(baseexcess) AS baseexcess_min, MAX(baseexcess) AS baseexcess_max
        , MIN(fio2_chartevents) AS fio2_chartevents_min, MAX(fio2_chartevents) AS fio2_chartevents_max
    FROM `physionet-data.mimiciv_icu.icustays` ie
    LEFT JOIN `physionet-data.mimiciv_derived.bg` bg
        ON ie.subject_id = bg.subject_id
            -- AND bg.specimen = 'ART.'
            AND bg.charttime >= DATETIME_SUB(ie.intime, INTERVAL '12' HOUR)
            AND bg.charttime <= DATETIME_ADD(ie.intime, INTERVAL '1' DAY)
    GROUP BY ie.subject_id, ie.stay_id
)
, lab_1day as
(
  select stay_id
  , hematocrit_min, hematocrit_max
  , hemoglobin_min, hemoglobin_max
  , platelets_min, platelets_max
  , wbc_min, wbc_max
  , albumin_min, albumin_max
  , aniongap_min, aniongap_max
  , bicarbonate_min, bicarbonate_max
  , bun_min, bun_max
  , calcium_min, calcium_max
  , chloride_min, chloride_max
  , creatinine_min, creatinine_max
  , glucose_min, glucose_max
  , sodium_min, sodium_max
  , potassium_min, potassium_max
  , fibrinogen_min, fibrinogen_max
  , inr_min, inr_max
  , pt_min, pt_max
  , ptt_min, ptt_max
  , alt_min, alt_max
  , alp_min, alp_max
  , ast_min, ast_max
  , bilirubin_total_min, bilirubin_total_max
  from `physionet-data.mimiciv_derived.first_day_lab` lab
)
select bg_1day.stay_id
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
, fibrinogen_min, fibrinogen_max
, inr_min, inr_max
, pt_min, pt_max
, ptt_min, ptt_max
, alt_min, alt_max
, alp_min, alp_max
, ast_min, ast_max
, bilirubin_total_min, bilirubin_total_max
from bg_1day
inner join lab_1day
    on lab_1day.stay_id = bg_1day.stay_id
order by bg_1day.stay_id


