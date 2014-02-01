Sometimes I need to prepare software package (ex. source files) and this package must be clear from any relation to me. This powershell script do magic and checks specified folder for some unexpected content. As result script will create 'result.html' with check summary.
Try run.ps1, by default it configured to .\Tests folder

Input parameters:
* TargetPath - target folder to check;
* DeniedContentPath - path to *.conf file with regex patterns. Used to check files content using regex patterns;
* DeniedFilesPath - path to *.conf file with regex patterns. Used to check files names using regex patterns;
* ExcludeFilesPath - path to *.conf file with regex patterns. Used to filter target files (such files like *.jpg or *.png don't needs content check).
* TemplateFileHTML - path to template.html;
* OutputFileHTML - path to place output result.