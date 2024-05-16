::@echo off

:: echo Stopping SQL Server service...

net stop "MSSQLSERVER" /y
:: echo SQL Server service stopped successfully.

:: set SQL_USER=NT Service\MSSQLSERVER
set SQL_PASSWORD=Xswqaz@21_

net start "MSSQLSERVER"
:: echo Starting SQL Server service...
:: echo SQL Server service started successfully.