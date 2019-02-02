<#
Name: get groups and users from sql server instances.ps1
Author: Amy Herold
Purpose: Query a CMS instance, connect to each sql server instance and pull group and user information and write to a table.

Notes:
Using connection test from the following - 
https://www.sqlhammer.com/powershell-sql-connection-test/

#>



#--------------------get all the servers from the cms-------------------------
$servers = New-Object System.Collections.ArrayList;
$servers.Clear();
$cms_server = 'SQLKITTENDB';
$groupaccessdb = 'GroupAccess13';

$good_servers = New-Object System.Collections.ArrayList
$good_servers.Clear();


$data_array = New-Object System.Collections.ArrayList
$data_array.Clear();

$user_data_array = New-Object System.Collections.ArrayList
$user_data_array.Clear();

#-----------------------------------get list of servers from CMS-------------------------------

<#
$get_cms_servers = 'select @@SERVERNAME AS [SQLInstance] 
union
SELECT distinct s.[server_name] AS [SQLInstance] 
FROM [dbo].[sysmanagement_shared_server_groups_internal] g 
LEFT JOIN [dbo].[sysmanagement_shared_registered_servers_internal] s ON	g.[server_group_id] = s.[server_group_id] 
WHERE g.[server_type] = 0  
AND	g.[is_system_object] = 0';
#>

#-----------------20180323 - updated query to only pull the ones that don't exist in ServerList-----------------
$get_cms_servers = ";with x as (select @@SERVERNAME AS [SQLInstance] 
union
SELECT distinct s.[server_name] AS [SQLInstance]
FROM [dbo].[sysmanagement_shared_server_groups_internal] g 
LEFT JOIN [dbo].[sysmanagement_shared_registered_servers_internal] s ON	g.[server_group_id] = s.[server_group_id]
WHERE g.[server_type] = 0  
AND	g.[is_system_object] = 0)
select x.SQLInstance
from x
left join $groupaccessdb.dbo.ServerList sl on x.SQLInstance = sl.server_name 
where sl.server_name is null";



$group_logins_query = 'select name, sysadmin, securityadmin, serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin from sys.syslogins where isntgroup = 1';

$user_logins_query = 'select name, sysadmin, securityadmin, serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin from sys.syslogins where isntgroup = 0';



#$servers_table_insert = 'insert ServerList (server_name) select distinct server_name from ServerGroups';

#--------------------20180323 - update $servers_table_insert to check and see if the server already exists in serverlist---------------
$servers_table_insert = 'insert ServerList (server_name) 
select distinct sg.server_name
from ServerGroups sg
left outer join serverlist sl on sg.server_name = sl.server_name
where sl.server_name is null';




#$groups_table_insert = 'insert Groups (group_name) select distinct group_name from ServerGroups';


#----------------------20180323 - update $groups_table_insert to see if the group is already in the groups table---------------------
$groups_table_insert = 'insert Groups (group_name)
select distinct sg.group_name
from ServerGroups sg
left outer join groups g on sg.group_name = g.group_name
where g.group_name is null';


#----------------------20180423 - add $users_table_insert---------------------
$users_table_insert = 'insert UserLogins (user_name)
select distinct su.user_name
from ServerUsers su
left outer join UserLogins ul on su.user_name = ul.user_name
where ul.user_name is null';



#-----------------------add serverid and groupid to ServerGroups--------------------------
$update_server_groups = 'update sg
set server_id =  s.id
,group_id = g.id
from ServerGroups sg
left outer join ServerList s on sg.server_name = s.server_name
left outer join Groups g on sg.group_name = g.group_name';


#-----------------------add serverid and userid to ServerUsers--------------------------
$update_server_users = 'update su
set server_id =  s.id
,user_id = ul.id
from ServerUsers su
left outer join ServerList s on su.server_name = s.server_name
left outer join UserLogins ul on su.user_name = ul.user_name';



#####$servers.AddRange(@(Invoke-Sqlcmd -ServerInstance $cms_server -Database msdb -Query $get_cms_servers));


$servers = @('SQLKITTENDB');


