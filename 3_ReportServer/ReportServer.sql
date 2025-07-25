SELECT
    el.TimeStart AS [Execution Start],
    el.TimeEnd AS [Execution End],
    DATEDIFF(SECOND, el.TimeStart, el.TimeEnd) AS [Execution Duration (sec)],
    el.ItemPath AS [Report Name/Path],
    el.UserName AS [Executed By],
    el.RequestType,
    el.Format,
    CASE
        WHEN el.RequestType = 'Interactive' AND (el.Format IS NULL OR el.Format = 'MHTML') THEN 'Viewed in Portal'
        WHEN el.RequestType = 'Interactive' AND el.Format IN ('EXCELOPENXML','PDF','CSV','WORDOPENXML','PPTX','XML','DataModel','PBIX','RPL') THEN 'Exported'
        WHEN el.RequestType = 'Subscription' THEN 'Subscription Delivery'
        WHEN el.RequestType = 'Refresh Cache' THEN 'Cache Refresh'
        ELSE 'Other'
    END AS [ActionType]
FROM
    ReportServer.dbo.ExecutionLog3 el
WHERE
    el.TimeStart >= DATEADD(DAY, -30, GETDATE())
-- Last 30 days; adjust as needed
ORDER BY
    el.TimeStart DESC



select [RequestType], [Format] , count(*)
FROM
    ReportServer.dbo.ExecutionLog3 el
group by [RequestType], [Format]
order by [RequestType], [Format]



---========###############average execution############

SELECT
    el.ItemPath AS [Report Name/Path],
    COUNT(*) AS [Number of Executions],
    AVG(DATEDIFF(SECOND, el.TimeStart, el.TimeEnd)) AS [Average Execution Time (sec)],
    MIN(DATEDIFF(SECOND, el.TimeStart, el.TimeEnd)) AS [Min Execution Time (sec)],
    MAX(DATEDIFF(SECOND, el.TimeStart, el.TimeEnd)) AS [Max Execution Time (sec)]
FROM
    ReportServer.dbo.ExecutionLog3 el
WHERE
    -- el.TimeStart >= DATEADD(DAY, -30, GETDATE()) -- Last 30 days; adjust as needed
    -- AND 
    el.Status = 'rsSuccess'
-- Only successful executions
GROUP BY
    el.ItemPath
ORDER BY
    [Average Execution Time (sec)] DESC



---select * from [RDL00001_EnterpriseDataLanding].[JDE_BI_OPS].[V_V0101]


select *
from [RDL00001_EnterpriseDataLanding].[JDE_BI_OPS].[V_V0101]


SELECT
    el.TimeStart AS [Execution Start],
    el.TimeEnd AS [Execution End],
    DATEDIFF(SECOND, el.TimeStart, el.TimeEnd) AS [Execution Duration (sec)],
    el.RequestType AS [Execution Type],
    el.UserName AS [Executed By],
    el.ItemPath AS [Report Name/Path],
    el.Format AS [Export Format]
FROM
    ReportServer.dbo.ExecutionLog3 el
WHERE
    el.TimeStart >= DATEADD(DAY, -30, GETDATE())
-- Last 30 days; adjust as needed
ORDER BY
    el.TimeStart DESC

