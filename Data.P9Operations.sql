-- Previously only 5 Shrink Patterns ("CP - 711","CP - 717","CP - 753","CP - 760","CP - 814")
    -- Opened up to all Shrink Patterns as of 2025.01.06 by Tim
WITH pattern_code AS (
	SELECT VALUE
	FROM (
		VALUES ('CP - 116'), ('CP - 255'), ('CP - 544'), ('CP - 604'), ('CP - 609'), ('CP - 711'), ('CP - 703')
			, ('CP - 680'), ('CP - 712'), ('CP - 713'), ('CP - 717'), ('CP - 724'), ('CP - 760'), ('CP - 731')
			, ('CP - 743'), ('CP - 768'), ('CP - 774'), ('CP - 777'), ('CP - 779'), ('CP - 759'), ('CP - 753')
			, ('CP - 804'), ('CP - 803'), ('CP - 798'), ('CP - 761'), ('CP - 848'), ('CP - 814'), ('CP - 702')
			, ('CP - 845'), ('CP - 838')
		) V(VALUE)
	)

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
			WHEN o.[OWNER] LIKE '%store manager%' THEN CAST( RIGHT(o.[OWNER], 5) AS int )
			WHEN LEFT(o.OPPORTUNITY_ENTITY, 7) LIKE '% -%' THEN CAST( LEFT(o.OPPORTUNITY_ENTITY, 5) AS int )
		END AS Store_Number
	,o.OPPORTUNITY_ENTITY
	,o.[OWNER]
	,o.LABELS
	,o.OPP_GENERATED_TIME AS CreatedDate 
	,MIN(o.LAST_MODIFIED) MIN_LAST_MODIFIED
	,o.DATE_INSERTED
FROM i2_data.dbo.PROFITECT_OPPORTUNITIES o
WHERE
	EXISTS (
		SELECT TOP 1 1
		FROM pattern_code
		WHERE
			PATTERN_NAME LIKE pattern_code.VALUE + '%' 
			)
	AND OPP_STATUS NOT IN ('History','HISTORY','Deleted')
	AND SUMMARY NOT LIKE 'Welcome to%'
	AND DATE_INSERTED BETWEEN '2020-03-01 00:00:00.001' AND GETDATE() 
	AND OPP_GENERATED_TIME BETWEEN '2020-03-01 00:00:00.001' AND GETDATE() 
	AND EMP_NUMBER_ASSIGNEE NOT IN ('4118541','4118551','analyst@profitect.com','9999999','1959518','1432914','2634721','1950877','1440795','1445805','jim.hare'
		,'1224862','2982027','2251383','1224862','1222234','2488189','1224384','1223749','2013702','1062954','2223799','4043932','2246468','2860864','IITeam'
		,'1185165','4546396','4234682','1863183','1325015','4255465','4256323','1448552','4546413','4546391','4546246','4546399','2589783','4639125')
	AND EMP_NUMBER_OWNER NOT IN ('4116158','4459658','amanda.duguay@zebra.com','1223749','4546246','4546396','4118541','1325015','1863183') 
	AND ASSIGNEE NOT IN ('Zebra Analysts')
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
	,MIN_LAST_MODIFIED
	; 

-- Pattern Group >> Patterns and their recipient groups from ZPA >> WILL HAVE TO BE MAINTAINED!!!!
-- Previously only 5 Shrink Patterns ("CP - 711","CP - 717","CP - 753","CP - 760","CP - 814")
    -- Opened up to all Shrink Patterns as of 2025.01.06 by Tim
WITH pattern_code AS (
	SELECT VALUE
	FROM (
		VALUES ('CP - 116'), ('CP - 255'), ('CP - 544'), ('CP - 604'), ('CP - 609'), ('CP - 711'), ('CP - 703')
			, ('CP - 680'), ('CP - 712'), ('CP - 713'), ('CP - 717'), ('CP - 724'), ('CP - 760'), ('CP - 731')
			, ('CP - 743'), ('CP - 768'), ('CP - 774'), ('CP - 777'), ('CP - 779'), ('CP - 759'), ('CP - 753')
			, ('CP - 804'), ('CP - 803'), ('CP - 798'), ('CP - 761'), ('CP - 848'), ('CP - 814'), ('CP - 702')
			, ('CP - 845'), ('CP - 838')
		) V(VALUE)
	)

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
WHERE
	EXISTS (
		SELECT TOP 1 1
		FROM pattern_code
		WHERE
			pg.PATTERN_CODE LIKE pattern_code.VALUE + '%' 
			)
ORDER BY
	1 DESC
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

