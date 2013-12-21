$Search_Folder = 'Tests'

$Search_RegExPatterns = ('invalid', 'invalid')
$Search_DeniedFilesExtensions = ('invalid', 'doc', 'xls')
$Search_ExcludeFiles = ('\.exe$', '\.dll$', '\.gif$', '\.png$', '\.jpg$', '\.jpeg$', '\.nupkg$')

$Result_Template = ((Split-Path $MyInvocation.MyCommand.Path) + '\Common\result_template.html')
$Result_File = ((Split-Path $MyInvocation.MyCommand.Path) + '\result.html')

#
# Preparing big exclude regex
$BigExcludeRegEx = '';
$Search_ExcludeFiles | ForEach-Object {
	$token = $_.Trim()
	if ($BigExcludeRegEx) {
		$BigExcludeRegEx = ($BigExcludeRegEx +'|(' + $token + ')')
	} else {
		$BigExcludeRegEx = ('(' + $token + ')')
	}
}

#
# Preparing big patterns regex
$BigRegExPatterns = '';
$Search_RegExPatterns | ForEach-Object {
	$token = $_.Trim()
	if ($BigRegExPatterns) {
		$BigRegExPatterns = ($BigRegExPatterns +'|(' + $token + ')')
	} else {
		$BigRegExPatterns = ('(' + $token + ')')
	}
}

#
# Preparing big files regex
$BigRegExFiles = '';
$Search_DeniedFilesExtensions | ForEach-Object {
	$token = $_.Trim()
	if ($BigRegExFiles) {
		$BigRegExFiles = ($BigRegExFiles +'|(\.' + $token + ')$')
	} else {
		$BigRegExFiles = ('(\.' + $token + ')$')
	}
}

#
# Filling files array
$Files = @()
Get-ChildItem $Search_Folder -Force -Recurse | ?{ !$_.PSIsContainer } | ForEach-Object {
	if ($_.FullName -notmatch $BigExcludeRegEx) {
		$Files += $_.FullName
	}
}
Write-Host ''
Write-Host ($Files.Length.ToString() + ' File(s) to check')

#
# Express files check
Write-Host ''
Write-Host 'Express file extensions check...'
$Express_FileExtensions = @()
$Files | ForEach-Object {
	if ($_ -match $BigRegExFiles) {
		$Express_FileExtensions += $_
	}
}
Write-Host ($Express_FileExtensions.Length.ToString() + ' File(s)')

Write-Host ''
Write-Host 'Express file names check...'
$Express_FileNames = @()
$Files | ForEach-Object {
	if ($_ -match $BigRegExPatterns) {
		$Express_FileNames += $_
	}
}
Write-Host ($Express_FileNames.Length.ToString() + ' File(s)')

Write-Host ''
Write-Host 'Express file content check...'
$Express_FileContent = @()
$Files | ForEach-Object {
	$content = Get-Content -Path $_
	if ($content -match $BigRegExPatterns) {
		$Express_FileContent += $_
	}
}
Write-Host ($Express_FileContent.Length.ToString() + ' File(s)')

#
# Checking files extensions
Write-Host ''
Write-Host 'Full file extensions check...'
$Result_FileExtensions = @{}
if ($Express_FileExtensions)
{
	$Search_DeniedFilesExtensions | ForEach-Object {
		$token = $_.Trim()
		$tokenRegEx = ('\.' + $_.Trim() + '$')
		
		$Express_FileExtensions | ForEach-Object {
			if ($_ -match $tokenRegEx) {
				if ($Result_FileExtensions[$token]) {
					$Result_FileExtensions[$token] += (',' + $_)
				} else {
					$Result_FileExtensions[$token] = $_
				}
			}
		}
	}
}

#
# Checking files names
Write-Host ''
Write-Host 'Full file names check...'
$Result_FileNames = @{}
if ($Express_FileNames)
{
	$Search_RegExPatterns | ForEach-Object {
		$token = $_.Trim()
		
		$Express_FileNames | ForEach-Object {
			if ($_ -match $token) {
				if ($Result_FileNames[$token]) {
					$Result_FileNames[$token] += (',' + $_)
				} else {
					$Result_FileNames[$token] = $_
				}
			}
		}
	}
}

#
# Checking files content
Write-Host ''
Write-Host 'Full file content check...'
$Result_FileContent = @{}
if ($Express_FileContent)
{
	$Search_RegExPatterns | ForEach-Object {
		$token = $_.Trim()
		
		$Express_FileContent | ForEach-Object {
			$content = Get-Content -Path $_
			if ($content -match $token) {
				if ($Result_FileContent[$token]) {
					$Result_FileContent[$token] += (',' + $_)
				} else {
					$Result_FileContent[$token] = $_
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
	if ($Result_FileExtensions)
	{
		$files = '<div class="result-list">'
		$Result_FileExtensions.GetEnumerator() | ForEach-Object {
			$key = $_.Key
			$value = $_.Value
			
			$value.Split(",") | ForEach-Object {
				$fileName = $_.Trim()
				$files += ('<div>' + $fileName + '</div>')
			}
		}
		$files += '</div>'
	}
	
	(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileExtensionResults%", ($files) } | Set-Content $Result_File
}

# Printing files names
if ($Search_RegExPatterns)
{
	$names = ''
	$Search_RegExPatterns | ForEach-Object {
		$token = $_.Trim()
		$names += ('<div>' + $token + '</div>')
	}
	
	(Get-Content $Result_File) | ForEach-Object { $_ -replace "%DeniedContent%", ($names) } | Set-Content $Result_File
	
	$files = 'Ok'
	if ($Result_FileNames)
	{
		$files = '<div class="result-list">'
		$Result_FileNames.GetEnumerator() | ForEach-Object {
			$key = $_.Key
			$value = $_.Value
			
			$value.Split(",") | ForEach-Object {
				$fileName = $_.Trim()
				$files += ('<div>' + $fileName + '</div>')
			}
		}
		$files += '</div>'
	}
	
	(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileNameResult%", ($files) } | Set-Content $Result_File
	
	$files = 'Ok'
	if ($Result_FileContent)
	{
		$files = ''
		$Result_FileContent.GetEnumerator() | ForEach-Object {
			$key = $_.Key
			$value = $_.Value
			
			$files += ('<h3>' + $key + '</h3>')
			$files += '<div class="result-list">'
			$value.Split(",") | ForEach-Object {
				$fileName = $_.Trim()
				$files += ('<div>' + $fileName + '</div>')
			}
			$files += '</div>'
		}
	}
	
	(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileContentResult%", ($files) } | Set-Content $Result_File
}