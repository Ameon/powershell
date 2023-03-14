Add-Type -AssemblyName System.Drawing

function Read-ColoredLine {
  param(
    [string]$Prompt,
    [System.ConsoleColor]$ForegroundColor = "Yellow"
  )
  Write-Host -NoNewline $Prompt -ForegroundColor $ForegroundColor
  #-BackgroundColor B
  return [Console]::ReadLine()
}

function Invoke-TestHost {
  $HostInput = Read-ColoredLine -Prompt "Введите алиас ssh сервера: "# -ForegroundColor Green
  $Host_0 = [string]$HostInput

  if(Test-SSHHost $Host_0){
    $HostnameInput = Read-ColoredLine -Prompt "Введите адрес сервера: "
    $PassworInput = Read-ColoredLine -Prompt "Введите пароль для root: "
    if(New-DirSsh $HostInput){
      if(New-SSHKey $env:USERPROFILE\.ssh\$HostInput){
        New-SetupServer $HostInput $HostnameInput "~/.ssh/$HostInput/id_ed25519"
        
      
      }
      
    }
  }
  
  # $Multiplier = [int]$UserInput2

  # $Step1Result = $Number * $Multiplier

  # $UserInput3 = Read-Host "Введите значение для добавления"
  # $ValueToAdd = [int]$UserInput3

  # $Step2Result = $Step1Result + $ValueToAdd

  #return $Host_0
}
New-Alias 'test_host' Invoke-TestHost

function Test-SSHHost {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true, Position=0)]
    [Alias('h')]
    [string]$HostName,
    
    [Parameter(Position=1)]
    [Alias('f')]
    [string]$FilePath = "$env:USERPROFILE\.ssh\config"
  )

  if (Test-Path -Path $FilePath) {
    $configFileContent = Get-Content -Path $FilePath

    if ($configFileContent -match "Host\s+$HostName\b") {
      Write-Host "Ошибка: " -NoNewline -ForegroundColor Red
      Write-Host "Host с названием " -NoNewline -ForegroundColor Yellow
      Write-Host $HostName -NoNewline -ForegroundColor Blue
      Write-Host " уже существует в " -NoNewline -ForegroundColor Yellow
      Write-Host $FilePath -ForegroundColor Magenta
      return 0
    }
    else {
      Write-Host "OK... " -NoNewline -ForegroundColor Green
      Write-Host "Host с названием " -NoNewline -ForegroundColor Yellow
      Write-Host $HostName -NoNewline -ForegroundColor Blue
      Write-Host " не существует в " -NoNewline -ForegroundColor Yellow
      Write-Host $FilePath -ForegroundColor Magenta
      return 1
    }
  }
  else {
    Write-Output "SSH config file $FilePath не существут"
  }
}
New-Alias 'th' Test-SSHHost

# 1. Создаем папку для ssh, если она существует выводим ошибку
function New-DirSsh {
  # Проверяем, существует ли папка "C:\Users\Username\Documents"
  if (Test-IsDir "$env:USERPROFILE\.ssh\$args\") {
    Write-Host "Ошибка: " -NoNewline -ForegroundColor Red
    Write-Host "Папка существует." -ForegroundColor DarkYellow
    return 0
  } else {
    ni -I "directory" -P $env:USERPROFILE\.ssh\$args\ | Out-Null
    Write-Host "OK... "  -NoNewline -ForegroundColor Green
    Write-Host "Создана папка "  -NoNewline -ForegroundColor Yellow
    Write-Host $env:USERPROFILE\.ssh\$args\ -ForegroundColor Magenta
    return 1
  }
}
New-Alias 'nds' New-DirSsh

# 2. Генерация нового SSH-ключа
function New-SSHKey {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$false)]
    [Alias('p')]
    [string]$Path = (Get-Location).Path,
    [Parameter(Mandatory=$false)]
    [Alias('n')]
    [string]$KeyName = "id_ed25519"
    
  )

  $FullPath = Join-Path $Path $KeyName
  Write-Host $FullPath

  # Проверяем, существует ли файл ключа
  if (Test-Path $FullPath) {
    throw "Ключ $FullPath уже существует."
  }else{
    # Генерируем новый ключ
    ssh-keygen -f $FullPath -N '""' -t ed25519 
    return 1
  }

}
New-Alias 'newkey' New-SSHKey

