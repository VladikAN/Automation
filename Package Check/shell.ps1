$Search_Folder = 'Tests'

$Search_RegExPatterns = 'invalid'
$Search_DeniedFilesExtensions = ('invalid')
$Search_ExcludeFiles = ("*.exe", "*.dll")

#
# Filling files array
$Files = @()
Get-ChildItem $Search_Folder -Force -Recurse -Exclude $Search_ExcludeFiles | ?{ !$_.PSIsContainer } | ForEach-Object {
	$Files += $_.FullName
}

#
# Checking files extensions
$ExtensionsResult = @{}
if ($Search_DeniedFilesExtensions)
{
	$Search_DeniedFilesExtensions.Split(",") | ForEach-Object {
		$token = $_.Trim()
		$tokenRegEx = ('\.' + $_.Trim() + '$')
		
		$Files | ForEach-Object {
			if ($_ -match $tokenRegEx) {
				$ExtensionsResult[$token] += ($_ + ',')
			}
		}
	}
}

#
# Checking files names
$NamesResult = @{}
if ($Search_RegExPatterns)
{
	$Search_RegExPatterns.Split(",") | ForEach-Object {
		$token = $_.Trim()
		
		$Files | ForEach-Object {
			if ($_ -match $token) {
				$NamesResult[$token] += ($_ + ',')
			}
		}
	}
}

#
# Checking files content
$ContentResult = @{}
if ($Search_RegExPatterns)
{
	$Search_RegExPatterns.Split(",") | ForEach-Object {
		$token = $_.Trim()
		
		$Files | ForEach-Object {
			$content = Get-Content -Path $_
			if ($content -match $token) {
				$ContentResult[$token] += ($_ + ',')
			}
		}
	}
}