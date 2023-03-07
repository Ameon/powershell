# ������� ����� ��� ssh, ���� ��� ���������� ������� ������
function New-CreateDirSsh {
  # ���������, ���������� �� ����� "C:\Users\Username\Documents"
  if (Test-IsDir "$env:USERPROFILE\.ssh\$args\") {
    Write-Host "������: " -NoNewline -ForegroundColor Red
    Write-Host "����� ����������." -ForegroundColor DarkYellow
    
  } else {
    ni -I "directory" -P $env:USERPROFILE\.ssh\$args\ | Out-Null
    Write-Host "������� ����� "  -NoNewline -ForegroundColor Green
    Write-Host $env:USERPROFILE\.ssh\$args\ -ForegroundColor Magenta
  }
  
}
New-Alias 'cds' New-CreateDirSsh

# ��������� ������ �����
function Generate-SSHKey {
  param (
    [Parameter(Mandatory=$true)]
    [string]$KeyPath,
    [Parameter(Mandatory=$true)]
    [string]$KeyName
  )
  # ���������, ���������� �� ���� �����
  $FullPath = Join-Path $KeyPath $KeyName
  if (Test-Path $FullPath) {
    throw "���� $FullPath ��� ����������."
  }
  # ���������� ����� ����
  ssh-keygen -t ed25519 -N "" -f $FullPath
}

function Add-SSHServer {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = '��� ����� ��� IP-����� SSH-�������')]
    [Alias('s')]
    [string]$Server,

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = '��� ������������, ������� ����� �������������� ��� ����������� � SSH-�������.')]
    [Alias('u')]
    [string]$Username = $env:USERNAME,

    [Parameter(Mandatory = $false, Position = 2, HelpMessage = '����, ������������ ��� ����������� � SSH-�������.')]
    [Alias('p')]
    [int]$Port = 22,

    [Parameter(Mandatory = $false, Position = 3, HelpMessage = '���� � ����� ��������� ����� ��� ������������� ��� ����������� � ������� SSH.')]
    [Alias('k')]
    [string]$PrivateKey = $null
  )
  # ���� � ����������������� ����� ssh
  $config_file = "$env:USERPROFILE\.ssh\config"

  # ��������� ������� ����������������� �����
  if (!(Test-Path $config_file)) {
    # ���� ���� �� ����������, ������� ���
    New-Item -ItemType File $config_file | Out-Null
  }

  # ������� ������ ��� ������ � ���������������� ������
  $ssh_config = New-Object -TypeName OpenSSHUtils.SshConfigFile -ArgumentList $config_file

  # ��������� ��������� �����������
  $server_config.AddParameter("User", $Username)
  $server_config.AddParameter("Port", $Port)

  # ���� ����� ���� � ���������� �����, ��������� ��� � ������������ �������
  if ($PrivateKey) {
    $key_file = Get-Item $PrivateKey

    if ($key_file.Extension -eq '.ppk') {
      # ������������ PuTTY-���� � OpenSSH-������
      $private_key = & "$env:ProgramFiles\PuTTY\puttygen.exe" $PrivateKey -O private-openssh
      $private_key = [System.Text.Encoding]::UTF8.GetString($private_key)

      $server_config.AddParameter("IdentityFile", $private_key)
    } else {
      $server_config.AddParameter("IdentityFile", $PrivateKey)
    }
  }

  # ��������� ������� ������������ ������� � ���������������� ����
  $ssh_config.AddHost($server_config)

  # ��������� ���������
  $ssh_config.Save()

  Write-Host "������ $Server ������� �������� � ���������������� ���� ssh."

}

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
    # ��������� ��� ������� �� ������ ������������
    $server = $_.Split(" ")[1]

    # ���������� ��� �������
    $server
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

        $key = Resolve-Path $key

        if (-not (Test-Path $key)) {
          throw "Key file not found: $key"
        }

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
New-Alias 'getkey' Get-SSHKeyByHostName