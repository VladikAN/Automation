## Description
Sometimes I need to prepare software package (ex. source files) and this package must be clear from any relation to me or my team. This powershell script do magic and checks specified folder for some unexpected content. As result script will create HTML file with check summary.


### Parameters
+ TargetPath - Target folder destination;
+ DeniedContentPath - Content config destination. Contains regular exressions, matced files will be added to result list;
+ DeniedFilesPath - Denied files config destination. Contains regular expressions, matced files will be added to result list;
+ ExcludeFilesPath - Exclude files config destination. Contains regular exressions, matched files will be skipped during content check;
+ TemplateFileHTML - Destination to HTML result template;
+ OutputFileHTML - Output file destination.


### Example
Try run.ps1, by default it configured to .\Tests folder
