#v_20171228
# Please run the script beforehand to load VMware PowerCLI Module: 
#C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1

#Add-PsSnapin VMware.VimAutomation.Core

#Parameters to be specified.
#-----------------------------------
$vmNameTemplate = "rhine-at-{0:D3}"  
$VM4CloneName = "vm-template-ubuntu-16.04.3-rhine"
$RequestVMNum = 2 #num of VMs to be created
$TemplateMemGB = 4
$VMNumber = 210
$VMFoldername = 'rhine-at' 
$staticIpList = Import-CSV C:\StaticIPs2.csv #IP list
$defaultGateway = '172.16.61.254' 

$dnsServer = '172.16.227.1'
$subnetMask = '255.255.255.0'

$VMFoldername2Del = ""
$templateName = ""

$HostMemThreshold = 30  # >30Gb reserved for single host is recommended
$vmList = New-Object -TypeName System.Collections.ArrayList  #initalize VM list
$domain = 'wx.bc'
$vc_username = 'administrator@vsphere.local' 
$vc_passwd = Read-Host  -Prompt "Please input PASSWORD for administrator@vsphere.local" #-AsSecureString
connect-viserver 172.16.227.5 -user $vc_username –password $vc_passwd
$cluster = Get-Cluster WXCluster
#-----------------------------------


#input password, restrict of 3 times of incorrect password.
Function InputPassword() {
    for ($i=1; $i -le 3; $i++)  {
        if ($vc_username -ne $null -and  $vc_passwd -ne $null) {
            $VIServer = connect-viserver 172.16.226.10 -user $vc_username –password $vc_passwd
            if ($VIServer -eq $null) { 
                continue
            }
            break
        }
    }
}

Function CreateVMs() {
    $VMFolder = Get-Folder -Name $VMFoldername
    $VMHosts = Get-VMHost -Location WXCluster
    $VMAvailHosts = @()
    $VMAvailHostsMemoryGB = @()
    $AvailTotalMem = 0
    $AllocVMs = @()
    # filter VMs whose memory is larger than $HostMemThreshold
    for ($i = 0; $i -lt $VMHosts.Count; $i ++) {

        $VMVailMemGB = $VMHosts[$i].MemoryTotalGB - $VMHosts[$i].MemoryUsageGB
        if ($VMVailMemGB -ge $HostMemThreshold) {
            $VMAvailHosts += $VMHosts[$i]

            $VMAvailHostsMemoryGB += $VMVailMemGB
            $AvailTotalMem += $VMVailMemGB
        }
    }
    # check total available cluster resources.
    if ($AvailTotalMem -lt ($RequestVMNum * $TemplateMemGB)) {
        echo "Cluster resource unsatisfied!"
        return
    }
    # compute host allocation ratio.
    $VMAccount = 0
    for ($i = 0; $i -lt $VMAvailHosts.Count; $i++) {
        if ($i -eq $VMAvailHosts.Count - 1) {
            $AllocVMs += $RequestVMNum - $VMAccount
            $VMAccount += $RequestVMNum - $VMAccount
            break
        }
        $AllocVMTmp = [Math]::Truncate($VMAvailHostsMemoryGB[$i] / $AvailTotalMem * $RequestVMNum)
        $AllocVMs += $AllocVMTmp
        $VMAccount += $AllocVMTmp
    }
    # create VMs

    #$NewVM.Clear()
    for ($i = 0; $i -lt $AllocVMs.Count; $i ++) {
        for ($j = 0; $j -lt $AllocVMs[$i]; $j++) {
            $vmName = $vmNameTemplate -f $VMNumber
            if  ($vmName -ne $null) {
                $HostTmp = $VMHosts[$i]
                 echo "Creating VM: $vmName on Host $HostTmp..."
                 if ($templateName -ne "") {
                    $template = Get-Template $temlateName
                    $NewVM = New-VM -Name $vmName  -VMHost $VMHosts[$i] -Location $VMFolder -Template $template -Datastore 'vsanDatastore' #-RunAsync 
                    $vmList += $NewVM
                 }
                 elseif ($VM4CloneName -ne "") {
                    $NewVM = New-VM -VM $VM4CloneName -Name $vmName -VMHost $VMHosts[$i] -Location $VMFolder  -Datastore 'vsanDatastore'  #-RunAsync
                    $vmList.Add($NewVM)
                 }
                 else {
                    echo "no template or clone source specified."
                 }
                $VMNumber ++
            }
        }
    }
}

