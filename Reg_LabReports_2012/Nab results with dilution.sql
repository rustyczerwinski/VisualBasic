-Nab results with dilution
WITH temp_t1 AS
  ( SELECT DISTINCT STUDY.NAME study_name,
    SUBSTR(ALIQUOT_B.DESCRIPTION,1,7) SOP,
    ALIQUOT_A.ALIQUOT_ID,
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
    UPPER (TRIM (DECODE(study_template.name, 'Clinical Study - Visits', NVL (SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR (SAMPLE_USER.U_SITE_NUMBER)), DECODE (sample_template.sample_template_id, 226, TO_CHAR (sample_user.u_site_number), sample_user.u_reference_number) )))
    ||''
    ||UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_subno, ALIQUOT_USER.U_SUBJECT_NUMBER))) subject,
    UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_visit, ALIQUOT_USER.U_VISIT_NUMBER))) visit,
    UPPER(TRIM(DECODE (study_template.name, 'Clinical Study - Visits', sample_user.u_timept, ALIQUOT_USER.U_SAMPLING_TIMEPOINT))) timept,
    TRIM ( REPLACE ( REPLACE (TRIM (REPLACE (REPLACE (TRIM (REPLACE (REPLACE (UPPER (aliquot_user.u_sample_designation), 'PRIMARY-', NULL), 'PRIMARY', NULL)), 'DUPLICATE-', NULL), 'DUPLICATE', NULL)), 'TRIPLICATE-', NULL ), 'TRIPLICATE', NULL)) designation,
    TO_CHAR(DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE.SAMPLED_ON, ALIQUOT_USER.U_DATE_TIME_SAMPLE_DRAWN), 'DD/MM/YYYY') collection_date_DDMMYYYY,
    DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE.SAMPLED_ON, ALIQUOT_USER.U_DATE_TIME_SAMPLE_DRAWN) collection_datetime,
    TO_CHAR(ALIQUOT_A.RECEIVED_ON,'DD/MM/YYYY') received_date_DDMMYYYY,
    RESULT_A.STATUS,
    PLATE.PLATE_ID PLATE_ID,
    TO_CHAR(RESULT_B.RAW_DATETIME_RESULT,'DD/MM/YYYY') Assay_Date_DDMMYYYY,
    UPPER (TRIM (DECODE(study_template.name, 'Clinical Study - Visits', NVL (SAMPLE_USER.U_REFERENCE_NUMBER, TO_CHAR (SAMPLE_USER.U_SITE_NUMBER)), DECODE (sample_template.sample_template_id, 226, TO_CHAR (sample_user.u_site_number), sample_user.u_reference_number) ))) site,
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
    END Assay_Name,
    CASE
      WHEN (ALIQUOT_B.DESCRIPTION LIKE '%Titer%')
      THEN RESULT_D.ORIGINAL_RESULT
      ELSE ''
    END titer,
    RESULT_A.FORMATTED_RESULT formatted_result,
    RESULT_D.ORIGINAL_RESULT dilution,
    DECODE (INSTR (result_a.name, 'Final Dose'),0, DECODE ( INSTR (aliquot_b.name, 'Screen'), 0, DECODE ( INSTR (aliquot_b.name, 'Specificity'), 0, DECODE (INSTR (aliquot_b.name, 'Titer'), 0, DECODE (result_a.formatted_result, 'NEGATIVE', 'Yes', 'POSITIVE', 'Yes', 'No'), DECODE (result_a.formatted_result, 'Reported Ab Titer', 'Yes', 'No') ), DECODE (result_a.formatted_result, 'DRUG SPECIFIC', 'Yes', 'NOT DRUG SPECIFIC', 'Yes', 'CONFIRMED NEGATIVE', 'Yes', 'No')), DECODE (result_a.formatted_result, 'NEGATIVE', 'Yes', 'POSITIVE', 'Yes', 'No')), DECODE (NVL (RESULT_A.REPORTED, 'F'), 'T', 'Yes', 'No')) reported,
    DECODE (Instr (Upper (Aliquot_User.U_Sample_Designation), 'TRIPLICATE'), 0, DECODE (Instr (Upper (Aliquot_User.U_Sample_Designation), 'DUPLICATE'), 0, 1, 2), 3) Score,
    --'1' sort_ref ,
    --substr(ALIQUOT_B.DESCRIPTION,1,7)||' '||
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
    LIMS_SYS.RESULT RESULT_B,
    LIMS_SYS.TEST TEST_B,
    LIMS_SYS.STUDY_USER,
    LIMS_SYS.SAMPLE_TEMPLATE,
    LIMS_SYS.RESULT RESULT_C,
    LIMS_SYS.RESULT RESULT_D,
    LIMS_SYS.UNIT UNIT_A,
    LIMS_SYS.UNIT UNIT_B,
    LIMS_SYS.STUDY_TEMPLATE
  WHERE (STUDY.STUDY_ID       IN (:Study_id) )
  AND (STUDY.GROUP_ID          = 13)
  AND (study.study_template_id = study_template.study_template_id)
  AND (Study_User.Study_Id     = Study.Study_Id)
  AND (Study.Study_Id          = Sample.Study_Id)
    --AND STUDY_USER.u_date_study_end IS NULL
  AND (SAMPLE.SAMPLE_TEMPLATE_ID            = SAMPLE_TEMPLATE.SAMPLE_TEMPLATE_ID)
  AND (SAMPLE.SAMPLE_ID                     = SAMPLE_USER.SAMPLE_ID)
  AND (ALIQUOT_A.SAMPLE_ID                  = SAMPLE.SAMPLE_ID)
  AND(ALIQUOT_USER.U_DOSE_ADMINISTERED_UNIT = LIMS_SYS.UNIT_A.UNIT_ID (+))
  AND (Sample_User.U_Dose_Administered_Units=Lims_Sys.Unit_B.Unit_Id (+))
  AND (Aliquot_User.Aliquot_Id              = Aliquot_A.Aliquot_Id)
    --AND (INSTR (',' || REPLACE (REPLACE (:Protocol_List, ', ', ','), ' ,', ',') || ',', ALIQUOT_B.DESCRIPTION) > 0)
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
  AND ( (Result_A.Name LIKE '%Final Dose%')
  OR (Result_A.Name LIKE '%Disposition%'
  AND Result_C.Name = 'Mean Well Value'))
    --AND (RESULT_A.FORMATTED_RESULT = 'DRUG SPECIFIC')
    --AND (RESULT_A.FORMATTED_RESULT = 'Reported Ab Titer')
  AND (TEST_A.TEST_ID              = RESULT_C.TEST_ID(+))
  AND (Test_A.Test_Id              = Result_D.Test_Id(+))
  AND (RESULT_D.NAME(+)            = 'Dilution')
  AND (ALIQUOT_B.PLATE_ID          = PLATE.PLATE_ID)
  AND (PLATE.CONCLUSION            = 'P')
  AND (PLATE.PLATE_ID              = TEST_B.PLATE_ID)
  AND (RESULT_B.TEST_ID            = TEST_B.TEST_ID)
  AND (RESULT_B.NAME               = 'Assay Date')
  AND ( RESULT_A.FORMATTED_RESULT IN ('NEGATIVE','POSITIVE','NOT DRUG SPECIFIC','DRUG SPECIFIC','CONFIRMED NEGATIVE','Reported Ab Titer'))
  AND ( ALIQUOT_A.RECEIVED_ON BETWEEN :Start_Date AND :End_Date)
  AND (ALIQUOT_A.STATUS NOT IN ('U', 'S', 'X'))
  AND (ALIQUOT_B.STATUS NOT IN ('U', 'S', 'X'))
  ORDER BY STUDY.NAME,
    SOP,
    cohort,
    subject,
    visit,
    timept,
    len_visit
  ),
  temp_t2 AS
  ( SELECT DISTINCT STUDY.NAME study_name,
    ALIQUOT_B.DESCRIPTION SOP,
    ALIQUOT_A.ALIQUOT_ID,
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
    --  DECODE(STUDY_TEMPLATE.NAME, 'Clinical Study - Visits', SAMPLE.SAMPLED_ON, ALIQUOT_USER.U_DATE_TIME_SAMPLE_DRAWN) draw_date,
    PLATE.PLATE_ID PLATE_ID,
    TO_CHAR(RESULT_B.RAW_DATETIME_RESULT,'DD/MM/YYYY') Assay_Date_DDMMYYYY,
    --   RESULT_A.NAME result_a_name,
    RESULT_A.FORMATTED_RESULT Nab,
    RESULT_D.FORMATTED_RESULT Pct_AR,
    RESULT_C.FORMATTED_RESULT Reported_Cutpoin,
    ALIQUOT_B_USER.U_RESULTS_REVIEW result_status ,
    --substr(ALIQUOT_B.DESCRIPTION,1,7)||' '||
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
    LIMS_SYS.TEST TEST_B ,
    LIMS_SYS.TEST TEST_C ,
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
  AND ( ALIQUOT_A.RECEIVED_ON BETWEEN :Start_Date AND :End_Date)
  AND ( ALIQUOT_USER.U_SAMPLE_DESIGNATION LIKE '%Ab')
  AND ( SAMPLE.SAMPLE_ID              = ALIQUOT_A.SAMPLE_ID )
  AND ( ALIQUOT_A.ALIQUOT_TEMPLATE_ID = ALIQUOT_TEMPLATE.ALIQUOT_TEMPLATE_ID )
  AND ( SAMPLE.SAMPLE_ID              = SAMPLE_USER.SAMPLE_ID )
  AND ( STUDY.STUDY_ID                = STUDY_USER.STUDY_ID )
  AND ( SAMPLE.SAMPLE_TEMPLATE_ID     = SAMPLE_TEMPLATE.SAMPLE_TEMPLATE_ID )
  AND ( STUDY.STUDY_TEMPLATE_ID       = STUDY_TEMPLATE.STUDY_TEMPLATE_ID)
  AND ( TEST_A.TEST_ID                = RESULT_D.TEST_ID )
  AND (STUDY.STUDY_ID                IN (:Study_id) )
  AND (STUDY.GROUP_ID                 = 13)
  AND (RESULT_A.NAME                  = 'Disposition' )
  AND (RESULT_B.NAME                  = 'Assay Date')
  AND (RESULT_C.NAME LIKE '%Reported Cutpoint%')
  AND (RESULT_D.NAME              = '%AR')
  AND (RESULT_A.FORMATTED_RESULT IN ('NEGATIVE','POSITIVE'))
  AND (Aliquot_B_User.U_Group     = 'Neutralizing Sample' )
  ORDER BY Study_Name ,
    Sop,
    Cohort,
    Subject,
    Visit,
    Timept
  ),
  Temp_T3 AS
  (SELECT DISTINCT study_name,
    cohort,
    SOP,
    subject,
    visit,
    timept ,
    new_id,
    MAX(DECODE(assay_name, 'Screen', formatted_result,NULL))  AS screen,
    MAX(DECODE(Assay_Name, 'Spiked', Formatted_Result ,NULL)) AS Confirmation,
    MAX(DECODE(assay_name, 'Titer', dilution ,NULL)) ada_assay_titer
  FROM Temp_T1
  GROUP BY study_name,
    cohort,
    SOP,
    subject,
    visit,
    timept,
    new_id
  )
