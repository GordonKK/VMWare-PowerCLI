$ats7VmFoldername = 'rhine-at'
$ats7VmFolder = Get-Folder -Name $ats7VmFoldername

for ($i = 121; $i -lt 129;  $i++)
    {
        $atstmpVm = 'rhine-at-211'
        $ats7VmName = 'rhine-at-dev-'+$i
        $vmHost = Get-VMHost '172.16.221.41'
        $ats7VM = New-VM -VMHost $vmHost -VM $atstmpVm -Name $ats7VmName -Location $ats7VmFolder  -Datastore 'VSANStore' -RunAsync
    }
for ($i = 121; $i -lt 129;  $i++)
    {
        $ats7VmName = 'rhine-at-dev-'+$i
        Set-VM $ats7VmName -MemoryGB 16 -NumCPU 8
    }