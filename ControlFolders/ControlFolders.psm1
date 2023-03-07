# 9. ���������� �������

function Test-IsDir {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [string]$Path
  )

  # ��������� ������������� ����� �� ��������� ����
  $exists = Test-Path -Path $Path -PathType Container

  # ���������� �������� ���� boolean
  return $exists
}
New-Alias is_dir Test-IsDir