-- Below query list APMs employee ID + the Districts they are assigned to for EPIQ Alerts
SELECT DISTINCT -- Updated 2024.06.10 bc duplicate EMP_NUMBER = 1828676 
	apm.EMP_NUMBER
	,apm.GROUP_NAMES
	,RESPONSIBILITY_VALUE AS APM_Assigned_Districts
FROM i2_Data.dbo.PROFITECT_USERS_APM apm
	;

-- Comments >> STAR SCHEMA 
-- Updated to only bring in OPP_ID from the alerts we are using, not trying to bring in all alerts as previous
WITH pattern_code AS (
	SELECT VALUE
	FROM (
		VALUES ('CP - 116'), ('CP - 255'), ('CP - 544'), ('CP - 604'), ('CP - 609'), ('CP - 711'), ('CP - 703')
			, ('CP - 680'), ('CP - 712'), ('CP - 713'), ('CP - 717'), ('CP - 724'), ('CP - 760'), ('CP - 731')
			, ('CP - 743'), ('CP - 768'), ('CP - 774'), ('CP - 777'), ('CP - 779'), ('CP - 759'), ('CP - 753')
			, ('CP - 804'), ('CP - 803'), ('CP - 798'), ('CP - 761'), ('CP - 848'), ('CP - 814'), ('CP - 702')
			, ('CP - 845'), ('CP - 838')
		) V(VALUE)
	)

SELECT DISTINCT
	pcom.OPP_ID
	,pcom.COMMENT
	,pcom.COMMENT_TIMESTAMP
--	,pcom.DATE_INSERTED
FROM i2_data.dbo.PROFITECT_OPPORTUNITY_COMMENTS pcom
WHERE pcom.OPP_ID IN (
	-- Below is the query being used for alerts. Just removed all the other columns for query requirements
	-- Previously only 5 Shrink Patterns ("CP - 711","CP - 717","CP - 753","CP - 760","CP - 814")
		-- Opened up to all Shrink Patterns as of 2025.01.06 by Tim
	SELECT 		
		o.OPP_ID
	FROM i2_data.dbo.PROFITECT_OPPORTUNITIES o
	WHERE
		EXISTS (
			SELECT TOP 1 1
			FROM pattern_code
			WHERE
				o.PATTERN_NAME LIKE pattern_code.VALUE + '%' 
				)
		AND o.OPP_STATUS NOT IN ('HISTORY','Deleted')
		AND o.SUMMARY NOT LIKE 'Welcome to%'
		AND o.DATE_INSERTED BETWEEN '2020-03-01 00:00:00.001' AND GETDATE() 
		AND o.OPP_GENERATED_TIME BETWEEN '2020-03-01 00:00:00.001' AND GETDATE()
		AND o.EMP_NUMBER_ASSIGNEE NOT IN ('4118541','4118551','analyst@profitect.com','9999999','1959518','1432914','2634721','1950877','1440795','1445805','jim.hare'
			,'1224862','2982027','2251383','1224862','1222234','2488189','1224384','1223749','2013702','1062954','2223799','4043932','2246468','2860864','IITeam'
			,'1185165','4546396','4234682','1863183','1325015','4255465','4256323','1448552','4546413','4546391','4546246','4546399','2589783','4639125')
		AND o.EMP_NUMBER_OWNER NOT IN ('4116158','4459658','amanda.duguay@zebra.com','1223749','4546246','4546396','4118541','1325015','1863183') 
		AND o.ASSIGNEE NOT IN ('Zebra Analysts')
	GROUP BY 
		o.OPP_ID
		) 
ORDER BY 
	pcom.OPP_ID
	,pcom.COMMENT_TIMESTAMP
	;


