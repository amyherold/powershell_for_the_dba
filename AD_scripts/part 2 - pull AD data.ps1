<#
Name: part 2 - pull AD data.ps1
Author: Amy Herold
Purpose: Based on groups in table, pull groups from AD.

Note: Update server and database. Update domain (hardcoded).
#>


$cms_server = 'SQLKITTENDB';#'CORPDBASQL01';
$database = 'GroupAccess13';


$db_server = $cms_server;
$db = $database;#"GroupAccess"
#$groups_new = 1;

#$groups = @();
$groups = New-Object System.Collections.ArrayList;
$groupmembers = New-Object System.Collections.ArrayList;
$groups.Clear();
$groupmembers.Clear();


$groups2 = New-Object System.Collections.ArrayList;
$groups2.Clear();


function get-groups 
{
    #$groups = New-Object System.Collections.ArrayList;
    #$groups.Clear();

    $groups_list_query = "select id, replace(replace(group_name,'SQLKITTEN\',''),' ','') as group_name from Groups where group_name not in ('NT SERVICE\MSSQLSERVER','NT SERVICE\SQLSERVERAGENT','BUILTIN\Administrators')"
    $groups.AddRange(@(Invoke-Sqlcmd -ServerInstance $db_server -Database $db -Query $groups_list_query));
    $groups_count = $groups.Count;
    #return $groups_count;
}


#$groups_list_query = "select id, replace(group_name,'SQLKITTEN\','') as group_name from Groups where group_name not in ('NT SERVICE\MSSQLSERVER','NT SERVICE\SQLSERVERAGENT','BUILTIN\Administrators')"
    
#Invoke-Sqlcmd -ServerInstance $db_server -Database $db -Username $username -Password $pwd -Query $sql_query

#$groups.AddRange(@(Invoke-Sqlcmd -ServerInstance $db_server -Database $db -Query $groups_list_query));

#$groups_count = $groups.Count;



#$groups


function insert-group ($gr)
{
    $sql_query = "if not exists (select 1 from Groups where replace(group_name,'SQLKITTEN\','') = '$gr') insert Groups(group_name) values ('$gr')"            
    Invoke-Sqlcmd -ServerInstance $db_server -Database $db -Query $sql_query
}


function get-groupid ($gr)
{
    $sql_query = "select id, group_name from Groups where replace(group_name,'SQLKITTEN\','') = '$gr'";
    $group_id = (Invoke-Sqlcmd -ServerInstance $db_server -Database $db -Query $sql_query);  
    return $group_id.id;
}


#------------------add groups to our list--------------
#get-groups;
$groups_old = 1;
$groups.Count;
$groups_current = 0;

write-host 'starting groups_old = '$groups_old;
write-host 'starting groups_count = '$groups.Count;

