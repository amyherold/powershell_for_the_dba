select 'select * from '+name,* from sys.tables




-------script 1
select * from Groups
select * from ServerGroups
select * from ServerList
select * from ServerUsers
select * from UserLogins


-------script 2
select * from Groups--------------------groups added
select * from ADGroupMembers
order by 2
select * from GroupRelationships


select * from GroupRelationships
where groupid = parentid


delete from GroupRelationships
where id = 9


select * from Groups
