[String]$DB_SearchPattern = 'DB'

[String]$DB_BackupName = 'db'
[String]$DB_BackupPrefix = 'db'

[String]$DB_ServerAddress = 'localhost'
[String]$DB_ServerBackupFolder = 'C:\Downloads\'
[String]$DB_ServerEthernetFolder = 'C:\Downloads\'
[String]$DB_LocalBackupFolder = ((Split-Path $MyInvocation.MyCommand.Path) + '\backups')

Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100

# Creating environment
New-Item -ItemType Directory -Force -Path $DB_LocalBackupFolder
Clear-Host

# Scan target database
echo 'Avaiting server response...'
$DB_Result = Invoke-Sqlcmd -ServerInstance $DB_ServerAddress -Query ('SELECT name FROM sys.databases WHERE name LIKE ''%' + $DB_SearchPattern + '%''')
Clear-Host

# Print scan results
echo 'Available targets:'
foreach($result in $DB_Result)
{
	$str = '  ' + ([array]::IndexOf($DB_Result, $result)) + ': ' + ($result['name'])
	echo ($str)
}

# Read user input
echo ''
[int]$DB_Selected = Read-Host "Select target database"
[string]$DB_BackupSuffix = Read-Host "Print backup suffix (optional)"
echo ''

# Backup
[String]$backupFileName = $DB_BackupPrefix
if ($DB_BackupSuffix) { 
	$backupFileName = $backupFileName + '_' + $DB_BackupSuffix
}
$backupFileName = $backupFileName + '_' + (Get-Date -format "ddMMyyyy")  + '.bak'

echo 'Creating backup...'
[String]$backupQuery = ('BACKUP DATABASE [' + $DB_Result[$DB_Selected]['name'] + '] TO DISK = N''' + ($DB_ServerBackupFolder + $backupFileName) + ''' WITH NOFORMAT, INIT, NAME = N''' + $DB_BackupName + ''', SKIP, NOREWIND, NOUNLOAD, STATS = 10')
Invoke-Sqlcmd -ServerInstance $DB_ServerAddress -Query $backupQuery

# Move
echo 'Moving backup...'
Move-Item ($DB_ServerEthernetFolder + $backupFileName) $DB_LocalBackupFolder -force