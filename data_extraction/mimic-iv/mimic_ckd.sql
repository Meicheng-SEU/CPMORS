WITH diag AS
(
    SELECT 
        hadm_id
        , CASE WHEN icd_version = 9 THEN icd_code ELSE NULL END AS icd9_code
        , CASE WHEN icd_version = 10 THEN icd_code ELSE NULL END AS icd10_code
    FROM `physionet-data.mimiciv_hosp.diagnoses_icd` diag
)
, com AS
(
    SELECT
        ad.hadm_id
        -- chronic kidney disease (CKD)
        , MAX(CASE WHEN
            SUBSTR(icd9_code, 1, 4) IN ('5851', '5852', '5853', '5854')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('N181', 'N182','N183', 'N184')

            OR
            SUBSTR(icd9_code, 1, 5) IN ('40300','40310','40390','40400','40401','40410','40411','40490','40491')
            OR 
            SUBSTR(icd10_code, 1, 4) IN ('I129', 'I130')
            OR 
            SUBSTR(icd10_code, 1, 5) IN ('I1310')

            THEN 1 
            ELSE 0 END) AS ckd

        -- End stage renal disease (ESRD)
        , MAX(CASE WHEN
            SUBSTR(icd9_code, 1, 4) IN ('5855', '5856')
            OR
            SUBSTR(icd9_code, 1, 5) IN ('V4511', 'V4512', '40391', '40402', '40301','40311', '40403', '40413', '40412',
                                        '40492','40493')
            OR
            SUBSTR(icd9_code, 1, 4) IN ('V560', 'V561', 'V568')
            OR 
            SUBSTR(icd10_code, 1, 3) IN ('Z49')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('N185', 'N186')
            OR
            SUBSTR(icd10_code, 1, 4) IN ('I120', 'Z940','Z992', 'I132')
            OR 
            SUBSTR(icd10_code, 1, 5) IN ('I1311', 'Z9115', 'Z4901')
            THEN 1 
            ELSE 0 END) AS esrd

    FROM `physionet-data.mimiciv_hosp.admissions` ad
    LEFT JOIN diag
    ON ad.hadm_id = diag.hadm_id
    GROUP BY ad.hadm_id
)
SELECT 
    ad.subject_id
    , ad.hadm_id
    , ckd
    , esrd
FROM `physionet-data.mimiciv_hosp.admissions` ad
LEFT JOIN com
ON ad.hadm_id = com.hadm_id
