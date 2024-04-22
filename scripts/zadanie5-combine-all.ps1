# combine all sql files in order to 1 sql file

# check if the file exists
if (Test-Path "./zadanie5/all.sql") {
    Remove-Item "./zadanie5/all.sql"
}

# combine all sql files
Get-Content "./zadanie5/DBS-2024-Zadanie5.sql" | Out-File "./zadanie5/all.sql"
Get-Content "./zadanie5/1proces.sql" | Out-File "./zadanie5/all.sql" -Append
Get-Content "./zadanie5/2proces.sql" | Out-File "./zadanie5/all.sql" -Append
Get-Content "./zadanie5/3proces.sql" | Out-File "./zadanie5/all.sql" -Append
Get-Content "./zadanie5/4proces.sql" | Out-File "./zadanie5/all.sql" -Append
Get-Content "./zadanie5/5proces.sql" | Out-File "./zadanie5/all.sql" -Append
Get-Content "./zadanie5/institutions_insert_trigger.sql" | Out-File "./zadanie5/all.sql" -Append
Get-Content "./zadanie5/ongoing_trigger.sql" | Out-File "./zadanie5/all.sql" -Append
Get-Content "./zadanie5/closed_trigger.sql" | Out-File "./zadanie5/all.sql" -Append
Get-Content "./zadanie5/example-data.sql" | Out-File "./zadanie5/all.sql" -Append