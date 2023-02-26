# Возможно для работы скрипта нужно будет на компе разрешить выполнение сценариев:
# Решение проблемы:
#	• Открываем терминал от админа.
#	• Пишем и запускаем: Set-ExecutionPolicy RemoteSigned
#   • На вопрос отвечаем: A (Да для всех)  (у меня вообще без вопросов заработало)


# 1. чекать вначале в сохраненном файлике булевую переменную, которая подскажет, запущена ли сессия
# если сессия уже запущена - выводим сообщение - завершить рабочую сессию - если ответ "Ок" - завершаем все, что в файлике приведено (или файликах)
# если сессия не запущена - запускаем сразу все.

# $app = Start-Process OneNote: -passthru
# Wait-Process $app.Id
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ProcessesHandlesFilePath = Join-Path $ENV:temp 'processhandles.xml' # ЗАДАТЬ один путь, чтоб всегда был один и тот же

# Если файлик с путями до xml-файлов, хранящих инфу о запущенных процессах, есть...
if(Test-Path -Path $ProcessesHandlesFilePath -PathType Leaf)
{
    # Закрываем эти все процессы
    foreach($line in Get-Content $ProcessesHandlesFilePath)
    {
    }
}

# Start
# $proc = Start-Process notepad -Passthru
# $proc | Export-Clixml -Path (Join-Path $ENV:temp 'processhandle.xml')
# $proc | Export-Clixml -Path (Join-Path $DesktopPath 'processhandle.xml')

# Stop
# $proc = Import-Clixml -Path (Join-Path $DesktopPath 'processhandle.xml')
# $proc | Stop-Process

# Добавить сюда имена/пути всех нужных приложений
function Get-ProcessesToStartNames {
    [OutputType([System.String[]])]
    param(
        
    )

    "notepad"
    # "OneNote:"
    # "C:\Users\Tims\AppData\Roaming\Reddy\Reddy.exe"
    # "C:\Program Files\SmartGit\bin\smartgit.exe"
}

# Отобразить в виде уведомления ошибки
function Notify-Errors
{
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$errors
    )

    if($errors.Count -le 0)
    {
        return;
    }

    Add-Type -AssemblyName System.Windows.Forms 
    $global:balloon = New-Object System.Windows.Forms.NotifyIcon
    $path = (Get-Process -id $pid).Path
    $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path) 
    $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
    $balloon.BalloonTipText = $errors
    $balloon.BalloonTipTitle = "Attention $Env:USERNAME" 
    $balloon.Visible = $true 
    $balloon.ShowBalloonTip(5000)
}

# Write-Debug Get-ProcessesToStartNames
[string[]]$processesNames = Get-ProcessesToStartNames
Write-Host $processesNames.ToString()
Write-Host $processesNames

# $processHandlesXmls = @();
$processHandlesXmls = New-Object System.Collections.ArrayList;
foreach($processName in $processesNames)
{
    $guid = [guid]::NewGuid()    
    $process = Start-Process $processName -Passthru
    $processHandleXmlFileName = "$($guid)$($process.Id).xml"
    $processHandleXmlFilePath = Join-Path $DesktopPath $processHandleXmlFileName
    Write-Host $processHandleXmlFileName

    $process | Export-Clixml -Path $processHandleXmlFilePath

    # Сохранить эту тему в файлик по однозначному пути в переменной $ProcessesHandlesFilePath; и как писал вначале, в файлике установить булевую переменную true - есть сессия
    # при повторном нажатии на скрипт - считываем оттуда что нам нужно закрыть
    $processHandlesXmls.Add($processHandleXmlFilePath);
}

# Stop
# $proc = Import-Clixml -Path (Join-Path $DesktopPath 'processhandle.xml')
# $proc | Stop-Process
$errors = New-Object System.Collections.ArrayList;
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
        $errors.Add("Error occured when stopping process with id: $($process.Id), $($process)")
    }
}

Notify-Errors $errors