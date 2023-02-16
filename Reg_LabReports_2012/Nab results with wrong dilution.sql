SELECT study,
  SOP,
  condition,
  group_id,
  cohort,
  treatment,
  Subject,
  visit,
  timepoint,
  parent_aliquot_id,
  collection_date_DDMMYYYY,
  received_date_DDMMYYYY,
  plate_id,
  assay_date_DDMMYYYY,
  result_code,
  final_result,
  summary_result,
  dilution,
  collection_datetime_unf
FROM
  (WITH temp_t1 AS
  (SELECT DISTINCT STUDY.NAME study,
    SUBSTR(ALIQUOT_B.DESCRIPTION,1,7) SOP,
    ALIQUOT_A.ALIQUOT_ID parent_aliquot_id,
    SAMPLE_USER.U_DOSING_SOLUTION_GROUP group_id,
    CASE
      WHEN DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED) = 0
      THEN DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED )
        ||' '
        || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME,UNIT_A.NAME)
        ||' '
        || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD)
        ||' '
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_FREQUENCY,ALIQUOT_USER.U_FREQUENCY)
      WHEN DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED) < 1
      THEN 0
        ||''
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED )
        ||' '
        || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME,UNIT_A.NAME)
        ||' '
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD)
        ||' '
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_FREQUENCY,ALIQUOT_USER.U_FREQUENCY)
      ELSE DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED )
        ||' '
        || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME,UNIT_A.NAME)
        ||' '
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD)
        ||' '
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_FREQUENCY,ALIQUOT_USER.U_FREQUENCY)
    END cohort,
    TRIM(DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_TREATMENT,'')
    || ' '
    || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME, UNIT_A.NAME)) treatment,
    ALIQUOT_USER.U_SAMPLE_CONDITIONS condition,
    UPPER (TRIM (DECODE(study_template.name, 'Clinical Study - Visits', NVL (SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR (SAMPLE_USER.U_SITE_NUMBER)),DECODE (sample_template.sample_template_id, 226, TO_CHAR (sample_user.u_site_number), sample_user.u_reference_number) )))
    ||''
    ||UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_subno, ALIQUOT_USER.U_SUBJECT_NUMBER))) subject,
    UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_visit, ALIQUOT_USER.U_VISIT_NUMBER))) visit,
    UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_timept, ALIQUOT_USER.U_SAMPLING_TIMEPOINT))) timept,
    TRIM (REPLACE (REPLACE (TRIM (REPLACE (REPLACE (TRIM (REPLACE (REPLACE (UPPER (aliquot_user.u_sample_designation), 'PRIMARY-', NULL), 'PRIMARY', NULL)), 'DUPLICATE-', NULL), 'DUPLICATE', NULL)),'TRIPLICATE-', NULL ),'TRIPLICATE', NULL))designation,
    TO_CHAR(DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE.SAMPLED_ON, ALIQUOT_USER.U_DATE_TIME_SAMPLE_DRAWN), 'DD/MM/YYYY') collection_date_DDMMYYYY,
    DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE.SAMPLED_ON, ALIQUOT_USER.U_DATE_TIME_SAMPLE_DRAWN) collection_datetime,
    TO_CHAR(ALIQUOT_A.RECEIVED_ON,'DD/MM/YYYY') received_date_DDMMYYYY,
    RESULT_A.STATUS,
    PLATE.PLATE_ID PLATE_ID,
    TO_CHAR(RESULT_B.RAW_DATETIME_RESULT,'DD/MM/YYYY') Assay_Date_DDMMYYYY,
    UPPER (TRIM (DECODE(study_template.name,'Clinical Study - Visits', NVL (SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR (SAMPLE_USER.U_SITE_NUMBER)), DECODE (sample_template.sample_template_id, 226, TO_CHAR (sample_user.u_site_number), sample_user.u_reference_number))))site,
    UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_subno, ALIQUOT_USER.U_SUBJECT_NUMBER))) subject_number,
    LENGTH (UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_visit, ALIQUOT_USER.U_VISIT_NUMBER)))) len_visit,
    CASE
      WHEN INSTR ( ALIQUOT_B.NAME, 'Screen') > 0
      THEN 'Screen'
      WHEN INSTR (ALIQUOT_B.NAME, 'Spiked') > 0
      THEN 'Spiked'
      WHEN INSTR (ALIQUOT_B.NAME, 'Titer') > 0
      THEN 'Titer'
      ELSE ''
    END assay_name,
    CASE
      WHEN INSTR (ALIQUOT_B.NAME, 'Titer') > 0
      AND RESULT_D.NAME                    = 'Disposition'
      AND RESULT_D.FORMATTED_RESULT        = 'Reported Ab Titer'
      THEN TO_CHAR(RESULT_D.RAW_NUMERIC_RESULT)
      ELSE NULL
    END dilution,
    RESULT_CODE_PHRASE.PHRASE_INFO result_code,
    RESULT_A.FORMATTED_RESULT formatted_result,
    DECODE (INSTR (result_a.name, 'Final Dose'),0, DECODE ( INSTR (aliquot_b.name, 'Screen'), 0, DECODE (INSTR (aliquot_b.name, 'Specificity'),0, DECODE (INSTR (aliquot_b.name, 'Titer'),0, DECODE (result_a.formatted_result, 'NEGATIVE', 'Yes', 'POSITIVE', 'Yes', 'No'), DECODE (result_a.formatted_result, 'Reported Ab Titer', 'Yes', 'No')),DECODE (result_a.formatted_result, 'DRUG SPECIFIC', 'Yes', 'NOT DRUG SPECIFIC', 'Yes', 'CONFIRMED NEGATIVE', 'Yes', 'No')), DECODE (result_a.formatted_result, 'NEGATIVE', 'Yes', 'POSITIVE', 'Yes', 'No')),DECODE (NVL (RESULT_A.REPORTED, 'F'), 'T', 'Yes', 'No')) reported,
    DECODE (INSTR (UPPER (aliquot_user.u_sample_designation), 'TRIPLICATE'), 0, DECODE (INSTR (UPPER (aliquot_user.u_sample_designation), 'DUPLICATE'), 0, 1, 2), 3) score,
    '1' sort_ref ,
    TRIM ( REPLACE ( REPLACE (TRIM (REPLACE (REPLACE (TRIM (REPLACE (REPLACE (UPPER (aliquot_user.u_sample_designation), 'PRIMARY-', NULL), 'PRIMARY', NULL)), 'DUPLICATE-', NULL), 'DUPLICATE', NULL)), 'TRIPLICATE-', NULL ), 'TRIPLICATE', NULL))
    ||' '
    || DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', NVL(SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR(SAMPLE_USER.U_SITE_NUMBER)), DECODE(SAMPLE_TEMPLATE.sample_template_id, 226, TO_CHAR(sample_user.u_site_number), sample_user.u_reference_number))
    ||' '
    || DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE_USER.U_SUBNO, ALIQUOT_USER.U_SUBJECT_NUMBER)
    || '  '
    || UPPER(TRIM(DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE_USER.U_VISIT, ALIQUOT_USER.U_VISIT_NUMBER)))
    ||' '
    || UPPER(TRIM(DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE_USER.U_TIMEPT, ALIQUOT_USER.U_SAMPLING_TIMEPOINT))) new_id
  FROM LIMS_SYS.ALIQUOT ALIQUOT_A,
    LIMS_SYS.RESULT RESULT_A,
    LIMS_SYS.TEST TEST_A,
    LIMS_SYS.ALIQUOT ALIQUOT_B,
    LIMS_SYS.ALIQUOT_FORMULATION,
    LIMS_SYS.SAMPLE,
    LIMS_SYS.STUDY,
    LIMS_SYS.ALIQUOT_USER,
    LIMS_SYS.SAMPLE_USER,
    LIMS_SYS.PLATE,
    LIMS_SYS.PLATE_USER,
    LIMS_SYS.RESULT RESULT_B,
    LIMS_SYS.TEST TEST_B,
    LIMS_SYS.STUDY_USER,
    LIMS_SYS.SAMPLE_TEMPLATE,
    LIMS_SYS.RESULT RESULT_C,
    LIMS_SYS.RESULT RESULT_D,
    LIMS_SYS.RESULT RESULT_E,
    LIMS_SYS.UNIT UNIT_A,
    LIMS_SYS.UNIT UNIT_B,
    LIMS_SYS.STUDY_TEMPLATE,
    LIMS_SYS.PHRASE_ENTRY RESULT_CODE_PHRASE
  WHERE (STUDY.STUDY_ID                    IN ( 35206 ) )
  AND (study.study_template_id              = study_template.study_template_id)
  AND (STUDY_USER.STUDY_ID                  = STUDY.STUDY_ID)
  AND (STUDY.STUDY_ID                       = SAMPLE.STUDY_ID)
  AND (SAMPLE.SAMPLE_TEMPLATE_ID            = SAMPLE_TEMPLATE.SAMPLE_TEMPLATE_ID)
  AND (SAMPLE.SAMPLE_ID                     = SAMPLE_USER.SAMPLE_ID)
  AND (ALIQUOT_A.SAMPLE_ID                  = SAMPLE.SAMPLE_ID)
  AND(ALIQUOT_USER.U_DOSE_ADMINISTERED_UNIT = LIMS_SYS.UNIT_A.UNIT_ID (+))
  AND (SAMPLE_USER.U_DOSE_ADMINISTERED_UNITS=LIMS_SYS.UNIT_B.UNIT_ID (+))
  AND (ALIQUOT_USER.ALIQUOT_ID              = ALIQUOT_A.ALIQUOT_ID)
  AND ( ALIQUOT_USER.U_SAMPLE_DESIGNATION LIKE '%Ab' )
  AND (ALIQUOT_A.SAMPLE_ID   = ALIQUOT_B.SAMPLE_ID)
  AND ( ALIQUOT_B.ALIQUOT_ID = ALIQUOT_FORMULATION.CHILD_ALIQUOT_ID (+))
  AND ( ALIQUOT_A.ALIQUOT_ID = ALIQUOT_FORMULATION.PARENT_ALIQUOT_ID )
  AND (aliquot_b.aliquot_id IN
    ( SELECT DISTINCT a2.child_aliquot_id
    FROM
      (SELECT af.parent_aliquot_id,
        af.child_aliquot_id
      FROM lims_sys.aliquot_formulation af
      ) a2
      START WITH a2.parent_aliquot_id      = aliquot_a.aliquot_id
      CONNECT BY PRIOR a2.child_aliquot_id = a2.parent_aliquot_id
    ))
  AND (TEST_A.ALIQUOT_ID = ALIQUOT_B.ALIQUOT_ID)
  AND (TEST_A.TEST_ID    = RESULT_A.TEST_ID)
  AND ( (RESULT_A.NAME LIKE '%Final Dose%')
  OR (RESULT_A.NAME LIKE '%Disposition%'
  AND RESULT_C.NAME                 = 'Mean Well Value'))
  AND (RESULT_A.FORMATTED_RESULT    = 'DRUG SPECIFIC')
  AND (TEST_A.TEST_ID               = RESULT_C.TEST_ID(+))
  AND (TEST_A.TEST_ID               = RESULT_D.TEST_ID(+))
  AND ( TEST_A.TEST_ID              = RESULT_E.TEST_ID (+) )
  AND ( RESULT_E.NAME (+)           = 'Result Code' )
  AND ( RESULT_E.ORIGINAL_RESULT    = RESULT_CODE_PHRASE.PHRASE_NAME (+))
  AND (RESULT_D.NAME(+)             = 'Disposition'
  AND RESULT_D.FORMATTED_RESULT (+) = 'Reported Ab Titer')
  AND (ALIQUOT_B.PLATE_ID           = PLATE.PLATE_ID)
  AND (PLATE.PLATE_ID               = PLATE_USER.PLATE_ID)
  AND (PLATE.CONCLUSION             = 'P')
  AND (PLATE.PLATE_ID               = TEST_B.PLATE_ID)
  AND (RESULT_B.TEST_ID             = TEST_B.TEST_ID)
  AND (RESULT_B.NAME                = 'Assay Date')
  AND ( RESULT_A.FORMATTED_RESULT  IN ('NEGATIVE','POSITIVE','NOT DRUG SPECIFIC','DRUG SPECIFIC','CONFIRMED NEGATIVE','Reported Ab Titer'))
  AND 1                             =1
  AND (1                            =1
  AND (upper(NVL(PLATE_USER.U_PLATE_TYPE,'Regular%')) LIKE 'REGULAR%') )
  AND 1                          =1
  AND 1                          =1
  AND 1                          =1
  AND ( RESULT_E.ORIGINAL_RESULT = RESULT_CODE_PHRASE.PHRASE_NAME (+))
  AND (ALIQUOT_A.STATUS NOT     IN ('U', 'S', 'X'))
  AND (ALIQUOT_B.STATUS NOT     IN ('U', 'S', 'X'))
  ),
  temp_t2 AS
  ( SELECT DISTINCT STUDY.NAME study,
    ALIQUOT_B.DESCRIPTION SOP,
    ALIQUOT_A.ALIQUOT_ID parent_aliquot_id,
    CASE
      WHEN DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED) = 0
      THEN DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits', SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED )
        ||' '
        || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME,UNIT_A.NAME)
        ||' '
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD)
        ||' '
        || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_FREQUENCY,ALIQUOT_USER.U_FREQUENCY)
      WHEN DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED) < 1
      THEN 0
        ||''
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits', SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED )
        ||' '
        || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME,UNIT_A.NAME)
        ||' '
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD)
        ||' '
        || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_FREQUENCY,ALIQUOT_USER.U_FREQUENCY)
      ELSE DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED )
        ||' '
        || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME,UNIT_A.NAME)
        ||' '
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD)
        ||' '
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_FREQUENCY,ALIQUOT_USER.U_FREQUENCY)
    END cohort,
    TRIM(DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_TREATMENT,'')
    || ' '
    || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME, UNIT_A.NAME)) treatment,
    ALIQUOT_USER.U_SAMPLE_CONDITIONS condition,
    UPPER (TRIM (DECODE(study_template.name, 'Clinical Study - Visits', NVL (SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR (SAMPLE_USER.U_SITE_NUMBER)), DECODE (sample_template.sample_template_id, 226, TO_CHAR (sample_user.u_site_number), sample_user.u_reference_number) )))
    ||''
    ||UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_subno, ALIQUOT_USER.U_SUBJECT_NUMBER))) subject,
    LIMS_SYS.SAMPLE_USER.U_PHASE phase,
    DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE_USER.U_VISIT, ALIQUOT_USER.U_VISIT_NUMBER) visit,
    DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE_USER.U_TIMEPT, ALIQUOT_USER.U_SAMPLING_TIMEPOINT) timept,
    DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', ALIQUOT_USER.U_ALTID, ALIQUOT_A.EXTERNAL_REFERENCE) ALT_ID,
    TO_CHAR(DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE.SAMPLED_ON, ALIQUOT_USER.U_DATE_TIME_SAMPLE_DRAWN), 'DD/MM/YYYY') collection_date_DDMMYYYY,
    DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE.SAMPLED_ON, ALIQUOT_USER.U_DATE_TIME_SAMPLE_DRAWN) collection_datetime,
    TO_CHAR(ALIQUOT_A.RECEIVED_ON,'DD/MM/YYYY') received_date_DDMMYYYY,
    PLATE.PLATE_ID PLATE_ID,
    TO_CHAR(RESULT_B.RAW_DATETIME_RESULT,'DD/MM/YYYY') Assay_Date_DDMMYYYY,
    RESULT_A.FORMATTED_RESULT Nab,
    RESULT_D.FORMATTED_RESULT Pct_AR,
    RESULT_C.FORMATTED_RESULT Reported_Cutpoin,
    ALIQUOT_B_USER.U_RESULTS_REVIEW result_status,
    TRIM ( REPLACE ( REPLACE (TRIM (REPLACE (REPLACE (TRIM (REPLACE (REPLACE (UPPER (aliquot_user.u_sample_designation), 'PRIMARY-', NULL), 'PRIMARY', NULL)), 'DUPLICATE-', NULL), 'DUPLICATE', NULL)), 'TRIPLICATE-', NULL ), 'TRIPLICATE', NULL))
    ||' '
    ||DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', NVL(SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR(SAMPLE_USER.U_SITE_NUMBER)), DECODE(SAMPLE_TEMPLATE.sample_template_id, 226, TO_CHAR(sample_user.u_site_number), sample_user.u_reference_number))
    ||' '
    || DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE_USER.U_SUBNO, ALIQUOT_USER.U_SUBJECT_NUMBER)
    || '  '
    || UPPER(TRIM(DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE_USER.U_VISIT, ALIQUOT_USER.U_VISIT_NUMBER)))
    ||' '
    || UPPER(TRIM(DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE_USER.U_TIMEPT, ALIQUOT_USER.U_SAMPLING_TIMEPOINT))) new_id
  FROM LIMS_SYS.ALIQUOT ALIQUOT_A,
    LIMS_SYS.ALIQUOT_FORMULATION,
    LIMS_SYS.ALIQUOT ALIQUOT_B,
    LIMS_SYS.RESULT RESULT_A,
    LIMS_SYS.RESULT RESULT_B,
    LIMS_SYS.RESULT RESULT_C,
    LIMS_SYS.RESULT RESULT_D,
    LIMS_SYS.TEST TEST_A,
    LIMS_SYS.ALIQUOT_USER,
    LIMS_SYS.SAMPLE,
    LIMS_SYS.STUDY,
    LIMS_SYS.ALIQUOT_TEMPLATE,
    LIMS_SYS.SAMPLE_USER,
    LIMS_SYS.STUDY_USER,
    LIMS_SYS.SAMPLE_TEMPLATE,
    LIMS_SYS.PLATE,
    LIMS_SYS.TEST TEST_B,
    LIMS_SYS.TEST TEST_C,
    LIMS_SYS.UNIT UNIT_A,
    LIMS_SYS.UNIT UNIT_B,
    LIMS_SYS.STUDY_TEMPLATE,
    LIMS_SYS.ALIQUOT_USER ALIQUOT_B_USER
  WHERE (ALIQUOT_B.PLATE_ID                  = PLATE.PLATE_ID (+))
  AND ( TEST_B.PLATE_ID (+)                  = PLATE.PLATE_ID)
  AND ( TEST_C.PLATE_ID (+)                  = PLATE.PLATE_ID)
  AND (TEST_B.TEST_ID                        = RESULT_B.TEST_ID(+))
  AND (TEST_C.TEST_ID                        = RESULT_C.TEST_ID(+))
  AND (ALIQUOT_USER.U_DOSE_ADMINISTERED_UNIT =UNIT_A.UNIT_ID (+))
  AND (SAMPLE_USER.U_DOSE_ADMINISTERED_UNITS =UNIT_B.UNIT_ID (+))
  AND ( ALIQUOT_A.ALIQUOT_ID                 = ALIQUOT_FORMULATION.PARENT_ALIQUOT_ID )
  AND ( ALIQUOT_FORMULATION.CHILD_ALIQUOT_ID = ALIQUOT_B.ALIQUOT_ID )
  AND ( ALIQUOT_B.ALIQUOT_ID                 = TEST_A.ALIQUOT_ID )
  AND ( TEST_A.TEST_ID                       = RESULT_A.TEST_ID )
  AND ( ALIQUOT_A.ALIQUOT_ID                 = ALIQUOT_USER.ALIQUOT_ID )
  AND ( ALIQUOT_B.ALIQUOT_ID                 = ALIQUOT_B_USER.ALIQUOT_ID )
  AND ( STUDY.STUDY_ID                       = SAMPLE.STUDY_ID )
  AND 1                                      =1
  AND ( ALIQUOT_USER.U_SAMPLE_DESIGNATION LIKE '%Ab')
  AND ( SAMPLE.SAMPLE_ID              = ALIQUOT_A.SAMPLE_ID )
  AND ( ALIQUOT_A.ALIQUOT_TEMPLATE_ID = ALIQUOT_TEMPLATE.ALIQUOT_TEMPLATE_ID )
  AND ( SAMPLE.SAMPLE_ID              = SAMPLE_USER.SAMPLE_ID )
  AND ( STUDY.STUDY_ID                = STUDY_USER.STUDY_ID )
  AND ( SAMPLE.SAMPLE_TEMPLATE_ID     = SAMPLE_TEMPLATE.SAMPLE_TEMPLATE_ID )
  AND ( STUDY.STUDY_TEMPLATE_ID       = STUDY_TEMPLATE.STUDY_TEMPLATE_ID)
  AND ( TEST_A.TEST_ID                = RESULT_D.TEST_ID )
  AND (STUDY.STUDY_ID                IN ( 35206 ) )
  AND (RESULT_A.NAME                  = 'Disposition' )
  AND (RESULT_B.NAME                  = 'Assay Date')
  AND (RESULT_C.NAME LIKE '%Reported Cutpoint%')
  AND (RESULT_D.NAME                                = '%AR')
  AND (RESULT_A.FORMATTED_RESULT                   IN ('NEGATIVE','POSITIVE'))
  AND (1                                            =1
  AND (upper(NVL(ALIQUOT_B.DESCRIPTION,'PCL2192')) IN ( 'PCL2192') ) )
  AND 1                                             =1
  AND 1                                             =1
  AND 1                                             =1
  AND 1                                             =1
  AND (ALIQUOT_B_USER.U_GROUP                       = 'Neutralizing Sample' )
  ORDER BY study ,
    SOP,
    cohort,
    subject,
    visit,
    timept
  )
