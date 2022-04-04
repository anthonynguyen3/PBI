-- PATTERN CENTRIC UPDATE: Query build to include comments + location + DM
	-- Goal is to build Star Schema to integrate LOCATION + DM information

-- Pattern Group >> Patterns and their recipient groups from ZPA >> WILL HAVE TO BE MAINTAINED!!!!
SELECT 
	pg.PATTERN_CODE
	,pg.OWNER_GROUP
	,CASE
		WHEN pg.ZPA_STATUS = 1 THEN 'Active'
		ELSE 'Inactive'
	END AS ZPA_STATUS
	,pg.PATTERN_SCHEDULE
	,pg.PATTERN_SCHEDULE_RUN_DAY
	,pg.LAST_UPDATED_DTTM
FROM i2_data.dbo.PROFITECT_PATTERNS_BY_OWNER_GROUP pg

-- Below Query is pretty much the same of PATTERN CENTRIC but updating o.EMP_NUMBER_OWNER + o.[OWNER] to find STORE and add new column "Store_Number"
SELECT 		
	o.OPP_ID
	,o.SUMMARY
	,o.OPP_STATUS
	,o.OPP_RESOLUTION
	,o.OPP_VALUE
	,SUBSTRING(o.PATTERN_NAME, 1, PATINDEX('% %',REPLACE(o.PATTERN_NAME,'CP - ',''))+LEN('CP - ')) PATTERN_CODE
	,o.ASSIGNEE
	,o.EMP_NUMBER_ASSIGNEE
	,CASE
		WHEN o.EMP_NUMBER_OWNER LIKE '%MGR%' THEN CAST(RIGHT(o.EMP_NUMBER_OWNER, 5) AS nvarchar)
		WHEN o.EMP_NUMBER_OWNER = '2627994' AND o.[OWNER] = 'Rick Gaitan' THEN '1509257'
		WHEN o.EMP_NUMBER_OWNER = '1543428' AND o.[OWNER] = 'Store Manager 05463' THEN CAST('5463' AS nvarchar)
		WHEN o.EMP_NUMBER_OWNER = '1808676' AND o.[OWNER] = 'Store Manager 03197' THEN CAST('3197' AS nvarchar)
		WHEN o.EMP_NUMBER_OWNER = '1991504' AND o.[OWNER] = 'Store Manager 13705' THEN CAST('12705' AS nvarchar)
		WHEN o.EMP_NUMBER_OWNER = '1634916' AND o.[OWNER] = 'Store Manager 15010' THEN CAST('15010' AS nvarchar)
		WHEN o.EMP_NUMBER_OWNER = '2925478' AND o.[OWNER] = 'Store Manager 17217' THEN CAST('17217' AS nvarchar)
		WHEN o.EMP_NUMBER_OWNER = '2923967' AND o.[OWNER] = 'Store Manager 17684' THEN CAST('17684' AS nvarchar)
		WHEN o.EMP_NUMBER_OWNER = 'SteeringCommittee' THEN CAST('SteeringCommittee' AS nvarchar)
			ELSE o.EMP_NUMBER_OWNER
		END AS EMP_NUMBER_OWNER 
	,CASE
			WHEN o.[OWNER] LIKE '%store manager%' THEN CAST( RIGHT(o.[OWNER], 5) AS int )
			WHEN LEFT(o.OPPORTUNITY_ENTITY, 7) LIKE '% -%' THEN CAST( LEFT(o.OPPORTUNITY_ENTITY, 5) AS int )
		END AS Store_Number
--	,CHARINDEX(')',o.OPPORTUNITY_ENTITY) - CHARINDEX('(',o.OPPORTUNITY_ENTITY) AS charcount -- This was used to test the character count for Entity's = DISTRICTS >> 6 = Districts
	,CASE
		WHEN 
			SUBSTRING(o.PATTERN_NAME, 1, 8) IN ( 'CP - 296','CP - 305','CP - 577' ) -- This is a list of patterns assigned to DM's OR Entity = District ***UPDATE AND CHECK IF ENTITY = DISTRICTS*** IF NO, DON'T USE. 
			AND	o.OPPORTUNITY_ENTITY LIKE '%(%' -- This was used to test the character count for Entity's = DISTRICTS >> 6 = Districts
			AND CHARINDEX(')',o.OPPORTUNITY_ENTITY) - CHARINDEX('(',o.OPPORTUNITY_ENTITY) = 6 -- This was used to test the character count for Entity's = DISTRICTS >> 6 = Districts
