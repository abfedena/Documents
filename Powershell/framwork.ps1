$Result = Dism /online /Get-featureinfo /featurename:NetFx3

          If($Result -contains "State : Enabled") 
                    { 
                        Write-Host "Install .Net Framework 3.5 successfully." 
                    } 
                    Else 
                    { 
                        Write-Host "Failed to install Install .Net Framework 3.5,please make sure the local source is correct." 
                    }
   




If 