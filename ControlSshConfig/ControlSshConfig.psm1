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
  $HostInput = Read-ColoredLine -Prompt "������� ����� ssh �������: "# -ForegroundColor Green
  $Host_0 = [string]$HostInput

  if(Test-SSHHost $Host_0){
    $HostnameInput = Read-ColoredLine -Prompt "������� ����� �������: "
    $PassworInput = Read-ColoredLine -Prompt "������� ������ ��� root: "
    if(New-DirSsh $HostInput){
      if(New-SSHKey $env:USERPROFILE\.ssh\$HostInput){
        New-SetupServer $HostInput $HostnameInput "~/.ssh/$HostInput/id_ed25519"
        
      
      }
      
    }
  }
  
  # $Multiplier = [int]$UserInput2

  # $Step1Result = $Number * $Multiplier

  # $UserInput3 = Read-Host "������� �������� ��� ����������"
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
      Write-Host "������: " -NoNewline -ForegroundColor Red
      Write-Host "Host � ��������� " -NoNewline -ForegroundColor Yellow
      Write-Host $HostName -NoNewline -ForegroundColor Blue
      Write-Host " ��� ���������� � " -NoNewline -ForegroundColor Yellow
      Write-Host $FilePath -ForegroundColor Magenta
      return 0
    }
    else {
      Write-Host "OK... " -NoNewline -ForegroundColor Green
      Write-Host "Host � ��������� " -NoNewline -ForegroundColor Yellow
      Write-Host $HostName -NoNewline -ForegroundColor Blue
      Write-Host " �� ���������� � " -NoNewline -ForegroundColor Yellow
      Write-Host $FilePath -ForegroundColor Magenta
      return 1
    }
  }
  else {
    Write-Output "SSH config file $FilePath �� ���������"
  }
}
New-Alias 'th' Test-SSHHost

# 1. ������� ����� ��� ssh, ���� ��� ���������� ������� ������
function New-DirSsh {
  # ���������, ���������� �� ����� "C:\Users\Username\Documents"
  if (Test-IsDir "$env:USERPROFILE\.ssh\$args\") {
    Write-Host "������: " -NoNewline -ForegroundColor Red
    Write-Host "����� ����������." -ForegroundColor DarkYellow
    return 0
  } else {
    ni -I "directory" -P $env:USERPROFILE\.ssh\$args\ | Out-Null
    Write-Host "OK... "  -NoNewline -ForegroundColor Green
    Write-Host "������� ����� "  -NoNewline -ForegroundColor Yellow
    Write-Host $env:USERPROFILE\.ssh\$args\ -ForegroundColor Magenta
    return 1
  }
}
New-Alias 'nds' New-DirSsh

# 2. ��������� ������ SSH-�����
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

  # ���������, ���������� �� ���� �����
  if (Test-Path $FullPath) {
    throw "���� $FullPath ��� ����������."
  }else{
    # ���������� ����� ����
    ssh-keygen -f $FullPath -N '""' -t ed25519 
    return 1
  }

}
New-Alias 'newkey' New-SSHKey

function New-SetupServer {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'O��������� ��� ��� ��������� �����')]
    [Alias('a')]
    [string]$HostAlias,
    [Parameter(Mandatory = $true, Position = 1, HelpMessage = '��� ����� ��� IP-����� SSH-�������')]
    [Alias('h')]
    [string]$Hostname,
    [Parameter(Mandatory = $true, Position = 2, HelpMessage = '���� � ����� ��������� ����� ��� ������������� ��� ����������� � ������� SSH.')]
    [Alias('k')]
    [string]$PrivateKeyPath,
    #[string]$PrivateKey = $null,
    [Parameter(Mandatory = $false, Position = 3, HelpMessage = '����, ������������ ��� ����������� � SSH-�������.')]
    [Alias('p')]
    [int]$Port = 22,
    [Parameter(Mandatory = $false, Position = 4, HelpMessage = '��� ������������, ������� ����� �������������� ��� ����������� � SSH-�������.')]
    [Alias('u')]
    [string]$Username = "root"
  )

  # ���� � ����������������� ����� ssh
  $config_file = "$env:USERPROFILE\.ssh\config"

  # ������� ������ ��� ������ � ���������������� ������
  #$ssh_config = New-Object -TypeName OpenSSHUtils.SshConfigFile -ArgumentList $config_file

  # # ��������� ��������� �����������
  # $server_config.AddParameter("User", $Username)
  # $server_config.AddParameter("Port", $Port)

  # ���� ����� ���� � ���������� �����, ��������� ��� � ������������ �������
  if ($PrivateKeyPath) {
    $key_file = Get-Item $PrivateKeyPath

    if ($key_file.Extension -eq '.ppk') {
      # ������������ PuTTY-���� � OpenSSH-������
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
    # ��������� ������� ������������ ������� � ���������������� ����
    Add-Content $config_file $config
    }
  }

  Write-Host "������ $Server ������� �������� � ���������������� ���� ssh."

}

# ������� ������ �������� �� ����� config

function Get-SSHServerList {
  # ���� � ����������������� ����� ssh
  $config_file = "$env:USERPROFILE\.ssh\config"

  # ��������� ������� ����������������� �����
  if (!(Test-Path $config_file)) {
    Write-Warning "���������������� ���� $config_file �� ������."
    return
  }

  # ������ ���������� ����� � ���� ������, ������������ � "Host"
  Get-Content $config_file | Where-Object { $_.StartsWith("Host ") } | ForEach-Object {
    # ��������� ��� ������� �� ������ ������������ � �������
    Write-Host $_.Split(" ")[1] -ForegroundColor Blue

  }
}



function Find-SSHKeyByHostName {

  # ��������� �������� �������, ������� ������ ���� ������� � ������������.
  param(
    [Parameter(Mandatory = $true)]
    [string]$HostName
  )

  # ���������� � ����� � ����� ������������ SSH � �������� ���������� ������������.
  $sshConfigPath = "$env:USERPROFILE\.ssh\config"

  # ������ ������ ����� ������������ �����
  $hostEntryStartPattern = "Host "

  # ������ ������ ���������� �����
  $pubKeyStartPattern = "IdentityFile"

  # ���������� �����, ������� �� ����� ���������.
  $key = ""
    
  try {
    $sshConfig = Get-Content $sshConfigPath -ErrorAction Stop

    # ������������� ����, ����������� �� ��, ��� �� ��� �� ����� ���� ������������ ��� ��������� ����� �����.
    $foundHostEntry = $false

    # ���� �� ������� ����������������� �����.
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
        # �������� ���������� ���������� �����
        $key = Get-Content $key -Raw
        break
      }
    }

    # ���� �� �� ����� ���� ������������ ��� ��������� ����� �����
    if (-not $foundHostEntry) {
      # ����������� ����������
      throw "Host not found: $HostName"
    }

    # ���� ���� ������������ ��� ������, �� ������� ���� �� �����
    Write-Output $key

  } 
  catch {
    Write-Error $_.Exception.Message
  }
}
New-Alias 'getkey' Find-SSHKeyByHostName