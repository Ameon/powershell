# Управление проектами

  # 1. Открытие проекта
  function Get-OpenProject {
    if($args[0] -eq 'api'){
      code c:/proj/api.go.ams74.ru
    }elseif($args[0] -eq 'docs'){
      code c:/proj/web/docs.mse.su
    }elseif($args[0] -eq 'nest-api'){
      code c:/proj/web/nest-api
    }elseif($args[0] -eq 'all'){
      & code D:\YandexDisk\PowerShell\Settings;
      code c:/proj/phpmyadmin;
      code c:/proj/web/docs.mse.su;
      code c:/proj/web/nest-api;
      code c:/proj/api.go.ams74.ru
      code c:/proj/web/go.update;
    }elseif($args[0] -eq 'set'){
      code D:\YandexDisk\PowerShell\Settings;
    }elseif($args[0] -eq 'proj'){
      code D:\YandexDisk\PowerShell\Projects;
    }elseif($args[0] -eq 'git'){
      code D:\YandexDisk\PowerShell\Git;
    }elseif($args[0] -eq 'gb'){
      code D:\YandexDisk\PowerShell\GitBranches;
    }elseif($args[0] -eq 'ssh'){
      code c:/users/ameon/.ssh;
    }
  }
  Set-Alias 'o' Get-OpenProject     # Открыть проект ...

  # 2. Обновление проетов
  function Update-Project{
    if($args[0] -eq 'docs'){
      Get-Push;ssh ztv 'cd /var/proj/docs.mse.su && git pull'
    }elseif($args[0] -eq 'api'){
      Get-YarnBuild;
      Get-Push;
      ssh react 'cd /var/projects/crm/api_ameon && git pull && systemctl restart api_ameon'
    }
    elseif($args[0] -eq 'mse'){
      Get-Push;
      ssh ztv 'cd /var/proj/mse.su && git pull'
    }elseif($args[0] -eq 'nestjs'){
      Get-Push;ssh ztv 'cd /var/proj/nestjs.mse.su && git pull'
    }elseif($args[0] -eq 'nestjs.ru'){
      Get-Docs;Get-Build;Get-Push2;Get-GitDist;ch dist;Get-Push;ch master;ssh ameon 'cd ~/domains/nestjs.ru && git pull'
    }
  }
  Set-Alias 'u' Update-Project      # Обновить проект ...