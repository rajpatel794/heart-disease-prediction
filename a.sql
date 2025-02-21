CREATE
	OR REPLACE VIEW "EI_INFO"."EXPENSE_TIERS_V" (
	"REPORT_ID",
	"EXPENSE_ID",
	"APPROVED_AMOUNT_RPT",
	"EMPLOYEE_ID",
	"NAME",
	"FROM_CREDIT_CARD",
	"PAID_DATE",
	"TRANSACTION_DATE",
	"CAR_RENTAL_START",
	"CAR_RENTAL_END",
	"EXPENSE_TYPE",
	"EMP_POLICY",
	"BASELINE_PARENT_EXPENSE_TYPE",
	"PARENT_EXPENSE_TYPE",
	"VENDOR_COUNTRY",
	"VENDOR_CITY_LOCATION",
	"MERCHANT_COUNTRY_CODE",
	"MERCHANT_COUNTRY",
	"MERCHANT_NUMBER",
	"MERCHANT",
	"MERCHANT_REFERENCE_NUMBER",
	"MERCHANT_CODE",
	"DESCRIPTION",
	"MERCHANT_STREET_ADDRESS",
	"MERCHANT_CITY_LOCATION",
	"MERCHANT_STATE_PROVINCE_REGION",
	"MONTH_DATE",
	"YEAR_DATE",
	"VENDOR_GEO",
	"EXP_TIER_1",
	"EXP_TIER_2",
	"EXP_TIER_3",
	"EXP_TIER_4",
	"EXP_TIER_5",
	"EXP_TIER_6",
	"EXP_TIER_7",
	"EXP_TIER_8",
	"EXP_TIER_9",
	"EXP_TIER_10",
	"MERCH_TIER_1",
	"MERCH_TIER_2",
	"MERCH_TIER_3",
	"MERCH_TIER_4",
	"MERCH_TIER_5",
	"MERCH_TIER_6",
	"MERCH_TIER_7",
	"IS_HCAM"
	) AS
	WITH ATT AS (
			SELECT UPPER(TRIM(REPORT_ID) || TRIM(ENTRY_KEY) || TRIM(ENTRY_KEY_VER)) AS EXPENSE_ID,
				MAX(1, COUNT(SEQ_NO)) AS NUM_ATTENDEES
			FROM EI_INFO.ATTENDEES
			GROUP BY REPORT_ID,
				ENTRY_KEY,
				ENTRY_KEY_VER
			),
		DISTINCT_EXPENSE_COMMENTS AS (
			SELECT DISTINCT REPORT_ID,
				ENTRY_KEY,
				ENTRY_KEY_VER
			FROM EI_INFO.EXPENSE_COMMENTS ec
			WHERE (
					COALESCE(UPPER(EC.COMMENTS), '') LIKE '%HCAM%'
					OR COALESCE(UPPER(EC.COMMENTS), '') LIKE '%HCAM %'
					)
			),
		EXP_TIER AS (
			SELECT exp.REPORT_ID,
				exp.EXPENSE_ID,
				CASE 
					WHEN UPPER(TRIM(EXPENSE_TYPE)) = 'CAR RENTAL'
						THEN exp.APPROVED_AMOUNT_RPT / MAX(1, EXP.CAR_RENTAL_DAYS)
					ELSE APPROVED_AMOUNT_RPT / COALESCE(ATT.NUM_ATTENDEES, 1)
					END AS APPROVED_AMOUNT_RPT,
				CASE 
					WHEN TRIM(UPPER(EXP.EXPENSE_TYPE)) IN (
							SELECT DISTINCT EXPENSE_TYPE
							FROM LOOKUP.EXPENSE_TYPE_MAPPING
							WHERE BASELINE_EXPENSE_TYPE_ID = 1
							)
						THEN 'FLIGHT'
					ELSE TRIM(UPPER(EXP.PARENT_EXPENSE_TYPE))
					END AS BASELINE_PARENT_EXPENSE_TYPE,
				PARENT_EXPENSE_TYPE,
				EMP.EMPLOYEE_ID AS EMPLOYEE_ID,
				EMP.NAME,
				EXP.FROM_CREDIT_CARD AS FROM_CREDIT_CARD,
				EXP.PAID_DATE,
				EXP.TRANSACTION_DATE AS TRANSACTION_DATE,
				TRIM(UPPER(EXP.DEPARTURE_AIRPORT)) AS DEPARTURE_AIRPORT,
				TRIM(UPPER(EXP.ARRIVAL_AIRPORT)) AS ARRIVAL_AIRPORT,
				COALESCE(VENDOR_CITY_LOCATION, EXP.EXPENSE_ID) AS VENDOR_CITY_LOCATION,
				VENDOR_COUNTRY,
				COALESCE(COALESCE(TRIM(UPPER(MERCHANT_COUNTRY_CODE)), TRIM(UPPER(EXP_CLST.COUNTRY_CODE))), TRIM(UPPER(EMP.COUNTRY_CODE))) AS MERCHANT_COUNTRY_CODE,
				COALESCE(COALESCE(TRIM(UPPER(MERCH_CLST.COUNTRY_NAME)), TRIM(UPPER(EXP_CLST.COUNTRY_NAME))), TRIM(UPPER(EMP_CLST.COUNTRY_NAME))) AS MERCHANT_COUNTRY,
				TRIM(UPPER(MERCHANT_REFERENCE_NUMBER)) AS MERCHANT_REFERENCE_NUMBER,
				TRIM(UPPER(MERCHANT_REFERENCE_NUMBER)) || '_' || TRIM(UPPER(TRANS.MERCHANT_CODE)) AS MERCHANT_NUMBER,
				TRIM(UPPER(MERCHANT)) AS MERCHANT,
				TRIM(UPPER(TRANS.MERCHANT_CODE)) AS MERCHANT_CODE,
				DESCRP.DESCRIPTION,
				TRIM(UPPER(EXP_CLST.COUNTRY_CODE)) AS EXP_CLST_COUNTRY_CODE,
				COALESCE(EXP_CLST.EXPENSE_TIER_REGION, EMP_CLST.EXPENSE_TIER_REGION) AS EXP_CLST_REGION,
				EXP_CLST.EXPENSE_TIER_GEO AS EXP_CLST_GEO,
				MERCH_CLST.EXPENSE_TIER_REGION AS MERCH_CLST_REGION,
				MERCH_CLST.EXPENSE_TIER_GEO AS MERCH_CLST_GEO,
				TRANS.MERCHANT_STREET_ADDRESS,
				TRANS.MERCHANT_CITY_LOCATION,
				TRANS.MERCHANT_STATE_PROVINCE_REGION,
				CASE 
					WHEN (
							COALESCE(UPPER(EXP.REPORT_NAME), '') LIKE '%HCAM%'
							OR COALESCE(UPPER(EXP.REPORT_NAME), '') LIKE '%HCAM %'
							OR COALESCE(UPPER(EXP.RPTPURPOSE), '') LIKE '%HCAM%'
							OR COALESCE(UPPER(EXP.RPTPURPOSE), '') LIKE '%HCAM %'
							OR COALESCE(UPPER(EXP.EXPENSE_PURPOSE), '') LIKE '%HCAM%'
							OR COALESCE(UPPER(EXP.EXPENSE_PURPOSE), '') LIKE '%HCAM %'
							OR COALESCE(UPPER(EXP.CLAIM_PURPOSE), '') LIKE '%HCAM%'
							OR COALESCE(UPPER(EXP.CLAIM_PURPOSE), '') LIKE '%HCAM %'
							OR COALESCE(UPPER(EXP.RPT_PROJECT_NO), '') LIKE '%HCAM%'
							OR COALESCE(UPPER(EXP.RPT_PROJECT_NO), '') LIKE '%HCAM %'
							OR EC.REPORT_ID || EC.ENTRY_KEY || EC.ENTRY_KEY_VER IS NOT NULL
							)
						THEN 1
					ELSE 0
					END AS IS_HCAM
			FROM EI_INFO.EXPENSES EXP
			JOIN EI_PROFILE.EMPLOYEES EMP ON EMP.EMPLOYEE_ID = EXP.EMPLOYEE_ID
			LEFT JOIN EI_INFO.CREDIT_TRANSACTIONS TRANS ON CREDIT_CARD_TRANS_KEY = CREDIT_CARD_TRANSACTION_LEGACY_KEY
				AND CREDIT_CARD_TRANSACTION_LEGACY_KEY_VER = CREDIT_CARD_TRANS_KEY_VER
				AND EXP.TRANSACTION_SOURCE = TRANS.TRANSACTION_SOURCE
			JOIN LOOKUP.GEOGRAPHY_INFO EXP_CLST ON TRIM(UPPER(EXP_CLST.COUNTRY_CODE)) = TRIM(UPPER(EXP.VENDOR_COUNTRY))
			LEFT JOIN LOOKUP.GEOGRAPHY_INFO MERCH_CLST ON COALESCE(COALESCE(TRIM(UPPER(MERCHANT_COUNTRY_CODE)), TRIM(UPPER(EXP_CLST.COUNTRY_CODE))), TRIM(UPPER(EMP.COUNTRY_CODE))) = UPPER(TRIM(MERCH_CLST.COUNTRY_CODE))
			LEFT JOIN LOOKUP.GEOGRAPHY_INFO EMP_CLST ON EMP_CLST.COUNTRY_CODE = UPPER(TRIM(EMP.COUNTRY_CODE))
			LEFT JOIN LOOKUP.MERCHANT_CODE_NAMES DESCRP ON TRANS.MERCHANT_CODE = DESCRP.MERCHANT_CODE
			LEFT JOIN ATT ON ATT.EXPENSE_ID = EXP.EXPENSE_ID
			LEFT JOIN TRAVEL_RAW_LANDING.MCOFFICER M ON EMP.EMPLOYEE_ID = M.EMPCNUM
			LEFT JOIN DISTINCT_EXPENSE_COMMENTS EC ON EXP.EXPENSE_ID = EC.REPORT_ID || EC.ENTRY_KEY || EC.ENTRY_KEY_VER
			WHERE TRIM(UPPER(PERSONAL)) = 'N'
				AND EXP.APPROVED_AMOUNT_RPT <> 0
				AND UPPER(TRIM(EXP.EMP_POLICY)) = 'TR'
				AND EXP.APPROVED_AMOUNT_RPT IS NOT NULL
				AND M.EMPCNUM IS NULL
			)
