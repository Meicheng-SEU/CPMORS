with comorbidity as
(
  select charlson.hadm_id
  , ckd.ckd
  , congestive_heart_failure as chf
  , chronic_pulmonary_disease as cpd
  , severe_liver_disease as liver
  , case 
      when diabetes_without_cc = 1 or diabetes_with_cc = 1
      then 1
    else 0 end as diabetes
  from `physionet-data.mimiciv_derived.charlson` charlson
  inner join `cpmors.mimic.ckd` ckd
    on ckd.hadm_id = charlson.hadm_id
)
, height as
(
  select ie.stay_id
  , round(cast(avg(height) as numeric), 2) as height
  from `physionet-data.mimiciv_icu.icustays` ie
  left join `physionet-data.mimiciv_derived.height` ht
    on ie.stay_id = ht.stay_id
  group by ie.stay_id
)
, weight_stay as 
(
  select ie.stay_id
  , avg(case when weight_type = 'admit' then ce.weight else null end) as weight_admit
  , avg(ce.weight) as weight_avg
  , min(ce.weight) as weight_min
  , max(ce.weight) as weight_max
  from `physionet-data.mimiciv_icu.icustays` ie
  left join `physionet-data.mimiciv_derived.weight_durations` ce
    on ie.stay_id = ce.stay_id
  group by ie.subject_id, ie.stay_id
  order by ie.stay_id
)
select pat.hadm_id
, pat.stay_id
, pat.gender
, case when adm.race like '%ASIAN%' then 'ASIAN'
        when adm.race like '%WHITE%' then 'WHITE'
        when adm.race like '%BLACK%' then 'BLACK'
            else 'other' end as ethni 
, pat.admission_age as age
, height.height
, case when weight_admit is not null then weight_admit else weight_avg end as weight
, ckd
, chf
, cpd
, liver
, diabetes
, pat.sofa_score as sofa
, first_day_gcs.gcs_min as gcs
, apsiii.apsiii
, first_day_input.input_total_1day as input_total
, first_day_urine_output.urineoutput as urine_total
, case when first_day_vasopressor.nee_max is null then 0 
       when first_day_vasopressor.nee_max >5 then 5
       else first_day_vasopressor.nee_max end as nee_max
, pat.hospital_expire_flag as hos_death
, datetime_diff(pat.icu_outtime, pat.icu_intime, hour) icu_los
from `cpmors.mimic.mimic_study_population` pat
inner join `physionet-data.mimiciv_hosp.admissions` adm
  on adm.hadm_id = pat.hadm_id
inner join height
  on height.stay_id = pat.stay_id
inner join weight_stay
  on weight_stay.stay_id = pat.stay_id
inner join comorbidity
  on comorbidity.hadm_id = pat.hadm_id
inner join `physionet-data.mimiciv_derived.first_day_gcs` first_day_gcs
  on first_day_gcs.stay_id = pat.stay_id
inner join `physionet-data.mimiciv_derived.apsiii` apsiii
  on apsiii.stay_id = pat.stay_id
inner join `cpmors.mimic.first_day_input` first_day_input
  on first_day_input.stay_id = pat.stay_id
inner join `cpmors.mimic.first_day_urine_output` first_day_urine_output
  on first_day_urine_output.stay_id = pat.stay_id
inner join `cpmors.mimic.first_day_vasopressor` first_day_vasopressor
  on first_day_vasopressor.stay_id = pat.stay_id
order by pat.stay_id


