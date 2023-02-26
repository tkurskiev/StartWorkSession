$process = Start-Process "OneNote:" -Passthru

$string = @"
C:\Program Files\OpenVPN\bin\openvpn-gui.exe = --command connect intra.ovpn
Msg2 = She said, "Hello, World."
Msg3 = Enter an alias (or "nickname").
"@

Write-Host $string

$hash = ConvertFrom-StringData $string

Write-Host $hash

$hash.GetEnumerator() | ForEach-Object {
    Write-Host "The value of '$($_.Key)' is: $($_.Value)"
}

# Записать в файл пути до xml-файлов, хранящих инфу о каждом запущенном процессе
function Write-HandlesXmlsPathsToFile
{
    param(
            [Parameter(Mandatory=$true)]
            [System.Collections.ArrayList]$handlesXmlsPaths
    )

    foreach($handleXmlPath in $handlesXmlsPaths)
    {
        Add-Content $ProcessesHandlesFilePath "`n$($handleXmlPath)"
    }
}

# Запустить процессы с указанными именами/путями, вернув список путей до xml-файлов, хранящих инфу о каждом запущенном процессе
function Start-ProcessesGettingHandlesXmls
{
    param(
            [Parameter(Mandatory=$true)]
            [System.Collections.Hashtable]$processesNames
    )

    $processHandlesXmls = New-Object System.Collections.ArrayList;

    $processesNames.GetEnumerator() | ForEach-Object {
        
        try
        {
            $processName = $_.Key
            $processCommandLineArguments = $_.Value

            if($processCommandLineArguments)
            {
                $process = Start-Process $processName -Passthru -ArgumentList $processCommandLineArguments
            }
            else
            {
                $process = Start-Process $processName -Passthru
            }

            $guid = [guid]::NewGuid()
            $processHandleXmlFileName = "$($guid)$($process.Id).xml"
            $processHandleXmlFilePath = Join-Path $ENV:temp $processHandleXmlFileName
            Write-Host $processHandleXmlFileName

            $process | Export-Clixml -Path $processHandleXmlFilePath

            $null = $processHandlesXmls.Add($processHandleXmlFilePath);
        }
        catch [System.SystemException]
        {
            # (!) Работает как "continue" в обычном foreach (https://stackoverflow.com/a/7763698/5706952)
            return;
        }
    }

    return $processHandlesXmls
}

# Добавить сюда имена/пути всех нужных приложений
function Get-ProcessesToStartNames {

    # "notepad"
    # "C:\Program Files\OpenVPN\bin\openvpn-gui.exe"
    # "notepad"
    # "OneNote:"
    # "C:\Users\Tims\AppData\Roaming\Reddy\Reddy.exe"
    # "C:\Program Files\SmartGit\bin\smartgit.exe"

    return $processesNameWithCommandLineArguments = @{
        
        "C:\Program Files\OpenVPN\bin\openvpn-gui.exe" = "--command connect intra.ovpn";
        "notepad" = $null;

    }
}

$processesNames = Get-ProcessesToStartNames
Write-Host $processesNames.ToString()
Write-Host $processesNames.GetType()

$handlesXmls = Start-ProcessesGettingHandlesXmls $processesNames
Write-HandlesXmlsPathsToFile $handlesXmls

Write-Host "This is test message"