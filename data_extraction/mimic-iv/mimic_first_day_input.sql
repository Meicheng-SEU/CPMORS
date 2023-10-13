with iv_1day as
(
  select input.stay_id
  -- , starttime
  , datetime_diff(starttime, icu_intime, hour) as start_hour
  -- , endtime
  , datetime_diff(endtime, icu_intime, hour) as end_hour
  , case when amountuom='L' then amount*1000 else amount end as iv_amount
  , amountuom
  , case when rateuom='mL/min' then rate*60 else rate end as iv_rate
  , rateuom
  , ordercategoryname
  , ordercategorydescription
  from `physionet-data.mimiciv_icu.inputevents` input
  inner join `physionet-data.mimiciv_derived.icustay_detail` icu
    on input.stay_id = icu.stay_id
  where ordercategorydescription != 'Non Iv Meds'
  and date_diff(starttime, icu_intime, hour) <= 24 and date_diff(endtime, icu_intime, hour) > 0
  and rateuom in ('mL/min','mL/hour')
  order by stay_id, start_hour
)
, iv_duration as
(
  select stay_id
  , start_hour
  , end_hour
  , case when (start_hour>=0 and end_hour<=24) then iv_amount 
    when (start_hour<0 and end_hour>=0) then end_hour*iv_rate
    when (start_hour>=0 and end_hour>=24) then (24-start_hour)*iv_rate
    when (start_hour<0 and end_hour>=24) then 24*iv_rate
    end as duration_input_total
  , iv_amount
  , iv_rate
  from iv_1day
)
select ie.stay_id
, sum(duration_input_total) as input_total_1day
from `physionet-data.mimiciv_derived.icustay_detail` ie
left join iv_duration
  on iv_duration.stay_id = ie.stay_id
group by ie.stay_id
order by ie.stay_id

