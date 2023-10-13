with sep as
(
select 
  sep_raw.subject_id,
  sep_raw.stay_id,
  sep_raw.suspected_infection_time,
  sep_raw.sofa_time,
  sep_raw.sofa_score,
  icu.intime,
  case when sofa_time >= suspected_infection_time then suspected_infection_time
      else sofa_time end as sepsis_onset,
  datetime_diff(icu.outtime, icu.intime, hour) as icu_stay
from `cpmors.mimic.sepsis3` sep_raw
inner join `physionet-data.mimiciv_icu.icustays` icu 
  on icu.stay_id = sep_raw.stay_id
order by stay_id, icu.intime
)
select
  sep.*,
  datetime_diff(sep.sepsis_onset, sep.intime, hour) as sepsis_time
from sep
where datetime_diff(sep.sepsis_onset, sep.intime, hour) <= 24   
order by stay_id, sep.intime
