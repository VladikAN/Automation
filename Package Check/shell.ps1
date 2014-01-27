param(
	[Parameter(Mandatory=$true)]
	[string]$TargetPath,
	[string]$DeniedContentPath = '.\denied content.conf',
	[string]$DeniedFilesPath = '.\denied files.conf',
	[string]$ExcludeFilesPath = '.\exclude files.conf'
)

Add-Type -AssemblyName System.Web

$Search_ContentRegex = Get-Content $DeniedContentPath
$Search_FilesRegex = Get-Content $DeniedFilesPath
$Search_ExcludeFiles = Get-Content $ExcludeFilesPath

[string]$Result_Template = ((Split-Path $MyInvocation.MyCommand.Path) + '\Common\result_template.html')
[string]$Result_File = ((Split-Path $MyInvocation.MyCommand.Path) + '\result.html')

Add-Type -Language CSharp @"
	public class PackageCheckResult
	{
		public string FileName;
		public int[] LinesNumbers;
		public string[] LinesContent;
		public string[] LinesMatch;
	}
"@;

# Preparing express regex patterns
[string]$Search_ContentRegex_Common = '(?>' + ($Search_ContentRegex -join '|') + ')'
[string]$Search_FilesRegex_Common = '(?>' + ($Search_FilesRegex -join '|') + ')'
[string]$Search_ExcludeFiles_Common = '(?>' + ($Search_ExcludeFiles -join '|') + ')'

# Filling files array
$TargetFiles = @{}
Get-ChildItem $TargetPath -Force -Recurse | ?{ !$_.PSIsContainer } | ForEach-Object {
	$fullName = $_.FullName.ToLower()
	if ($_.FullName -notmatch $Search_ExcludeFiles_Common) {
		$key = $fullName.replace($TargetPath, '\');
		$TargetFiles[$key] = $fullName
	}
}

if ($TargetFiles -eq $null)
{
	exit
}

#
# Checking files extensions
$Result_FileExtensions = @{}
Write-Host 'Express file extensions check... ' -nonewline
$Express_FileExtensions = $TargetFiles.GetEnumerator() | Where-Object { $_.Key -match $Search_FilesRegex_Common } | Select -uniq -ExpandProperty Key
if ($Express_FileExtensions) {
	Write-Host ("$($Express_FileExtensions.Length) File(s)")
	Write-Host 'Full file extensions check...'
	ForEach ($token in $Search_FilesRegex) {
		$Express_FileExtensions | Where-Object { $_ -match $token } | ForEach-Object {
			if (-not $Result_FileExtensions.ContainsKey($token)) { $Result_FileExtensions[$token] = @() }
			$Result_FileExtensions[$token] += $_
		}
	}
} else {
	Write-Host '0 File(s)'
}

#
# Checking files names
$Result_FileNames = @{}
Write-Host 'Express file names check... ' -nonewline
$Express_FileNames = $TargetFiles.GetEnumerator() | Where-Object { $_.Key -match $Search_ContentRegex_Common } | Select -uniq -ExpandProperty Key
if ($Express_FileNames) {
	Write-Host ("$($Express_FileNames.Length) File(s)")
	Write-Host 'Full file names check...'
	ForEach ($token in $Search_ContentRegex) {
		$Express_FileNames | Where-Object { $_ -match $token } | ForEach-Object {
			if (-not $Result_FileNames.ContainsKey($token)) { $Result_FileNames[$token] = @() }
			$Result_FileNames[$token] += $_
		}
	}
} else {
	Write-Host '0 File(s)'
}

#
# Checking files content
$Result_FileContent = @{}
Write-Host 'Express file content check... ' -nonewline
$Express_FileContent = $TargetFiles.GetEnumerator() | Where-Object { (Get-Content -Path $_.Value) -match $Search_ContentRegex_Common } | Select -uniq -ExpandProperty Key
if ($Express_FileContent) {
	Write-Host ("$($Express_FileContent.Length) File(s)")
	Write-Host 'Full file content check...'
	ForEach ($token in $Search_ContentRegex) {
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

				if (-not $Result_FileContent.ContainsKey($token)) { $Result_FileContent[$token] = @() }
				$Result_FileContent[$token] += $resultObj
			}
		}
	}
} else {
	Write-Host '0 File(s)'
}

