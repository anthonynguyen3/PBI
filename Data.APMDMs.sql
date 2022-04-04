-- *NEEDED* = Create a list of APMs assigned to Districts
-- APMs which responsible for EPIQ Alert
	-- RESPONSIBILITY_VALUE = District's the APMs are assigned to
		-- This one is tough bc parsing out the RESPONSIBILITY_VALUE without STRING_SPLIT 
	-- RESPONSIBILITY_VALUE = APMs with no districs will not receive EPIQ alerts
SELECT *
FROM i2_Data.dbo.PROFITECT_USERS_APM

-- APM = POC for store or everything that is labeled a store
SELECT *
FROM i2_Data.dbo.ATLAS_CONTACTS
-- Below is list of APMs which are POC for stores
SELECT 
	apm.POC_APM_EMP_NUM AS APM_Emp_Num
	,emp.FIRST_NAME
	,emp.LAST_NAME
	,emp.WORK_EMAIL_ADDRESS
	,l.PARENT_LOCATION_NUMBER AS DISTRICT_NUMBER
--	,CONCAT(l.DISTRICT_NAME,' (', l.DISTRICT_NUMBER,')') AS DISTRICT
	,CONCAT(FORMAT(l.LOC_NUM,'00000'),' - ',l.CITY,' ,',l.ADDRESS_LINE_1,' ,',l.[STATE]) AS Store
	,CAST(RIGHT(apm.NODE_ADDRESS, 5) AS int) AS STORE_NUMBER
FROM i2_Data.dbo.ATLAS_CONTACTS apm
LEFT OUTER JOIN i2_Data.dbo.LOCATION l
	ON apm.NODE_ADDRESS = l.NODE_ADDRESS
LEFT OUTER JOIN i2_data.dbo.EISB_LP_FEED emp
	ON apm.POC_APM_EMP_NUM = emp.EMP_NUMBER
WHERE 
	l.LOC_TYPE_CODE = 'S'

-- List of Stores w/Districts 
SELECT 
	u.login_username AS emp_num_assignee
	,u.First_Name
	,u.Last_Name
	,u.[Group] AS Recipient_Group
	,CAST(l.LOC_ID AS nvarchar) AS STORE_NUMBER
	,l.DISTRICT_NUMBER
	,CONCAT(l.DISTRICT_NAME,' (', l.DISTRICT_NUMBER,')') AS DISTRICT
	,CONCAT(FORMAT(l.LOC_NUM,'00000'),' - ',l.CITY,' ,',l.ADDRESS_LINE_1,' ,',l.[STATE]) AS Store
FROM i2_Data.dbo.PROFITECT_USERS_FILE u
LEFT OUTER JOIN i2_Data.dbo.LOCATION_FLAT_VIEW l
	ON u.Responsibility_value = l.LOC_ID AND u.First_Name LIKE 'Store Manager' AND l.LOC_TYPE_CODE = 'S' 
WHERE
	l.LOC_TYPE_CODE = 'S'

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


/*
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