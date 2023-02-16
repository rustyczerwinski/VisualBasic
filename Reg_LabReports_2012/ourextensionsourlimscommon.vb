Public Class OurLIMSCommon
    Implements OurLIMSCommonInterface
    ' need to have field/label/property for formatted_result, study, and other parent properties for aliquots (can create field label and then when creating aliquots in that case crate the parent object and set the property
    ' replace column name/label properties with constants to reduce code
#Region "COM GUIDs"
    ' These  GUIDs provide the COM identity for this class 
    ' and its COM interfaces. If you change them, existing 
    ' clients will no longer be able to access the class.
    Public Const ClassId As String = "f5439d27-b94e-4d0d-a190-969559d12071"
    Public Const InterfaceId As String = "9c0b9f8c-b047-475f-ab8d-71b67da70a1a"
    Public Const EventsId As String = "670b3be7-2b61-421f-9cd4-17b84d0d684d"
    Public Interface OurLIMSCommonInterface
        WriteOnly Property LogFileName() As String
    End Interface
#End Region

    ' A creatable COM class must have a Public Sub New() 
    ' with no parameters, otherwise, the class will not be 
    ' registered in the COM registry and cannot be created 
    ' via CreateObject.
    Public Sub New()
        MyBase.New()
        sLogFileName = "OurLIMS.log"
        bLogEnabled = True

        ' NR Code fields
        'define Sample Conditions where sample stability determines NR value
        ConditionsNotStableSampleNRCodes = New Hashtable
        ConditionsNotStableSampleNRCodes.Add("Acceptable", "1")
        ConditionsNotStableSampleNRCodes.Add("Acceptable(-Discrepancy)", "1")
        ConditionsNotStableSampleNRCodes.Add("Acceptable-Flag", "1")
        ConditionsNotStableSampleNRCodes.Add("Acceptable-Resolved", "1")
        ConditionsNotStableSampleNRCodes.Add("Acceptable-Resolved Flag", "1")
        ConditionsNotStableSampleNRCodes.Add("Acceptable-Un-quarantined", "1")

        ' avail common variables and procedures

        'define NR Values that correspond to certain Sample Conditions
        SampleConditionNRCodes = New Hashtable
        SampleConditionNRCodes.Add("Disposed of per site/CRO", 5)
        SampleConditionNRCodes.Add("Empty Vial", 4)
        SampleConditionNRCodes.Add("Arrived Empty", 4)
        SampleConditionNRCodes.Add("Arrived Thawed", 2)
        SampleConditionNRCodes.Add("Thawed", 2)

        NRCodesDescriptions = New Hashtable
        NRCodesDescriptions.Add(1, "Stability exceeded")
        NRCodesDescriptions.Add(2, "Integrity compromised")
        NRCodesDescriptions.Add(3, "Inconsistent result")
        NRCodesDescriptions.Add(4, "Insufficient sample")
        NRCodesDescriptions.Add(5, "Disposed of per site/CRO")

        ResultforNotStableSampleNRCodes = New Hashtable
        ResultforNotStableSampleNRCodes.Add("Failed plate", "11")
        ResultforNotStableSampleNRCodes.Add("Rejected plate", "12")
        ResultforNotStableSampleNRCodes.Add("PI Authorized Rejection", "14")
        ResultforNotStableSampleNRCodes.Add("Incorrect Sample Designation", "20")

        ResultNRCodes = New Hashtable
        ResultNRCodes.Add("long term stability exceeded", "1")
        ResultNRCodes.Add("bench top stability exceeded", "1")
        ResultNRCodes.Add("per PCL046 3X reject", "3")
        ResultNRCodes.Add("SMG has disposed of the sample due to an issue that was previously unknown at the time of analysis (e.g., sample was thawed for an unknown time at the site)", "2")
        ResultNRCodes.Add("Inconsistent result", "3")
        ResultNRCodes.Add("Freeze Thaws exceeded", "1")
        ResultNRCodes.Add("ALQRHD ", "1")
        ResultNRCodes.Add("BLQRLD ", "2")
        ResultNRCodes.Add("CV not met ", "5")
        ResultNRCodes.Add("Failed plate ", "11")
        ResultNRCodes.Add("Rejected plate ", "12")
        ResultNRCodes.Add("PI Authorized Rejection ", "14")
        ResultNRCodes.Add("Incorrect Sample Designation ", "20")

        QuarantineConditionsUppercase = New Collection ' use key so .Contains method works
        QuarantineConditionsUppercase.Add("QUARANTINE-SCREEN FAIL", Key:="QUARANTINE-SCREEN FAIL")
        QuarantineConditionsUppercase.Add("QUARANTINE-OUTSIDE PROTOCOL", Key:="QUARANTINE-OUTSIDE PROTOCOL")
        QuarantineConditionsUppercase.Add("QUARANTINE-UN-RECONCILED", Key:="QUARANTINE-UN-RECONCILED")
        QuarantineConditionsUppercase.Add("QUARANTINE-UNRANDOMIZED", Key:="QUARANTINE-UNRANDOMIZED")

        collMasterReanalysisCodes = New Hashtable
        collMasterReanalysisCodes.Add(key:="A", value:="Confirmation requested by PI")
        collMasterReanalysisCodes.Add(key:="B", value:="Confirmation requested by Kineticist")
        collMasterReanalysisCodes.Add(key:="C", value:="Reanalysis Confirmation")

        collMasterReanalysisResultCodes = New Hashtable
        collMasterReanalysisResultCodes.Add(key:="6", value:="Analyzed 2X, accept initial")
        collMasterReanalysisResultCodes.Add(key:="7", value:="Analyzed 3X, accept 1st confirmed result")
        collMasterReanalysisResultCodes.Add(key:="8", value:="Analyzed 3X, reject all %CV")
        collMasterReanalysisResultCodes.Add(key:="17", value:="Inconsistent(Result)")
    End Sub

    Public Const GROUP_FULL_ACCESS = "TTSAR" ' group that has access to all reports
    Public Const SAMPLE_STABILITY_LIMIT_DEFAULT = 24 ' months default stability for a sample
    Public Const LIMS_TYPE = "Nautilus"
    Public Const RESULT_CODE_NO_RESULT = "NR"
    Public Const RESULT_CODE_BQL = "BLQ"
    Public Const RESULT_CODE_AQL = "ALQ"
    Public Const DISPOSITION_CODE_FAIL = "F"
    Public Const DISPOSITION_CODE_PASS = "P"
    Public Const DISPOSITION_REPORT_FAIL = "Fail"
    Public Const DISPOSITION_REPORT_PASS = "Pass"

    Public Const REPORT_DISPLAY_NUMBER_SIG_FIGS = 3
    Public Const REPORT_DISPLAY_EMPTY_STAT = "NC"

    ' STUDY_TEMPLATE.NAME values
    Public Const STUDY_TYPE_CLINICAL = "Clinical Study - Visits"
    ' report titles
    Public Const REPORT_TITLE_TREND_ANALYSIS_STD = "Trend Analysis Report - Stds"

    Public Const REPORT_DATE_FORMAT_MASK = "dd/MM/yyyy"

    Public Const REPORT_NULL_VALUE = "---"

    Public Const FIELD_LABEL_PQC As String = "PQC" 'zz make these either class properties or constants, not both
    Public Const FIELD_LABEL_PQC_NOMINAL As String = "PQC_NOMINAL"
    Public Const FIELD_LABEL_HLQC As String = "HLQC"
    Public Const FIELD_LABEL_HLQC_NOMINAL As String = "HLQC_NOMINAL"
    Public Const FIELD_LABEL_QC_UNITS As String = "QC_UNITS"
    Public Const FIELD_LABEL_STANDARD_UNITS As String = "STD_UNITS"
    Public Const CRLF = Chr(13) & Chr(10)

    ' logging
    Dim sLogFileName As String
    Dim fileLog As System.IO.StreamWriter
    Dim bLogEnabled As Boolean

    ' NR Code
    Public NRCodesDescriptions As Hashtable
    Public ResultforNotStableSampleNRCodes As Hashtable
    Public ResultNRCodes As Hashtable
    Public SampleConditionNRCodes As Hashtable
    Public ConditionsNotStableSampleNRCodes As Hashtable

    Public QuarantineConditionsUppercase As Collection

    Public collMasterReanalysisCodes As Hashtable
    Public collMasterReanalysisResultCodes As Hashtable

    Public ReadOnly Property LIMSType() As String
        Get
            Return LIMS_TYPE
        End Get
    End Property
    Public Property LogEnabled() As Boolean
        Get
            Return bLogEnabled
        End Get
        Set(ByVal value As Boolean)
            bLogEnabled = value
        End Set
    End Property
    Public ReadOnly Property NRCodesAndDescriptions() As Hashtable
        Get
            Return NRCodesDescriptions
        End Get
    End Property

    Public ReadOnly Property SampleStabilityDefault() As Integer
        Get
            Return SAMPLE_STABILITY_LIMIT_DEFAULT
        End Get
    End Property

    Public ReadOnly Property FormattedResultNoResult() As String
        Get
            Return RESULT_CODE_NO_RESULT
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_PLATE_CONCLUSION() As String
        Get
            Return "FIELD_LABEL_PLATE_CONCLUSION"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_SITE_SUBJECT() As String
        Get
            Return "FIELD_LABEL_SITE_SUBJECT"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_SITE() As String
        Get
            Return "FIELD_LABEL_SITE"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_RESULT_CODE() As String
        Get
            Return "FIELD_LABEL_RESULT_CODE"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLING_VISIT_TIMEPOINT() As String
        Get
            Return "FIELD_LABEL_ALIQUOT_SAMPLING_VISIT_TIMEPOINT"
        End Get
    End Property

    'define labels for LIMS database fields
    '--------------------------------------------------------------
    Public ReadOnly Property FIELD_LABEL_STUDY() As String
        Get
            Return "FIELD_LABEL_STUDY"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_COHORT() As String
        Get
            Return "FIELD_LABEL_COHORT"
        End Get
    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_ALIQUOT_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_ALIQUOT_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_ALIQUOT_TYPE() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_ALIQUOT_TYPE"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_ALIQUOT_TYPE_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_ALIQUOT_TYPE_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_AMOUNT() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_AMOUNT"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_ARCHIVED_CHILD_COMPLETE() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_ARCHIVED_CHILD_COMPLETE"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_AUTHORISED_BY() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_AUTHORISED_BY"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_AUTHORISED_BY_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_AUTHORISED_BY_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_AUTHORISED_ON() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_AUTHORISED_ON"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_BLINDED() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_BLINDED"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_CLINICAL_SAMPLE_TYPES() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_CLINICAL_SAMPLE_TYPES"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_COMMENTS() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_COMMENTS"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_COMPLETED_BY() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_COMPLETED_BY"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_COMPLETED_BY_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_COMPLETED_BY_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_COMPLETED_ON() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_COMPLETED_ON"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_CONCLUSION() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_CONCLUSION"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_CONDITION() As String
        Get
            Return "CONDITION"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_CONDITION() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_CONDITION"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_CONTAINER_TYPE() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_CONTAINER_TYPE"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_CONTAINER_TYPE_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_CONTAINER_TYPE_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_CORE_NUMBER() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_CORE_NUMBER"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_CREATED_BY() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_CREATED_BY"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_CREATED_BY_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_CREATED_BY_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_CREATED_ON() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_CREATED_ON"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DATE_RESULTS_REQUIRED() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DATE_RESULTS_REQUIRED"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DATE_SAMPLE_RECEIVED() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DATE_SAMPLE_RECEIVED"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DATE_TIME_OF_DOSING() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DATE_TIME_OF_DOSING"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DATE_TIME_SAMPLE_COLLECT() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DATE_TIME_SAMPLE_COLLECT"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_DATE_TIME_ASSAY() As String
        Get
            Return "FIELD_LABEL_DATE_TIME_ASSAY"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DATE_TIME_SAMPLE_DRAWN() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DATE_TIME_SAMPLE_DRAWN"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DESCRIPTION() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DESCRIPTION"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DOSE_ADMINISTERED() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DOSE_ADMINISTERED"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DOSE_ADMINISTERED_UNIT() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DOSE_ADMINISTERED_UNIT"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DOSE_ADMINISTERED_UNIT_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DOSE_ADMINISTERED_UNIT_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DOSED_BY() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DOSED_BY"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DOSED_BY_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DOSED_BY_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DOSED_VOLUME() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DOSED_VOLUME"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DOSED_VOLUME_UNITS() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DOSED_VOLUME_UNITS"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_DOSED_VOLUME_UNITS_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_DOSED_VOLUME_UNITS_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_EXPECTED_ON() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_EXPECTED_ON"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_EXPIRES_ON() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_EXPIRES_ON"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_EXTERNAL_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_EXTERNAL_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_EXTERNAL_REFERENCE() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_EXTERNAL_REFERENCE"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_GROUP() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_GROUP"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_GROUP_ID() As String

        Get

            Return "FIELD_LABEL_GROUP_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_INSPECTION_PLAN() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_INSPECTION_PLAN"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_LOCATION() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_LOCATION"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_LOCATION_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_LOCATION_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_MANUF_EXPIRATION_DATE() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_MANUF_EXPIRATION_DATE"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_MATRIX_TYPE() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_MATRIX_TYPE"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_NAME() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_NAME"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_NEEDS_REVIEW() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_NEEDS_REVIEW"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_NO_TIMEPOINTS() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_NO_TIMEPOINTS"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_OLD_STATUS() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_OLD_STATUS"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_OPERATOR() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_OPERATOR"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_OPERATOR_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_OPERATOR_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_PARENT_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_PARENT_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_PARENT_NAME() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_PARENT_NAME"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_PK_SAMPLE_TYPE() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_PK_SAMPLE_TYPE"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_PK_SAMPLE_TYPE_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_PK_SAMPLE_TYPE_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_PLATE_ALIQUOT_TYPE() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_PLATE_ALIQUOT_TYPE"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_PLATE_ALIQUOT_TYPE_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_PLATE_ALIQUOT_TYPE_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_PLATE_COLUMN() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_PLATE_COLUMN"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_PLATE_ID() As String
        Get
            Return "FIELD_LABEL_PLATE_ID"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_STD() As String
        Get
            Return "STANDARD"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_STD_NOMINAL() As String
        Get
            Return "STANDARD_NOMINAL"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_QC() As String
        Get
            Return "QC"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_QC_NOMINAL() As String
        Get
            Return "QC_NOMINAL"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_PLATE_ORDER() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_PLATE_ORDER"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_PLATE_ROW() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_PLATE_ROW"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_PRIORITY() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_PRIORITY"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_RANDOMIZED_NUMBER() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_RANDOMIZED_NUMBER"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_RECEIVED_BY() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_RECEIVED_BY"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_RECEIVED_BY_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_RECEIVED_BY_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_RECEIVED_ON() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_RECEIVED_ON"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_REPORTED() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_REPORTED"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_RESULTS_REVIEW() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_RESULTS_REVIEW"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_REVIEWED_BY() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_REVIEWED_BY"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_REVIEWED_BY_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_REVIEWED_BY_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_REVIEWED_ON() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_REVIEWED_ON"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLE_CONDITION() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SAMPLE_CONDITION"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLE_CONDITIONS() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SAMPLE_CONDITIONS"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLE_DESIGNATION() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SAMPLE_DESIGNATION"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_SAMPLE_ID() As String

        Get

            Return "FIELD_LABEL_SAMPLE_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLE_NAME() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SAMPLE_NAME"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLE_RECEIVED_BY() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SAMPLE_RECEIVED_BY"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLE_RECEIVED_BY_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SAMPLE_RECEIVED_BY_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLE_REVIEW() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SAMPLE_REVIEW"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLE_TYPE() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SAMPLE_TYPE"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLE_TYPE_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SAMPLE_TYPE_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLED_BY() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SAMPLED_BY"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLED_BY_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SAMPLED_BY_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SAMPLING_TIMEPOINT() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SAMPLING_TIMEPOINT"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SCHEDULED_VISIT_NO() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SCHEDULED_VISIT_NO"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SCREEN() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SCREEN"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_SOP() As String

        Get

            Return "FIELD_LABEL_SOP"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_STATUS() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_STATUS"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_STOCK_TEMPLATE_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_STOCK_TEMPLATE_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_STORAGE() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_STORAGE"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SUBJECT_INITIALS() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SUBJECT_INITIALS"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_SUBJECT_NUMBER() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_SUBJECT_NUMBER"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_TIMEPOINT_HOURS() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_TIMEPOINT_HOURS"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_TREATMENT() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_TREATMENT"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_UNIT() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_UNIT"

        End Get

    End Property

    Public ReadOnly Property FIELD_LABEL_ALIQUOT_UNIT_ID() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_UNIT_ID"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_USAGE_COUNT() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_USAGE_COUNT"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_VISIT_NUMBER() As String

        Get

            Return "FIELD_LABEL_ALIQUOT_VISIT_NUMBER"

        End Get

    End Property
    Public ReadOnly Property FIELD_LABEL_ALIQUOT_FORMATTED_SUMMARY_RESULT() As String
        Get
            Return "FORMATTED_SUMMARY_RESULT"
        End Get
    End Property
    Public ReadOnly Property FIELD_LABEL_FORMATTED_RESULT() As String
        Get
            Return "FORMATTED_RESULT"
        End Get
    End Property
    Public WriteOnly Property LogFileName() As String Implements OurLIMSCommonInterface.LogFileName
        Set(ByVal value As String)
            sLogFileName = value
        End Set
    End Property


    Public Sub LogFileUpdate(ByRef pstrLogMsg As String)
        If Not bLogEnabled Then Return
        Try
            fileLog = New System.IO.StreamWriter(sLogFileName, True)
            fileLog.WriteLine(pstrLogMsg & "," & Format(Now), "yyyyMMdd HHmmss")
            fileLog.Flush()
        Catch ex As Exception
            MsgBox("Error writing log file " & sLogFileName & ":" & pstrLogMsg & ":" & ex.ToString)
        Finally
            fileLog.Close()
        End Try
        Exit Sub
    End Sub

    Public Function FormatValueSigFigs(ByVal dValue As Double, ByVal iNumFigs As Integer) As String
        Dim s As String : s = ""
        Try
            Dim formatmask As String : formatmask = ""
            Dim sigfigsmask As String : sigfigsmask = ""
            Dim i As Integer
            For i = 1 To iNumFigs
                sigfigsmask = sigfigsmask & "0"
            Next i

            If dValue >= 10 ^ (iNumFigs - 1) Then
                formatmask = "0"
            Else
                formatmask = "0.############"
            End If

            s = Format(Val(Format(dValue, sigfigsmask & "E+0")), formatmask)

        Catch ex As Exception

        End Try
        Return s
    End Function

    Public Function ValueorDefault(ByRef value As Object, ByRef defaultvalue As Object) As Object
        LogEnabled = False ' turn off debugging
        LogFileUpdate("valueordefault:" & value & ":" & defaultvalue)
        On Error Resume Next
        ValueorDefault = value
        If IsNumeric(value) Then
            If value = 0 Then
                ValueorDefault = defaultvalue
            Else
                ValueorDefault = value
            End If
        ElseIf IsDate(value) Then
            If value < DateSerial(1900, 1, 1) Then
                ValueorDefault = defaultvalue
            Else
                ValueorDefault = value
            End If
        ElseIf IsReference(value) Then
            If (value Is Nothing) Then
                ValueorDefault = defaultvalue
                LogFileUpdate("valueordefault reference nothing")
            Else
                ValueorDefault = value
                LogFileUpdate("valueordefault reference value")
            End If
        ElseIf IsNothing(value) Then
            ValueorDefault = defaultvalue
        Else ' assume string at this point
            If value = "" Then
                ValueorDefault = defaultvalue
                LogFileUpdate("valueordefault string default")
            Else
                ValueorDefault = value
                LogFileUpdate("valueordefault string value")
            End If
        End If
        On Error GoTo 0 'clear any errors
        LogEnabled = True
        Exit Function
    End Function

End Class

