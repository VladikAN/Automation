$Search_Folder = 'target'

$Search_Patterns = 'belarus'
$Search_DeniedFileExt = ('.pdb', '.swf')
$Search_ExcludeFiles = ("*.png", "*.gif", "*.dll")

$Result = @{}

if ($Search_Patterns) { $Search_Patterns = $Search_Patterns.Split(",") }
if ($Search_DeniedFilePattrns) { $Search_DeniedFilePattrns = $Search_DeniedFilePattrns.Split(",") }

Get-ChildItem $Search_Folder -Force -Recurse -File -Exclude $Search_ExcludeFiles | ForEach-Object {
	$FullName = $_.FullName;
	$Ext = [System.IO.Path]::GetExtension($FullName);
	$Content = Get-Content -Path $FullName;
	
	$Search_DeniedFileExt | ForEach {
		if ($Ext -eq $_)
		{
			echo ''
			echo (' ! ' + $FullName + ' - *' + $_)
		}
	}
	
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