SELECT study,
  DECODE (NAb_sop, '', missing_sop, NAb_sop) SOP,
  condition,
  group_id,
  cohort,
  treatment,
  subject,
  visit,
  timepoint,
  parent_aliquot_id,
  collection_date_DDMMYYYY,
  received_date_DDMMYYYY,
  DECODE(plate_id, '','---', plate_id) plate_id,
  DECODE(Assay_Date_DDMMYYYY, '','---',Assay_Date_DDMMYYYY) Assay_Date_DDMMYYYY,
  result_code,
  DECODE(Nab,'NEGATIVE','Negative','POSITIVE','Positive', '---') Final_Result,
  DECODE(Nab,'NEGATIVE','Negative','POSITIVE','Positive', '---') Summary_Result,
  MAX(dilution) OVER (PARTITION BY study, SOP, condition, cohort, subject, visit, timepoint) dilution,
  collection_datetime collection_datetime_unf
FROM
  (SELECT a.study,
    a.SOP,
    b.SOP NAb_sop,
    a.condition,
    a.group_id,
    TRIM(a.cohort) cohort,
    a.treatment,
    a.subject,
    a.visit,
    a.timept AS timepoint,
    a.designation,
    a.parent_aliquot_id,
    a.collection_date_DDMMYYYY,
    a.collection_datetime,
    a.received_date_DDMMYYYY,
    a.result_code,
    a.formatted_result AS confirmation,
    a.dilution,
    b.Assay_Date_DDMMYYYY,
    b.plate_id,
    b.Nab,
    ( SELECT DISTINCT SOP FROM temp_t2 WHERE SOP IS NOT NULL
    ) AS missing_sop
  FROM temp_t1 a,
    temp_t2 b
  WHERE a.new_id = b.new_id (+)
  )
  )

