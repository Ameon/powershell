# 2 - Работа с ветками 
# 2.1.1 Список веток                              # gb    git branch $args
# 2.1.2 Переключение между ветками                # ch    git git checkout $args
# 2.1.3 Переключюиться на ветку master            # m     git checkout master

  # 2.1.1 - Список веток
  
    function Get-GitBranch { & git branch $args}
    Set-Alias 'gb' Get-GitBranch

    # 2.1.2 - Переключение между ветками

    function Get-GitCheckout { & git checkout $args}
    Set-Alias 'ch' Get-GitCheckout

    # 2.1.3 - Переключюиться на ветку master            

    function Get-CheckoutMaster { & git checkout master}
    Set-Alias 'm' Get-CheckoutMaster    # git checkout master