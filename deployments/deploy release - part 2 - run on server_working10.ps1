<#
Name: deploy release - part 2.ps1
Author: Amy Herold
Date: 15 March 2018
Purpose: With the parameters that were created in part 1, deploy scripts to either test or prod.

Note: See code for notations on changes.


#>


#----------------20180328 - wrapped in cmdlet function; this will be imported and called from a separate script---------------
function global:Deploy-SQL{

PARAM(

[parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,Position=0)]
[int]$release

,[parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,Position=1)]
[string]$environment

,[parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,Position=2)]
[string]$paramfile

)



#Import-Module sqlps;

$server_name = $null;
$script_name = $null;
$server = '';
$server1 = '';
$server2 = '';
$server3 = '';


$local_path = 'C:\Users\Amy\Documents\GitHub\'
$local_path2 = 'C:\Users\Amy\Desktop\'
$date = get-date -Format yyyyMMdd;

$output_dir = 'C:\MSSQL\DatabaseChanges\2019\'+$date+'_DB-'+$release

if ($paramfile -eq 'PARAM')
{
    $params_file = $output_dir+'\params.txt';
}

if ($paramfile -eq 'CORP')
{
    $params_file = $output_dir+'\params2.txt';
}

if ($paramfile -eq 'RDS')
{
    $params_file = $output_dir+'\params_RDS.txt';
}

$scripts_array = New-Object System.Collections.ArrayList;
$scripts_array.Clear();

$imports_array = New-Object System.Collections.ArrayList;
$imports_array.Clear();


foreach ($p in (Get-Content -Path $params_file))
{

    if ($p -like '*.txt')
    {
        $imports_array.Add($p) | Out-Null;

    }


    if ($p -like '*.sql')
    {
        $scripts_array.Add($p) | Out-Null;
    }
}


Write-Host '**************************scripts array*****************************'
$scripts_array

Write-Host '**************************imports array*****************************'
$imports_array


#--------------------20180328 - check for valid environment; this should be passed in-------------------
if ($environment -notin ('TEST','PROD'))
{
    Write-Host '*********************VALID ENVIRONMENT REQUIRED!!!********************************';
    break;

}

#---------------get list of databases and servers---------------------
if ($environment -eq 'TEST')
{
    $server1 = 'SQLKITTEN-II\SQLSERVER2017';
    $server2 = 'SQLKITTEN-II\SQLSERVER2017';
    $server3 = 'SQLKITTEN-II\SQLSERVER2017';
    $path1 = 'filesystem::\\sqlkitten-ii\c$\Imports\';
    $path2 = 'filesystem::\\sqlkitten-ii\c$\Imports\';
    $path3 = 'filesystem::\\sqlkitten-ii\c$\Imports\';


    
}
if ($environment -eq 'PROD')
{    
    $server1 = 'SQLKITTEN-II\SQLSERVER2017';
    $server2 = 'SQLKITTEN-II\SQLSERVER2017';
    $server3 = 'SQLKITTEN-II\SQLSERVER2017';
    $path1 = 'filesystem::\\sqlkitten-ii\c$\imports\';
    $path2 = 'filesystem::\\sqlkitten-ii\c$\imports\';
    $path3 = 'filesystem::\\sqlkitten-ii\c$\imports\';


}


$get_databases_query = 'select name, @@SERVERNAME as servername
from sys.databases
where name not in (''master'',''tempdb'',''model'',''msdb'')';

$db1 = @(Invoke-Sqlcmd -ServerInstance $server1 -Database master -Query $get_databases_query -MaxCharLength 8000000);
$db2 = @(Invoke-Sqlcmd -ServerInstance $server2 -Database master -Query $get_databases_query -MaxCharLength 8000000);
$db3 = @(Invoke-Sqlcmd -ServerInstance $server3 -Database master -Query $get_databases_query -MaxCharLength 8000000);


#-----------------------------------------------------
$error_code = 0
Write-Host 'error#1 = '$error_code

###################################################################################################################################
###################################################################################################################################


#$regex_path = [regex]"\((.*?)\)"

<#-----------------------------------------------------------------------------------------------------------------------------------------#>
<#-----------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------copy files to c:\imports-------------------------------------------------------#>
<#-----------------------------------------------------------------------------------------------------------------------------------------#>
<#-----------------------------------------------------------------------------------------------------------------------------------------#>

Write-Host '*******************************itterate through the imports array*****************************'
foreach ($import in $imports_array)
{
    $script = $import.Split('|')[-1];
    $script;
    write-host 'copy file = '$script
    Copy-Item -Path $script -Destination $path1 -Force
    Copy-Item -Path $script -Destination $path2 -Force
    Copy-Item -Path $script -Destination $path3 -Force
    Copy-Item -Path $script -Destination $path4 -Force

}


<#-----------------------------------------------------------------------------------------------------------------------------------------#>
<#-----------------------------------------------------------------------------------------------------------------------------------------#>
<#----------------------------------------------------------deploy the release-------------------------------------------------------------#>
<#-----------------------------------------------------------------------------------------------------------------------------------------#>
<#-----------------------------------------------------------------------------------------------------------------------------------------#>


for ([int]$b = 0; $b -lt ($scripts_array | Measure-Object).Count; $b++)
{

    $database = $scripts_array[$b].Split('|')[0]
    $script = $scripts_array[$b].Split('|')[-1]

    if ($database -in $db1.name)
    {
        $server = $server1;

    }
    if ($database -in $db2.name)
    {
        $server = $server2;

    }

    if ($database -in $db3.name)
    {
        $server = $server3;

    }


            if ($script -ne $null -and $database -ne $null)
            {

                #---------------set $output_dir above - going to have one output file for a release--------------------
                #$output_dir = $script | split-path -parent 
                $out_file = $output_dir+'\log_'+$release+'.txt'

                #-----------create the log file if it doesn't exist-----------------
                if (!(Test-Path $out_file))
                {
                    New-Item -Path $out_file -ItemType File
                }

                #------------add the name of the script to the file---------------
                $info = 'SCRIPT NAME: '+$script;
                $info2 = 'SERVER: '+$server;
                $info3 = 'DATABASE: '+$database;
                add-content -path $out_file -value "****************************************************************************************";
                add-content -path $out_file -value $info;
                add-content -path $out_file -value $info2;
                add-content -path $out_file -value $info3;
                add-content -path $out_file -value "`r`n";


                $path_open = '"'+$output_dir+'"'    
                #Invoke-Expression "explorer '/e,/root,'$path_open''"

                Write-Host 'database = '$database
                Write-Host 'server = '$server
                Write-Host 'script = '$script
                Write-Host 'outfile = '$out_file                                       

                sqlcmd -S $server -d $database -i $script -b | Add-Content -path $out_file
                
                add-content -path $out_file -value "`r`n`r`n";
            }

            $error_code = $error_code + $LASTEXITCODE    



}
write-host '$error_code = '+$error_code


#----------------------20180328 - created script to start and stop the browser service; this script will fail if the browser service is not running----------------
#------------------stop the browser service--------------------

#-----------------20180403 - commented out since the browser service should be running now-------------------
#####Invoke-Expression "C:\deployment\PS\browser_service.ps1 -action 'stop'"


}#end cmdlet function