/*			o.PATTERN_NAME LIKE 'CP - 418%' -- Assigned to DM's but Dont Use = Tobacco >> Entity = Cashier
			OR o.PATTERN_NAME LIKE 'CP - 428%' -- Assigned to DM's but Dont Use = Alcohol >> Entity = Cashier
			OR o.PATTERN_NAME LIKE 'CP - 439%' -- Assigned to DM's but Dont Use = Paid Outs Above Limits >> Entity = Store
			OR o.PATTERN_NAME LIKE 'CP - 502%' -- Assigned to DM's but Dont Use = California Price Modifies >> Entity = Store
			OR o.PATTERN_NAME LIKE 'CP - 568%' -- Assigned to DM's but Dont Use YET = DM Escalation Users w/3 or more overdue >> OWNER = RAY NOVAK ***CHECK IN FUTURE ONCE THIS IS LIVE***
			OR o.PATTERN_NAME LIKE 'CP - 577%' -- Assigned to DM's and YES BEING USED! = DM Escalation Inventory >> Entity = District
			OR o.PATTERN_NAME LIKE 'CP - 578%' -- Assigned to DM's but Dont Use = DM Escalation Overdue Compliance Alerts >> Entity = Cashier
			OR o.PATTERN_NAME LIKE 'CP - 591%' -- Assigned to DM's but Dont Use = DM Escalation Multiple Alcohol/Tobacco Compliance Alerts >> Entity = Cashier
*/			THEN CAST( -- Find the DISTRICT NUMBER between ( ) 
					SUBSTRING(o.OPPORTUNITY_ENTITY, CHARINDEX('(',o.OPPORTUNITY_ENTITY) +1 
					,CHARINDEX(')',o.OPPORTUNITY_ENTITY) - CHARINDEX('(',o.OPPORTUNITY_ENTITY)-1) 
				AS int ) 
		END AS DISTRICT_NUMBER
	,o.OPPORTUNITY_ENTITY
	,o.[OWNER]
	,o.LABELS
	,o.OPP_GENERATED_TIME AS CreatedDate -- Added 9.23.2021 > Calendar Table Should be Modeled After This Date
	,MIN(o.LAST_MODIFIED) MIN_LAST_MODIFIED
	,o.DATE_INSERTED
FROM i2_data.dbo.PROFITECT_OPPORTUNITIES o
WHERE 
	o.OPP_STATUS NOT IN ('HISTORY','Deleted')
	AND o.SUMMARY NOT LIKE 'Welcome to%'
	AND o.DATE_INSERTED BETWEEN '2020-03-01 00:00:00.001' AND GETDATE() -- Tim confirmed 6.30.2021 that FQ2 2020 (Feb 2020) is not needed
	AND o.OPP_GENERATED_TIME BETWEEN '2020-03-01 00:00:00.001' AND GETDATE() -- Was going to replace DATE_INSERTED with this but loss of 4k rows >> RAY confirmed that we can add this filter to get rid of unneccesary historical data 9.28.2021
	AND o.ASSIGNEE NOT IN ('Molly Pollard','Alex Beizerov','analyst profitect','APS Technology','BRETT CAMPBELL','BRIAN ITTNER'
	,'DEREK LANNI','GARY MONAGHAN','Alison Harmon','BILL INZEO','Jim Hare','Investigative Analytics','JACK DONOVAL','JAMES SPENCER','JEFF TOLVA'
	,'JOHN DONOVAL','KIMBERLY GANDY','LAUREN NESTOR','MELISSA VAN DE CARR','RAYMOND NOVAK','RAYMOND STUKEL','SCOTT JONKMAN','RACHEL KAMENIR'
	,'RAY NOVAK','SETH HUGHES','STEPHEN LAMALFA','Zebra Analysts','TAL HAREL','ANTHONY NGUYEN','EKATERINA REVENYUK','SEMETRIUS CANNEDY')
	AND o.ASSIGNEE NOT LIKE '%KEN O''CONNOR%' AND o.ASSIGNEE NOT LIKE '%KENNETH O''CONNOR%' 
	AND o.EMP_NUMBER_OWNER NOT IN ('4116158','IITeam') AND o.EMP_NUMBER_OWNER NOT LIKE '%duguay%' -- Tim confirmed 9.9.2021 to REMOVE (EMP_NUMBER_OWNER = 4116158) and ADD ('SteeringCommittee')
	AND o.[OWNER] NOT LIKE '%NOVAK%' AND o.[OWNER] NOT LIKE '%Molly Pollard%'
