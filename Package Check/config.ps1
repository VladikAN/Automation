# https://github.com/VladikAN/Daily-Stuff/tree/master/Package Check

# Files to ignore
$ExcludeFiles = @(
    '\.eot$',
    '\.woff$',
    '\.woff2$',
    '\.xpi$',
    '\.ttf$',
    '\.chm$',
    '\.exe$',
    '\.dll$',
    '\.gif$',
    '\.png$',
    '\.jpg$',
    '\.jpeg$',
    '\.nupkg$',
    '\.nuspec$')

# Content to search
$DeniedContent = @(
    '\.myconf',
    'invalid',
    'companyname',
    'MYCOMPANY')