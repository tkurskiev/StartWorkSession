# TODO: Закомментировать в конце лишние строки с "Write-Host"

# $DesktopPath = [Environment]::GetFolderPath("Desktop") - использовался в функции Start-ProcessesGettingHandlesXmls - где хранить эти xml-файлы
$ProcessesHandlesFilePath = Join-Path $ENV:temp 'processhandles.xml' # ЗАДАТЬ один путь, чтоб всегда был один и тот же

$handlesFileExists = Test-Path -Path $ProcessesHandlesFilePath -PathType Leaf
#$handlesFileExists | Export-Clixml -Path $ProcessesHandlesFilePath
Write-Host $handlesFileExists

# Добавить сюда имена/пути всех нужных приложений и соответствующие аргументы командной строки для них
function Get-ProcessesToStartNames {

    return $processesNameWithCommandLineArguments = [ordered]@{
        
        # "C:\Program Files\OpenVPN\bin\openvpn-gui.exe" = "--command connect intra.ovpn";
        # "C:\Users\Tims\AppData\Roaming\Reddy\Reddy.exe" = $null;
        # "C:\Program Files\SmartGit\bin\smartgit.exe" = $null;
        # "C:\Program Files\JetBrains\JetBrains Rider 2022.2.3\bin\rider64.exe" = $null;
        # # "C:\Users\Tims\AppData\Local\Postman\Postman.exe" = $null;6
        "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" = $null;
        # "C:\Program Files\3T Software Labs\Studio 3T\Studio 3T.exe" = $null;
        # "OneNote:" = $null;
        # "C:\Program Files\DBeaver\dbeaver.exe\" = "-nl ru\"

    }

}

# Прочитать пути до xml-файлов, хранящих инфу о запущенных процессах
function Read-HandlesXmlsPaths
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$filePath
    )

    $result = New-Object System.Collections.ArrayList
    foreach($line in Get-Content $filePath)
    {
        # из комментариев отсюда: https://stackoverflow.com/q/71917330/5706952
        $null = $result.Add($line)
    }

    return $result
}

# Остановить запущенные процессы на основе заданных путей до xml-файлов, хранящих инфу о них
function Stop-Processes
{
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.ArrayList]$processHandlesXmls
    )

    foreach($handle in $processHandlesXmls)
    {
    
        try
        {
            $process = Import-Clixml -Path $handle
            $stopProcessResult = $process | Stop-Process -ErrorAction SilentlyContinue -PassThru

            if(!$stopProcessResult)
            {
                # One more try
                $stopProcessResult = Stop-Process -processname $process.Name
            }

            # Удаление файлов в конце - больше не нужны
            rm -fo $handle
        }
        catch [System.SystemException]
        {
            # $errors.Add("Error occured when stopping process with id: $($process.Id), $($process)")
        }
    }
}

# Запустить процессы с указанными именами/путями и аргументами командной строки,
# вернув список путей до xml-файлов, хранящих инфу о каждом запущенном процессе
function Start-ProcessesGettingHandlesXmls
{
    param(
            [Parameter(Mandatory=$true)]
            [System.Collections.Specialized.OrderedDictionary]$processesNames
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

# Записать в файл пути до xml-файлов, хранящих инфу о каждом запущенном процессе
function Write-HandlesXmlsPathsToFile
{
    param(
            [Parameter(Mandatory=$true)]
            [System.Collections.ArrayList]$handlesXmlsPaths
    )

    foreach($handleXmlPath in $handlesXmlsPaths)
    {
        if($handleXmlPath)
        {
            Add-Content $ProcessesHandlesFilePath "`n$($handleXmlPath)"
        }
    }
}

# Если есть файл с путями до xml-файлов, хранящих инфу о запущенных процессах, значит рабочая сессия начата и в нем хранится инфа
if($handlesFileExists)
{
    # 1. Считать handles
    $handlesXmls = Read-HandlesXmlsPaths $ProcessesHandlesFilePath

    # 2. Завершить все процессы оттуда, удаляя файлики сами
    Stop-Processes $handlesXmls

    # 3. Удалить сам файл с путями до xml-файлов, хранящих инфу о запущенных процессах
    rm -fo $ProcessesHandlesFilePath

    # Завершаем на этом работу
    Exit
}

# else...
# Если файла с путями до xml-файлов, хранящих инфу о запущенных процессах, не существует, значит рабочая сессия не начата
$processesNames = Get-ProcessesToStartNames
Write-Host $processesNames.ToString()
Write-Host $processesNames

$handlesXmls = Start-ProcessesGettingHandlesXmls $processesNames
Write-HandlesXmlsPathsToFile $handlesXmls


Write-Host "Test Message"