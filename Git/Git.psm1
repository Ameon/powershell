# 1. Git
  # 1.1 - ������� �������
    # 1.1.1 - ������������� �����������                 # g       git init
    # 1.1.2 - ������ �����������                        # gs      git status
    # 1.1.3 - ���������� � ������ (������������)        # ga      git add .
    # 1.1.5 - ��������� ���������                       # gpu     git push

    
    # 1.1.5 - ���������� ������ ������������          # git     remote -v       
              # ��������� ������������ Git      
                  
    function Get-GitAdd { & git add .}
      Set-Alias 'ga' Get-GitAdd

# 1. Git

  # 1.1 - ������� �������
    
    # 1.1.1 - ������������� �����������
    
      function Get-GitInit { & git init $args }
      Set-Alias 'g' Get-GitInit

    # 1.1.2 - ������ �����������

      function Get-GitStatus { & git status $args }
      Set-Alias 'gs' Get-GitStatus

    # 1.1.3 - ���������� � ������ (������������)

      function Get-GitAdd { & git add .}
      Set-Alias 'ga' Get-GitAdd

    # 1.1.4 - ���������� ������ ������ 

      function Get-GitCommit { 
        if($args[0]){ & git commit -m 'update';}
        else { & git commit -m $args; }
        # else { & git commit -m $args; }
      }
      Set-Alias 'gcmt' Get-GitCommit
    
    # 1.1.5 - ���������� ������ ������

      function Get-Gpu { & git push; }
      Set-Alias 'gpu' Get-Gpu                   # git push


    # 1.1.5 - ����� ����������� � �������

      function Get-GitRemote {
        if(!$args[0]){
          & git remote -v
        }else{
          & git remote $args
        }
      }
      Set-Alias 'gr' Get-GitRemote

  # 1.2 - ����������� �������

    # 1.2.1 - ����� ����������� � �������

      function Get-GitFullInit {
        $v = $args[0];g;ga;git commit -m 'init';git remote add origin git@github.com:Ameon/$v.git;git push -u origin master;
      }
      Set-Alias 'init' Get-GitFullInit
    
    