SELECT REPORT_ID,
	EXPENSE_ID,
	APPROVED_AMOUNT_RPT,
	EMPLOYEE_ID,
	NAME,
	FROM_CREDIT_CARD,
	PAID_DATE,
	TRANSACTION_DATE,
	CAR_RENTAL_START,
	CAR_RENTAL_END,
	EXPENSE_TYPE,
	EMP_POLICY,
	BASELINE_PARENT_EXPENSE_TYPE,
	PARENT_EXPENSE_TYPE,
	VENDOR_COUNTRY,
	VENDOR_CITY_LOCATION,
	MERCHANT_COUNTRY_CODE,
	MERCHANT_COUNTRY,
	MERCHANT_NUMBER,
	MERCHANT,
	MERCHANT_REFERENCE_NUMBER,
	MERCHANT_CODE,
	DESCRIPTION,
	MERCHANT_STREET_ADDRESS,
	MERCHANT_CITY_LOCATION,
	MERCHANT_STATE_PROVINCE_REGION,
	MONTH(PAID_DATE) AS MONTH_DATE,
	YEAR(PAID_DATE) AS YEAR_DATE,
	EXP_CLST_GEO AS VENDOR_GEO,
	CASE 
		WHEN BASELINE_PARENT_EXPENSE_TYPE = 'FLIGHT'
			THEN CASE 
					WHEN DEPARTURE_AIRPORT IS NULL
						OR ARRIVAL_AIRPORT IS NULL
						THEN EXPENSE_ID
					ELSE DEPARTURE_AIRPORT || ARRIVAL_AIRPORT || '_' || EXPENSE_TYPE
					END
		ELSE EXP_TIER.EXPENSE_ID
		END AS EXP_TIER_1,
	VENDOR_CITY_LOCATION || '_' || EXPENSE_TYPE AS EXP_TIER_2,
	EXP_CLST_COUNTRY_CODE || '_' || EXPENSE_TYPE AS EXP_TIER_3,
	EXP_CLST_REGION || EXPENSE_TYPE AS EXP_TIER_4,
	EXP_CLST_GEO || '_' || EXPENSE_TYPE AS EXP_TIER_5,
	VENDOR_CITY_LOCATION || '_' || BASELINE_PARENT_EXPENSE_TYPE AS EXP_TIER_6,
	EXP_CLST_COUNTRY_CODE || '_' || BASELINE_PARENT_EXPENSE_TYPE AS EXP_TIER_7,
	EXP_CLST_REGION || '_' || BASELINE_PARENT_EXPENSE_TYPE AS EXP_TIER_8,
	EXP_CLST_GEO || '_' || BASELINE_PARENT_EXPENSE_TYPE AS EXP_TIER_9,
	BASELINE_PARENT_EXPENSE_TYPE AS EXP_TIER_10,
	MERCHANT_COUNTRY_CODE || '_' || MERCHANT_NUMBER || '_' || EXPENSE_TYPE AS MERCH_TIER_1,
	MERCH_CLST_REGION || '_' || MERCHANT_NUMBER || '_' || EXPENSE_TYPE AS MERCH_TIER_2,
	MERCH_CLST_GEO || '_' || MERCHANT_NUMBER || '_' || EXPENSE_TYPE AS MERCH_TIER_3,
	MERCHANT_NUMBER || '_' || EXPENSE_TYPE AS MERCH_TIER_4,
	MERCHANT_COUNTRY_CODE || '_' || MERCHANT_CODE || '_' || EXPENSE_TYPE AS MERCH_TIER_5,
	MERCH_CLST_REGION || '_' || MERCHANT_CODE || '_' || EXPENSE_TYPE AS MERCH_TIER_6,
	MERCH_CLST_GEO || '_' || MERCHANT_CODE || '_' || EXPENSE_TYPE AS MERCH_TIER_7,
	IS_HCAM
FROM EXP_TIER;
