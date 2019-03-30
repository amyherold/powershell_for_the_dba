[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | Out-Null

$machines = @('SQLKITTEN');

foreach ($machine in $machines)
{
    write-host "***************server name = $machine*********************";
    #Get-Service -ComputerName $machine | where-object {($_.name-like '*SQLAgent*')} | select name

    Get-Service -ComputerName $machine | where-object {($_.name-like '*SQLAgent*' -and $_.name -notlike '*SQLAgent*2016*')} | Stop-service
    

    #Get-Service -ComputerName $machine | where-object {($_.name-like '*SQLAgent*' -and $_.name -notlike '*SQLAgent*2016*')} | Start-service


}

#Get-Service | where-object {($_.name-like '*SQLAgent*')} | Stop-service





