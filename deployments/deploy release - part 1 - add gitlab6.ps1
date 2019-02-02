<#
Name: deploy release - part 1.ps1
Author: Amy Herold
Date: 15 March 2018
Purpose: Scrape the release notes page for a release, extract out the sql scripts and databases, pull those scripts from github, 
create and copy them to a folder that will be copied to the server, and create the parameters that will be added to part 2.


Install-Module -Name posh-git -Force
Get-Module -Name posh-git -ListAvailable

***********************************************************************
pull the database and scripts from the release notes - parse to array
do github pull for all involved areas - DB-XXXX for all except XXXXXXXX - pull all from master
isolate script names into their own array
for each script, search local github repository - 
    if found, copy full path to release folder
    if not found, add to "not found" list
    ------------------->if "not found" list > 0 - break with error and list missing scripts


if no errors, output scripts and databases for $blah_array param in script 2
***********************************************************************

***************Fixes*********************************
Added 'C:\Imports' to the databases list so that it will be included and the file will be grabbed. Text files will need to be copied to the appropriate folder on the server
Looking to the release branch for all repositories in github except DatabaseOCR.
Github issues - manually resolved issues with github checkout. Before this errors were being thrown when running this script. Need to address this some how if this continues to happen.
Items removed from deployment - when something is removed the HTML is struck through. Added "$_.innerHTML -inotlike '*`<S`>*`<`/S`>*'" when filtering for elements to fix.





****************Instructions*************************
1. Run deploy release - part 1.ps1. This will do a pull from github, copy the files for the deployment to a separate folder 
so they can be copied to the server, and generates output for the second step.

2. Copy files to server.

    a. In the event there are other files that need to be imported by a subsequent script, copy those files (txt, csv, etc) to the specified location.

3. Copy output from step 1 to the $blah_array variable in step 2.

4. Run deploy release - part 2 - run on server.ps1 on the server. This will run the scripts in the order given in the $blah_array. 
After each script the process will pause and output the informaiton from the script that was run; at this time you can copy/paste this to hipchat.

#>

#Import-Module sqlps;
#Import-Module -Name posh-git;



#-----------variables you need to set-----------------
$release_server = 'SQLKITTEN-II\SQLSERVER2017';

$release = 1234;
$database_name = $null;
$script_name = $null;
$branch = 'DB-'+$release;

$deploy_date = Get-Date -Format yyyyMMdd

$local_path = 'C:\Users\Amy\Documents\GitHub\';
#$local_path_gitlab = 'C:\Users\Amy\Documents\GitLab\';
$local_path2 = 'C:\Users\Amy\Desktop\';

#----------------list of all databases - if it ain't in here it ain't going out!-------------------------
$deployment_databases = @('StackOverflow','WWI','C:\Imports','kragle','testdb');

#---------------lists of databases that will be used for separating out things in different param files-------------------------
$deployment_databases1 = @('StackOverflow','WWI');
$deployment_databases2 = @('kragle','testdb');
$deployment_databases3 = @('FirstSample');


$deployment_path = $local_path2+$deploy_date+'_DB-'+$release+'\';
$deployment_path

$new_path = $dirpath -replace [regex]::escape($local_path),$deployment_path;

$server_path = 'C:\MSSQL\DatabaseChanges\2019\'+$deploy_date+'_DB-'+$release+'\';

$param2 = '';
$param3 = '';
$param4 = '';

$scripts_full_path2 = New-Object System.Collections.ArrayList;
$scripts_full_path2.Clear();




$get_deployment_scripts = "SELECT [TicketID]
      ,[OrderOfExec]
      ,[ServerID]
      ,[Database]
      ,[Script]
 FROM [DBA].[dbo].[Deployments]
 WHERE TicketID = 'DB-$release'
 ORDER BY OrderOfExec";


 $elements = Invoke-Sqlcmd -ServerInstance $release_server -Database DBA -Query $get_deployment_scripts;



#-----------------------------------------------------

