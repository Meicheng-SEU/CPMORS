with first_day_gcs as
(
  select patientunitstayid
  , min(gcs) as gcs
  from `physionet-data.eicu_crd_derived.pivoted_gcs`
  where chartoffset >= 60*(-6) and chartoffset <= 60*24
  group by patientunitstayid
  order by patientunitstayid
)
, first_day_input as   
(
  select patientunitstayid
  , sum(intaketotal) as input_total
  from `physionet-data.eicu_crd.intakeoutput`
  where intakeoutputoffset >= 0 and intakeoutputoffset <= 60*24
  group by patientunitstayid
  order by patientunitstayid
)
, first_day_output as   
(
  select patientunitstayid
  , SUM(urineoutput) AS urine_total
  FROM `physionet-data.eicu_crd_derived.pivoted_uo` uo
  WHERE chartoffset >= 0 AND chartoffset <= 24*60 
  GROUP BY uo.patientunitstayid
  order by patientunitstayid
)
, first_icu as
(
  select icu.patientunitstayid
  , age
  , hosp_mort as hos_death
  , gender as male
  , case when ethnicity = 'Caucasian' then 1 else 0 end as white
  , case when ethnicity = 'African American' then 1 else 0 end as black
  , case when ethnicity = 'Asian' then 1 else 0 end as asian
  , case when ethnicity = 'Hispanic' or ethnicity = '' or ethnicity = 'Other/Unknown' 
         or ethnicity = 'Native American' then 1 else 0 end as ethni_other
  , ckd
  , chf
  , cld as cpd
  , case when diabetes_without_cc = 1 or diabetes_with_cc = 1 then 1 else 0 end as diabetes
  , severe_liver_disease as liver

  , sep.sofa
  , sep.sofa_resp as sofa_respiration
  , sep.sofa_hematology as sofa_coagulation
  , sep.sofa_liver as sofa_liver
  , sep.sofa_circ as sofa_cardiovascular
  , sep.sofa_gcs as sofa_cns
  , sep.sofa_renal as sofa_renal

  , apsiii
  , nee_use   --remember transfer null to 0

  , admissionheight as height
  , admissionweight as weight
  , icu_los_hours as icu_los
  from `physionet-data.eicu_crd_derived.icustay_detail` icu
  left join `cpmors.eicu.charlson` charlson
    on charlson.patientunitstayid = icu.patientunitstayid
  left join (select * from `cpmors.eicu.sofa` where day=1) sep
    on sep.patientunitstayid = icu.patientunitstayid
  left join (select patientunitstayid, max(acutephysiologyscore) as apsiii
              from `physionet-data.eicu_crd.apachepatientresult`
              group by patientunitstayid) apache
    on apache.patientunitstayid = icu.patientunitstayid
  left join (select patientunitstayid, max(vasopressor) as nee_use
              from `physionet-data.eicu_crd_derived.pivoted_treatment_vasopressor`
              where chartoffset<=30*60 and chartoffset>=(-12)*60
              group by patientunitstayid) vaso
    on vaso.patientunitstayid = icu.patientunitstayid
  WHERE icu.unitvisitnumber = 1
  and hosp_mort is not null
)
, exclu_age AS
(
    select * from 
      (select *
      , case when age = '> 89' then 90
            else cast(age as NUMERIC) end as age_int
      FROM (SELECT * FROM first_icu WHERE age != ''))
    WHERE age_int >= 18
)
, exclu_stay AS
(
    SELECT * FROM exclu_age
    WHERE icu_los > 24
    -- AND icu_los_hours <= 24*28
)
, sepsis as
(
  select patientunitstayid
  , case when apacheadmissiondx = 'Sepsis, pulmonary' then 1 else 0 end as lung_infection
  , case when apacheadmissiondx = 'Sepsis, GI' then 1 else 0 end as Gastrointestinal_infection
  , case when apacheadmissiondx = 'Sepsis, renal/UTI (including  bladder)' then 1 else 0 end as Genitourinary_infection
  from `physionet-data.eicu_crd.patient`
  where apacheadmissiondx in ('Sepsis, cutaneous/soft tissue', 'Sepsis, GI', 
  'Sepsis, gynecologic', 'Sepsis, other', 'Sepsis, pulmonary', 'Sepsis, renal/UTI (including  bladder)', 'Sepsis, unknown')
)
, patient_icu_death as
(
  select patientunitstayid,
  CASE WHEN lower(pt.unitdischargestatus) like '%alive%' THEN 0
      WHEN lower(pt.unitdischargestatus) like '%expired%' THEN 1
      ELSE NULL END AS icu_death,
  from `physionet-data.eicu_crd.patient` pt
  order by pt.uniquepid, pt.unitvisitnumber
)
, database as
(
  select exclu_stay.patientunitstayid as stay_id
  , icu_death
  , hos_death
  , male
  , white
  , black
  , asian
  , ethni_other

  , ckd
  , chf
  , cpd
  , liver
  , diabetes

  , lung_infection
  , Gastrointestinal_infection
  , Genitourinary_infection

  , case when nee_use = 1 then 1 else 0 end as nee_use

  , age_int as age
  , height
  , weight
  , gcs
  , apsiii

  , sofa
  , sofa_respiration
  , sofa_coagulation
  , sofa_liver
  , sofa_cardiovascular
  , sofa_cns
  , sofa_renal

  , input_total
  , urine_total

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
  , 100*fio2_chartevents_min as fio2_chartevents_min, 100*fio2_chartevents_max as fio2_chartevents_max
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
  , icu_los
  from exclu_stay
  inner join sepsis
    on sepsis.patientunitstayid = exclu_stay.patientunitstayid
  inner join patient_icu_death
    on patient_icu_death.patientunitstayid = exclu_stay.patientunitstayid
  left join `cpmors.eicu.first_day_vital_bg_lab` vital_bg_lab
    on vital_bg_lab.stay_id = exclu_stay.patientunitstayid
  left join first_day_gcs
    on first_day_gcs.patientunitstayid = exclu_stay.patientunitstayid
  left join first_day_input
    on first_day_input.patientunitstayid = exclu_stay.patientunitstayid
  left join first_day_output
    on first_day_output.patientunitstayid = exclu_stay.patientunitstayid
  order by exclu_stay.patientunitstayid
)
select * from database
where heart_rate_min is not null