UNION

SELECT DISTINCT study,
  SOP,
  condition,
  group_id,
  cohort,
  treatment,
  Subject,
  visit,
  timepoint,
  parent_aliquot_id,
  '' collection_date_DDMMYYYY,
  '' received_date_DDMMYYYY,
  plate_id,
  '' assay_date_DDMMYYYY,
  '' result_code,
  Final_Concentration_ngml final_result,
  formatted_result summary_result,
  dilution,
  collection_datetime_unf
FROM
  (WITH temp_t1 AS
  (SELECT DISTINCT ALIQUOT_A.ALIQUOT_ID parent_aliquot_id
  FROM LIMS_SYS.ALIQUOT ALIQUOT_A,
    LIMS_SYS.RESULT RESULT_A,
    LIMS_SYS.TEST TEST_A,
    LIMS_SYS.ALIQUOT ALIQUOT_B,
    LIMS_SYS.ALIQUOT_FORMULATION,
    LIMS_SYS.SAMPLE,
    LIMS_SYS.STUDY,
    LIMS_SYS.ALIQUOT_USER,
    LIMS_SYS.SAMPLE_USER,
    LIMS_SYS.PLATE,
    LIMS_SYS.PLATE_USER,
    LIMS_SYS.RESULT RESULT_B,
    LIMS_SYS.TEST TEST_B,
    LIMS_SYS.STUDY_USER,
    LIMS_SYS.SAMPLE_TEMPLATE,
    LIMS_SYS.RESULT RESULT_C,
    LIMS_SYS.RESULT RESULT_D,
    LIMS_SYS.RESULT RESULT_E,
    LIMS_SYS.UNIT UNIT_A,
    LIMS_SYS.UNIT UNIT_B,
    LIMS_SYS.STUDY_TEMPLATE,
    LIMS_SYS.PHRASE_ENTRY RESULT_CODE_PHRASE
  WHERE (STUDY.STUDY_ID                    IN ( 35206 ) )
  AND (study.study_template_id              = study_template.study_template_id)
  AND (STUDY_USER.STUDY_ID                  = STUDY.STUDY_ID)
  AND (STUDY.STUDY_ID                       = SAMPLE.STUDY_ID)
  AND (SAMPLE.SAMPLE_TEMPLATE_ID            = SAMPLE_TEMPLATE.SAMPLE_TEMPLATE_ID)
  AND (SAMPLE.SAMPLE_ID                     = SAMPLE_USER.SAMPLE_ID)
  AND (ALIQUOT_A.SAMPLE_ID                  = SAMPLE.SAMPLE_ID)
  AND(ALIQUOT_USER.U_DOSE_ADMINISTERED_UNIT = LIMS_SYS.UNIT_A.UNIT_ID (+))
  AND (SAMPLE_USER.U_DOSE_ADMINISTERED_UNITS=LIMS_SYS.UNIT_B.UNIT_ID (+))
  AND (ALIQUOT_USER.ALIQUOT_ID              = ALIQUOT_A.ALIQUOT_ID)
  AND ( ALIQUOT_USER.U_SAMPLE_DESIGNATION LIKE '%Ab' )
  AND (ALIQUOT_A.SAMPLE_ID   = ALIQUOT_B.SAMPLE_ID)
  AND ( ALIQUOT_B.ALIQUOT_ID = ALIQUOT_FORMULATION.CHILD_ALIQUOT_ID (+))
  AND ( ALIQUOT_A.ALIQUOT_ID = ALIQUOT_FORMULATION.PARENT_ALIQUOT_ID )
  AND (aliquot_b.aliquot_id IN
    ( SELECT DISTINCT a2.child_aliquot_id
    FROM
      (SELECT af.parent_aliquot_id,
        af.child_aliquot_id
      FROM lims_sys.aliquot_formulation af
      ) a2
      START WITH a2.parent_aliquot_id      = aliquot_a.aliquot_id
      CONNECT BY PRIOR a2.child_aliquot_id = a2.parent_aliquot_id
    ))
  AND (TEST_A.ALIQUOT_ID = ALIQUOT_B.ALIQUOT_ID)
  AND (TEST_A.TEST_ID    = RESULT_A.TEST_ID)
  AND ( (RESULT_A.NAME LIKE '%Final Dose%')
  OR (RESULT_A.NAME LIKE '%Disposition%'
  AND RESULT_C.NAME              = 'Mean Well Value'))
  AND (RESULT_A.FORMATTED_RESULT = 'DRUG SPECIFIC')
  AND (TEST_A.TEST_ID            = RESULT_C.TEST_ID(+))
  AND (TEST_A.TEST_ID            = RESULT_D.TEST_ID(+))
  AND ( TEST_A.TEST_ID           = RESULT_E.TEST_ID (+) )
  AND ( RESULT_E.NAME (+)        = 'Result Code' )
  AND ( RESULT_E.ORIGINAL_RESULT = RESULT_CODE_PHRASE.PHRASE_NAME (+))
  AND (RESULT_D.NAME(+) LIKE '%Dilution%')
  AND (ALIQUOT_B.PLATE_ID                           = PLATE.PLATE_ID)
  AND (PLATE.PLATE_ID                               = PLATE_USER.PLATE_ID)
  AND (PLATE.CONCLUSION                             = 'P')
  AND (PLATE.PLATE_ID                               = TEST_B.PLATE_ID)
  AND (RESULT_B.TEST_ID                             = TEST_B.TEST_ID)
  AND (RESULT_B.NAME                                = 'Assay Date')
  AND ( RESULT_A.FORMATTED_RESULT                  IN ('NEGATIVE','POSITIVE','NOT DRUG SPECIFIC','DRUG SPECIFIC','CONFIRMED NEGATIVE','Reported Ab Titer'))
  AND (1                                            =1
  AND (upper(NVL(ALIQUOT_B.DESCRIPTION,'PCL2192')) IN ( 'PCL2192') ) )
  AND 1                                             =1
  AND 1                                             =1
  AND 1                                             =1
  AND 1                                             =1
  AND ( RESULT_E.ORIGINAL_RESULT                    = RESULT_CODE_PHRASE.PHRASE_NAME (+))
  AND (ALIQUOT_A.STATUS NOT                        IN ('U', 'S', 'X'))
  AND (ALIQUOT_B.STATUS NOT                        IN ('U', 'S', 'X'))
  ),
  tempPK_sql AS
  (SELECT DISTINCT STUDY.NAME study,
    ALIQUOT_B.DESCRIPTION description,
    UPPER (TRIM (DECODE(study_template.name, 'Clinical Study - Visits', NVL (SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR (SAMPLE_USER.U_SITE_NUMBER)), DECODE (sample_template.sample_template_id, 226, TO_CHAR (sample_user.u_site_number), sample_user.u_reference_number) )))
    ||''
    ||UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_subno, ALIQUOT_USER.U_SUBJECT_NUMBER))) site_subject,
    TRIM(DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_TREATMENT,'')
    || ' '
    || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME, UNIT_A.NAME)) treatment,
    DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD) admin_method,
    CASE
      WHEN DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED) = 0
      THEN DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED )
        ||' '
        || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME,UNIT_A.NAME)
        ||' '
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD)
      WHEN DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED) < 1
      THEN 0
        ||''
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED )
        ||' '
        || DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits',UNIT_B.NAME,UNIT_A.NAME)
        ||' '
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD)
      ELSE DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED )
        ||' '
        || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME,UNIT_A.NAME)
        ||' '
        ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD)
    END cohort,
    ALIQUOT_USER.U_RANDOMIZED_NUMBER u_randomized_number,
    UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_visit, ALIQUOT_USER.U_VISIT_NUMBER))) visit,
    UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_timept, ALIQUOT_USER.U_SAMPLING_TIMEPOINT))) timept,
    TRIM ( REPLACE ( REPLACE (TRIM (REPLACE (REPLACE (TRIM (REPLACE (REPLACE (UPPER (aliquot_user.u_sample_designation), 'PRIMARY-', NULL), 'PRIMARY', NULL)), 'DUPLICATE-', NULL), 'DUPLICATE', NULL)), 'TRIPLICATE-', NULL ), 'TRIPLICATE', NULL)) designation,
    SAMPLE_USER.U_PHASE phase,
    ALIQUOT_A.ALIQUOT_ID,
    ALIQUOT_A.EXTERNAL_REFERENCE,
    TO_CHAR(DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE.SAMPLED_ON, ALIQUOT_USER.U_DATE_TIME_SAMPLE_DRAWN),'DD/MM/YYYY') collection_date_DDMMYYYY,
    DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE.SAMPLED_ON, ALIQUOT_USER.U_DATE_TIME_SAMPLE_DRAWN) collection_datetime_unf,
    TO_CHAR(ALIQUOT_A.RECEIVED_ON,'DD/MM/YYYY') Received_Date_DDMMYYYY,
    ALIQUOT_A.RECEIVED_ON received_date,
    TO_CHAR(RESULT_B.RAW_DATETIME_RESULT,'DD/MM/YYYY') assay_date_DDMMYYYY,
    RESULT_B.RAW_DATETIME_RESULT assay_datetime,
    RESULT_A.STATUS,
    RESULT_A.FORMATTED_RESULT formatted_result,
    RESULT_A.RAW_NUMERIC_RESULT numeric_result,
    aliquot_b.name aliquot_name,
    aliquot_a.aliquot_id parent_aliquot_id,
    aliquot_user.u_sample_conditions condition,
    sample_user.U_DOSING_SOLUTION_GROUP group_id,
    aliquot_b.sample_id sample_id,
    PLATE.PLATE_ID plate_id,
    PLATE_USER.U_PLATE_TYPE plate_type,
    STUDY_USER.U_CLINICAL_STUDY_TYPE u_clinical_study_type,
    ALIQUOT_USER.U_CLINICAL_SAMPLE_TYPES,
    SAMPLE_TEMPLATE.SAMPLE_TEMPLATE_ID,
    study_template.name study_tempname,
    UPPER (TRIM (DECODE(study_template.name, 'Clinical Study - Visits', NVL (SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR (SAMPLE_USER.U_SITE_NUMBER)), DECODE (sample_template.sample_template_id, 226, TO_CHAR (sample_user.u_site_number), sample_user.u_reference_number) ))) site,
    UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_subno, ALIQUOT_USER.U_SUBJECT_NUMBER))) subject_number,
    LENGTH (UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', SAMPLE_USER.U_VISIT, ALIQUOT_USER.U_VISIT_NUMBER)))) len_visit,
    DECODE (INSTR (result_a.name, 'Final Dose'),0, DECODE ( INSTR (aliquot_b.name, 'Screen'), 0, DECODE ( INSTR (aliquot_b.name, 'Specificity'), 0, DECODE (INSTR (aliquot_b.name, 'Titer'), 0, DECODE (result_a.formatted_result, 'NEGATIVE', 'Yes', 'POSITIVE', 'Yes', 'No'), DECODE (result_a.formatted_result, 'Reported Ab Titer', 'Yes', 'No') ), DECODE (result_a.formatted_result, 'DRUG SPECIFIC', 'Yes', 'NOT DRUG SPECIFIC', 'Yes', 'CONFIRMED NEGATIVE', 'Yes', 'No')), DECODE (result_a.formatted_result, 'NEGATIVE', 'Yes', 'POSITIVE', 'Yes', 'No')), DECODE (NVL (RESULT_A.REPORTED, 'F'), 'T', 'Yes', 'No')) reported,
    NULL dilution,
    DECODE (INSTR (UPPER (aliquot_user.u_sample_designation), 'TRIPLICATE'), 0, DECODE (INSTR (UPPER (aliquot_user.u_sample_designation), 'DUPLICATE'), 0, 1, 2), 3) score,
    '1' sort_ref ,
    ALIQUOT_B.DESCRIPTION
    || ' @ '
    || DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', NVL(SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR(SAMPLE_USER.U_SITE_NUMBER)), DECODE(SAMPLE_TEMPLATE.sample_template_id, 226, TO_CHAR(sample_user.u_site_number), sample_user.u_reference_number))
    ||''
    || DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE_USER.U_SUBNO, ALIQUOT_USER.U_SUBJECT_NUMBER)
    || ' @ '
    || UPPER(TRIM(DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE_USER.U_VISIT, ALIQUOT_USER.U_VISIT_NUMBER)))
    ||' '
    || UPPER(TRIM(DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE_USER.U_TIMEPT, ALIQUOT_USER.U_SAMPLING_TIMEPOINT))) new_id
  FROM LIMS_SYS.ALIQUOT ALIQUOT_A,
    LIMS_SYS.RESULT RESULT_A,
    LIMS_SYS.TEST TEST_A,
    LIMS_SYS.ALIQUOT ALIQUOT_B,
    LIMS_SYS.ALIQUOT_FORMULATION,
    LIMS_SYS.SAMPLE,
    LIMS_SYS.STUDY,
    LIMS_SYS.ALIQUOT_USER,
    LIMS_SYS.ALIQUOT_USER ALIQUOT_B_USER,
    LIMS_SYS.SAMPLE_USER,
    LIMS_SYS.PLATE,
    LIMS_SYS.PLATE_USER,
    LIMS_SYS.RESULT RESULT_B,
    LIMS_SYS.TEST TEST_B,
    LIMS_SYS.STUDY_USER,
    LIMS_SYS.SAMPLE_TEMPLATE,
    LIMS_SYS.RESULT RESULT_C,
    LIMS_SYS.UNIT UNIT_A,
    LIMS_SYS.UNIT UNIT_B,
    LIMS_SYS.STUDY_TEMPLATE
  WHERE (STUDY.STUDY_ID         IN ( 35206 ) )
  AND (STUDY.GROUP_ID            = 13)
  AND (study.study_template_id   = study_template.study_template_id)
  AND (STUDY_USER.STUDY_ID       = STUDY.STUDY_ID)
  AND (STUDY.STUDY_ID            = SAMPLE.STUDY_ID)
  AND (SAMPLE.SAMPLE_TEMPLATE_ID = SAMPLE_TEMPLATE.SAMPLE_TEMPLATE_ID)
  AND (SAMPLE.SAMPLE_ID          = SAMPLE_USER.SAMPLE_ID)
  AND (ALIQUOT_A.SAMPLE_ID       = SAMPLE.SAMPLE_ID)
  AND (ALIQUOT_USER.ALIQUOT_ID   = ALIQUOT_A.ALIQUOT_ID)
  AND ALIQUOT_A.ALIQUOT_ID      IN
    (SELECT PARENT_ALIQUOT_ID
    FROM temp_t1
    )
  AND ( ALIQUOT_B.ALIQUOT_ID                 = ALIQUOT_B_USER.ALIQUOT_ID )
  AND (ALIQUOT_USER.U_DOSE_ADMINISTERED_UNIT = LIMS_SYS.UNIT_A.UNIT_ID (+))
  AND (SAMPLE_USER.U_DOSE_ADMINISTERED_UNITS =LIMS_SYS.UNIT_B.UNIT_ID (+))
  AND (1                                     =1
  AND (upper(NVL(ALIQUOT_USER.U_SAMPLE_DESIGNATION,'%PK%')) LIKE '%PK%') )
  AND (1=1
  AND (upper(NVL(ALIQUOT_USER.U_SAMPLE_DESIGNATION,'%PK%')) LIKE '%PK%') )
  AND (1                                             =1
  AND (upper(NVL(ALIQUOT_B.DESCRIPTION,'PCL2023'))  IN ( 'PCL2023') ) )
  AND ( ALIQUOT_B.ALIQUOT_ID                         = ALIQUOT_FORMULATION.CHILD_ALIQUOT_ID (+))
  AND ( ALIQUOT_A.ALIQUOT_ID                         = ALIQUOT_FORMULATION.PARENT_ALIQUOT_ID )
  AND (INSTR (ALIQUOT_B.DESCRIPTION, 'Specificity')  = 0)
  AND (INSTR (ALIQUOT_B.DESCRIPTION, 'Confirmation') = 0)
  AND (INSTR (ALIQUOT_B.DESCRIPTION, 'Titer')        = 0)
  AND (aliquot_b.aliquot_id                         IN
    ( SELECT DISTINCT a2.child_aliquot_id
    FROM
      (SELECT af.parent_aliquot_id,
        af.child_aliquot_id
      FROM lims_sys.aliquot_formulation af
      ) a2
      START WITH a2.parent_aliquot_id      = aliquot_a.aliquot_id
      CONNECT BY PRIOR a2.child_aliquot_id = a2.parent_aliquot_id
    ))
  AND (TEST_A.ALIQUOT_ID = ALIQUOT_B.ALIQUOT_ID)
  AND (TEST_A.TEST_ID    = RESULT_A.TEST_ID)
  AND (RESULT_A.NAME LIKE '%Final Dose%')
  AND (TEST_A.TEST_ID     = RESULT_C.TEST_ID(+))
  AND (PLATE.CONCLUSION   = 'P')
  AND (ALIQUOT_B.PLATE_ID = PLATE.PLATE_ID)
  AND (PLATE.PLATE_ID     = PLATE_USER.PLATE_ID)
  AND (PLATE.PLATE_ID     = TEST_B.PLATE_ID)
  AND (RESULT_B.TEST_ID   = TEST_B.TEST_ID)
  AND (UPPER(ALIQUOT_USER.U_SAMPLE_CONDITIONS) NOT LIKE 'QUARANTINE%')
  AND (RESULT_B.NAME                            = 'Assay Date')
  AND (ALIQUOT_A.STATUS NOT                    IN ('U', 'S', 'X'))
  AND (ALIQUOT_B.STATUS NOT                    IN ('U', 'S', 'X'))
  AND NVL(ALIQUOT_B_USER.U_TEST_CHOICE,-1) NOT IN ('LTS','ISR')
  ORDER BY STUDY.NAME ASC,
    description ASC,
    site ASC,
    subject_number ASC,
    ALIQUOT_USER.U_RANDOMIZED_NUMBER ASC,
    len_visit ASC,
    visit ASC,
    timept ASC,
    designation ASC,
    Received_Date_DDMMYYYY,
    Received_date,
    reported DESC,
    score ASC,
    status ASC,
    ALIQUOT_A.ALIQUOT_ID
  )
