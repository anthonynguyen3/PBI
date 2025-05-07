-- Below is list of APMs and their ASSIGNED DISTRICTS which are responsible for EPIQ Alerts
	-- RESPONSIBILITY_VALUE = District's the APMs are assigned to
		-- This one is tough bc parsing out the RESPONSIBILITY_VALUE without STRING_SPLIT 
	-- RESPONSIBILITY_VALUE = APMs with no districs will not receive EPIQ alerts
WITH tmp(EMP_NUMBER, GROUP_NAMES, Assigned_Districts, Responsibility_value) 
	AS
	(
		SELECT 
			EMP_NUMBER
			,GROUP_NAMES
			,LEFT(Responsibility_value, CHARINDEX(',', Responsibility_value + ',') - 1)
			,STUFF(Responsibility_value, 1, CHARINDEX(',', Responsibility_value + ','), '')
		FROM i2_Data.dbo.PROFITECT_USERS_APM
		
			UNION ALL

		SELECT
			EMP_NUMBER
			,GROUP_NAMES
			,LEFT(Responsibility_value, CHARINDEX(',', Responsibility_value + ',') - 1)
			,STUFF(Responsibility_value, 1, CHARINDEX(',', Responsibility_value + ','), '')
		FROM tmp
		WHERE
			Responsibility_value > ''
	)
SELECT
    EMP_NUMBER
    ,GROUP_NAMES
    ,Assigned_Districts
FROM tmp
ORDER BY EMP_NUMBER
	;
	-- OPTION (maxrecursion 0)
		-- Normally recursion is limited to 100. 
		-- If you know you have very longstrings, uncomment the option.

-- APM = POC for store or everything that is labeled a store
SELECT *
FROM i2_Data.dbo.ATLAS_CONTACTS
	;

-- List of all stores + location data + POC APMs for the stores + Supervising APDs to the APMs
	-- Updated to exclude PARENT_LOCATION_NUMBER = 199 
		-- 199 is code for store "Closed/Dead"
-- Updated bc LOCATION table was flattened to add new location category = PODS (LOC_TYPE_CODE = 'F')
	-- New Location Hierarchy = Operations > Region > Area > Pod > District > Store
SELECT 
	apm.EMP_NUMBER AS APM_EMP_NUMBER
	,CASE
		WHEN apm.EMP_NUMBER IN ('4438507','4464491') 
			THEN
				UPPER(LEFT(apm.FIRST_NAME, 1)) + LOWER(SUBSTRING(apm.FIRST_NAME, 2, LEN(apm.FIRST_NAME))) 
				+ ' ' + UPPER(LEFT(apm.LAST_NAME, 1)) + LOWER(SUBSTRING(apm.LAST_NAME, 2, LEN(apm.LAST_NAME)))
		WHEN apm.EMP_NUMBER IN ('2402374','1844920','2921746') 
			THEN apm.FIRST_NAME + ' ' + apm.LAST_NAME
		WHEN apm.NICKNAME IS NULL 
			THEN apm.FIRST_NAME + ' ' + apm.LAST_NAME
		WHEN apm.EMP_NUMBER = 2948973 
			THEN 'Jim ' + apm.LAST_NAME
				ELSE apm.NICKNAME + ' ' + apm.LAST_NAME
			END AS APM_FULL_NAME
	,apm.JOB_TITLE AS APM_TITLE
	,apm.SUPERVISOR_EMP_NUMBER AS APD_EMP_NUMBER
	,CASE
		WHEN apd.NICKNAME IS NULL THEN apd.FIRST_NAME + ' ' + apd.LAST_NAME
		 ELSE apd.NICKNAME + ' ' + apd.LAST_NAME
		END AS APD_FULL_NAME
	,apd.JOB_TITLE AS APD_TITLE
	,s.LOC_NUM AS STORE_NUMBER
	,CONCAT(FORMAT(s.LOC_NUM,'00000'),' - ',s.CITY,', ',s.ADDRESS_LINE_1,', ',s.[STATE]) AS STORE
	,s.DISTRICT_NUMBER
	,CONCAT(s.DISTRICT_NAME, ' (', s.DISTRICT_NUMBER, ')' ) AS DISTRICT
	,s.POD_NUMBER
	,CONCAT(s.POD_NAME, ' (', s.POD_NUMBER, ')' ) AS POD
	,s.AREA_NUMBER
	,CONCAT(s.AREA_NAME, ' (', s.AREA_NUMBER, ')' ) AS AREA
	,s.REGION_NUMBER
	,CONCAT(s.REGION_NAME, ' (', s.REGION_NUMBER, ')' ) AS REGION
