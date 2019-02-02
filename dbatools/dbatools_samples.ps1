
#-----------------get the current version of DBATools that is already installed--------------
Get-InstalledModule DBATools




#------------------Find the DBA Modules in PSGallery---------------
Find-Module DBA*


#-----------------get modules that have been imported or can be imported----------------
Get-Module -All


Find-Module DBA*

Get-Module DBA* -ListAvailable


get-help DBATools





#-----------------install the DBA Tools module-----------------------
Install-Module DBATools -Force


#------------------------------------------------------------let's use some of the cmdlets!!!---------------------------------------------------------------


#---------------get uptime of sql instances--------------
$servers = @('SQLKITTEN-II\SQLSERVER2017','SQLKITTEN-II\SQLSERVER2016');


foreach ($s in $servers)
{

    Get-DbaUptime -SqlInstance $s | select sqlserver, sqlstarttime


}



#----------------------get current and recommended maxdop for list of servers-------------------------------------
foreach ($s in $servers)
{
    Test-DbaMaxDop -SqlInstance $s | Select-Object *

}

#----------------------get file space info for databases - does this exist after update?-------------------------------------
foreach ($s in $servers)
{

    #Get-DbaDbSpace -SqlInstance $s

    Get-DbaDatabaseSpace -SqlInstance $s

    #Find-DbaCommand space


}





#----------------------get orphaned users-------------------------------------
foreach ($s in $servers)
{

    Get-DbaOrphanUser -SqlInstance $s

}



#--------------------dump out permissions------------------
$servers = @('SQLKITTEN-II\SQLSERVER2017');
foreach ($s in $servers)
{

    
    Export-DbaLogin -SqlInstance $s 
    Export-DbaUser -SqlServer $s -Database 'kragle'


}

<#

#find availble modules in psgallery
Find-Module DBA*


#-force 

#Update-Module



get-help

get-member


defining variable type - loosely typed vs strongly typed

passing parameters

adding item to an array destroys the array and recreates it - ????
https://mcpmag.com/articles/2017/09/28/create-arrays-for-performance-in-powershell.aspx

destruction of the array happens when you use the "+=" operator to add items to the array
this does not happen when you add items to an array with System.Collections.ArrayList




comparison operators

do...until...


ouputting operators with write-host - 
ex. write-host 'server name = '+$blah
plus sign will also output


differences in how to construct output?

get-childitem
remove-item - using this with a filter
-whatif
-recurse
-include



$_ - takes on thie type of the object; 


creating own cmdlets - creating cmdlets that are to be shared globally?
how to do this


functions

get-date - running this and formatting? would be something interesting to cover


visual studio code



invoke-sql


SMO



https://dbareports.io
















#>

$path = 'C:\Users\Amy\Desktop\';
$date = get-date -format yyyyMMdd;
$new_folder = 'MYNEWFOLDER';

$new_path = $path + $new_folder + '_' + $date;


$test_path = Test-Path $new_path
if ($test_path -eq $false)
{
    New-Item -Path $new_path -ItemType Directory

}



