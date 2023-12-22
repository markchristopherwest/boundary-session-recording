# Install Firefox, Putty, VSCode
#
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-7.1
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-process?view=powershell-7.1
# https://leanpub.com/thebigbookofpowershellerrorhandling/read

try {
    Write-Host "Downloading Firefox"
    Invoke-WebRequest -Uri "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=en-GB" -OutFile FirefoxSetup.msi
  
    Write-Host "Installing Firefox"
    $firefox = (Start-Process msiexec.exe -ArgumentList "/i","FirefoxSetup.msi","/passive" -NoNewWindow -Wait -PassThru)
    if ($firefox.ExitCode -ne 0) {
      Write-Error "Error installing Firefox"
      exit 1
    }
  
  #   Write-Host "Downloading Putty"
  #   Invoke-WebRequest -Uri "https://the.earth.li/~sgtatham/putty/0.74/w64/putty-64bit-0.74-installer.msi" -OutFile putty-installer.msi
  
  #   Write-Host "Installing Putty"
  #   $putty = (Start-Process msiexec.exe -ArgumentList "/i","putty-installer.msi","/passive" -NoNewWindow -Wait -PassThru)
  #   if ($putty.ExitCode -ne 0) {
  #     Write-Error "Error installing Putty"
  #     exit 1
  #   }
  
    Write-Host "Downloading VSCode"
    Invoke-WebRequest -Uri "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" -OutFile VSCodeSetup.exe
  
    Write-Host "Installing VSCode"
    $vscode = (Start-Process .\VSCodeSetup.exe -ArgumentList "/SILENT","/NORESTART","/MERGETASKS=!runcode" -NoNewWindow -Wait -PassThru)
    if ($vscode.ExitCode -ne 0) {
      Write-Error "Error installing VSCode"
      exit 1
    }
  
    $vscode_extensions = @("ms-vscode-remote.remote-ssh")
    foreach ($vse in $vscode_extensions) {
      Write-Host "Installing VSCode extension $vse"
      # Unfortunately this always seems to return 0 even if there's an error
      $vscodeext = (Start-Process "C:\Program Files\Microsoft VS Code\bin\code.cmd" -ArgumentList "--install-extension",$vse,"--force" -NoNewWindow -Wait -PassThru)
      if ($vscodeext.ExitCode -ne 0) {
        Write-Error "Error installing VSCode extension"
        exit 1
      }
    }
  }
  catch
  {
    Write-Error $_.Exception
    exit 1
  }