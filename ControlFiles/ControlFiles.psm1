# 9. ”правление файлами

function Touch-File {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FileName,
    [datetime]$DateTime,
    [Parameter(Mandatory=$false, Position=1)]
    [string]$Path = (Get-Location).Path
    # [string]$FileName,
    # [datetime]$DateTime
  )
  $fullPath = Join-Path $Path $FileName
  if (-not $PSBoundParameters.ContainsKey('DateTime')) {
    $DateTime = Get-Date
  }
  if (Test-Path $fullPath) {
    (Get-Item $fullPath).LastWriteTime = $DateTime
  } else {
    New-Item -ItemType File -Path $fullPath | Out-Null
  }
}
New-Alias touch Touch-File