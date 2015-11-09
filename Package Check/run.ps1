# https://github.com/VladikAN/Continuous-Integration/tree/master/Package Check

. .\core.ps1
Check-Directory -TargetPath 'Tests\' -TemplateFileHTML 'template.html' -OutputFileHTML 'result.html'