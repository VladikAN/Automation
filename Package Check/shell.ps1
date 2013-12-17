$Search_Patterns = 'regex to search'
$Search_Patterns = $Search_Patterns.Split(",")
$Search_Files = 'target'
$Result = @{}

Get-ChildItem $Search_Files -force -recurse -file  | ForEach-Object {
	$FullName = $_.FullName;
	$Content = Get-Content -Path $FullName;

	$Search_Patterns | ForEach {
		$token = "$_".Trim()
		
		if ($FullName -match $token)
		{
			echo ''
			echo (' ! ' + $FullName + ' - ' + $token)
		}
		
		if ($Content -match $token)
		{
			if (!$Result[$FullName])
			{
				$Result[$FullName] += $token
				echo ''
				echo (' ! ' + $FullName)
			}
			
			echo (' - ' + $token)
		}
	}
}