GROUP BY 
	o.OPP_ID,o.SUMMARY,o.OPP_STATUS,o.OPP_RESOLUTION,o.OPP_VALUE,o.ASSIGNEE,o.PATTERN_NAME,o.OPPORTUNITY_ENTITY
	,o.EMP_NUMBER_ASSIGNEE,o.[OWNER],o.EMP_NUMBER_OWNER,o.LABELS,o.DATE_INSERTED,o.OPP_GENERATED_TIME

ORDER BY 
	o.OPP_ID 
	,CASE 
		WHEN o.OPP_STATUS = 'New' THEN 1 
		WHEN o.OPP_STATUS = 'In progress' THEN 2 
		WHEN o.OPP_STATUS LIKE 'Resolved - %' THEN 3 
			ELSE 9 
		END
	,MIN_LAST_MODIFIED; 

-- Comments >> STAR SCHEMA 
-- Updated to only bring in OPP_ID from the alerts we are using, not trying to bring in all alerts as previous
SELECT 
	pcom.OPP_ID
	,pcom.COMMENT
	,pcom.COMMENT_TIMESTAMP
	,pcom.DATE_INSERTED
FROM i2_data.dbo.PROFITECT_OPPORTUNITY_COMMENTS pcom
WHERE pcom.OPP_ID IN (
	-- Below is the query being used for alerts. Just removed all the other columns for query requirements
	SELECT 		
		o.OPP_ID
	FROM i2_data.dbo.PROFITECT_OPPORTUNITIES o
	WHERE 
		o.OPP_STATUS NOT IN ('HISTORY','Deleted')
		AND o.SUMMARY NOT LIKE 'Welcome to%'
		AND o.DATE_INSERTED BETWEEN '2020-03-01 00:00:00.001' AND GETDATE() -- Tim confirmed 6.30.2021 that FQ2 2020 (Feb 2020) is not needed
		AND o.OPP_GENERATED_TIME BETWEEN '2020-03-01 00:00:00.001' AND GETDATE()
		AND o.ASSIGNEE NOT IN ('Molly Pollard','Alex Beizerov','analyst profitect','APS Technology','BRETT CAMPBELL','BRIAN ITTNER'
		,'DEREK LANNI','GARY MONAGHAN','Alison Harmon','BILL INZEO','Jim Hare','Investigative Analytics','JACK DONOVAL','JAMES SPENCER','JEFF TOLVA'
		,'JOHN DONOVAL','KIMBERLY GANDY','LAUREN NESTOR','MELISSA VAN DE CARR','RAYMOND NOVAK','RAYMOND STUKEL','SCOTT JONKMAN','RACHEL KAMENIR'
		,'RAY NOVAK','SETH HUGHES','STEPHEN LAMALFA','Zebra Analysts','TAL HAREL','ANTHONY NGUYEN')
		AND o.ASSIGNEE NOT LIKE '%KEN O''CONNOR%' AND o.ASSIGNEE NOT LIKE '%KENNETH O''CONNOR%' 
		AND o.EMP_NUMBER_OWNER NOT IN ('4116158','IITeam') AND o.EMP_NUMBER_OWNER NOT LIKE '%duguay%' -- Tim confirmed 9.9.2021 to REMOVE (EMP_NUMBER_OWNER = 4116158) and ADD ('SteeringCommittee')
		AND o.[OWNER] NOT LIKE '%NOVAK%' AND o.[OWNER] NOT LIKE '%Molly Pollard%'
	GROUP BY 
		o.OPP_ID
		) 
