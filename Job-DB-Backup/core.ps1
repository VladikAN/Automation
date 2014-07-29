function Job-DB-Backup
{
	[CmdletBinding()]
	param(
        [Parameter(Mandatory=$true)]
        [string]$DB_Server = 'localhost\SQLEXPRESS',

        [Parameter(Mandatory=$true)]
        [string]$DB_Name = 'Database',

        [Parameter(Mandatory=$true)]
        [string]$DB_Backup_Location = 'c:\downloads\',

        [string]$DB_Backup_Prefix = 'project',
        [string]$DB_Backup_Suffix = 'trunk',

        [int]$DB_Backup_StoreCount = 3
	)

	begin
	{
        Add-PSSnapin SqlServerCmdletSnapin100
        Add-PSSnapin SqlServerProviderSnapin100

        $raw_db_name = ((@($DB_Backup_Prefix, $DB_Name, $DB_Backup_Suffix) | Where-Object { $_ -ne $null }) -join '_').ToString().ToLower().Replace(' ', '_')
        $raw_db_date = (Get-Date -format "ddMMyyyy_HHmmss")

        # If parameter greater then 0 then locate existed backups and remove oldest
        if ($DB_Backup_StoreCount -ge 1)
        {
            Write-Output "Locate existed backups ..."

            $raw_files_regex = ("{0}.*?\.bak" -f $raw_db_name)
            $raw_files_backups = @(Get-Childitem $DB_Backup_Location | Where-Object { $_.Name -match $raw_files_regex } | Sort-Object LastWriteTime | Select -ExpandProperty Name)
            
            # If backups count greater then defined store count then remove oldest
            if ($raw_files_backups.length -ge $DB_Backup_StoreCount)
            {
                $raw_files_count = $raw_files_backups.length - $DB_Backup_StoreCount
                Write-Output "Prepare to remove $($raw_files_count + 1) backup(s) ..."

                $raw_files_backups[0..$raw_files_count] | ForEach-Object {
                    Write-Output "Remove $($_) ..."
                    Remove-Item -Force ($DB_Backup_Location + $_)
                }
            }
        }
	}

	process
	{
        $backup_name = ("{0}_{1}.bak" -f $raw_db_name, $raw_db_date)
        $backup_query = ("BACKUP DATABASE [{0}] TO DISK = N'{1}/{2}' WITH NOFORMAT, INIT, NAME = N'{2}', SKIP, NOREWIND, NOUNLOAD, STATS = 10" -f $DB_Name, $DB_Backup_Location.TrimEnd('/'), $backup_name)

        Write-Output "Backup database ..."
        Invoke-Sqlcmd -ServerInstance $DB_Server -Query $backup_query
	}

	end
	{
        Remove-PSSnapin SqlServerCmdletSnapin100
        Remove-PSSnapin SqlServerProviderSnapin100
	}
}