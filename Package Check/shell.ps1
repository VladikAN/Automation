$Search_Folder = 'Tests'

$Search_ContentRegex = ('invalid')
$Search_FilesRegex = ('\.invalid$')
$Search_ExcludeFiles = ('\.exe$', '\.dll$', '\.gif$', '\.png$', '\.jpg$', '\.jpeg$', '\.nupkg$')

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
# Preparing big patterns regex
$Search_ContentCommon = '';
$Search_ContentRegex | ForEach-Object {
	$token = $_.Trim()
	if ($Search_ContentCommon) {
		$Search_ContentCommon = ($Search_ContentCommon +'|(' + $token + ')')
	} else {
		$Search_ContentCommon = ('(' + $token + ')')
	}
}

#
# Preparing big files regex
$Search_FilesCommon = '';
$Search_FilesRegex | ForEach-Object {
	$token = $_.Trim()
	if ($Search_FilesCommon) {
		$Search_FilesCommon = ($Search_FilesCommon +'|(' + $token + ')')
	} else {
		$Search_FilesCommon = ('(' + $token + ')')
	}
}

#
# Preparing big exclude regex
$Search_ExcludeFilesCommon = '';
$Search_ExcludeFiles | ForEach-Object {
	$token = $_.Trim()
	if ($Search_ExcludeFilesCommon) {
		$Search_ExcludeFilesCommon = ($Search_ExcludeFilesCommon +'|(' + $token + ')')
	} else {
		$Search_ExcludeFilesCommon = ('(' + $token + ')')
	}
}

#
# Filling files array
$TargetFiles = @()
Get-ChildItem $Search_Folder -Force -Recurse | ?{ !$_.PSIsContainer } | ForEach-Object {
	if ($_.FullName -notmatch $Search_ExcludeFilesCommon) {
		$TargetFiles += $_.FullName
	}
}
Write-Host ''
Write-Host ($TargetFiles.Length.ToString() + ' File(s) to check')

#
# Express files check
Write-Host ''
Write-Host 'Express file extensions check...'
$Express_FileExtensions = @()
$TargetFiles | ForEach-Object {
	if ($_ -match $Search_FilesCommon) {
		$Express_FileExtensions += $_
	}
}
Write-Host ($Express_FileExtensions.Length.ToString() + ' File(s)')

Write-Host ''
Write-Host 'Express file names check...'
$Express_FileNames = @()
$TargetFiles | ForEach-Object {
	if ($_ -match $Search_ContentCommon) {
		$Express_FileNames += $_
	}
}
Write-Host ($Express_FileNames.Length.ToString() + ' File(s)')

Write-Host ''
Write-Host 'Express file content check...'
$Express_FileContent = @()
$TargetFiles | ForEach-Object {
	$content = Get-Content -Path $_
	if ($content -match $Search_ContentCommon) {
		$Express_FileContent += $_
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
		$resultObj.FileName = $_

		$matches = Select-String -Path $_ -Pattern $token -AllMatches | Foreach {
			$resultObj.LinesNumbers += $_.LineNumber
			$resultObj.LinesContent += $_.Line
			$resultObj.LinesMatch += $_.Matches
		}
		
		if ($matches.Length -ne 0) {
			$resultObj.LinesMatch = $resultObj.LinesMatch | Select -uniq
			$Result_FileContent[$token] += $resultObj
		}
	}
}

#
# Creating result
Copy-Item $Result_Template $Result_File

# Printing files extensions
$extensions = 'None'
if ($Search_FilesRegex)
{
	$extensions = ''
	$Search_FilesRegex | ForEach-Object {
		$token = $_.Trim()
		$extensions += ('<div>' + $token + '</div>')
	}
}
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileExtension%", ($extensions) } | Set-Content $Result_File
	
$TargetFiles = 'Ok'
if ($Result_FileExtensions)
{
	$TargetFiles = '<div class="result-list">'
	$Result_FileExtensions.GetEnumerator() | ForEach-Object {
		$key = $_.Key
		$value = $_.Value
		
		$value | ForEach-Object {
			$fileName = $_.Trim()
			$match = ([regex]$key).Matches($filename);

			$fileName = $fileName.replace($match, ('<span class="mark">' + $match + '</span>'))
			$TargetFiles += ('<div>' + $fileName + '</div>')
		}
	}
	$TargetFiles += '</div>'
}
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileExtensionResults%", ($TargetFiles) } | Set-Content $Result_File

# Printing files names
$names = 'None'
if ($Search_ContentRegex)
{
	$names = ''
	$Search_ContentRegex | ForEach-Object {
		$token = $_.Trim()
		$names += ('<div>' + $token + '</div>')
	}
}
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%DeniedContent%", ($names) } | Set-Content $Result_File

$TargetFiles = 'Ok'
if ($Result_FileNames)
{
	$TargetFiles = '<div class="result-list">'
	$Result_FileNames.GetEnumerator() | ForEach-Object {
		$key = $_.Key
		$value = $_.Value
		
		$value | ForEach-Object {
			$fileName = $_.Trim()
			$match = ([regex]$key).Matches($filename);

			$fileName = $fileName.replace($match, ('<span class="mark">' + $match + '</span>'))
			$TargetFiles += ('<div>' + $fileName + '</div>')
		}
	}
	$TargetFiles += '</div>'
}
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileNameResult%", ($TargetFiles) } | Set-Content $Result_File

$TargetFiles = 'Ok'
if ($Result_FileContent)
{
	$TargetFiles = ''
	$Result_FileContent.GetEnumerator() | ForEach-Object {
		$token = $_.Key
		$obj = $_.Value
		
		$TargetFiles += ('<h3>' + $token + '</h3>')
		$obj | ForEach-Object {	
			$TargetFiles += '<table class="result-list">'
			$TargetFiles += ('<tr><th colspan="2">' + $_.FileName + '</th></tr>')
			
			for ($i = 0; $i -le $_.LinesNumbers.Length - 1; $i++) {
				$content = $_.LinesContent[$i]
				$_.LinesMatch | Foreach {
					$content = $content.replace($_, ('<span class="mark">' + $_ + '</span>'))
				}

				$TargetFiles += ('<tr><td>' + $_.LinesNumbers[$i] + '</td><td>' + $content + '</td></tr>')
			}

			$TargetFiles += '</table>'
		}
	}
}
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileContentResult%", ($TargetFiles) } | Set-Content $Result_File