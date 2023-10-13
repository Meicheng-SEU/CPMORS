select demo.stay_id
, hos_death
, case when demo.gender = 'M' then 1 else 0 end as male
, case when demo.ethni = 'WHITE' then 1 else 0 end as white
, case when demo.ethni = 'BLACK' then 1 else 0 end as black
, case when demo.ethni = 'ASIAN' then 1 else 0 end as asian
, case when demo.ethni = 'other' then 1 else 0 end as ethni_other
, demo.ckd
, demo.chf
, demo.cpd
, demo.liver
, demo.diabetes

, infect.lung_infection
, Gastrointestinal_infection
, infect.Genitourinary_infection
, case when demo.nee_max>0 then 1 else 0 end as nee_use

, demo.age
, demo.height
, demo.weight
, demo.gcs
, demo.apsiii

, sofa_1day.sofa
, sofa_1day.respiration as sofa_respiration
, sofa_1day.coagulation as sofa_coagulation
, sofa_1day.liver as sofa_liver
, sofa_1day.cardiovascular as sofa_cardiovascular
, sofa_1day.cns as sofa_cns
, sofa_1day.renal as sofa_renal

, demo.input_total
, demo.urine_total

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
, lab.glucose_min, lab.glucose_max
, sodium_min, sodium_max
, potassium_min, potassium_max
, inr_min, inr_max
, pt_min, pt_max
, ptt_min, ptt_max
, alt_min, alt_max
, alp_min, alp_max
, ast_min, ast_max
, bilirubin_total_min, bilirubin_total_max
, icu_los

from `cpmors.mimic.demographics` demo
inner join `cpmors.mimic.first_day_vitalsign_combine_invasive_nonin` vs
  on vs.stay_id = demo.stay_id
inner join `cpmors.mimic.first_day_bg_lab` lab
  on lab.stay_id = demo.stay_id
left join `physionet-data.mimiciv_derived.first_day_sofa` sofa_1day 
  on sofa_1day.stay_id = demo.stay_id
left join `cpmors.mimic.infection_site` infect
  on infect.stay_id = demo.stay_id
order by demo.stay_id