#-------------------test the connection for each of the servers in the cms - if connection successful, add to $server_array-------------------
foreach ($s in $servers)
{
    #$name = $s.SQLInstance;
       
 
    $name = $s;
     
 
    #--------------try to connect to the server - if you can, then get the groups------------------------
    $connectionString = "Data Source=$name;Integrated Security=true;Initial Catalog=master;Connect Timeout=30;"
    $sqlConn = new-object ("Data.SqlClient.SqlConnection") $connectionString
    trap
    {
        Write-Host "Cannot connect to $name";
        continue
    }

    $sqlConn.Open()

    if ($sqlConn.State -eq 'Open')
    {
        
        #----------if we can connect to the server then add it to $good_servers---------
        Write-Host "Successfully connected to $name";
        #$good_servers.Add(@($name)) | Out-Null;

        $logins = @(Invoke-Sqlcmd -ServerInstance $name -Database master -Query $group_logins_query);

        $users = @(Invoke-Sqlcmd -ServerInstance $name -Database master -Query $user_logins_query);

        #----------------add all groups to $data_aray - when this is done this will all be written to a single location-----------------
        foreach ($l in $logins)
        {    
            $data_array.Add(@($name,$l.name,$l.sysadmin, $l.securityadmin, $l.serveradmin, $l.setupadmin, $l.processadmin, $l.diskadmin, $l.dbcreator, $l.bulkadmin)) | Out-Null;
        }

        foreach ($u in $users)
        {    
            $user_data_array.Add(@($name,$u.name,$u.sysadmin, $u.securityadmin, $u.serveradmin, $u.setupadmin, $u.processadmin, $u.diskadmin, $u.dbcreator, $u.bulkadmin)) | Out-Null;
        }

        $sqlConn.Close();
    }   
    
}