ORDER BY pcom.OPP_ID,pcom.COMMENT_TIMESTAMP

-- Below query is a list of all stores + location data >> updated this query bc this one is so much faster to run vs the previous
SELECT 
	l.LOC_NUM AS STORE_NUMBER
	,CONCAT(l.REGION_NAME,' (', l.REGION_NUMBER,')') AS REGION
	,CONCAT(l.AREA_NAME,' (', l.AREA_NUMBER,')') AS AREA
	,l.DISTRICT_NUMBER
	,CONCAT(l.DISTRICT_NAME,' (', FORMAT(l.DISTRICT_NUMBER,'00000'),')') AS DISTRICT
--	,CONCAT(l.LOC_NUM,' - ',l.CITY,' ,',l.ADDRESS_LINE_1,' ,',l.[STATE]) AS LOCATION
	,CONCAT(FORMAT(l.LOC_NUM,'00000'),' - ',l.CITY,' ,',l.ADDRESS_LINE_1,' ,',l.[STATE]) AS Store
FROM i2_Data.dbo.LOCATION_FLAT_VIEW l
WHERE
	l.LOC_TYPE_CODE = 'S'
	AND NOT l.DISTRICT_NAME = 'Closed/Dead'
ORDER BY 
	1

-- Below query list APMs employee ID + the Districts they are assigned to for EPIQ Alerts
SELECT 
	apm.EMP_NUMBER
	,apm.GROUP_NAMES
	,RESPONSIBILITY_VALUE AS APM_Assigned_Districts
FROM i2_Data.dbo.PROFITECT_USERS_APM apm

-- Date / Time Data refreshed
SELECT
	MAX(DATE_INSERTED) AS data_refreshed