#while ($groups_old -ne $groups.Count)
while ($groups_old -ne $groups_current)
{
    

    $groups.Clear();
    get-groups;

    write-host 'groups_old = '$groups_old;
    #write-host 'groups_count = '$groups.Count;


    write-host 'groups_count = '$groups_current;


    #$groups_old.GetType().FullName
    #$groups.Count.GetType().FullName



    #--------------set old to new and new to null - we are starting with a new, longer list of groups-----------
    $groups_old = $groups.Count;

    $groups2.Clear();



    #foreach($group in $groups)
    for ($i = 0;$i -lt ($groups | Measure-Object).count;$i++)
    {

       $groupname = $groups[$i].group_name
       $groupid = $groups[$i].id

   
    
    write-host "****************************************'$groupname' - '$groupid'***************************************"
    #Get-ADGroupMember -Identity $group.groupname -Recursive;


   #Get-ADGroupMember -Identity $name;
    #$groupmembers = Get-ADGroupMember -Identity $group[$i].groupname;

    $groupmembers.Clear();

    if ($groupname -ne $null)
    {
        $groupmembers.AddRange(@(Get-ADGroupMember -Identity $groupname));
    }
    foreach ($groupmember in $groupmembers)
    {
        $objectClass_groupmember = $groupmember.objectClass;
        
        #-----------------------------------get users in groups--------------------------------
       if ($objectClass_groupmember -eq "user")
        {
            $name = [regex]::Replace($groupmember.name,"'","''")
            $SamAccountName = $groupmember.SamAccountName

           $IsEnabled = Get-ADUser -Filter {samaccountname -eq $SamAccountName} | Select-Object -Property enabled
           [int]$enabled = [bool]$IsEnabled.enabled



           #Get-ADUser -Filter * -Properties whenCreated,userAccountControl,DisplayName,postOfficeBox,POBox,Department,mail,objectGUID,SamAccountName | Select-Object -Property whenCreated,userAccountControl,DisplayName,@{n='postOfficeBox'; e={$_.postOfficeBox -join ';'}},POBox,Department,mail,objectGUID,SamAccountName | foreach {
            
            #$groupid = $group.groupid
            #$objectClass = $groupmember.objectClass        
            #$IsEnabled = Get-ADUser -Filter {(ObjectClass -eq $SamAccountName)} | -Properties * | select Enabled

           #Write-Host $objectClass_groupmember' - '$name' - '$IsEnabled


           $sql_query = "MERGE INTO [dbo].[ADGroupMembers] AS Target
                            USING (VALUES ('$name', '$SamAccountName', $groupid, $enabled)) AS SOURCE (MemberName, MemberLogin, Groupid, IsEnabled)
                            ON TARGET.MemberLogin = SOURCE.MemberLogin and TARGET.Groupid = SOURCE.Groupid
                            WHEN MATCHED THEN
                            UPDATE SET IsEnabled = SOURCE.IsEnabled
                            WHEN NOT MATCHED THEN
                            INSERT (MemberName, MemberLogin, Groupid, IsEnabled) VALUES (SOURCE.MemberName, SOURCE.MemberLogin, SOURCE.Groupid, SOURCE.IsEnabled);"

           #$sql_query
            
            
            Invoke-Sqlcmd -ServerInstance $db_server -Database $db -Query $sql_query
            
        }

         

        #--------------------------------------get groups in groups----------------------------------
       if ($objectClass_groupmember -eq 'group')
        {
            $name = [regex]::Replace($groupmember.name,"'","''")
            $parentid = $groupid;
  
            
            #----------------group found - add group to table; will be processed next time the job is run-------------
            $name

            #----------------create parent/child relationship record if the group already exists------------------------
            if ($name -in $groups.group_name)
            { 
                
                
                $id = (get-groupid($name)); 
                Write-Host 'id number = '$id;
                #Write-Host 'group name = '$id.group_name
                               
                
                #$sql_query = "insert GroupRelationships (groupid, parentid) values ("+$id+","+$parentid+")";
                #$sql_query;

                #-------------make sure the parent and the group are not the same....this will not end well-----------
                if ($id -ne $parentid)
                {
                    $sql_query = "MERGE INTO [dbo].[GroupRelationships] AS Target
                                    USING (VALUES ($id, $parentid)) AS SOURCE (groupid, parentid)
                                    ON TARGET.parentid = SOURCE.parentid and TARGET.Groupid = SOURCE.Groupid
                                    WHEN NOT MATCHED THEN
                                    INSERT (groupid, parentid) VALUES (SOURCE.groupid, SOURCE.parentid);"



                    Invoke-Sqlcmd -ServerInstance $db_server -Database $db -Query $sql_query;
                }


            }


            if ($name -notin $groups.group_name)
            {
            
                #$sql_query = "if not exists (select 1 from Groups where groupname = '$name') insert Groups(groupname, alerts) values ('$name',0)"
                #$sql_query = "if not exists (select 1 from Groups where replace(group_name,'ONETECH\','') = '$name') insert Groups(group_name) values ('$name')"            
                #Invoke-Sqlcmd -ServerInstance $db_server -Database $db -Query $sql_query
                #$sql_query  


                #----add the group------
                insert-group ($name);
            
                #----for the group we just added, get the id--------
                $sql_query = "select id, group_name from Groups where group_name = '$name'";
                $group_id = (Invoke-Sqlcmd -ServerInstance $db_server -Database $db -Query $sql_query);  
                
                #---add the relationship record-------
                #$sql_query = "insert GroupRelationships (groupid, parentid) values ("+$group_id.id+","+$parentid+")";
                #$sql_query;

                if ($id -ne $parentid)
                {
                    $sql_query = "MERGE INTO [dbo].[GroupRelationships] AS Target
                                    USING (VALUES ($id, $parentid)) AS SOURCE (groupid, parentid)
                                    ON TARGET.parentid = SOURCE.parentid and TARGET.Groupid = SOURCE.Groupid
                                    WHEN NOT MATCHED THEN
                                    INSERT (groupid, parentid) VALUES (SOURCE.groupid, SOURCE.parentid);"

                    Invoke-Sqlcmd -ServerInstance $db_server -Database $db -Query $sql_query;
                          
                
                    #$test = get-groupid ($name);

                    $groups2.Add(@($group_id.id,$group_id.group_name)) | Out-Null;   
                }
                
                       
            }


       }

       
    }
  


}#end for loop

for ($gg = 0; $gg -lt ($groups2 |Measure-Object).Count; $gg++)
{
    Write-Host $groups2[$gg][0]'   '$groups2[$gg][1]
  

}

if ($groups2.Count -gt 0)
{

    $groups.AddRange(@($groups2.id,$groups2.group_name));

}

write-host 'groups2 count = '$groups2.Count;

<#

if ($groups_new -lt $groups.Count)
{
    $groups_new = $groups.Count;
}
else
{
    $groups_new = $null;


}
#>


$groups_current = $groups.Count;

}#end while loop

$groups_count_new = $groups.Count;

#$groups.group_name;
$groups;

$groupmembers.Clear();
$groups.Clear();



