# 2 - ������ � ������� 
# 2.1.1 ������ �����                              # gb    git branch $args
# 2.1.2 ������������ ����� �������                # ch    git git checkout $args
# 2.1.3 �������������� �� ����� master            # m     git checkout master

  # 2.1.1 - ������ �����
  
    function Get-GitBranch { & git branch $args}
    Set-Alias 'gb' Get-GitBranch

    # 2.1.2 - ������������ ����� �������

    function Get-GitCheckout { & git checkout $args}
    Set-Alias 'ch' Get-GitCheckout

    # 2.1.3 - �������������� �� ����� master            

    function Get-CheckoutMaster { & git checkout master}
    Set-Alias 'm' Get-CheckoutMaster    # git checkout master