FROM (
	SELECT 		
		o.OPP_ID
		,o.SUMMARY
		,o.OPP_STATUS
		,o.OPP_RESOLUTION
		,o.OPP_VALUE
		,SUBSTRING(o.PATTERN_NAME, 1, PATINDEX('% %',REPLACE(o.PATTERN_NAME,'CP - ',''))+LEN('CP - ')) PATTERN_CODE
		,o.ASSIGNEE
		,o.EMP_NUMBER_ASSIGNEE
		,CASE
			WHEN o.EMP_NUMBER_OWNER LIKE '%MGR%' THEN CAST(RIGHT(o.EMP_NUMBER_OWNER, 5) AS nvarchar)
			WHEN o.EMP_NUMBER_OWNER = '2627994' AND o.[OWNER] = 'Rick Gaitan' THEN '1509257'
			WHEN o.EMP_NUMBER_OWNER = '1543428' AND o.[OWNER] = 'Store Manager 05463' THEN CAST('5463' AS nvarchar)
			WHEN o.EMP_NUMBER_OWNER = '1808676' AND o.[OWNER] = 'Store Manager 03197' THEN CAST('3197' AS nvarchar)
			WHEN o.EMP_NUMBER_OWNER = '1991504' AND o.[OWNER] = 'Store Manager 13705' THEN CAST('12705' AS nvarchar)
			WHEN o.EMP_NUMBER_OWNER = '1634916' AND o.[OWNER] = 'Store Manager 15010' THEN CAST('15010' AS nvarchar)
			WHEN o.EMP_NUMBER_OWNER = '2925478' AND o.[OWNER] = 'Store Manager 17217' THEN CAST('17217' AS nvarchar)
			WHEN o.EMP_NUMBER_OWNER = '2923967' AND o.[OWNER] = 'Store Manager 17684' THEN CAST('17684' AS nvarchar)
			WHEN o.EMP_NUMBER_OWNER = 'SteeringCommittee' THEN CAST('SteeringCommittee' AS nvarchar)
				ELSE o.EMP_NUMBER_OWNER
			END AS EMP_NUMBER_OWNER 
		,CASE
				WHEN o.[OWNER] LIKE '%store manager%' THEN CAST( RIGHT(o.[OWNER], 5) AS int )
				WHEN LEFT(o.OPPORTUNITY_ENTITY, 7) LIKE '% -%' THEN CAST( LEFT(o.OPPORTUNITY_ENTITY, 5) AS int )
			END AS Store_Number
		,o.[OWNER]
		,o.LABELS
		,o.OPP_GENERATED_TIME AS CreatedDate
		,MIN(o.LAST_MODIFIED) MIN_LAST_MODIFIED
		,o.DATE_INSERTED
	FROM i2_data.dbo.PROFITECT_OPPORTUNITIES o
	WHERE 
		o.OPP_STATUS NOT IN ('HISTORY','Deleted')
		AND o.SUMMARY NOT LIKE 'Welcome to%'
		AND o.DATE_INSERTED BETWEEN '2020-03-01 00:00:00.001' AND GETDATE() -- Tim confirmed 6.30.2021 that FQ2 2020 (Feb 2020) is not needed
		AND o.OPP_GENERATED_TIME BETWEEN '2020-03-01 00:00:00.001' AND GETDATE()
		AND o.ASSIGNEE NOT IN ('Molly Pollard','Alex Beizerov','analyst profitect','APS Technology','BRETT CAMPBELL','BRIAN ITTNER'
		,'DEREK LANNI','GARY MONAGHAN','Alison Harmon','BILL INZEO','Jim Hare','Investigative Analytics','JACK DONOVAL','JAMES SPENCER','JEFF TOLVA'
		,'JOHN DONOVAL','KIMBERLY GANDY','LAUREN NESTOR','MELISSA VAN DE CARR','RAYMOND NOVAK','RAYMOND STUKEL','SCOTT JONKMAN','RACHEL KAMENIR'
		,'RAY NOVAK','SETH HUGHES','STEPHEN LAMALFA','Zebra Analysts','TAL HAREL','ANTHONY NGUYEN')
		AND o.ASSIGNEE NOT LIKE '%KEN O''CONNOR%' AND o.ASSIGNEE NOT LIKE '%KENNETH O''CONNOR%' 
		AND o.EMP_NUMBER_OWNER NOT IN ('4116158','IITeam') AND o.EMP_NUMBER_OWNER NOT LIKE '%duguay%' -- Tim confirmed 9.9.2021 to REMOVE (EMP_NUMBER_OWNER = 4116158) and ADD ('SteeringCommittee')
		AND o.[OWNER] NOT LIKE '%NOVAK%' AND o.[OWNER] NOT LIKE '%Molly Pollard%'
	GROUP BY 
		o.OPP_ID,o.SUMMARY,o.OPP_STATUS,o.OPP_RESOLUTION,o.OPP_VALUE,o.ASSIGNEE,o.PATTERN_NAME
		,o.EMP_NUMBER_ASSIGNEE,o.[OWNER],o.EMP_NUMBER_OWNER,o.LABELS,o.DATE_INSERTED,o.OPP_GENERATED_TIME
/*
	ORDER BY 
		o.OPP_ID 
		,CASE 
			WHEN o.OPP_STATUS = 'New' THEN 1 
			WHEN o.OPP_STATUS = 'In progress' THEN 2 
			WHEN o.OPP_STATUS LIKE 'Resolved - %' THEN 3 
				ELSE 9 
			END
		,MIN_LAST_MODIFIED; */
		) TEST

