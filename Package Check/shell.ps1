$Search_Folder = 'C:\Vlad\Github\Daily-Stuff\Package Check\Tests\'

$Search_ContentRegex = ('invalid', 'wrong')
$Search_FilesRegex = ('\.invalid$')
$Search_ExcludeFiles = ('\.eot$', '\.woff$', '\.xpi$','\.ttf$','\.chm$', '\.exe$', '\.dll$', '\.gif$', '\.png$', '\.jpg$', '\.jpeg$', '\.nupkg$', '\.nuspec$', '\\jquery\.globalize\\cultures\\globalize\.culture\..*\.js$', '\\jquery\.globalize\\cultures\\globalize\.cultures\.js$')

$Result_Template = ((Split-Path $MyInvocation.MyCommand.Path) + '\Common\result_template.html')
$Result_File = ((Split-Path $MyInvocation.MyCommand.Path) + '\result.html')

Add-Type -Language CSharp @"
	public class PackageCheckResult
	{
		public string FileName;
		public int[] LinesNumbers;
		public string[] LinesContent;
		public string[] LinesMatch;
	}
"@;

#
# Preparing express regex patterns
$Search_ContentRegex_Common = '(?>' + ($Search_ContentRegex -join '|') + ')'
$Search_FilesRegex_Common = '(?>' + ($Search_FilesRegex -join '|') + ')'
$Search_ExcludeFiles_Common = '(?>' + ($Search_ExcludeFiles -join '|') + ')'