$array = New-Object System.Collections.ArrayList;
$scripts = New-Object System.Collections.ArrayList;
$databases = New-Object System.Collections.ArrayList;
$paths = New-Object System.Collections.ArrayList;
$repo_list = New-Object System.Collections.ArrayList;
$scripts_list = New-Object System.Collections.ArrayList;

$repo_list_gitlab = New-Object System.Collections.ArrayList;
$repo_list_github = New-Object System.Collections.ArrayList;

$array.Clear();
$scripts.Clear();
$databases.Clear();
$paths.Clear();
$repo_list.Clear();
$scripts_list.Clear();
$repo_list_github.Clear();
$repo_list_gitlab.Clear();


for ([int]$x = 0; $x -lt ($elements | Measure-Object).Count; $x++) 
{
    
    
    if ($elements[$x][4] -like '*.sql*' -or $elements[$x][4] -like '*.txt*')
    { 
        
        #--------set db name to variable - this is in case the script is in the group and we need the previous database; use this going forward--------
        if ($elements[$x][3] -ne $null -and $elements[$x][3] -in ($deployment_databases))
        {                       

            
            $database_name = $elements[$x][3]
            $database_name

            if ($elements[$x][4] -ne $null)
            {
                $script_name = $elements[$x][4]
            }
            else
            {
                $script_name = '';

            }

            
            #------------when the database name provided is not the actual name of the database-----------
            if ($database_name -eq 'BrentOzarWasHere')
            {
                $database_name = 'StackOverflow';
            }
            if ($database_name -eq 'DavidKleeForPresident')
            {
                $database_name = 'StackOverflow';
            }
            if ($database_name -eq 'OlaHallengren')
            {
                $database_name = 'StackOverflow';
            }
        }
    
 
        #------------------added to array later and used for param files----------------
        switch ($elements[$x][3])
        {
            {$_ -in $deployment_databases1}{$filenum = 1;}
            {$_ -in $deployment_databases2}{$filenum = 2;}
            {$_ -in $deployment_databases3}{$filenum = 3;}

        } 


        write-host 'database name = '$database_name;
        Write-Host 'script name = '$script_name;
        Write-Host 'filenum = '$filenum;

        $array.Add(@($database_name, $script_name, $filenum)) | Out-Null;


        #-----------get distinct list of databases--------------
        if ($database_name -notin $databases)
        {
            $databases.Add($database_name);

        }


    }

}


#-------------------create folder for files to be copied (local)-------------
if (!(Test-Path -Path $deployment_path))
{
    New-Item -Path $deployment_path -ItemType Directory -Force
}