SELECT collection_datetime_unf,
  study,
  description AS SOP,
  site
  ||''
  ||subject_number AS Subject,
  treatment,
  admin_method,
  cohort,
  visit,
  timept AS timepoint,
  visit
  ||' '
  ||timept AS visit_timepoint,
  Collection_Date_DDMMYYYY,
  Received_Date_DDMMYYYY,
  Received_date,
  assay_date_DDMMYYYY,
  assay_datetime,
  parent_aliquot_id,
  condition,
  group_id,
  sample_id,
  plate_id,
  plate_type,
  'NR' AS Final_Concentration_ngml,
  formatted_result,
  NULL dilution,
  designation,
  phase
FROM
  (SELECT tempPK_tbl.*,
    NVL (LAG (description
    || '@'
    || designation
    || '@'
    || site
    || '@'
    || subject_number
    || '@'
    || visit
    || '@'
    || timept, 1) OVER (ORDER BY ROWNUM), '-1') slip,
    0 T_GROUP_ID
  FROM
    ( SELECT DISTINCT STUDY.NAME study,
      phrase_entry.phrase_name description,
      UPPER ( TRIM ( DECODE (study_template.name, 'Clinical Study - Visits', NVL (SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR (SAMPLE_USER.U_SITE_NUMBER)), DECODE (sample_template.sample_template_id, 226, TO_CHAR (sample_user.u_site_number), sample_user.u_reference_number) )))
      ||'-'
      ||UPPER (TRIM (DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_subno, ALIQUOT_USER.U_SUBJECT_NUMBER))) site_subject,
      TRIM(DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_TREATMENT,'')
      || ' '
      || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME, UNIT_A.NAME)) treatment,
      DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD) admin_method,
      CASE
        WHEN DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED, ALIQUOT_USER.U_DOSE_ADMINISTERED) = 0
        THEN DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED )
          ||' '
          || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME,UNIT_A.NAME)
          ||' '
          ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD)
        WHEN DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED) < 1
        THEN 0
          ||''
          ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED )
          ||' '
          || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME,UNIT_A.NAME)
          ||' '
          ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD)
        ELSE DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_DOSE_ADMINISTERED,ALIQUOT_USER.U_DOSE_ADMINISTERED )
          ||' '
          || DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',UNIT_B.NAME,UNIT_A.NAME)
          ||' '
          ||DECODE(STUDY_TEMPLATE.NAME,'Clinical Study - Visits',SAMPLE_USER.U_ADMINISTRATION_METHOD,ALIQUOT_USER.U_SA_ADMINISTRATION_METHOD)
      END cohort,
      ALIQUOT_USER.U_RANDOMIZED_NUMBER,
      UPPER (TRIM (DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_visit, ALIQUOT_USER.U_VISIT_NUMBER))) visit,
      UPPER (TRIM (DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_timept, ALIQUOT_USER.U_SAMPLING_TIMEPOINT))) timept,
      TRIM ( REPLACE ( REPLACE ( TRIM (REPLACE (REPLACE (TRIM (REPLACE (REPLACE (UPPER (aliquot_user.u_sample_designation), 'PRIMARY-', NULL), 'PRIMARY', NULL)), 'DUPLICATE-', NULL), 'DUPLICATE', NULL)), 'TRIPLICATE-',NULL), 'TRIPLICATE',NULL)) designation,
      SAMPLE_USER.U_PHASE phase,
      ALIQUOT_A.ALIQUOT_ID,
      ALIQUOT_A.EXTERNAL_REFERENCE,
      TO_CHAR(DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE.SAMPLED_ON, ALIQUOT_USER.U_DATE_TIME_SAMPLE_DRAWN), 'DD/MM/YYYY') collection_date_DDMMYYYY,
      DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE.SAMPLED_ON, ALIQUOT_USER.U_DATE_TIME_SAMPLE_DRAWN) collection_datetime_unf,
      TO_CHAR(ALIQUOT_A.RECEIVED_ON,'DD/MM/YYYY') Received_Date_DDMMYYYY,
      ALIQUOT_A.RECEIVED_ON Received_Date,
      NULL assay_date_DDMMYYYY,
      NULL assay_datetime,
      'V' status,
      NULL formatted_result,
      NULL dilution,
      NULL numeric_result,
      NULL aliquot_name,
      ALIQUOT_A.ALIQUOT_ID parent_aliquot_id,
      ALIQUOT_USER.U_SAMPLE_CONDITIONS condition,
      NULL group_id,
      NULL sample_id,
      NULL plate_id,
      NULL plate_type,
      STUDY_USER.U_CLINICAL_STUDY_TYPE,
      ALIQUOT_USER.U_CLINICAL_SAMPLE_TYPES,
      SAMPLE_TEMPLATE.SAMPLE_TEMPLATE_ID,
      study_template.name Study_tempname,
      UPPER ( TRIM ( DECODE (study_template.name, 'Clinical Study - Visits', NVL (SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR (SAMPLE_USER.U_SITE_NUMBER)), DECODE (sample_template.sample_template_id, 226, TO_CHAR (sample_user.u_site_number), sample_user.u_reference_number) ))) site,
      UPPER (TRIM (DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_subno, ALIQUOT_USER.U_SUBJECT_NUMBER))) subject_number,
      LENGTH (UPPER (TRIM (DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_visit, ALIQUOT_USER.U_VISIT_NUMBER)))) len_visit,
      'No' reported,
      DECODE (INSTR (UPPER (aliquot_user.u_sample_designation), 'TRIPLICATE'), 0, DECODE (INSTR (UPPER (aliquot_user.u_sample_designation), 'DUPLICATE'), 0, 1, 2), 3) score,
      '0' sort_ref
    FROM LIMS_SYS.STUDY,
      LIMS_SYS.STUDY_USER,
      LIMS_SYS.SAMPLE,
      LIMS_SYS.SAMPLE_USER,
      LIMS_SYS.ALIQUOT ALIQUOT_A,
      LIMS_SYS.ALIQUOT_USER,
      LIMS_SYS.UNIT UNIT_A,
      LIMS_SYS.UNIT UNIT_B,
      LIMS_SYS.SAMPLE_TEMPLATE,
      LIMS_SYS.STUDY_TEMPLATE,
      LIMS_SYS.PHRASE_HEADER,
      LIMS_SYS.PHRASE_ENTRY
    WHERE (STUDY.STUDY_ID         IN ( 35206 ) )
    AND (STUDY.GROUP_ID            = 13)
    AND (study.study_template_id   = study_template.study_template_id)
    AND (STUDY.STUDY_ID            = STUDY_USER.STUDY_ID)
    AND (STUDY.STUDY_ID            = SAMPLE.STUDY_ID)
    AND (SAMPLE.SAMPLE_ID          = SAMPLE_USER.SAMPLE_ID)
    AND (SAMPLE.SAMPLE_TEMPLATE_ID = SAMPLE_TEMPLATE.SAMPLE_TEMPLATE_ID)
    AND (ALIQUOT_A.SAMPLE_ID       = SAMPLE.SAMPLE_ID)
    AND (ALIQUOT_A.ALIQUOT_ID      = ALIQUOT_USER.ALIQUOT_ID)
    AND ALIQUOT_A.ALIQUOT_ID      IN
      (SELECT PARENT_ALIQUOT_ID
      FROM temp_t1
      )
    AND (ALIQUOT_USER.U_DOSE_ADMINISTERED_UNIT = LIMS_SYS.UNIT_A.UNIT_ID (+))
    AND (SAMPLE_USER.U_DOSE_ADMINISTERED_UNITS =LIMS_SYS.UNIT_B.UNIT_ID (+))
    AND (1                                     =1
    AND (upper(NVL(ALIQUOT_USER.U_SAMPLE_DESIGNATION,'%PK%')) LIKE '%PK%') )
    AND (1                                                   =1
    AND (upper(NVL(phrase_entry.phrase_name,'PCL2023'))     IN ( 'PCL2023') ) )
    AND (NVL (ALIQUOT_A.PLATE_ID,                            -1) = -1)
    AND (ALIQUOT_A.STATUS NOT                               IN ('U', 'S', 'X'))
    AND (UPPER(ALIQUOT_USER.U_SAMPLE_CONDITIONS) NOT LIKE 'QUARANTINE%')
    AND (phrase_header.name                               = 'SOP')
    AND (phrase_entry.phrase_id                           = phrase_header.phrase_id)
    AND (INSTR (phrase_entry.phrase_name, 'Specificity')  = 0)
    AND (INSTR (phrase_entry.phrase_name, 'Confirmation') = 0)
    AND (INSTR (phrase_entry.phrase_name, 'Titer')        = 0)
    AND (phrase_entry.phrase_name
      || '@'
      || TRIM (REPLACE (REPLACE (TRIM (REPLACE (REPLACE (TRIM (REPLACE (REPLACE (UPPER (aliquot_user.u_sample_designation), 'PRIMARY-', NULL), 'PRIMARY', NULL)), 'DUPLICATE-', NULL), 'DUPLICATE', NULL)), 'TRIPLICATE-', NULL), 'TRIPLICATE',NULL))
      || '@'
      || UPPER ( TRIM ( DECODE (study_template.name, 'Clinical Study - Visits', NVL (SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR (SAMPLE_USER.U_SITE_NUMBER)), DECODE (sample_template.sample_template_id, 226, TO_CHAR (sample_user.u_site_number), sample_user.u_reference_number))))
      || '@'
      || UPPER (TRIM (DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_subno, ALIQUOT_USER.U_SUBJECT_NUMBER)))
      || '@'
      || TRIM (UPPER (DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_visit, ALIQUOT_USER.U_VISIT_NUMBER)))
      || '@'
      || UPPER (TRIM (DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_timept, ALIQUOT_USER.U_SAMPLING_TIMEPOINT))) NOT IN
      ( SELECT DISTINCT description
        || '@'
        || designation
        || '@'
        || site
        || '@'
        || subject_number
        || '@'
        || visit
        || '@'
        || timept tag
      FROM tempPK_sql
      ))
    ORDER BY STUDY.NAME ASC,
      description ASC,
      site ASC,
      subject_number ASC,
      ALIQUOT_USER.U_RANDOMIZED_NUMBER ASC,
      len_visit ASC,
      visit ASC,
      timept ASC,
      designation ASC,
      reported ASC,
      score ASC,
      ALIQUOT_A.ALIQUOT_ID
    ) tempPK_tbl
  ) tempPK_tbl2
