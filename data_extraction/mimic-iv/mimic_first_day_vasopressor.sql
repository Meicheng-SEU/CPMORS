with vaso_1day as
(
  select ie.stay_id
  , norepinephrine_equivalent_dose
  from `physionet-data.mimiciv_derived.icustay_detail` ie
  inner join `cpmors.mimic.norepinephrine_equivalent_dose` vaso
    on ie.stay_id = vaso.stay_id
  where date_diff(starttime, ie.icu_intime, hour) <= 24 and date_diff(endtime, ie.icu_intime, hour) >= 0
  order by stay_id, starttime
)
, vaso_max as
(
  select ie.stay_id
  , max(norepinephrine_equivalent_dose) as nee_max
  from `physionet-data.mimiciv_derived.icustay_detail` ie
  left join `cpmors.mimic.norepinephrine_equivalent_dose` vaso
  on vaso.stay_id = ie.stay_id
  group by ie.stay_id
  order by ie.stay_id
)
select * from vaso_max