#
# Filling files array
$Search_Folder = $Search_Folder.ToLower()
$TargetFiles = @{}
Get-ChildItem $Search_Folder -Force -Recurse | ?{ !$_.PSIsContainer } | ForEach-Object {
	if ($_.FullName -notmatch $Search_ExcludeFiles_Common) {
		$fullName = $_.FullName.ToLower()
		$key = $fullName.replace($Search_Folder, '\');
		$TargetFiles[$key] = $fullName
	}
}

#
# Express files check
Write-Host ''
Write-Host 'Express file extensions check...'
$Express_FileExtensions = @()
$TargetFiles.GetEnumerator() | ForEach-Object {
	if ($_.Value -match $Search_FilesRegex_Common) {
		$Express_FileExtensions += $_.Key
	}
}
Write-Host ($Express_FileExtensions.Length.ToString() + ' File(s)')

Write-Host ''
Write-Host 'Express file names check...'
$Express_FileNames = @()
$TargetFiles.GetEnumerator() | ForEach-Object {
	if ($_.Value -match $Search_ContentRegex_Common) {
		$Express_FileNames += $_.Key
	}
}
Write-Host ($Express_FileNames.Length.ToString() + ' File(s)')

Write-Host ''
Write-Host 'Express file content check...'
$Express_FileContent = @()
$TargetFiles.GetEnumerator() | ForEach-Object {
	$content = Get-Content -Path $_.Value
	if ($content -match $Search_ContentRegex_Common) {
		$Express_FileContent += $_.Key
	}
}
Write-Host ($Express_FileContent.Length.ToString() + ' File(s)')

#
# Checking files extensions
Write-Host ''
Write-Host 'Full file extensions check...'
$Result_FileExtensions = @{}
$Search_FilesRegex | ForEach-Object {
	$token = $_.Trim()
	$Result_FileExtensions[$token] = @()

	$Express_FileExtensions | ForEach-Object {
		if ($_ -match $token) {
			$Result_FileExtensions[$token] += $_
		}
	}
}

#
# Checking files names
Write-Host ''
Write-Host 'Full file names check...'
$Result_FileNames = @{}
$Search_ContentRegex | ForEach-Object {
	$token = $_.Trim()
	$Result_FileNames[$token] = @()

	$Express_FileNames | ForEach-Object {
		if ($_ -match $token) {
			$Result_FileNames[$token] += $_
		}
	}
}

#
# Checking files content
Write-Host ''
Write-Host 'Full file content check...'
$Result_FileContent = @{}
$Search_ContentRegex | ForEach-Object {
	$token = $_.Trim()
	$Result_FileContent[$token] = @()

	$Express_FileContent | ForEach-Object {
		$resultObj = New-Object PackageCheckResult
		
		$matches = Select-String -Path $TargetFiles[$_] -Pattern $token -AllMatches | Foreach {
			$resultObj.LinesNumbers += $_.LineNumber
			$resultObj.LinesContent += $_.Line
			$resultObj.LinesMatch += $_.Matches
		}

		if ($resultObj.LinesMatch.Length -and $resultObj.LinesMatch.Length.ToString() -ne '0') {
			$resultObj.FileName = $_
			$resultObj.LinesMatch = $resultObj.LinesMatch | Select -uniq
			$Result_FileContent[$token] += $resultObj
		}
	}
}

#
# Creating result
Copy-Item $Result_Template $Result_File

# Printing files extensions
$extensions = ''
if ($Search_FilesRegex)
{
	$Search_FilesRegex | ForEach-Object {
		$token = $_.Trim()
		$extensions += ('<div class="pattern">' + $token + '</div>')
	}
}
	
$FileExtensionResult = ''
if ($Result_FileExtensions.GetEnumerator().Length -ne 0)
{
	$FileExtensionResult = '<div class="result-list">'
	$Result_FileExtensions.GetEnumerator() | ForEach-Object {
		$key = $_.Key
		$value = $_.Value

		$value | ForEach-Object {
			$fileName = $_.Trim()
			$match = ([regex]$key).Matches($filename);

			$fileName = $fileName.replace($match, ('<span class="mark">' + $match + '</span>'))
			$FileExtensionResult += ('<div>' + $fileName + '</div>')
		}
	}
	$FileExtensionResult += '</div>'
}

# Printing files names
$names = ''
if ($Search_ContentRegex)
{
	$Search_ContentRegex | ForEach-Object {
		$token = $_.Trim()
		$names += ('<div class="pattern">' + $token + '</div>')
	}
}

$FileNameResult = ''
if ($Result_FileNames.GetEnumerator().Length -ne 0)
{
	$FileNameResult = '<div class="result-list">'
	$Result_FileNames.GetEnumerator() | ForEach-Object {
		$key = $_.Key
		$value = $_.Value
		
		$value | ForEach-Object {
			$fileName = $_.Trim()
			$match = ([regex]$key).Matches($filename) | Select -uniq | Foreach {
				$fileName = $fileName.replace($_, ('<span class="mark">' + $_ + '</span>'))
			}
			$FileNameResult += ('<div>' + $fileName + '</div>')
		}
	}
	$FileNameResult += '</div>'
}

$FileContentResult = ''
if ($Result_FileContent.GetEnumerator().Length -ne 0)
{
	$Result_FileContent.GetEnumerator() | ForEach-Object {
		$token = $_.Key
		$obj = $_.Value
		
		if ($obj.Length -ne 0)
		{
			$FileContentResult += ('<div class="pattern">' + $token + '</div>')
		
			$obj | ForEach-Object {	
				$FileContentResult += '<div class="result-list-wrapper"><table class="result-list">'
				$FileContentResult += ('<tr><th colspan="2">' + $_.FileName + '</th></tr>')
				
				for ($i = 0; $i -le $_.LinesNumbers.Length - 1; $i++) {
					$content = $_.LinesContent[$i]

					$_.LinesMatch | Foreach {
						$content = $content.replace($_, ('<span class="mark">' + $_ + '</span>'))
					}

					$FileContentResult += ('<tr><td>' + $_.LinesNumbers[$i] + '</td><td>' + $content + '</td></tr>')
				}

				$FileContentResult += '</table></div>'
			}
		}
	}
}

$cleanText = '<span class="info">Everything is clean</span>'

if ($extensions -eq '') { $extensions = 'None' }
if ($FileExtensionResult -eq '') { $FileExtensionResult = $cleanText }

(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileExtension%", ($extensions) } | Set-Content $Result_File
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileExtensionResults%", ($FileExtensionResult) } | Set-Content $Result_File

if ($name -eq '') { $names = 'None' }
if ($FileNameResult -eq '') { $FileNameResult = $cleanText }
if ($FileContentResult -eq '') { $FileContentResult = $cleanText }

(Get-Content $Result_File) | ForEach-Object { $_ -replace "%DeniedContent%", ($names) } | Set-Content $Result_File
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileNameResult%", ($FileNameResult) } | Set-Content $Result_File
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileContentResult%", ($FileContentResult) } | Set-Content $Result_File