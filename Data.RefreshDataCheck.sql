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
		,'RAY NOVAK','SETH HUGHES','STEPHEN LAMALFA','Zebra Analysts','TAL HAREL','SCOTT MCMULLEN','MICHAEL OADDAMS','JAMES MORRIS','MIKE ROSSI','JIM MORRIS JR','STEPHEN BASUMATARY'
		,'ANTHONY NGUYEN','EKATERINA REVENYUK','SEMETRIUS CANNEDY','SARA MARTEL','BRANDON CAMPBELL','DAMARIS VILLA','ANIL KUMAR SAMPATH KUMAR','MALATHI BABU','TEJASWINI B L','Bhuvaneshwari R')
		AND o.ASSIGNEE NOT LIKE '%KEN O''CONNOR%' AND o.ASSIGNEE NOT LIKE '%KENNETH O''CONNOR%' 
		AND o.EMP_NUMBER_OWNER NOT IN ('4116158','IITeam') AND o.EMP_NUMBER_OWNER NOT LIKE '%duguay%' -- Tim confirmed 9.9.2021 to REMOVE (EMP_NUMBER_OWNER = 4116158) and ADD ('SteeringCommittee')
		AND o.[OWNER] NOT IN ('Molly Pollard','RAY NOVAK','RAYMOND NOVAK','SEMETRIUS CANNEDY','ANTHONY NGUYEN','EKATERINA REVENYUK','SARA MARTEL','BRANDON CAMPBELL','DAMARIS VILLA'
		,'ANIL KUMAR SAMPATH KUMAR','MALATHI BABU','TEJASWINI B L','Alex Beizerov','STEPHEN BASUMATARY','Bhuvaneshwari R')
		AND o.OPP_ID NOT IN ('2565116','2565168') -- Tim confirmed removal 3.6.2023 bc it is inflating Completed values
	--	AND o.[OWNER] NOT LIKE '%NOVAK%' AND o.[OWNER] NOT LIKE '%Molly Pollard%'
	GROUP BY 
		o.OPP_ID,o.SUMMARY,o.OPP_STATUS,o.OPP_RESOLUTION,o.OPP_VALUE,o.ASSIGNEE,o.PATTERN_NAME,o.OPPORTUNITY_ENTITY
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
		,MIN_LAST_MODIFIED; 
		*/
		) TEST