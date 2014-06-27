function Check-Directory
{
	[CmdletBinding()]
	param(
        [Parameter(Mandatory=$true)]
        [string]$DB_Server = .\SQLEXP,

        [Parameter(Mandatory=$true)]
        [string]$DB_Name = 'Database_1',

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

        $raw_db_name = (@($DB_Backup_Prefix, $DB_Name, $DB_Backup_Suffix) | Where-Object { $_ -ne $null }) -join '_').ToString().ToLower()
        $raw_db_name_regex = "$($raw_db_name).*?\.bak";
	}

	process
	{
	}

	end
	{
	}
}