WHERE (description
  || '@'
  || designation
  || '@'
  || site
  || '@'
  || subject_number
  ||'@'
  || visit
  || '@'
  || timept != slip)
AND description
  || '@'
  || designation
  || '@'
  || site
  || '@'
  || subject_number
  ||'@'
  || visit
  || '@'
  || timept NOT IN
  (SELECT description
    || '@'
    || designation
    || '@'
    || site
    || '@'
    || subject_number
    ||'@'
    || visit
    || '@'
    || timept
  FROM tempPK_sql
  WHERE reported = 'Yes'
  )

UNION

SELECT collection_datetime_unf,
  study,
  description AS SOP,
  site
  ||''
  ||subject_number AS Subject,
  treatment,
  admin_method,
  cohort,
  visit,
  timept AS timepoint,
  visit
  ||' '
  ||timept AS visit_timepoint,
  Collection_Date_DDMMYYYY,
  Received_Date_DDMMYYYY,
  Received_Date,
  NULL assay_date_DDMMYYYY,
  NULL assay_datetime,
  parent_aliquot_id,
  condition,
  NULL group_id,
  NULL sample_id,
  NULL plate_id,
  NULL plate_type,
  'NR' AS Final_Concentration_ngml,
  '' formatted_result,
  NULL dilution,
  NULL designation,
  NULL phase
FROM
  (SELECT tempPK_sql.*,
    NVL (LAG (description
    || '@'
    || designation
    || '@'
    || site
    || '@'
    || subject_number
    || '@'
    || visit
    || '@'
    || timept, 1) OVER (ORDER BY ROWNUM), '-1') slip,
    0 V_GROUP_ID
  FROM tempPK_sql
  ) tempPK_tbl2
WHERE status IN ('V', 'C', 'A')
AND (description
  || '@'
  || designation
  || '@'
  || site
  || '@'
  || subject_number
  || '@'
  || visit
  || '@'
  || timept != slip)
AND reported = 'No'
AND description
  || '@'
  || site
  || '@'
  || subject_number
  || '@'
  || visit
  || '@'
  || timept NOT IN
  (SELECT description
    || '@'
    || site
    || '@'
    || subject_number
    || '@'
    || visit
    || '@'
    || timept
  FROM tempPK_sql
  WHERE reported = 'Yes'
  )
  )
ORDER BY study ,
  SOP,
  cohort,
  subject,
  collection_datetime_unf,
  visit,
  timepoint