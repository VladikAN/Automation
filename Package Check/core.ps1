function Check-Directory
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[string]$TargetPath,
		
		[string]$DeniedContentPath = '.\denied content.conf',
		[string]$ExcludeFilesPath = '.\exclude files.conf',

		[Parameter(Mandatory=$true)]
		[string]$TemplateFileHTML,

		[Parameter(Mandatory=$true)]
		[string]$OutputFileHTML
	)

	begin
	{
		Add-Type -AssemblyName System.Web

		# preparing environment variables
		$TargetPath = $TargetPath.ToLower()
		[string[]]$Search_ContentRegex = Get-Content $DeniedContentPath
		[string[]]$Search_ExcludeFiles = Get-Content $ExcludeFilesPath

		$ResultObjectDefinition = @{ FileName = ''; LinesNumbers = @(); LinesContent = @(); LinesMatch = @(); }

		# Preparing express regex patterns
		[string]$Search_ContentRegex_Common = '(?>' + (($Search_ContentRegex | ForEach-Object { @("({0})" -f $_) }) -join '|') + ')'
		[string]$Search_ExcludeFiles_Common = '(?>' + (($Search_ExcludeFiles | ForEach-Object { @("({0})" -f $_) }) -join '|') + ')'

		# Filling target items array
		$AllItemsFiles = @{}
		$ContentFiles = @{}
		Get-ChildItem $TargetPath -Force -Recurse | ForEach-Object {
			$fullName = $_.FullName.ToLower()
			$key = $fullName.replace($TargetPath, '\');

			$AllItemsFiles[$key] = $fullName
			if (!$_.PSIsContainer -and $fullName -notmatch $Search_ExcludeFiles_Common) {
				$ContentFiles[$key] = $fullName
			}
		}

		Write-Output "[info] $($AllItemsFiles.Count) files"
		Write-Output "[info] $($ContentFiles.Count) content files"
	}

	process
	{
		# Checking files names
		$Result_FileNames = @{}
		Write-Output "`r`n[info] File names check..."
		$Express_FileNames = $AllItemsFiles.GetEnumerator() | Where-Object { $_.Key -match $Search_ContentRegex_Common } | Select -uniq -ExpandProperty Key
		if ($Express_FileNames) {
			ForEach ($token in $Search_ContentRegex) {
				$Express_FileNames | Where-Object { $_ -match $token } | ForEach-Object {
					if (-not $Result_FileNames.ContainsKey($token)) { $Result_FileNames[$token] = @() }
					$Result_FileNames[$token] += $_
					Write-Output "[match] $($_)"
				}
			}
		}

		# Checking files content
		$Result_FileContent = @{}
		Write-Output "`r`n[info] File content check..."
		$Express_FileContent = $ContentFiles.GetEnumerator() | Where-Object { (Get-Content -Path $_.Value) -match $Search_ContentRegex_Common } | Select -uniq -ExpandProperty Key
		if ($Express_FileContent) {
			ForEach ($token in $Search_ContentRegex) {
				$Express_FileContent | ForEach-Object {
					$resultObj = New-Object PSObject -Property $ResultObjectDefinition
					$matches = Select-String -Path $ContentFiles[$_] -Pattern $token -AllMatches | Foreach {
						$resultObj.LinesNumbers += $_.LineNumber
						$resultObj.LinesContent += $_.Line
						$resultObj.LinesMatch += $_.Matches
					}

					if ($resultObj.LinesMatch.Length -and $resultObj.LinesMatch.Length.ToString() -ne '0') {
						$resultObj.FileName = $_
						$resultObj.LinesMatch = $resultObj.LinesMatch | Select -uniq

						if (-not $Result_FileContent.ContainsKey($token)) { $Result_FileContent[$token] = @() }
						$Result_FileContent[$token] += $resultObj
						Write-Output "[match] $($_) matches: $($resultObj.LinesNumbers.Length)"
					}
				}
			}
		}
	}

	end
	{
		# Creating result
		Copy-Item $TemplateFileHTML $OutputFileHTML

		# Printing files names
		[string]$TextDeniedContent = ''
		if ($Search_ContentRegex)
		{
			$Search_ContentRegex | ForEach-Object { $TextDeniedContent += @("`r`n<div class='pattern {0}'>{1}</div>" -f $(if($Result_FileNames.ContainsKey($_) -or $Result_FileContent.ContainsKey($_)) { "invalid" } else { "valid" }), $_) }
		}

		[string]$TextFileNameResult = ''
		if ($Result_FileNames.GetEnumerator().Length -ne 0)
		{
			$Result_FileNames.GetEnumerator() | ForEach-Object {
				$key = $_.Key
				$value = $_.Value
				
				ForEach ($fileName in $value){
					([regex]$key).Matches($filename) | Select -uniq | Foreach { $fileName = $fileName.replace($_, ("<mark>$_</mark>")) }
					$TextFileNameResult += ("`r`n<p>$fileName</p>")
				}
			}
		}

		# Printing content results
		[string]$TextFileContentResult = ''
		if ($Result_FileContent.GetEnumerator().Length -ne 0)
		{
			$Result_FileContent.GetEnumerator() | ForEach-Object {
				$token = $_.Key
				$obj = $_.Value
				
				if ($obj.Length -ne 0)
				{
					$TextFileContentResult += ("`r`n<div class='pattern invalid'>$token</div>")
				
					$obj | ForEach-Object {	
						$TextFileContentResult += "`r`n<div class=""file-table-wrapper"">`r`n<table class=""file-table"">"
						$TextFileContentResult += ("`r`n<tr>`r`n<th colspan='2'>$($_.FileName)</th>`r`n</tr>")
						
						for ($i = 0; $i -le $_.LinesNumbers.Length - 1; $i++) {
							$content = [System.Web.HttpUtility]::HtmlEncode($_.LinesContent[$i])
							$_.LinesMatch | Foreach { $content = $content.replace($_, ("<mark>$_</mark>")) }

							$TextFileContentResult += @("`r`n<tr>`r`n<td>`r`n<div>{0}</div>`r`n</td>`r`n<td>{1}</td>`r`n</tr>" -f $_.LinesNumbers[$i], $content)
						}

						$TextFileContentResult += "`r`n</table>`r`n</div>"
					}
				}
			}
		}

		[string]$cleanText = "`r`n<b>No results to display</b>"

		if ($TextDeniedContent -eq '') { $TextDeniedContent = 'None' }
		if ($TextFileNameResult -eq '') { $TextFileNameResult = $cleanText }
		if ($TextFileContentResult -eq '') { $TextFileContentResult = $cleanText }
		(Get-Content $OutputFileHTML) | ForEach-Object { $_ -replace "%DeniedContent%", ($TextDeniedContent) } | Set-Content -Encoding UTF8 $OutputFileHTML
		(Get-Content $OutputFileHTML) | ForEach-Object { $_ -replace "%FileNameResult%", ($TextFileNameResult) } | Set-Content -Encoding UTF8 $OutputFileHTML
		(Get-Content $OutputFileHTML) | ForEach-Object { $_ -replace "%FileContentResult%", ($TextFileContentResult) } | Set-Content -Encoding UTF8 $OutputFileHTML
	}
}