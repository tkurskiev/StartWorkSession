# TODO: Закомментировать в конце лишние строки с "Write-Host"

# $DesktopPath = [Environment]::GetFolderPath("Desktop") - использовался в функции Start-ProcessesGettingHandlesXmls - где хранить эти xml-файлы
$ProcessesHandlesFilePath = Join-Path $ENV:temp 'processhandles.xml' # ЗАДАТЬ один путь, чтоб всегда был один и тот же

$handlesFileExists = Test-Path -Path $ProcessesHandlesFilePath -PathType Leaf
#$handlesFileExists | Export-Clixml -Path $ProcessesHandlesFilePath
Write-Host $handlesFileExists

# Добавить сюда имена/пути всех нужных приложений
function Get-ProcessesToStartNames {

    "notepad"
    # "notepad"
    # "OneNote:"
    # "C:\Users\Tims\AppData\Roaming\Reddy\Reddy.exe"
    # "C:\Program Files\SmartGit\bin\smartgit.exe"
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

            # Удаление файлов в конце - больше не нужны
            rm -fo $handle
        }
        catch [System.SystemException]
        {
            # $errors.Add("Error occured when stopping process with id: $($process.Id), $($process)")
        }
    }
}

# Запустить процессы с указанными именами/путями, вернув список путей до xml-файлов, хранящих инфу о каждом запущенном процессе
function Start-ProcessesGettingHandlesXmls
{
    param(
            [Parameter(Mandatory=$true)]
            [System.Collections.ArrayList]$processesNames
    )

    $processHandlesXmls = New-Object System.Collections.ArrayList;
    foreach($processName in $processesNames)
    {
        $guid = [guid]::NewGuid()    
        $process = Start-Process $processName -Passthru
        $processHandleXmlFileName = "$($guid)$($process.Id).xml"
        $processHandleXmlFilePath = Join-Path $ENV:temp $processHandleXmlFileName
        Write-Host $processHandleXmlFileName

        $process | Export-Clixml -Path $processHandleXmlFilePath

        $null = $processHandlesXmls.Add($processHandleXmlFilePath);
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
        Add-Content $ProcessesHandlesFilePath "`n$($handleXmlPath)"
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