for ([int]$y = 0; $y -lt ($array | Measure-Object).Count; $y++) 
{
   <#########################################################################################################################################>
#--------------------------------------------github - pull and update scripts in local repository-------------------------
 
        #-----fixing the paths-------------       
        #$array[$y][1] = $array[$y][1] -replace "/", "\" 
        $array[$y][1] = $array[$y][1] -replace [regex]::escape('/'),'\';
        $array[$y][1] = $array[$y][1] -replace [regex]::escape('\\'),'\';
        $array[$y][1] = $array[$y][1] -replace [regex]::escape(' '),'';
        
        
        #------------------------HTML fix!!!-------------------------------------------------------------------------------------------
        #-----------------------in the event the repository path has been entered incorrectly, we need to fix it-----------------------
        if ($array[$y][1] -like 'sql*')
        {
            if ($array[$y][0] -eq 'Stackoverflow')
            { 
                $array[$y][1] = $array[$y][1] -replace [regex]::escape('sql\'),'Stackoverflow\sql\';
            }
            if ($array[$y][0] -eq 'KleeForPresident')
            { 
                $array[$y][1] = $array[$y][1] -replace [regex]::escape('sql\'),'Stackoverflow\sql\';
            }
            if ($array[$y][0] -eq 'OlaHallengren')
            { 
                $array[$y][1] = $array[$y][1] -replace [regex]::escape('sql\'),'Stackoverflow\sql\';
            }
            if ($array[$y][0] -in ('BrentOzarWasHere'))
            { 
                $array[$y][1] = $array[$y][1] -replace [regex]::escape('sql\'),'Stackoverflow\sql\';
            }
            


        }
        
       #---------------------add values to the $paths array - we are going to use these to create the folders where we copy the files--------------------
        $script_path = $array[$y][1].substring(0,$array[$y][1].LastIndexOf('\'))
        if ($script_path -notin $paths)
        {
            $paths.Add($script_path) | out-null;
        }

        #-------------------repo array - the list of repositories we need to pull from for this deployment---------------------------
        $repo = $array[$y][1].Split('\')[0];
        if ($repo -notin $repo_list)
        {
            $repo_list.Add($repo) | out-null;
        }


        $script_name = $array[$y][1].Split('\')[-1];
        if ($script_name -notin $scripts_list)
        {
            $scripts_list.Add($script_name) | out-null;
        }


        $array[$y][1]

}

#$scripts_list
write-host '*********************************************************************************************'
write-host '*********************************LIST PATHS**************************************************'
write-host '*********************************************************************************************'
$paths

#------------------------create repsitory lists fot github--------------------------
foreach($github in (Get-ChildItem 'C:\Users\Amy\Documents\GitHub\' | Select name))
{
    $repo_list_github.Add($github.Name) | out-null;
}





write-host '*********************************************************************************************'
write-host '*********************************PULL FILES FROM GITHUB**************************************'
write-host '*********************************************************************************************'

#---------------------pull github files-----------------------
foreach ($rh in $repo_list_github)
{    
   if ($rh -in $repo_list)
   {
   
        $rh
        $github_path = $local_path + $rh;
        $github_path


        Set-Location $github_path
    
        #-------------------if not WWI or kragle, then we need to pull the branch for the release---------------------
        if ($rh -notlike '*WWI*' -and $rh -notlike '*kragle*')
        { 
            git pull -q origin $branch;#------------------pull from the deployment branch 

        }
        else
        {    
            git pull -q      #-----------------------------pull from master
        }
   
   }
    
}

set-location C:\;

write-host '*************************************************************************************************************'
write-host '*********************************ITTERATION OF GITHUB SCRIPTS************************************************'
write-host '*************************************************************************************************************'

#-------------------------------------------------------get all the github scripts--------------------------------------------------
foreach ($rh in $repo_list_github)
{    
    #---------is the repository in the list for the deployment-------------
    if ($rh -in $repo_list)
    {
        #---------set the base path for the repository----------
        $rh
        $github_path = $local_path + $rh;
        $github_path

        #--------itterate through the databases, and for the ones that have a valid gitlab path in the repo, get the files for that database-----------
            if (Test-Path $github_path)
            {
                foreach ($script_gh in (Get-ChildItem -Path $github_path -Recurse -Force | Where-Object {$_.Name -in $scripts_list} | select FullName))
                {
                    $scripts_full_path2.Add($script_gh.FullName) | out-null;

                }

            }
          
    }
}


write-host '*************************************************************************************************************'
write-host '*********************************LIST OF SCRIPTS IN $scripts_full_path2**************************************'
write-host '*************************************************************************************************************'

$scripts_full_path2

#-------------------create folder for files to be copied (local)-------------
foreach ($p in $paths)
{    
    $local_file_path = $deployment_path + $p + '\';

    
    if (!(Test-Path -Path $local_file_path))
    {
        New-Item -Path $local_file_path -ItemType Directory -Force
    }

}


write-host '*********************************************************************************************'
write-host '*********************************COPY FILES TO LOCATION**************************************'
write-host '*********************************************************************************************'


foreach ($s in $scripts_full_path2)
{
        
        <####################################
        if (!(Get-ChildItem -Path $local_path -Recurse -Force | Where-Object {$_.Name -eq $s.FullName.Split('\')[-1]}))
        #if (!(Get-ChildItem -Path $github_path -Recurse -Force | Where-Object {$_.Name -eq $s.FullName.Split('\')[-1]}))------using the path that only generates one file to test if the file is there - seems to work
        {
            $a = "****************WARNING: MISING FILE - "+$s.FullName.Split('\')[-1]+" ***********************"
            
            write-host $a
        

        }
        ################################>


        $dirpath = $s | Split-Path -Parent 
        Write-Host '$dirpath = '$dirpath


        if ($dirpath -like '*Github*')
        {
                
            $new_path = $dirpath -replace [regex]::escape($local_path),$deployment_path;
            #$new_path

        }


        if (!(Test-Path -Path $new_path))
        {
            New-Item -Path $new_path -ItemType Directory -Force
        }
        
        Copy-Item -Path $s -Destination $new_path -Force #---------------------comment out for testing (time saver)

        $s 
        $new_path


}


write-host '*******************************************************************************************************'
write-host '*********************************BUILD PARAMETERS FOR OUTPUT*******************************************'
write-host '*******************************************************************************************************'


#**************this outputs params that include the database and proper script path for each script, and in the correct order****************
#**************path is based on current naming convention for releases and must match for this to work!!!*********
$param = '';


for ([int]$zz = 0; $zz -lt ($array | Measure-Object).Count; $zz++) 
{
        

        #-------------------20180410 - revised $sname to be the full name that is stated in the array....coming from what is in confluence; 
        #-------------------this is because duplicate files names across database instances
        $dbname = $array[$zz][0]
        $sname = $array[$zz][1]
        $file = $array[$zz][2]
        $sname_full = $scripts_full_path2 | Where-Object {$_ -like "*$sname"}

        if ($sname_full -like '*Github*')
        {          

            $sname_full2 = $sname_full;

            #-------------------replace the local_path with the server_path - this is where we will copy the files------------------
            $sname_full2 = $sname_full2 -replace [regex]::escape($local_path),$server_path; 

        }


       
        #------------------------------paramter files - creating param (full list) and param# (individual lists)--------------------
        if ($param -eq '')
        {            
            $param = $param + ''''+$array[$zz][0]+'|'+$sname_full2+'''';

            #--------------using the filenum value in the array, create our individual parameter files------------------
            switch ($array[$zz][2])
            {
                1 {$param2 = $param2 + $array[$zz][0]+'|'+$sname_full2+"`n"}
                2 {$param3= $param3 + $array[$zz][0]+'|'+$sname_full2+"`n"}
                3 {$param4 = $param4 + $array[$zz][0]+'|'+$sname_full2+"`n"}
            
            }
        }
        else
        {            
            $param = $param + ','''+$array[$zz][0]+'|'+$sname_full2+''''+"`n"
            
            switch ($array[$zz][2])
            {
                1 {$param2 = $param2 + $array[$zz][0]+'|'+$sname_full2+"`n"}
                2 {$param3= $param3 + $array[$zz][0]+'|'+$sname_full2+"`n"}
                3 {$param4 = $param4 + $array[$zz][0]+'|'+$sname_full2+"`n"}
            
            }

        }
                       
      
}

write-host '*********************************************************************************************'
write-host '*********************************OUTPUT PARAMETERS*******************************************'
write-host '*********************************************************************************************'
$param

$param_file = $deployment_path+'params.txt'
$param_file
$param_file2 = $deployment_path+'params_SQL001.txt'
$param_file2
$param_file3 = $deployment_path+'params_RDS.txt'
$param_file3


#-----------------if the files already exist, delete them------------
if ($param_file)
{
    Remove-Item $param_file -ErrorAction Ignore
    Remove-Item $param_file2 -ErrorAction Ignore
    Remove-Item $param_file3 -ErrorAction Ignore

}


#----------------check to see if there are scripts for each file; if so, create the file with Add-Content-------------
if ($param2 -ne '')
{$param2.Trim() | Add-Content -Path $param_file}

if ($param3 -ne '')
{$param3.Trim() | Add-Content -Path $param_file2}

if ($param4 -ne '')
{$param4.Trim() | Add-Content -Path $param_file3}


