if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null) {
    try {
        Write-Host "Loading PowerCLI plugin, this may take a little while" -foregroundcolor "cyan"
        Add-PSSnapin VMware.VimAutomation.Core
        $PCLIVer = Get-PowerCLIVersion
        if ((($PCLIVer.Major * 10 ) + $PCLIVer.Minor) -ge 51) {
            $null = Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm:$false -Scope "Session"
        }
    }
    catch {
        Write-Host "Unable to load the PowerCLI plugin. Please verify installation or install VMware PowerCLI and run this script again."
        Read-Host "Press <Enter> to exit"
        exit
    }
}