FROM i2_Data.dbo.LOCATION s
LEFT JOIN i2_Data.dbo.ATLAS_CONTACTS atlas
	ON atlas.NODE_ADDRESS = s.NODE_ADDRESS
LEFT JOIN i2_Data.dbo.EISB_LP_FEED apm
	ON atlas.POC_APM_EMP_NUM = apm.EMP_NUMBER
LEFT JOIN i2_Data.dbo.EISB_LP_FEED apd
	ON apm.SUPERVISOR_EMP_NUMBER = apd.EMP_NUMBER
WHERE
	s.LOC_TYPE_CODE = 'S'
	AND s.PARENT_LOCATION_NUMBER <> 199
ORDER BY
	s.LOC_NUM ASC
	;

-- List of all stores + location data
-- Updated bc LOCATION table was flattened to add new location category = POD (LOC_TYPE_CODE = 'F')
	-- New Location Hierarchy = Operations > Region > Area > Pod > District > Store
SELECT 
	s.LOC_NUM AS STORE_NUMBER
	,CONCAT(FORMAT(s.LOC_NUM,'00000'),' - ',s.CITY,', ',s.ADDRESS_LINE_1,', ',s.[STATE]) AS Store
	,s.DISTRICT_NUMBER
	,CONCAT(s.DISTRICT_NAME, ' (', s.DISTRICT_NUMBER, ')' ) AS DISTRICT
	,s.POD_NUMBER
	,CONCAT(s.POD_NAME, ' (', s.POD_NUMBER, ')' ) AS POD
	,s.AREA_NUMBER
	,CONCAT(s.AREA_NAME, ' (', s.AREA_NUMBER, ')' ) AS AREA
	,s.REGION_NUMBER
	,CONCAT(s.REGION_NAME, ' (', s.REGION_NUMBER, ')' ) AS REGION
FROM i2_Data.dbo.LOCATION s
WHERE
	s.LOC_TYPE_CODE = 'S'
	AND s.PARENT_LOCATION_NUMBER <> 199
	;


