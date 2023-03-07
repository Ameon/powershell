function Add-SSHKeyToServerDefaultConfig {
  [CmdletBinding()]
  param()

  $configPath = "$env:USERPROFILE\.ssh\config"
  $config = Get-Content $configPath

  $args = $PSBoundParameters.GetEnumerator() | Where-Object { $_.Key -ne "ServerAlias" }

  foreach ($serverLine in $config | Select-String -Pattern "^Host\s+\S+\s*$") {
    $serverAlias = ($serverLine | Select-Object -ExpandProperty Line).Trim().Replace("Host ", "")

    if ($serverAlias -in $args.Values) {
      $serverConfig = ($config | Select-String -Pattern "^Host\s+$serverAlias\s*$" -Context 1 | Select-Object -ExpandProperty Context | Select-Object -Skip 1 | Select-Object -First 1).Trim()

      $userName = ($serverConfig | Select-String -Pattern "^User\s+" | Select-Object -ExpandProperty Line).Replace("User ", "")
      $keyPath = ($serverConfig | Select-String -Pattern "^IdentityFile\s+" | Select-Object -ExpandProperty Line).Replace("IdentityFile ", "")

      $key = Get-Content $keyPath
      $session = New-PSSession -ComputerName $serverAlias -Credential $userName
      $command = "New-Item -ItemType Directory -Path ~/.ssh"
      Invoke-Command -Session $session -ScriptBlock { $using:command }
      $command = "echo `"$key`" >> ~/.ssh/authorized_keys"
      Invoke-Command -Session $session -ScriptBlock { $using:command }
      Remove-PSSession $session
    }
  }
}

function Add-SSHKeyToRemoteServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Alias
    )

    # # Check if OpenSSH module is installed
    # if (-not (Get-Module -Name OpenSSH)) {
    #     Write-Host "OpenSSH module not found. Please install the OpenSSH module for PowerShell." -ForegroundColor Red
    #     return
    # }

    # Get the SSH key from the config file
    $sshKey = ssh-add -L | Where-Object { $_.Contains($Alias) } | ForEach-Object {
        $_.Split(" ")[1]
    }

    # Check if the SSH key was found
    if (-not $sshKey) {
        Write-Host "SSH key not found for the alias $Alias" -ForegroundColor Red
        return
    }

    # Add the SSH key to the ssh-agent
    ssh-add $sshKey

    # Get the hostname from the config file
    $hostname = ssh-config -l | Where-Object { $_.Contains($Alias) } | ForEach-Object {
        $_.Split(" ")[1]
    }

    # Check if the hostname was found
    if (-not $hostname) {
        Write-Host "Hostname not found for the alias $Alias" -ForegroundColor Red
        return
    }

    # Add the SSH key to the authorized_keys file on the remote server
    $session = New-SSHSession -ComputerName $hostname -Credential (Get-Credential -Message "Enter the credentials for $hostname")
    $command = "echo $sshKey >> ~/.ssh/authorized_keys"
    Invoke-SSHCommand -SessionId $session.SessionId -Command $command

    # Close the SSH session
    Remove-SSHSession -SessionId $session.SessionId

    Write-Host "SSH key added for the alias $Alias" -ForegroundColor Green
}

function Add-SSHKey {
  Param (
    [Parameter(Mandatory=$true)]
    [string]$HostName
  )

  $configFile = "~/.ssh/config"
  $sshKeyFile = "~/.ssh/id_rsa.pub"

  # Find the line in the config file that starts with the given host name
  $line = Get-Content $configFile | Select-String -Pattern "^Host $HostName\s*$"
  if ($line -eq $null) {
      Write-Error "Could not find host '$HostName' in config file '$configFile'"
      return
  }

  # Extract the hostname and user from the config file
  $hostLine = $line.Line.Trim()
  $hostName = $hostLine.Substring(5).Trim()
  $userName = $null
  $tokens = $hostLine.Split()
  for ($i = 1; $i -lt $tokens.Count; $i++) {
    if ($tokens[$i].ToLower() -eq "user") {
      $userName = $tokens[$i+1]
      break
    }
  }

  if ($userName -eq $null) {
      # If user is not specified in the config file, use the current user
      $userName = $env:USERNAME
  }

  # Read the public key from the key file
  $sshKey = Get-Content $sshKeyFile

  # Add the key to the authorized_keys file on the remote server
  $command = "echo `$sshKey >> ~/.ssh/authorized_keys"
  $session = New-SSHSession -ComputerName $hostName -Credential $userName
  Invoke-SSHCommand -Session $session -Command $command
  Remove-SSHSession -Session $session

  Write-Output "Added SSH key to '$hostName'"
}

# function Get-ConfigKey {
#     param (
#         [string]$ConfigFilePath,    # путь к файлу конфигурации
#         [string]$KeyName,          # имя ключа, который нужно отправить
#         [string]$SSHServer,        # адрес сервера SSH
#         [string]$SSHUser,          # имя пользователя SSH
#         [string]$SSHPass           # пароль пользователя SSH
#     )

#     # Открываем файл конфигурации и ищем ключ по имени
#     $Config = Get-Content $ConfigFilePath
#     $Value = $Config | Select-String -Pattern "$KeyName\s*=\s*(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }