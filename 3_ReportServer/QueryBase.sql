SELECT
    c.ItemID,
    c.Name AS ReportName,
    c.Type,
    el.ItemPath, -- Chemin d'exécution du rapport
    SUBSTRING(                              
        c.Path,
        2,
        CASE 
            WHEN CHARINDEX('/', c.Path, 2) > 0 
                THEN CHARINDEX('/', c.Path, 2) - 2
            ELSE LEN(c.Path)
        END
    ) AS GroupA,
    el.UserName,
    CONVERT(date, el.TimeStart) AS ExecDate, -- Date d'exécution (sans l'heure)
    COUNT(*) AS [NumberOfExecutions], -- Nombre total d'exécutions
    MIN(el.TimeStart) AS MinTimeStart, -- Heure la plus tôt de début
    MAX(el.TimeEnd) AS MaxTimeEnd, -- Heure la plus tardive de fin
    AVG(DATEDIFF(SECOND, el.TimeStart, el.TimeEnd)) AS [AvgExecutionTimeSec], -- Durée moyenne
    MIN(DATEDIFF(SECOND, el.TimeStart, el.TimeEnd)) AS [MinExecutionTimeSec], -- Durée la plus courte
    MAX(DATEDIFF(SECOND, el.TimeStart, el.TimeEnd)) AS [MaxExecutionTimeSec]
-- Durée la plus longue
FROM ReportServer.dbo.ExecutionLog3 el
    LEFT JOIN ReportServer.dbo.Catalog c
    ON el.ItemPath = c.Path
WHERE 
    el.RequestType <> 'Refresh Cache' -- Exclut les exécutions liées au cache
    AND el.ItemAction IN ('Execute', 'Render', 'DataRefresh', 'ASModelStream') -- Actions réelles d'exécution
    AND c.Type IN (2, 13)
-- Type du rapport (2 = paginé, 13 = Power BI)
GROUP BY 
    c.ItemID, c.Name, c.Type, el.ItemPath, el.UserName, CONVERT(date, el.TimeStart),
    SUBSTRING(                              
        c.Path,
        2,
        CASE 
            WHEN CHARINDEX('/', c.Path, 2) > 0 
                THEN CHARINDEX('/', c.Path, 2) - 2
            ELSE LEN(c.Path)
        END
    )
