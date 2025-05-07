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
-- Below was previous List of all stores + location data
-- Replaced with above query bc LOCATION table was flattened to PODS (LOC_TYPE_CODE = 'F')
	-- New Hierarchy = Operations > Region > Area > Pod > District > Store
-- Was previously updated to join active APMs but removed bc there could be active stores that do not have APM currently assigned
	-- If I kept this same, we would be missing stores that have are valid and active
-- Updated to exclude PARENT_LOCATION_NUMBER = 199 
		-- 199 is code for store "Closed/Dead"
SELECT 
	r.LOC_NUM AS REGION_NUMBER
	,CONCAT(r.[NAME], ' (', r.LOC_NUM, ')' ) AS REGION
	,a.LOC_NUM AS AREA_NUMBER
	,CONCAT(a.[NAME], ' (', a.LOC_NUM, ')' ) AS AREA
	,d.LOC_NUM AS DISTRICT_NUMBER
	,CONCAT(d.[NAME], ' (', d.LOC_NUM, ')' ) AS DISTRICT
	,s.LOC_NUM AS STORE_NUMBER
	,CONCAT(FORMAT(s.LOC_NUM,'00000'),' - ',s.CITY,', ',s.ADDRESS_LINE_1,', ',s.[STATE]) AS Store
FROM i2_Data.dbo.LOCATION s
--LEFT OUTER JOIN i2_Data.dbo.ATLAS_CONTACTS apm
--	ON apm.NODE_ADDRESS = s.NODE_ADDRESS
LEFT OUTER JOIN i2_Data.dbo.LOCATION d
	ON s.PARENT_LOCATION_NUMBER = d.LOC_NUM AND s.PARENT_LOCATION_TYPE_CODE = d.LOC_TYPE_CODE
LEFT OUTER JOIN i2_Data.dbo.LOCATION a
	ON d.PARENT_LOCATION_NUMBER = a.LOC_NUM AND d.PARENT_LOCATION_TYPE_CODE = a.LOC_TYPE_CODE
LEFT OUTER JOIN i2_Data.dbo.LOCATION r
	ON a.PARENT_LOCATION_NUMBER = r.LOC_NUM AND a.PARENT_LOCATION_TYPE_CODE = r.LOC_TYPE_CODE
WHERE
	s.LOC_TYPE_CODE = 'S'
--	AND apm.POC_APM_EMP_NUM IS NOT NULL
--	AND s.OPEN_DATE IS NOT NULL
--	AND s.CLOSE_DATE IS NULL
	AND s.PARENT_LOCATION_NUMBER <> 199 -- PARENT_LOCATION_NUMBER = 199 is the code for store "Closed/Dead"
	;

-- Below was previous location query but updated bc there are stores that were not being captured for other projects
	-- Other projects EX: BinaxNow + Theragun
SELECT DISTINCT	
	CAST(LEFT(o.OPPORTUNITY_ENTITY, 5) AS int) AS store_num
	,CONCAT(l.REGION_NAME,' ', l.REGION_NUMBER) AS REGION
	,CONCAT(l.AREA_NAME,' ', l.AREA_NUMBER) AS AREA
	,CONCAT(l.DISTRICT_NAME,' ', l.DISTRICT_NUMBER) AS DISTRICT
	,CONCAT(l.LOC_NUM,' - ',l.CONCATENATED_ADDRESS) AS LOCATION
	,o.OPPORTUNITY_ENTITY
FROM i2_data.dbo.PROFITECT_OPPORTUNITIES o
LEFT OUTER JOIN i2_Data.dbo.PROFITECT_USERS_FILE u
	ON CAST(LEFT(o.OPPORTUNITY_ENTITY, 5) AS int) = CAST(u.Last_Name AS int)
LEFT OUTER JOIN i2_Data.dbo.PROFITECT_STORE_ROLLOUT_PHASES_VIEW p
	ON CAST(LEFT(o.OPPORTUNITY_ENTITY, 5) AS int) = p.LOC_NUM
LEFT OUTER JOIN i2_Data.dbo.LOCATION_FLAT_VIEW l
	ON p.LOC_NUM = l.LOC_NUM AND l.LOC_TYPE_CODE = 'S'
WHERE 
	o.OPP_STATUS <> 'HISTORY' AND o.OPP_STATUS <> 'Deleted'
	AND o.PATTERN_NAME = 'CP - 545 Welcome to ZPA'
	AND p.LOC_NUM IN (
					SELECT DISTINCT CAST(LEFT(o.OPPORTUNITY_ENTITY, 5) AS int) AS list_of_stores
					FROM i2_data.dbo.PROFITECT_OPPORTUNITIES o
					WHERE o.PATTERN_NAME = 'CP - 545 Welcome to ZPA'
						)
	AND p.PHASE NOT LIKE '%Closed%'
GROUP BY
	o.OPP_ID,p.PHASE,o.PATTERN_NAME,o.OPP_STATUS,o.OPPORTUNITY_ENTITY -- Tried getting rid of this line but it was taking too long to run, so kept it
	,CONCAT(l.REGION_NAME,' ', l.REGION_NUMBER),CONCAT(l.AREA_NAME,' ', l.AREA_NUMBER)
	,CONCAT(l.DISTRICT_NAME,' ', l.DISTRICT_NUMBER),CONCAT(l.LOC_NUM,' - ',l.CONCATENATED_ADDRESS)
ORDER BY 
	CAST(LEFT(o.OPPORTUNITY_ENTITY, 5) AS int) --AS store_num
	;
*/