#-----------------------itterate through $data_array and do table insert to central location---------------------------
for ($d = 0; $d -lt $data_array.Count; $d++)
{

    #Write-Host $data_array[$d][0]'      '$data_array[$d][1]

    <#
    $server_group_insert = 'insert into ServerGroups (server_name, group_name, sysadmin, securityadmin, serveradmin, setupadmin, processadmin 
    , diskadmin, dbcreator, bulkadmin) 
    values ('''+$data_array[$d][0]+''','''+$data_array[$d][1]+''','+$data_array[$d][2]+','+$data_array[$d][3]+','+$data_array[$d][4]+','`
    +$data_array[$d][5]+','+$data_array[$d][6]+','+$data_array[$d][7]+','+$data_array[$d][8]+','+$data_array[$d][9]+')';
    #>
    
    #-----------------20180323 - made this a merge update since there is already data in the table-----------------
    $server_group_insert = 'merge dbo.ServerGroups as target
using (values('''+$data_array[$d][0]+''','''+$data_array[$d][1]+''','+$data_array[$d][2]+','+$data_array[$d][3]+','+$data_array[$d][4]+','`
    +$data_array[$d][5]+','+$data_array[$d][6]+','+$data_array[$d][7]+','+$data_array[$d][8]+','+$data_array[$d][9]+')) as source (server_name, group_name, sysadmin, securityadmin, serveradmin, setupadmin, processadmin 
    , diskadmin, dbcreator, bulkadmin)
	on target.server_name = source.server_name and target.group_name = source.group_name
	when matched then 
	update set sysadmin = source.sysadmin
	, securityadmin = source.securityadmin
	, serveradmin = source.serveradmin
	, setupadmin = source.setupadmin
	, processadmin = source.processadmin
	, diskadmin = source.diskadmin
	, dbcreator = source.dbcreator
	, bulkadmin = source.bulkadmin
	when not matched then
	insert (server_name, group_name, sysadmin, securityadmin, serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin) 
	values (source.server_name, source.group_name, source.sysadmin, source.securityadmin, source.serveradmin
	, source.setupadmin, source.processadmin, source.diskadmin, source.dbcreator, source.bulkadmin);';


    #-----------------20180423 - made this a merge update since there is already data in the table-----------------
    <#
    $server_users_insert = 'merge dbo.ServerUsers as target 
    using (values('''+$user_data_array[$d][0]+''','''+$user_data_array[$d][1]+''','+$user_data_array[$d][2]+','+$user_data_array[$d][3]+','+$user_data_array[$d][4]+','`
    +$user_data_array[$d][5]+','+$user_data_array[$d][6]+','+$user_data_array[$d][7]+','+$user_data_array[$d][8]+','+$user_data_array[$d][9]+')) as source (server_name, user_name, sysadmin, securityadmin, serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin)
	on target.server_name = source.server_name and target.user_name = source.user_name
	when matched then 
	update set sysadmin = source.sysadmin
	, securityadmin = source.securityadmin
	, serveradmin = source.serveradmin
	, setupadmin = source.setupadmin
	, processadmin = source.processadmin
	, diskadmin = source.diskadmin
	, dbcreator = source.dbcreator
	, bulkadmin = source.bulkadmin
    , update_date = CURRENT_TIMESTAMP
	when not matched then
	insert (server_name, user_name, sysadmin, securityadmin, serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin) 
	values (source.server_name, source.user_name, source.sysadmin, source.securityadmin, source.serveradmin
	, source.setupadmin, source.processadmin, source.diskadmin, source.dbcreator, source.bulkadmin);';
#>



    $server_group_insert;
    #$server_users_insert;

    Invoke-Sqlcmd -ServerInstance $cms_server -Database $groupaccessdb -Query $server_group_insert;

    #Invoke-Sqlcmd -ServerInstance $cms_server -Database $groupaccessdb -Query $server_users_insert;

}




#-----------------------itterate through $data_array and do table insert to central location---------------------------
for ($dd = 0; $dd -lt $user_data_array.Count; $dd++)
{


    #-----------------20180423 - made this a merge update since there is already data in the table-----------------
    $server_users_insert = 'merge dbo.ServerUsers as target 
    using (values('''+$user_data_array[$dd][0]+''','''+$user_data_array[$dd][1]+''','+$user_data_array[$dd][2]+','+$user_data_array[$dd][3]+','+$user_data_array[$dd][4]+','`
    +$user_data_array[$dd][5]+','+$user_data_array[$dd][6]+','+$user_data_array[$dd][7]+','+$user_data_array[$dd][8]+','+$user_data_array[$dd][9]+')) as source (server_name, user_name, sysadmin, securityadmin, serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin)
	on target.server_name = source.server_name and target.user_name = source.user_name
	when matched then 
	update set sysadmin = source.sysadmin
	, securityadmin = source.securityadmin
	, serveradmin = source.serveradmin
	, setupadmin = source.setupadmin
	, processadmin = source.processadmin
	, diskadmin = source.diskadmin
	, dbcreator = source.dbcreator
	, bulkadmin = source.bulkadmin
    , update_date = CURRENT_TIMESTAMP
	when not matched then
	insert (server_name, user_name, sysadmin, securityadmin, serveradmin, setupadmin, processadmin, diskadmin, dbcreator, bulkadmin) 
	values (source.server_name, source.user_name, source.sysadmin, source.securityadmin, source.serveradmin
	, source.setupadmin, source.processadmin, source.diskadmin, source.dbcreator, source.bulkadmin);';




    $server_users_insert;


    Invoke-Sqlcmd -ServerInstance $cms_server -Database $groupaccessdb -Query $server_users_insert;

}






#-----------------get a distinct list of good servers recorded to the table ServerList------------------------
<#
for ($g = 0; $g -lt ($good_servers | Measure-Object).Count; $g++)
{
    #$blah2 = $good_servers[$g];
    #$blah2
    
    $servers_insert = 'insert into ServerList (server_name) values ('''+$good_servers[$g]+''')';
    $servers_insert;
    Invoke-Sqlcmd -ServerInstance $cms_server -Database 'GroupAccess' -Query $servers_insert;
}
#>

Invoke-Sqlcmd -ServerInstance $cms_server -Database $groupaccessdb -Query $groups_table_insert

Invoke-Sqlcmd -ServerInstance $cms_server -Database $groupaccessdb -Query $users_table_insert

Invoke-Sqlcmd -ServerInstance $cms_server -Database $groupaccessdb -Query $servers_table_insert

Invoke-Sqlcmd -ServerInstance $cms_server -Database $groupaccessdb -Query $update_server_groups

Invoke-Sqlcmd -ServerInstance $cms_server -Database $groupaccessdb -Query $update_server_users
