WITH DirectReports (parentID, groupID, [sum], code, code2, /*code3,*/ [Level], parent_name, group_name)
AS
(
-- Anchor member definition
    SELECT e.parentid
	, e.groupid
	, e.groupid as [sum]
	, CAST(CAST(e.parentid AS VARCHAR) + ', ' + CAST(e.groupid AS VARCHAR) AS VARCHAR(255)) as code
	, CAST(CAST(gp.group_name AS VARCHAR) + '---->' + CAST(gg.group_name AS VARCHAR) AS VARCHAR(255)) as code2
	--, CAST(gp.group_name AS VARCHAR) as code3
	--,cast(e.groupID as varchar(255)) as code
    ,0 AS Level
	,gp.group_name as parent_name
	,gg.group_name
    FROM GroupRelationships AS e
	left outer join GroupRelationships e2 on e.parentid = e2.groupid
	left outer join Groups gp on e.parentid = gp.id
	left outer join Groups gg on e.groupid = gg.id 
	where 1=1 
	--and e2.parentid is null
	and e.parentid in (select distinct group_id from ServerGroups
					where 1=1
					and sysadmin = 1)
    UNION ALL
-- Recursive member definition
    SELECT e.parentID as parentid
	, e.groupID as groupid
	, [sum] + e.groupid as [Sum]
	, CAST(code + ', ' + cast(e.groupid AS VARCHAR) AS VARCHAR(255)) as code
	, CAST(code2 + '---->' + cast(gg.group_name AS VARCHAR) AS VARCHAR(255)) as code2
	--, CAST(code3 + '---->' + cast(gg.group_name AS VARCHAR) AS VARCHAR) as code3
	--,cast(d.parentid as varchar(255)) + '  ' + cast(e.groupID as varchar(255)) as code
	--,concat(d.parentid,'  ',e.groupID) as code
	,Level + 1
	,d.parent_name
	,gg.group_name
    FROM GroupRelationships AS e
	join Groups gg on e.groupid = gg.id
	--left outer join Groups gp on e.parentid = gp.id
	--left outer join Groups gg on e.groupid = gg.id 
    INNER JOIN DirectReports AS d ON e.parentID = d.groupID
)
select *-- distinct
	--groupid
from DirectReports
where 1=1 
--and groupID in (select distinct group_id from ServerGroups
--					where 1=1
--					and sysadmin = 1)
--or groupID in (16,17,20,33,34))
--where code like '%12%'
--order by 2, 1