SELECT DISTINCT Study_Name,
  --PK_SOP,
  DECODE (NAb_sop, '', missing_sop, NAb_sop) SOP,
  cohort,
  subject,
  visit,
  timepoint,
  collection_date_DDMMYYYY,
  received_date_DDMMYYYY,
  DECODE(plate_id, '','---', plate_id) plate_id,
  DECODE(Assay_Date_Ddmmyyyy, '','---',Assay_Date_Ddmmyyyy) Assay_Date_Ddmmyyyy,
  DECODE(Nab,'NEGATIVE','Negative','POSITIVE','Positive', 'NR') Final_Result,
  DECODE(Ada_Assay_Titer, '','---', Ada_Assay_Titer) Ada_Assay_Titer,
  collection_datetime
FROM
  (SELECT A.Study_Name,
        B.Sop Nab_Sop,
    Trim(A.Cohort) Cohort,
    A.Subject,
    A.Visit,
    A.Timept AS Timepoint,
    A.Designation,
    A.Collection_Date_Ddmmyyyy,
    A.Collection_Datetime,
    A.Received_Date_Ddmmyyyy,
    A.Formatted_Result AS Confirmation,
    B.Assay_Date_Ddmmyyyy,
    B.Plate_Id,
    B.Nab,
    c.ada_assay_titer,
    ( SELECT DISTINCT Sop FROM Temp_T2 WHERE Sop IS NOT NULL
    ) AS Missing_Sop
  FROM Temp_T1 A,
    Temp_T2 B,
    Temp_T3 C
  WHERE A.New_Id                 = B.New_Id (+)
  AND A.New_Id                   = C.New_Id
  AND NVL(A.Formatted_Result,-1) = 'DRUG SPECIFIC'  )D
Where ((Plate_Id     >0 And Ada_Assay_Titer Is Not Null)
OR (Plate_Id        IS NULL AND Ada_Assay_Titer IS NOT NULL) )
ORDER BY study_name ,
  SOP,
  cohort,
  subject,
  collection_datetime,
  visit,
  timepoint
