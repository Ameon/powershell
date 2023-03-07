# Создаем папку для ssh, если она существует выводим ошибку
function New-CreateDirSsh {
  # Проверяем, существует ли папка "C:\Users\Username\Documents"
  if (Test-IsDir "$env:USERPROFILE\.ssh\$args\") {
    Write-Host "Ошибка: " -NoNewline -ForegroundColor Red
    Write-Host "Папка существует." -ForegroundColor DarkYellow
    
  } else {
    ni -I "directory" -P $env:USERPROFILE\.ssh\$args\ | Out-Null
    Write-Host "Создана папка "  -NoNewline -ForegroundColor Green
    Write-Host $env:USERPROFILE\.ssh\$args\ -ForegroundColor Magenta
  }
  
}
New-Alias 'cds' New-CreateDirSsh

# Генерация нового ключа
function Generate-SSHKey {
  param (
    [Parameter(Mandatory=$true)]
    [string]$KeyPath,
    [Parameter(Mandatory=$true)]
    [string]$KeyName
  )
  # Проверяем, существует ли файл ключа
  $FullPath = Join-Path $KeyPath $KeyName
  if (Test-Path $FullPath) {
    throw "Ключ $FullPath уже существует."
  }
  # Генерируем новый ключ
  ssh-keygen -t ed25519 -N "" -f $FullPath
}

function Add-SSHServer {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Имя хоста или IP-адрес SSH-сервера')]
    [Alias('s')]
    [string]$Server,

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'Имя пользователя, которое будет использоваться при подключении к SSH-серверу.')]
    [Alias('u')]
    [string]$Username = $env:USERNAME,

    [Parameter(Mandatory = $false, Position = 2, HelpMessage = 'Порт, используемый при подключении к SSH-серверу.')]
    [Alias('p')]
    [int]$Port = 22,

    [Parameter(Mandatory = $false, Position = 3, HelpMessage = 'Путь к файлу закрытого ключа для использования при подключении к серверу SSH.')]
    [Alias('k')]
    [string]$PrivateKey = $null
  )
  # Путь к конфигурационному файлу ssh
  $config_file = "$env:USERPROFILE\.ssh\config"

  # Проверяем наличие конфигурационного файла
  if (!(Test-Path $config_file)) {
    # Если файл не существует, создаем его
    New-Item -ItemType File $config_file | Out-Null
  }

  # Создаем объект для работы с конфигурационным файлом
  $ssh_config = New-Object -TypeName OpenSSHUtils.SshConfigFile -ArgumentList $config_file

  # Добавляем параметры подключения
  $server_config.AddParameter("User", $Username)
  $server_config.AddParameter("Port", $Port)

  # Если задан путь к приватному ключу, добавляем его в конфигурацию сервера
  if ($PrivateKey) {
    $key_file = Get-Item $PrivateKey

    if ($key_file.Extension -eq '.ppk') {
      # Конвертируем PuTTY-ключ в OpenSSH-формат
      $private_key = & "$env:ProgramFiles\PuTTY\puttygen.exe" $PrivateKey -O private-openssh
      $private_key = [System.Text.Encoding]::UTF8.GetString($private_key)

      $server_config.AddParameter("IdentityFile", $private_key)
    } else {
      $server_config.AddParameter("IdentityFile", $PrivateKey)
    }
  }

  # Добавляем элемент конфигурации сервера в конфигурационный файл
  $ssh_config.AddHost($server_config)

  # Сохраняем изменения
  $ssh_config.Save()

  Write-Host "Сервер $Server успешно добавлен в конфигурационный файл ssh."

}

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
    # Извлекаем имя сервера из строки конфигурации
    $server = $_.Split(" ")[1]

    # Возвращаем имя сервера
    $server
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

        $key = Resolve-Path $key

        if (-not (Test-Path $key)) {
          throw "Key file not found: $key"
        }

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
New-Alias 'getkey' Get-SSHKeyByHostName