/*
-- Below query was previously active but ODIN was updated to not have the following table active
	-- Table no longer active = i2_data.dbo.SOC_SITE_STATUS_SOCNET_USER_LIST
-- DMs
SELECT DISTINCT
	emp.EMP_NUMBER
	,emp.FIRST_NAME
	,emp.LAST_NAME
	,ISNULL(dm.WORK_EMAIL_ADDRESS,'') AS dm_email_address
	,s.DISTRICT_NUMBER
	,s.DISTRICT_NAME + ' (' + RIGHT('00000' + CAST( s.DISTRICT_NUMBER AS varchar ), 5) + ')' AS District
	,emp.JOB_TITLE
	,CAST(RIGHT(o.[OWNER], 5) AS int) AS STORE_NUMBER
	,RIGHT('00000' + CAST(STORE_INFO.LOC_NUM AS varchar),5) + ' - ' + STORE_INFO.CITY + ' ' + STORE_INFO.ADDRESS_LINE_1 + ' ' + STORE_INFO.STATE AS Store
FROM i2_data.dbo.PROFITECT_OPPORTUNITIES o
LEFT OUTER JOIN i2_data.dbo.LOCATION_FLAT_VIEW s
	ON s.NODE_ADDRESS = 'S' + RIGHT(o.[OWNER],5)
LEFT OUTER JOIN i2_data.dbo.SOC_SITE_STATUS_SOCNET_USER_LIST dm
	ON dm.WORK_LOC_NUM = s.DISTRICT_NUMBER
LEFT OUTER JOIN i2_data.dbo.EISB_LP_FEED emp
	ON dm.EMP_NUMBER = emp.EMP_NUMBER
LEFT OUTER JOIN i2_data.dbo.LOCATION STORE_INFO
	ON STORE_INFO.LOC_TYPE_CODE = 'S' AND RIGHT(o.[OWNER],5) = STORE_INFO.LOC_NUM
WHERE 
	dm.POSITION = 'DM'
	AND ISNUMERIC ( RIGHT( o.[OWNER],5 ) ) = 1
	AND o.[OWNER] NOT LIKE '%NOVAK%'
--	AND CAST(RIGHT(o.[OWNER], 5) AS int) LIKE '17559' --TEST Store Numbers
--	AND DISTRICT_NUMBER = 814 --TEST DM Numbers
GROUP BY 
	emp.EMP_NUMBER,emp.FIRST_NAME,emp.LAST_NAME,dm.WORK_EMAIL_ADDRESS
	,s.DISTRICT_NAME,emp.JOB_TITLE,o.[OWNER],STORE_INFO.LOC_NUM,STORE_INFO.CITY
	,s.DISTRICT_NUMBER,STORE_INFO.ADDRESS_LINE_1,STORE_INFO.STATE
ORDER BY 
	DISTRICT_NUMBER,District;

-- Store MGRs
SELECT  
	u.login_username AS emp_id
	,emp.FIRST_NAME
	,emp.LAST_NAME
	,DISTRICT_INFO.LOC_NUM AS district_num
	,DISTRICT_INFO.NAME + ' (' + RIGHT('00000' + CAST(DISTRICT_INFO.LOC_NUM AS varchar),5) + ')' District
	,u.Security_value AS store_num
	,RIGHT('00000' + CAST(STORE_INFO.LOC_NUM AS varchar),5) + ' - ' + STORE_INFO.CITY + ' ' + STORE_INFO.ADDRESS_LINE_1 + ' ' + STORE_INFO.STATE AS Store
	,emp.job_title
	,u.Email
	,MAX 
		(CASE emp.job_title
			WHEN 'Store Manager' THEN 1
			WHEN 'Registered Store Manager' THEN 2
			WHEN 'Store Manager Unassigned' THEN 3	
			WHEN 'Emerging Store Manager' THEN 4
			ELSE 5
		END) storemgr_job_rank
FROM i2_Data.dbo.PROFITECT_USERS_FILE u
LEFT OUTER JOIN i2_data.dbo.EISB_LP_FEED emp
	ON u.login_username = emp.EMP_NUMBER
LEFT OUTER JOIN i2_data.dbo.LOCATION DISTRICT_INFO
	ON DISTRICT_INFO.LOC_TYPE_CODE = 'D' AND emp.ASSIGNED_DISTRICT_# = DISTRICT_INFO.LOC_NUM
LEFT OUTER JOIN i2_data.dbo.LOCATION STORE_INFO
	ON STORE_INFO.LOC_TYPE_CODE = 'S' AND emp.WORK_LOC_NUM = STORE_INFO.LOC_NUM
WHERE 
	u.User_Role = 'ManagerUser'
	AND LEFT( u.[Email],3 ) LIKE 'mgr%'
	AND LEFT( u.login_username,3 ) NOT LIKE 'MGR%'
--	AND DISTRICT_INFO.LOC_NUM = 705 --TEST DM Validation
GROUP BY 
	u.login_username,emp.FIRST_NAME,emp.LAST_NAME,STORE_INFO.LOC_NUM,STORE_INFO.CITY,DISTRICT_INFO.NAME
	,DISTRICT_INFO.LOC_NUM,STORE_INFO.ADDRESS_LINE_1,STORE_INFO.STATE,u.Security_value,emp.job_title,u.Email
ORDER BY 
	u.Email,storemgr_job_rank;
*/