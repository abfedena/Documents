  
   $registryPath='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\explorer\ControlPanel\NameSpace\{025A5937-A6BE-4686-A844-36FE4BEC8B6D}'
   $name="Balanced"
   $Value="381b4222-f694-41f0-9685-ff5bb260df2e"


   $registryPath='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\explorer\ControlPanel\NameSpace\{025A5937-A6BE-4686-A844-36FE4BEC8B6D}'
   $name="Green mode"
   $Value="1d21efa6-ae97-4ddd-98e9-dc6b7db0b59f"


IF(!(Test-Path $registryPath))

  {

    

    New-ItemProperty -Path $registryPath -Name $name -Value $value   
}

 ELSE {

    New-ItemProperty -Path $registryPath -Name $name -Value $value   | Out-Null
    }