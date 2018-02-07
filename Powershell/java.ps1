$source = ((Invoke-WebRequest –Uri 'https://www.java.com/en/download/manual.jsp').Links | Where-Object { $_.innerHTML -eq "Windows Offline (64-bit)" }).href
$destination = "E:\jdk-7u60-windows-i5861.exe"
$client = new-object System.Net.WebClient 
$cookie = "oraclelicense=accept-securebackup-cookie"
$client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie) 
$client.downloadFile($source, $destination)


if (Test-Path $destination) {
$proc1 = Start-Process -FilePath "$destination" -ArgumentList "/s REBOOT=ReallySuppress" -Wait -PassThru
if ($proc1.ExitCode -eq 0) {
		Write-Host  "Succesfull Installed Java" 
        $jdkDp = (Get-ChildItem -Path "C:\Program Files\Java\jre*" | Sort-Object name | Select-Object -Last 1).FullName
        [System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + ";$jdkDp", "Machine")
      

       
}
	else {
		Write-Host  "Not Succesfull code install " 
	}
}
   
else {
  
    Write-Host  "Not Succesfull Download file " 
}




$Result = Dism /online /Get-featureinfo /featurename:NetFx3

          If($Result -contains "State : Enabled") 
                    { 
                        Write-Host "Install .Net Framework 3.5 successfully." 
                    } 
                    Else 
                    { 
                        Write-Host "Failed to install Install .Net Framework 3.5,please make sure the local source is correct." 
                    }



