with sep_icu as                 
(
  select icu.*, sofa_score from `physionet-data.mimiciv_derived.icustay_detail` icu
  inner join `cpmors.mimic.first_day_sepsis` sep
    on icu.stay_id = sep.stay_id
  order by icu.stay_id
)
, first_stay as                 
(
  select * from sep_icu
  where first_icu_stay = true
)
, longer_24hr as               
(
  select * from first_stay
  where datetime_diff(icu_outtime, icu_intime, hour) > 24)
, adult as                      
(
  select * from longer_24hr
  where admission_age >= 18 and admission_age is not null
)
select * from adult
order by stay_id
