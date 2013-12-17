$Search_Folder = 'Tests'

$Search_RegExPatterns = 'invalid'
$Search_DeniedFilesExtensions = ('invalid', 'doc', 'xls')
$Search_ExcludeFiles = ("*.exe", "*.dll")

$Result_Template = ((Split-Path $MyInvocation.MyCommand.Path) + '\Common\result_template.html')
$Result_File = ((Split-Path $MyInvocation.MyCommand.Path) + '\result.html')

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
	$Search_DeniedFilesExtensions | ForEach-Object {
		$token = $_.Trim()
		$tokenRegEx = ('\.' + $_.Trim() + '$')
		
		$Files | ForEach-Object {
			if ($_ -match $tokenRegEx) {
				if ($ExtensionsResult[$token]) {
					$ExtensionsResult[$token] += (',' + $_)
				} else {
					$ExtensionsResult[$token] = $_
				}
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
				if ($NamesResult[$token]) {
					$NamesResult[$token] += (',' + $_)
				} else {
					$NamesResult[$token] = $_
				}
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
				if ($ContentResult[$token]) {
					$ContentResult[$token] += (',' + $_)
				} else {
					$ContentResult[$token] = $_
				}
			}
		}
	}
}

#
# Creating result
Copy-Item $Result_Template $Result_File

# Printing files extensions
if ($Search_DeniedFilesExtensions)
{
	$extensions = ''
	$Search_DeniedFilesExtensions | ForEach-Object {
		$token = $_.Trim()
		$extensions += ('<div>' + $token + '</div>')
	}
	
	(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileExtension%", ($extensions) } | Set-Content $Result_File
	
	$files = 'Ok'
	if ($ExtensionsResult)
	{
		$files = '<ul>'
		$ExtensionsResult.GetEnumerator() | ForEach-Object {
			$key = $_.Key
			$value = $_.Value
			
			$value.Split(",") | ForEach-Object {
				$fileName = $_.Trim()
				$files += ('<li>' + $fileName + '</li>')
			}
		}
		$files += '</ul>'
	}
	
	(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileExtensionResults%", ($files) } | Set-Content $Result_File
}

# Printing files names
if ($Search_RegExPatterns)
{
	$names = ''
	$Search_RegExPatterns.Split(",") | ForEach-Object {
		$token = $_.Trim()
		$names += ('<div>' + $token + '</div>')
	}
	
	(Get-Content $Result_File) | ForEach-Object { $_ -replace "%DeniedContent%", ($names) } | Set-Content $Result_File
	
	$files = 'Ok'
	if ($NamesResult)
	{
		$files = '<ul>'
		$NamesResult.GetEnumerator() | ForEach-Object {
			$key = $_.Key
			$value = $_.Value
			
			$value.Split(",") | ForEach-Object {
				$fileName = $_.Trim()
				$files += ('<li>' + $fileName + '</li>')
			}
		}
		$files += '</ul>'
	}
	
	(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileNameResult%", ($files) } | Set-Content $Result_File
	
	$files = 'Ok'
	if ($ContentResult)
	{
		$files = ''
		$ContentResult.GetEnumerator() | ForEach-Object {
			$key = $_.Key
			$value = $_.Value
			
			$files += ('<h3>' + $key + '</h3>')
			$files += '<ul>'
			$value.Split(",") | ForEach-Object {
				$fileName = $_.Trim()
				$files += ('<li>' + $fileName + '</li>')
			}
			$files += '</ul>'
		}
	}
	
	(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileContentResult%", ($files) } | Set-Content $Result_File
}