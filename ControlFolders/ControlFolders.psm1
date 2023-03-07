# 9. Управление файлами

function Test-IsDir {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [string]$Path
  )

  # Проверяем существование папки по заданному пути
  $exists = Test-Path -Path $Path -PathType Container

  # Возвращаем значение типа boolean
  return $exists
}
New-Alias is_dir Test-IsDir