Function SortList($VMs2Sort) {
    
    $vmList = New-Object -TypeName System.Collections.ArrayList
    for ($i = 0; $i -lt $VMs2Sort.Count(); $i++) {
        $j =$i+1
        $vmName = $vmNameTemplate -f $j
        $vm = get-vm $vmName
        $vmList.Add($vm)
    }
    #$vmList = $vms
}

Function CreateCustomizationSpec() {
    if ($linuxSpec -ne $null) {
        Remove-OSCustomizationSpec LinuxCustomizaiton -Confirm:$false
    }
    #if ($specClone -ne $null) { 
        #Remove-OSCustomizationSpec $specClone -Confirm:$false
    #}
    $linuxSpec = New-OSCustomizationSpec -Name LinuxCustomizaiton -Domain $domain -DnsServer $dnsServer -NamingScheme VM -OSType Linux  #TODO 
    $specClone = New-OSCustomizationSpec -Spec $linuxSpec -Type NonPersistent
}


Function SetCustomizationSpec() {
    for($i = 0; $i -lt $vmList.Count; $i ++) {
        $ip = $staticIpList[$i].IP
        $nicMapping = Get-OSCustomizationNicMapping -OSCustomizationSpec $specClone
        $nicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $ip -SubnetMask $subnetMask -DefaultGateway $defaultGateway
        Set-VM -VM $vmList[$i] -OSCustomizationSpec $specClone -Confirm:$false
    }
}

#start the VMs
Function PoweronMultipleVMs() {
    for($i = 0; $i -lt $vmList.Count; $i ++) {
 
        if ($vmList[$i].PowerState -ne "PowerdOn") {
            Start-VM -VM $vmList[$i] -Confirm:$false
        }
    }
}


Function PoweroffMultipleVMs() {
    $vmList = get-vm
    for($i = 0; $i -lt $vmList.Count; $i ++) {
 
        if ($vmList[$i].PowerState -ne "PoweredOff") {
            echo $vmList[$i]
            #Stop-VM -VM $vmList[$i] -Confirm:$false
        }
    }
}

Function RemoveVMs($VM2Del) {
    if ($VM2Del.PowerState -eq "PowerdOn") {
        Stop-VM -VM VM -Confirm
    }
    Remove-VM -VM $VM2Del -DeletePermanently # -Confirm:$false
}




Function RemoveVMFolder($VMFoldername2Del) {
    $VMFolder2Del = Get-Folder $VMFoldername2Del
    if ($VMFolder2Del.Type -eq 'VM') {
        Remove-Folder -Folder $VMFolder2Del -DeletePermanently # -Confirm:$false
    }
}

Function RebuildVM ($VM2Rebuild, $specClone){
    RemoveVMs $VM2Rebuild  -DeletePermanently # -Confirm:$false
    $NewVM = New-VM -VM $VM4CloneName -Name $vmName -VMHost $VMHosts[$i] -Location $VMFolder  -Datastore 'vsanDatastore'  #-RunAsync
    if ($specClone) {
        Set-VM -VM $VM2Rebuild -OSCustomizationSpec $specClone -Confirm:$false
    }
}

Function ListFunc() {
    echo '
    InputPassword
    CreateVMs
    CreateCustomizationSpec
    SetCustomizationSpec
    PoweronMultipleVMs
    RemoveVMFolder FolderName
    RemoveVMs $VM2Del
    RebuildVM $VM2Rebuild, $specClone
    MultiVMCreationTask $VMNum
    '
}



Function MultiVMCreationTask ($VMNum) {
    New-Folder -name rhine-at -Location Test_Servers
    $RequestVMNum = 100
    CreateCustomizationSpec
    CreateVMs
    SetCustomizationSpec
    PoweronMultipleVMs
}

Function AddVM2List() {
    for ($i=0; $i -lt 101; $i++) {
        $vmname = "rhine-at-"+$i
        $vm = get-vm $vmname

        $vmList.add($vm)
    }
}

Function moveDatastore() {
    for ($i=41; $i -lt 100; $i++) {
        $vmname = "rhine-at-"+$i
        Move-VM -VM $vmname -Datastore 'vsanDatastore'
    }
}