function New-SetupServer {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Oпределяет имя или псевдоним хоста')]
    [Alias('a')]
    [string]$HostAlias,
    [Parameter(Mandatory = $true, Position = 1, HelpMessage = 'Имя хоста или IP-адрес SSH-сервера')]
    [Alias('h')]
    [string]$Hostname,
    [Parameter(Mandatory = $true, Position = 2, HelpMessage = 'Путь к файлу закрытого ключа для использования при подключении к серверу SSH.')]
    [Alias('k')]
    [string]$PrivateKeyPath,
    #[string]$PrivateKey = $null,
    [Parameter(Mandatory = $false, Position = 3, HelpMessage = 'Порт, используемый при подключении к SSH-серверу.')]
    [Alias('p')]
    [int]$Port = 22,
    [Parameter(Mandatory = $false, Position = 4, HelpMessage = 'Имя пользователя, которое будет использоваться при подключении к SSH-серверу.')]
    [Alias('u')]
    [string]$Username = "root"
  )

  # Путь к конфигурационному файлу ssh
  $config_file = "$env:USERPROFILE\.ssh\config"

  # Создаем объект для работы с конфигурационным файлом
  #$ssh_config = New-Object -TypeName OpenSSHUtils.SshConfigFile -ArgumentList $config_file

  # # Добавляем параметры подключения
  # $server_config.AddParameter("User", $Username)
  # $server_config.AddParameter("Port", $Port)

  # Если задан путь к приватному ключу, добавляем его в конфигурацию сервера
  if ($PrivateKeyPath) {
    $key_file = Get-Item $PrivateKeyPath

    if ($key_file.Extension -eq '.ppk') {
      # Конвертируем PuTTY-ключ в OpenSSH-формат
      $private_key = & "$env:ProgramFiles\PuTTY\puttygen.exe" $PrivateKeyPath -O private-openssh
      $private_key = [System.Text.Encoding]::UTF8.GetString($private_key)

      $server_config.AddParameter("IdentityFile", $private_key)
    } else {
          $config = @"

Host $HostAlias
  Port $Port
  HostName $Hostname
  IdentityFile $PrivateKeyPath
  User $Username
"@
    # Добавляем элемент конфигурации сервера в конфигурационный файл
    Add-Content $config_file $config
    }
  }

  Write-Host "Сервер $Server успешно добавлен в конфигурационный файл ssh."

}

# Выводит список серверов из файла config

function Get-SSHServerList {
  # Путь к конфигурационному файлу ssh
  $config_file = "$env:USERPROFILE\.ssh\config"

  # Проверяем наличие конфигурационного файла
  if (!(Test-Path $config_file)) {
    Write-Warning "Конфигурационный файл $config_file не найден."
    return
  }

  # Читаем содержимое файла и ищем строки, начинающиеся с "Host"
  Get-Content $config_file | Where-Object { $_.StartsWith("Host ") } | ForEach-Object {
    # Извлекаем имя сервера из строки конфигурации и выводим
    Write-Host $_.Split(" ")[1] -ForegroundColor Blue

  }
}



function Find-SSHKeyByHostName {

  # Объявляем параметр функции, который должен быть строкой и обязательным.
  param(
    [Parameter(Mandatory = $true)]
    [string]$HostName
  )

  # Переменная с путем к файлу конфигурации SSH в домашней директории пользователя.
  $sshConfigPath = "$env:USERPROFILE\.ssh\config"

  # Шаблон поиска блока конфигурации хоста
  $hostEntryStartPattern = "Host "

  # Шаблон поиска публичного ключа
  $pubKeyStartPattern = "IdentityFile"

  # Переменная ключа, которую мы будем заполнять.
  $key = ""
    
  try {
    $sshConfig = Get-Content $sshConfigPath -ErrorAction Stop

    # Устанавливаем флаг, указывающий на то, что мы еще не нашли блок конфигурации для заданного имени хоста.
    $foundHostEntry = $false

    # Цикл по строкам конфигурационного файла.
    foreach ($line in $sshConfig) {
      if ($line.StartsWith($hostEntryStartPattern)) {
        if ($foundHostEntry) {
          break
        }

        $currentHostName = $line.Substring($hostEntryStartPattern.Length).Trim()

        if ($currentHostName -eq $HostName) {
          $foundHostEntry = $true
        }
      } elseif ($line.StartsWith($pubKeyStartPattern) -and $foundHostEntry) {

        $key = $line.Substring($pubKeyStartPattern.Length).Trim()

        if ($key.StartsWith("~")) {
          $key = $key.Replace("~", $env:USERPROFILE)
        }

        $key = Resolve-Path "$key.pub"

        if (-not (Test-Path $key)) {
          throw "Key file not found: $key"
        }
        # Получаем содержимое публичного ключа
        $key = Get-Content $key -Raw
        break
      }
    }

    # Если мы не нашли блок конфигурации для заданного имени хоста
    if (-not $foundHostEntry) {
      # Выбрасываем исключение
      throw "Host not found: $HostName"
    }

    # Если блок конфигурации был найден, мы выводим ключ на экран
    Write-Output $key

  } 
  catch {
    Write-Error $_.Exception.Message
  }
}
New-Alias 'getkey' Find-SSHKeyByHostName