$staticIpList = Import-CSV C:\amazon4nics.csv #IP list
$defaultGateway = "172.16.201.254"
$domain = 'wx.bc'
$dnsServer = '172.16.227.1'
$subnetMask = '255.255.255.0'
$vms = New-Object -TypeName System.Collections.ArrayList  #initalize VM list
for ($i=101;$i -lt 110; $i++) {
  $vmName="ng-qa"+$i
  $vm=get-vm $vmName
  $vms.Add($vm)
}
Function CreateCustomizationSpec() {
    if ($linuxSpec -ne $null) {
        Remove-OSCustomizationSpec LinuxCustomizaiton -Confirm:$false
    }
    #if ($specClone -ne $null) { 
        #Remove-OSCustomizationSpec $specClone -Confirm:$false
    #}
    $linuxSpec = New-OSCustomizationSpec -Name LinuxCustomizaiton -Domain $domain -DnsServer $dnsServer -NamingScheme VM -OSType Linux -Type NonPersistent
    #$specClone = New-OSCustomizationSpec -Spec $linuxSpec -Type NonPersistent
}
CreateCustomizationSpec
Function SetCustomizationSpec(){
    for($i = 0; $i -lt $vms.Count; $i ++) {
        Remove-OSCustomizationSpec LinuxCustomizaiton -Confirm:$false
        $linuxSpec = New-OSCustomizationSpec -Name LinuxCustomizaiton -Domain $domain -DnsServer $dnsServer -NamingScheme VM -OSType Linux -Type NonPersistent
        $Niclist = Get-NetworkAdapter $vms[$i]
        $nicMapping = Get-OSCustomizationNicMapping –OSCustomizationSpec $linuxSpec
        Remove-OSCustomizationNicMapping –OSCustomizationNicMapping $nicMapping –Confirm:$false
        for ($j = 0; $j -lt $Niclist.Count; $j++) {
            $NIC = $Niclist[$j] 
            $nic_ip = 'nic' +$j
            $ip = $staticIpList[$i].$nic_ip
              $linuxSpec | New-OSCustomizationNicMapping –IpMode UseStaticIP –IpAddress $ip –SubnetMask $subnetMask –DefaultGateway $defaultGateway –NetworkAdapterMac $NIC.MacAddress

        }
        #$nicMapping = Get-OSCustomizationNicMapping -OSCustomizationSpec $specClone
        #$nicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $ip -SubnetMask $subnetMask -DefaultGateway $defaultGateway
        Set-VM -VM $vms[$i] -OSCustomizationSpec $linuxSpec -Confirm:$false
    }
}
SetCustomizationSpec