# Creating result
Copy-Item $Result_Template $Result_File
# Printing files extensions
[string]$TextFileExtension = ''
if ($Search_FilesRegex)
{
	$Search_FilesRegex | ForEach-Object {
		if ($Result_FileExtensions.ContainsKey($_)) {
			$TextFileExtension += ("<div class='pattern error'>$_</div>")
		}
		else {
			$TextFileExtension += ("<div class='pattern clean'>$_</div>")
		}
	}
}
	
[string]$TextFileExtensionResults = ''
if ($Result_FileExtensions.GetEnumerator().Length -ne 0)
{
	$Result_FileExtensions.GetEnumerator() | ForEach-Object {
		$key = $_.Key
		$value = $_.Value

		ForEach ($fileName in $value){
			$match = ([regex]$key).Matches($filename) | Select -uniq | Foreach {
				$fileName = $fileName.replace($_, ("<span class='match error'>$_</span>"))
			}
			$TextFileExtensionResults += ("<p>$fileName</p>")
		}
	}

	if ($TextFileExtensionResults -ne '') { $TextFileExtensionResults = ("<div class='result-list'>$TextFileExtensionResults</div>") }
}

# Printing files names
[string]$TextDeniedContent = ''
if ($Search_ContentRegex)
{
	$Search_ContentRegex | ForEach-Object {
		if ($Result_FileNames.ContainsKey($_) -or $Result_FileContent.ContainsKey($_)) {
			$TextDeniedContent += ("<div class='pattern error'>$_</div>")
		}
		else {
			$TextDeniedContent += ("<div class='pattern clean'>$_</div>")
		}
	}
}

[string]$TextFileNameResult = ''
if ($Result_FileNames.GetEnumerator().Length -ne 0)
{
	$Result_FileNames.GetEnumerator() | ForEach-Object {
		$key = $_.Key
		$value = $_.Value
		
		ForEach ($fileName in $value){
			$match = ([regex]$key).Matches($filename) | Select -uniq | Foreach {
				$fileName = $fileName.replace($_, ("<span class='match error'>$_</span>"))
			}
			$TextFileNameResult += ("<p>$fileName</p>")
		}
	}

	if ($TextFileNameResult -ne '') { $TextFileNameResult = ("<div class='result-list'>$TextFileNameResult</div>") }
}

[string]$TextFileContentResult = ''
if ($Result_FileContent.GetEnumerator().Length -ne 0)
{
	$Result_FileContent.GetEnumerator() | ForEach-Object {
		$token = $_.Key
		$obj = $_.Value
		
		if ($obj.Length -ne 0)
		{
			$TextFileContentResult += ("<div class='pattern error'>$token</div>")
		
			$obj | ForEach-Object {	
				$TextFileContentResult += '<div class="result-list-wrapper"><table class="result-list">'
				$TextFileContentResult += ("<tr><th colspan='2'>$($_.FileName)</th></tr>")
				
				for ($i = 0; $i -le $_.LinesNumbers.Length - 1; $i++) {
					$content = [System.Web.HttpUtility]::HtmlEncode($_.LinesContent[$i])

					$_.LinesMatch | Foreach {
						$content = $content.replace($_, ("<span class='match error'>$_</span>"))
					}

					$TextFileContentResult += ("<tr><td><div>$($_.LinesNumbers[$i])</div></td><td>$content</td></tr>")
				}

				$TextFileContentResult += '</table></div>'
			}
		}
	}
}

[string]$cleanText = '<span class="match clean">Everything is clean</span>'

if ($TextFileExtension -eq '') { $TextFileExtension = 'None' }
if ($TextFileExtensionResults -eq '') { $TextFileExtensionResults = $cleanText }
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileExtension%", ($TextFileExtension) } | Set-Content $Result_File
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileExtensionResults%", ($TextFileExtensionResults) } | Set-Content $Result_File

if ($TextDeniedContent -eq '') { $TextDeniedContent = 'None' }
if ($TextFileNameResult -eq '') { $TextFileNameResult = $cleanText }
if ($TextFileContentResult -eq '') { $TextFileContentResult = $cleanText }
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%DeniedContent%", ($TextDeniedContent) } | Set-Content $Result_File
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileNameResult%", ($TextFileNameResult) } | Set-Content $Result_File
(Get-Content $Result_File) | ForEach-Object { $_ -replace "%FileContentResult%", ($TextFileContentResult) } | Set-Content $Result_File