[string]$DB_SearchPattern = 'DB'

[string]$DB_BackupName = 'backup'

[string]$DB_SQLServerAddress = 'localhost'
[string]$DB_ServerBackupFolder = 'C:\Downloads\'
[string]$DB_ServerEthernetFolder = 'C:\Downloads\'
[string]$DB_LocalBackupFolder = ((Split-Path $MyInvocation.MyCommand.Path) + '\backups')

Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100

# Creating environment
New-Item -ItemType Directory -Force -Path $DB_LocalBackupFolder
Clear-Host

# Scan target database
Write-Output 'Avaiting server response...'
[string]$proc_query_search = "SELECT name FROM sys.databases WHERE name LIKE '%$DB_SearchPattern%'"
Write-Verbose $proc_query_search
$DB_Result = Invoke-Sqlcmd -ServerInstance $DB_SQLServerAddress -Query $proc_query_search
Clear-Host

# Print scan results
Write-Output 'Available targets:'
foreach($result in $DB_Result)
{
	Write-Output "$([array]::IndexOf($DB_Result, $result)): $($result['name'])"
}

# Read user input
Write-Output ''
[int]$DB_Selected = Read-Host "Select target database"
[string]$DB_BackupSuffix = Read-Host "Print backup suffix (optional)"
Write-Output ''

# Backup
[string]$backupDate = (Get-Date -format "ddMMyyyy")
[string[]]$backupNameParts = @($DB_BackupName, $DB_BackupSuffix, $backupDate) | Where { $_ -ne '' }
[string]$backupFileName = $backupNameParts -join '_'


Write-Output 'Creating backup...'
[string]$proc_backup_query = ('BACKUP DATABASE [' + $DB_Result[$DB_Selected]['name'] + '] TO DISK = N''' + ($DB_ServerBackupFolder + $backupFileName) + ''' WITH NOFORMAT, INIT, NAME = N''' + $DB_BackupName + ''', SKIP, NOREWIND, NOUNLOAD, STATS = 10')
Write-Verbose $proc_backup_query
Invoke-Sqlcmd -ServerInstance $DB_SQLServerAddress -Query $proc_backup_query

# Move
Write-Output 'Moving backup...'
Move-Item ($DB_ServerEthernetFolder + $backupFileName) $DB_LocalBackupFolder -force