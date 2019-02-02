Import-Module 'C:\Users\Amy\Desktop\sql sat session\sqlsat_cleveland_2019\session4\PS\deployments\deploy release - part 2 - run on server_working10.ps1'



Deploy-SQL -release 1234 -environment 'PROD' -paramfile 'PARAM'

