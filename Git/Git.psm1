# 1. Git
  # 1.1 - Основый команды
    # 1.1.1 - Инициализация репозитория                 # g       git init
    # 1.1.2 - Статус репозитория                        # gs      git status
    # 1.1.3 - Добавление в индекс (отслеживание)        # ga      git add .
    # 1.1.5 - Отправить изменения                       # gpu     git push

    
    # 1.1.5 - Отображает список подключенных          # git     remote -v       
              # удаленных репозиториев Git      
                  
    function Get-GitAdd { & git add .}
      Set-Alias 'ga' Get-GitAdd

# 1. Git

  # 1.1 - Основый команды
    
    # 1.1.1 - Инициализация репозитория
    
      function Get-GitInit { & git init $args }
      Set-Alias 'g' Get-GitInit

    # 1.1.2 - Статус репозитория

      function Get-GitStatus { & git status $args }
      Set-Alias 'gs' Get-GitStatus

    # 1.1.3 - Добавление в индекс (отслеживание)

      function Get-GitAdd { & git add .}
      Set-Alias 'ga' Get-GitAdd

    # 1.1.4 - Добавление нового комита 

      function Get-GitCommit { 
        if($args[0]){ & git commit -m 'update';}
        else { & git commit -m $args; }
        # else { & git commit -m $args; }
      }
      Set-Alias 'gcmt' Get-GitCommit
    
    # 1.1.5 - Добавление нового комита

      function Get-Gpu { & git push; }
      Set-Alias 'gpu' Get-Gpu                   # git push


    # 1.1.5 - Новый репозиторий с комитом

      function Get-GitRemote {
        if(!$args[0]){
          & git remote -v
        }else{
          & git remote $args
        }
      }
      Set-Alias 'gr' Get-GitRemote

  # 1.2 - Комплексные команды

    # 1.2.1 - Новый репозиторий с комитом

      function Get-GitFullInit {
        $v = $args[0];g;ga;git commit -m 'init';git remote add origin git@github.com:Ameon/$v.git;git push -u origin master;
      }
      Set-Alias 'init' Get-GitFullInit
    
    