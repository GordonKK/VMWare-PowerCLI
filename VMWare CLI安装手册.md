# 安装 VMWare PowerCLI
# 1. 安装/升级PowerShell 4.0 
## 1.1 获取安装介质：Windows6.1-KB2819745-x64-MultiPkg.msu
## 1.2 配置并安装
    * Windows+R 运行输入：services.msc;
    * 找到Windows Update，并左键双击：Windows Update；
    * 启动类型（E）栏中，在下拉菜单中点击选择【自动】或者【手动】，点击【应用】
    * 【服务状态】点击【启用】
    * 【开始】-搜索PowerShell，输入“$PSVersionTable.PSVersion”，确认Major版本为4.
# 2. 安装VMWare PowerCLI
    * PowerShel运行Set-ExecutionPolicy RemoteSigned，输入Y
    * 点击运行 VMware-PowerCLI-6.5.0-4624819，按提示默认安装即可.

# 3. Get Started
 连接VC
 connect-viserver 172.16.226.10 –user 'administrator@vsphere.local' –password
 Add-PSSnapin VMware.VimAutomation.Core
 %UserProfile%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 

write-host "Please enter your plain text. (Run this script as Administrator)"
$plainText = Read-Host | ConvertTo-SecureString -AsPlainText -force
$encryptedText = $plainText | ConvertFrom-SecureString
write-host $encryptedText