/*
-- Below was previous main query
	-- Replaced with above bc patterns were expanded to be included
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
			WHEN o.[OWNER] LIKE '%store manager%' THEN CAST( RIGHT(o.[OWNER], 5) AS int )
			WHEN LEFT(o.OPPORTUNITY_ENTITY, 7) LIKE '% -%' THEN CAST( LEFT(o.OPPORTUNITY_ENTITY, 5) AS int )
		END AS Store_Number
	,o.OPPORTUNITY_ENTITY
	,o.[OWNER]
	,o.LABELS
	,o.OPP_GENERATED_TIME AS CreatedDate 
	,MIN(o.LAST_MODIFIED) MIN_LAST_MODIFIED
	,o.DATE_INSERTED
FROM i2_data.dbo.PROFITECT_OPPORTUNITIES o
WHERE 
	o.OPP_STATUS NOT IN ('HISTORY','Deleted')
	AND o.SUMMARY NOT LIKE 'Welcome to%'
	AND o.DATE_INSERTED BETWEEN '2020-03-01 00:00:00.001' AND GETDATE() 
	AND o.OPP_GENERATED_TIME BETWEEN '2020-03-01 00:00:00.001' AND GETDATE() 
	AND o.EMP_NUMBER_ASSIGNEE NOT IN ('4118541','4118551','analyst@profitect.com','9999999','1959518','1432914','2634721','1950877','1440795','1445805','jim.hare'
		,'1224862','2982027','2251383','1224862','1222234','2488189','1224384','1223749','2013702','1062954','2223799','4043932','2246468','2860864','IITeam'
		,'1185165','4546396','4234682','1863183','1325015','4255465','4256323','1448552','4546413','4546391','4546246','4546399','2589783','4639125')
	AND o.EMP_NUMBER_OWNER NOT IN ('4116158','4459658','amanda.duguay@zebra.com','1223749','4546246','4546396','4118541','1325015','1863183') 
	AND o.ASSIGNEE NOT IN ('Zebra Analysts')
--	AND o.PATTERN_NAME IN ('CP - 711 Investigative: Cash Discrepancy','CP - 717 Investigative: Cash Deposit Variance','CP - 753 Investigative: Cash Discrepancy (Cashier details)','CP - 760 Cash Deposit Variance ','CP - 814 Investigative: High Dollar Value Hard Keyed Manufacturer Coupons')
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
	,MIN_LAST_MODIFIED
	; 

-- Pattern Group >> Patterns and their recipient groups from ZPA >> WILL HAVE TO BE MAINTAINED!!!!
	-- Replaced with above bc patterns were expanded to be included
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
--WHERE
	-- Previously only 5 Shrink Patterns ("CP - 711","CP - 717","CP - 753","CP - 760","CP - 814")
		-- Opened up to all Shrink Patterns as of 2025.01.06 by Tim
--	pg.PATTERN_CODE IN ('CP - 711','CP - 717','CP - 753','CP - 760')
ORDER BY
	1 DESC
	;

-- Comments >> STAR SCHEMA 
-- Updated to only bring in OPP_ID from the alerts we are using, not trying to bring in all alerts as previous
SELECT DISTINCT
	pcom.OPP_ID
	,pcom.COMMENT
	,pcom.COMMENT_TIMESTAMP
--	,pcom.DATE_INSERTED
FROM i2_data.dbo.PROFITECT_OPPORTUNITY_COMMENTS pcom
WHERE pcom.OPP_ID IN (
	-- Below is the query being used for alerts. Just removed all the other columns for query requirements
	-- Previously only 5 Shrink Patterns ("CP - 711","CP - 717","CP - 753","CP - 760","CP - 814")
		-- Opened up to all Shrink Patterns as of 2025.01.06 by Tim
	SELECT 		
		o.OPP_ID
	FROM i2_data.dbo.PROFITECT_OPPORTUNITIES o
	WHERE 
		o.OPP_STATUS NOT IN ('HISTORY','Deleted')
		AND o.SUMMARY NOT LIKE 'Welcome to%'
		AND o.DATE_INSERTED BETWEEN '2020-03-01 00:00:00.001' AND GETDATE() 
		AND o.OPP_GENERATED_TIME BETWEEN '2020-03-01 00:00:00.001' AND GETDATE()
		AND o.EMP_NUMBER_ASSIGNEE NOT IN ('4118541','4118551','analyst@profitect.com','9999999','1959518','1432914','2634721','1950877','1440795','1445805','jim.hare'
			,'1224862','2982027','2251383','1224862','1222234','2488189','1224384','1223749','2013702','1062954','2223799','4043932','2246468','2860864','IITeam'
			,'1185165','4546396','4234682','1863183','1325015','4255465','4256323','1448552','4546413','4546391','4546246','4546399','2589783','4639125')
		AND o.EMP_NUMBER_OWNER NOT IN ('4116158','4459658','amanda.duguay@zebra.com','1223749','4546246','4546396','4118541','1325015','1863183') 
		AND o.ASSIGNEE NOT IN ('Zebra Analysts')
--		AND o.PATTERN_NAME IN ('CP - 711 Investigative: Cash Discrepancy','CP - 717 Investigative: Cash Deposit Variance','CP - 753 Investigative: Cash Discrepancy (Cashier details)','CP - 760 Cash Deposit Variance ')
	GROUP BY 
		o.OPP_ID
		) 
ORDER BY 
	pcom.OPP_ID
	,pcom.COMMENT_TIMESTAMP
	;

-- Below was previous location query
	-- Replaced with above bc it is more accurate and includes PODs
-- Below query is a list of all stores + location data >> updated this query bc this one is so much faster to run vs the previous
SELECT DISTINCT
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
	;