function Check-Directory
{
	[CmdletBinding()]
	param(
        [Parameter(Mandatory=$true)]
        [string]$DB_Server,

        [Parameter(Mandatory=$true)]
        [string]$DB_Name,

        [Parameter(Mandatory=$true)]
        [string]$DB_Backup_Location,

        [string]$DB_Backup_Prefix,

        [string]$DB_Backup_Suffix,

        [int]$DB_Backup_StoreCount
	)

	begin
	{
        Add-PSSnapin SqlServerCmdletSnapin100
        Add-PSSnapin SqlServerProviderSnapin100
	}

	process
	{
	}

	end
	{
	}
}