/*
-- Below was previous attempt at trying to create one big query with PATTERN CENTRIC + LOCATION data
SELECT
	o.OPP_ID AS Opportunity
	,o.SUMMARY AS Summary
	,o.OPP_STATUS AS [Status]
	,o.OPP_RESOLUTION AS Resolution
	,o.OPP_VALUE AS [Value]
--	,REGION_INFO.NAME + ' (' + RIGHT('00000' + CAST(REGION_INFO.LOC_NUM AS varchar),5) + ')' Region
	,RIGHT('00000' + CAST(REGION_INFO.LOC_NUM AS varchar),5) AS Region_Num
	,REGION_INFO.NAME AS Region
--	,AREA_INFO.NAME + ' (' + RIGHT('00000' + CAST(AREA_INFO.LOC_NUM AS varchar),5) + ')' Area
	,RIGHT('00000' + CAST(AREA_INFO.LOC_NUM AS varchar),5) AS Area_Num
	,AREA_INFO.NAME AS Area
--	,DISTRICT_INFO.NAME + ' (' + RIGHT('00000' + CAST(DISTRICT_INFO.LOC_NUM AS varchar),5) + ')' District
	,RIGHT('00000' + CAST(DISTRICT_INFO.LOC_NUM AS varchar),5) AS District_Num
	,DISTRICT_INFO.NAME AS District
--	,RIGHT('00000' + CAST(STORE_INFO.LOC_NUM AS varchar),5) + ' - ' + STORE_INFO.CITY + ' ' + STORE_INFO.ADDRESS_LINE_1 + ' ' + STORE_INFO.STATE AS Store
	,RIGHT('00000' + CAST(STORE_INFO.LOC_NUM AS varchar),5) AS Store_Num
	,STORE_INFO.CITY + ' ' + STORE_INFO.ADDRESS_LINE_1 + ' ' + STORE_INFO.STATE AS Store
	,SUBSTRING(o.PATTERN_NAME, 1, PATINDEX('% %',REPLACE(o.PATTERN_NAME,'CP - ',''))+LEN('CP - ')) AS PATTERN_CODE
	,o.OPPORTUNITY_ENTITY AS Entity
	,o.ASSIGNEE AS Assignee
	,o.EMP_NUMBER_ASSIGNEE
	,o.EMP_NUMBER_OWNER
	,o.[OWNER]
	,o.OPP_CLASSIFICATION AS Classification
	,CASE
		WHEN LEFT(o.OPP_STATUS,8) LIKE 'Resolved' THEN o.LAST_MODIFIED
		ELSE NULL
		END AS ClosedDate
--	,pcom.COMMENT AS Comment
--	,o.LABELS
	,o.OPP_GENERATED_TIME AS CreatedDate
	,MIN(o.LAST_MODIFIED) MIN_LAST_MODIFIED
	,o.DATE_INSERTED
FROM (
	SELECT
		OPP_ID
--		,DATE_INSERTED
		,MIN(LAST_MODIFIED) MIN_LAST_MODIFIED
	FROM i2_data.dbo.PROFITECT_OPPORTUNITIES
	WHERE 
		OPP_STATUS NOT IN ('HISTORY','Deleted')
		AND SUMMARY NOT LIKE 'Welcome to%'
		AND DATE_INSERTED BETWEEN '2020-03-01 00:00:00.001' AND GETDATE() -- Tim confirmed 6.30.2021 that FQ2 2020 (Feb 2020) is not needed
		AND ASSIGNEE NOT IN ('Molly Pollard','Alex Beizerov','analyst profitect','APS Technology','BRETT CAMPBELL','BRIAN ITTNER'
		,'DEREK LANNI','GARY MONAGHAN','Alison Harmon','BILL INZEO','Jim Hare','Investigative Analytics','JACK DONOVAL','JAMES SPENCER','JEFF TOLVA'
		,'JOHN DONOVAL','KIMBERLY GANDY','LAUREN NESTOR','MELISSA VAN DE CARR','RAYMOND NOVAK','RAYMOND STUKEL','SCOTT JONKMAN','RACHEL KAMENIR'
		,'RAY NOVAK','SETH HUGHES','STEPHEN LAMALFA','Zebra Analysts','TAL HAREL')
		AND ASSIGNEE NOT LIKE '%KEN O''CONNOR%' AND ASSIGNEE NOT LIKE '%KENNETH O''CONNOR%' 
		AND [OWNER] NOT LIKE '%NOVAK%'
	GROUP BY 
		OPP_ID
--		,DATE_INSERTED
		) opp
LEFT OUTER JOIN i2_data.dbo.PROFITECT_OPPORTUNITIES o
	ON opp.opp_id = o.opp_id AND opp.MIN_LAST_MODIFIED = o.LAST_MODIFIED
LEFT OUTER JOIN i2_data.dbo.LOCATION_FLAT_VIEW s
	ON s.NODE_ADDRESS = 'S' + RIGHT(o.[OWNER], 5)
LEFT OUTER JOIN i2_data.dbo.EISB_LP_FEED emp
	ON LEFT(RIGHT(o.OPPORTUNITY_ENTITY, 8),7) = emp.EMP_NUMBER
LEFT OUTER JOIN i2_data.dbo.LOCATION REGION_INFO
	ON REGION_INFO.LOC_TYPE_CODE = 'R' AND emp.ASSIGNED_REGION_# = REGION_INFO.LOC_NUM
LEFT OUTER JOIN i2_data.dbo.LOCATION AREA_INFO
	ON AREA_INFO.LOC_TYPE_CODE = 'A' AND emp.ASSIGNED_AREA_# = AREA_INFO.LOC_NUM
LEFT OUTER JOIN i2_data.dbo.LOCATION DISTRICT_INFO
	ON DISTRICT_INFO.LOC_TYPE_CODE = 'D' AND emp.ASSIGNED_DISTRICT_# = DISTRICT_INFO.LOC_NUM
LEFT OUTER JOIN i2_data.dbo.LOCATION STORE_INFO
	ON STORE_INFO.LOC_TYPE_CODE = 'S' AND emp.WORK_LOC_NUM = STORE_INFO.LOC_NUM
GROUP BY
	o.OPP_ID,o.SUMMARY,o.OPP_STATUS,o.OPP_RESOLUTION,o.OPP_VALUE
	,REGION_INFO.LOC_NUM,REGION_INFO.NAME,AREA_INFO.LOC_NUM
	,AREA_INFO.NAME,DISTRICT_INFO.LOC_NUM,DISTRICT_INFO.NAME
	,STORE_INFO.LOC_NUM,STORE_INFO.CITY,STORE_INFO.ADDRESS_LINE_1,STORE_INFO.STATE
	,o.PATTERN_NAME,o.OPPORTUNITY_ENTITY,o.ASSIGNEE,o.EMP_NUMBER_ASSIGNEE,o.DATE_INSERTED
	,o.EMP_NUMBER_OWNER,o.[OWNER],o.OPP_CLASSIFICATION,o.OPP_GENERATED_TIME,o.LAST_MODIFIED
ORDER BY 
	o.OPP_ID 
	,CASE 
		WHEN o.OPP_STATUS = 'New' THEN 1 
		WHEN o.OPP_STATUS = 'In progress' THEN 2 
		WHEN o.OPP_STATUS LIKE 'Resolved - %' THEN 3 
		ELSE 9 
	END
	,MIN_LAST_MODIFIED;

-- Comments >> STAR SCHEMA -- This was initial Comments query. Replace with above to only have OPP_ID from the alerts we are using, not trying to bring in all alerts as previous
SELECT 
	pcom.OPP_ID
	,pcom.COMMENT
	,pcom.COMMENT_TIMESTAMP
	,pcom.DATE_INSERTED
FROM i2_data.dbo.PROFITECT_OPPORTUNITY_COMMENTS pcom

-- Below was previous location query. Updated with above bc it below was slower to run vs the query above
SELECT DISTINCT
	DISTRICT_NUMBER
	,District
	,STORE_NUMBER
	,Store
FROM (
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
--	ORDER BY 
--		DISTRICT_NUMBER,District;
) TEST
ORDER BY 1;
	*/