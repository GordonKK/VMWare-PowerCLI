$vswitch = Get-VirtualSwitch -Name "vSwitch0" 
$portname_prefix = "simproduct_0"
$port_array=30,50,60,70,80,90,110,111
$vswitch = Get-VMHost 172.16.221.37 | Get-VirtualSwitch -Name "vSwitch0"


for ($i=0;$i -lt $port_array.Count; $i++) {
  $my_count=$i+1
  $portname= $portname_prefix +"$my_count"
  $vportgroup1 =  New-VirtualPortGroup -VirtualSwitch $vswitch -Name $portname
  $vportgroup2 = Set-VirtualPortGroup -VirtualPortGroup $vportgroup1 -VLanId $port_array[$i]
}

$vmlist= get-vm -Location 172.16.221.11
for ($i=0;$i -lt $vmlist.Count;$i++) {
  move-vm $vmlist[$i] -Destination 172.16.221.13
}


for ($i=1;$i -lt 2;$i++) {
    $vm = get-vm "Win7x64-amazon0$i"; set-vm Win7x64-amazon0$i -MemoryGB 12 -Confirm:$false; 
    $vm | New-HardDisk -CapacityGB 80 -Persistence persistent
}