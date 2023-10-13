with mer as
(   
    select 
    patientunitstayid
    , diagnosisstring
    , icd9code
    from `physionet-data.eicu_crd.diagnosis` diag
    group by patientunitstayid, diagnosisstring, icd9code
)
, com AS
(
    SELECT
        ie.patientunitstayid
        --  hypertension
        , MAX(CASE WHEN
            past.pasthistorypath like '%ypertension%'            
            THEN 1
            else 0 end) as hypertension    

        -- chronic kidney disease (CKD)
        , MAX(CASE WHEN
            icd9code LIKE '%585%' 
            OR icd9code LIKE '%582%'
            OR icd9code LIKE '%586%'
            OR icd9code LIKE '%403.00%'
            OR icd9code LIKE '%403.10%'
            OR icd9code LIKE '%403.90%'
            OR icd9code LIKE '%404.00%'
            OR icd9code LIKE '%404.01%'
            OR icd9code LIKE '%404.10%'
            OR icd9code LIKE '%404.11%'
            OR icd9code LIKE '%404.90%'
            OR icd9code LIKE '%404.91%'
            OR icd9code LIKE '%I12.9%'
            OR icd9code LIKE '%I13.0%'
            OR icd9code LIKE '%I13.10%'
            OR icd9code LIKE '%N18%'
            OR icd9code LIKE '%N19%'
          
            THEN 1 
            ELSE 0 END) AS ckd

        -- End stage renal disease (ESRD)
        , MAX(CASE WHEN
            icd9code LIKE '%Z49%'
            OR icd9code LIKE '%585.5%'
            OR icd9code LIKE '%585.6%'
            OR icd9code LIKE '%V45.11%'
            OR icd9code LIKE '%V45.12%'
            OR icd9code LIKE '%403.91%'
            OR icd9code LIKE '%404.02%'
            OR icd9code LIKE '%403.01%'
            OR icd9code LIKE '%403.11%'
            OR icd9code LIKE '%404.03%'     
            OR icd9code LIKE '%404.13%'
            OR icd9code LIKE '%404.12%'
            OR icd9code LIKE '%404.92%'
            OR icd9code LIKE '%404.93%'

            OR icd9code LIKE '%V56.0%'
            OR icd9code LIKE '%V56.1%' 
            OR icd9code LIKE '%V56.8%'

            OR icd9code LIKE '%N18.5%'
            OR icd9code LIKE '%N18.6%'
            OR icd9code LIKE '%I12.0%'
            OR icd9code LIKE '%Z94.0%'
            OR icd9code LIKE '%Z99.2%'
            OR icd9code LIKE '%I13.2%'
            OR icd9code LIKE '%I13.11%'
            OR icd9code LIKE '%Z91.15%'
            OR icd9code LIKE '%Z49.01%'

            THEN 1 
            ELSE 0 END) AS esrd

        -- coronary heart disease (CHD)
        , MAX(CASE WHEN
            icd9code LIKE '%410%' 
            OR icd9code LIKE '%411%'
            OR icd9code LIKE '%412%'
            OR icd9code LIKE '%413.0%'
            OR icd9code LIKE '%413.1%'
            OR icd9code LIKE '%413.9%'
            OR icd9code LIKE '%414.0%'
            OR icd9code LIKE '%414.2%'
            OR icd9code LIKE '%414.3%'
            OR icd9code LIKE '%414.4%'
            OR icd9code LIKE '%429.79%'
            OR icd9code LIKE '%996.03%'

            OR icd9code LIKE '%I20%'
            OR icd9code LIKE '%I21%'
            OR icd9code LIKE '%I22%'
            OR icd9code LIKE '%I23%'
            OR icd9code LIKE '%I25.2%'
            OR icd9code LIKE '%I24.0%'
            OR icd9code LIKE '%I25.1%'
            OR icd9code LIKE '%I25.2%'
            OR icd9code LIKE '%I25.7%'
            OR icd9code LIKE '%I25.8%'

            OR pasthistorypath like '%oronary%' 
            or pasthistorypath like '%ST elevation%'
            or pasthistorypath like '%MI%'

            THEN 1 
            ELSE 0 END) AS chd

        -- Congestive heart failure  (CHF)
        , MAX(CASE WHEN 
            icd9code LIKE '%428%'
            OR icd9code LIKE '%398.91%'
            OR icd9code LIKE '%402.01%'
            OR icd9code LIKE '%402.11%'
            OR icd9code LIKE '%402.91%'
            OR icd9code LIKE '%404.01%'
            OR icd9code LIKE '%404.03%'
            OR icd9code LIKE '%404.11%'
            OR icd9code LIKE '%404.13%'
            OR icd9code LIKE '%404.91%'
            OR icd9code LIKE '%404.93%'
            OR icd9code LIKE '%425.4%'
            OR icd9code LIKE '%425.5%'
            OR icd9code LIKE '%425.6%'
            OR icd9code LIKE '%425.7%'
            OR icd9code LIKE '%425.8%'
            OR icd9code LIKE '%425.9%'

            OR icd9code LIKE '%I43%'
            OR icd9code LIKE '%I50%'

            OR icd9code LIKE '%I09.9%'
            OR icd9code LIKE '%I11.0%'
            OR icd9code LIKE '%I13.0%'
            OR icd9code LIKE '%I13.2%'
            OR icd9code LIKE '%I25.5%'
            OR icd9code LIKE '%I42.0%'
            OR icd9code LIKE '%I42.5%'
            OR icd9code LIKE '%I42.6%'
            OR icd9code LIKE '%I42.7%'
            OR icd9code LIKE '%I42.8%'
            OR icd9code LIKE '%I42.9%'

            OR pasthistorypath like '%Heart Failure%' 
            OR pasthistorypath like '%CHF%'

            OR diagnosisstring LIKE '%heart failure%'
    
            THEN 1 
            ELSE 0 END) AS chf

        -- -- Chronic pulmonary disease  
        , MAX(CASE WHEN 
            icd9code LIKE '%490%'
            OR icd9code LIKE '%491%'
            OR icd9code LIKE '%492%'
            OR icd9code LIKE '%493%'
            OR icd9code LIKE '%494%'
            OR icd9code LIKE '%495%'
            OR icd9code LIKE '%496%'
            OR icd9code LIKE '%497%'
            OR icd9code LIKE '%498%'
            OR icd9code LIKE '%499%'
            OR icd9code LIKE '%500%'
            OR icd9code LIKE '%501%'
            OR icd9code LIKE '%502%'
            OR icd9code LIKE '%503%'
            OR icd9code LIKE '%504%'
            OR icd9code LIKE '%505%'
            OR icd9code LIKE '%416.8%'
            OR icd9code LIKE '%416.9%'
            OR icd9code LIKE '%506.4%'
            OR icd9code LIKE '%508.1%'
            OR icd9code LIKE '%508.8%'

            OR icd9code LIKE '%J40%'
            OR icd9code LIKE '%J41%'
            OR icd9code LIKE '%J42%'
            OR icd9code LIKE '%J43%'
            OR icd9code LIKE '%J44%'
            OR icd9code LIKE '%J45%'
            OR icd9code LIKE '%J46%'
            OR icd9code LIKE '%J47%'

            OR icd9code LIKE '%J60%'
            OR icd9code LIKE '%J61%'
            OR icd9code LIKE '%J62%'
            OR icd9code LIKE '%J63%'
            OR icd9code LIKE '%J64%'
            OR icd9code LIKE '%J65%'
            OR icd9code LIKE '%J66%'
            OR icd9code LIKE '%J67%'

            OR icd9code LIKE '%I27.8%'
            OR icd9code LIKE '%I27.9%'
            OR icd9code LIKE '%J68.4%'
            OR icd9code LIKE '%J70.1%'
            OR icd9code LIKE '%J70.3%'
            OR pasthistorypath like '%COPD%'
            THEN 1 
            ELSE 0 END) AS cld

        , MAX(CASE WHEN 
            diagnosisstring LIKE '%diabetes mellitus%'
            THEN 1 
            ELSE 0 END) AS diabetes_without_cc

        , MAX(CASE WHEN 
            past.pasthistorypath like '%iabetes%' 
            THEN 1 
            ELSE 0 END) AS diabetes_with_cc

        -- Moderate or severe liver disease 
        , MAX(CASE WHEN 
            icd9code LIKE '%456.0%'
            OR icd9code LIKE '%456.1%'
            OR icd9code LIKE '%456.2%'

            OR icd9code LIKE '%572.2%'
            OR icd9code LIKE '%572.3%'
            OR icd9code LIKE '%572.4%'
            OR icd9code LIKE '%572.5%'
            OR icd9code LIKE '%572.6%'
            OR icd9code LIKE '%572.7%'
            OR icd9code LIKE '%572.8%'

            OR icd9code LIKE '%I85.0%'
            OR icd9code LIKE '%I85.9%'
            OR icd9code LIKE '%I86.4%'
            OR icd9code LIKE '%I98.2%'
            OR icd9code LIKE '%K70.4%'
            OR icd9code LIKE '%K71.1%'
            OR icd9code LIKE '%K72.1%'
            OR icd9code LIKE '%K72.9%'
            OR icd9code LIKE '%K76.5%'
            OR icd9code LIKE '%K76.6%'
            OR icd9code LIKE '%K76.7%'

            THEN 1 
            ELSE 0 END) AS severe_liver_disease

    FROM `physionet-data.eicu_crd_derived.icustay_detail` ie
    LEFT JOIN mer
    ON ie.patientunitstayid = mer.patientunitstayid
    LEFT JOIN `physionet-data.eicu_crd.pasthistory` past
    ON ie.patientunitstayid = past.patientunitstayid
    GROUP BY ie.patientunitstayid
)
SELECT 
    ie.patientunitstayid
    , hypertension
    , ckd
    , esrd
    , chd
    , chf
    , cld
    , diabetes_without_cc
    , diabetes_with_cc
    , severe_liver_disease 

FROM `physionet-data.eicu_crd_derived.icustay_detail` ie
LEFT JOIN com
ON ie.patientunitstayid = com.patientunitstayid
;
