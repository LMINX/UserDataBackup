<#----------------------
Author:George Liu
Date: 2017.08.29
function: check the BMB TS has successfully deployment on PC and RG for APTOS RG and PC
Language: support English and Chinese.
update on 2017.9.18
add the device type check: RG shoud not installed with name RNAPxxxxxxpc001 ,PC shoud not installed with name RNAPxxxxxxrg001
update on 2017.9.26
bug fixed
1 if you insert more than one drives on the devices, the tools will not able to run the test after “partition verification”
2 the tools can not display the user account which in the localadmin groups by invoke command ,it will throw exception when you run the tools . now it has been fixed.
3 the tools can verify both QA and Production Devices.
update on 2017.10.19
new feature added
check the chinese charaset is on the line display and POs print. 
update on 2017.11.9
new feature added
add PC performancea and NIC power save setting check which will make the PC still online.
bug fixed
check the device type , if it is rg, the 12th checkitem is character check ,if it is pc, the 12th checkitem is performancea and NIC power save setting check.
-----------------------#>
function Check-Devicename
{
param ($devicename)
$computername_regex = "RN(AP|LQ)\d{5}(PC|RG|SV|HV|CM)\d{3}"
$Verifyname="Device New Naming Convention Verification"
If ($devicename -match $computername_regex){
if($global:languageOption -eq "ENG")
{return “[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="主机新命名格式验证"
return “[Info]$Verifyname --passed,"}
}
else{
if($global:languageOption -eq "ENG")
{$Verifyname="Device New Naming Convention Verification"
return “[Info]$Verifyname --failed,[Error]the hostname is not like RNAP0xxxxxPC/RG00X,[Tips]reimage with the RNAP0xxxxPC/RG00X"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="主机新命名格式验证"
return “[Info]$Verifyname --failed,[Error]主机名不符合RNAP0xxxxxPC/RG00X格式,[Tips]请使用RNAP0xxxxPC/RG00X主机名重新安装镜像"}
}
}

function Check-DeviceType
{
$devicemodel=gwmi win32_computersystem
if((($devicemodel.Manufacturer -eq "TOSHIBA") -and  ($devicemodel.Model -eq "6140E3R"))  -or (($devicemodel.Manufacturer -eq "IBM CORPORATION") -and  ($devicemodel.Model -in "4900E85")))
{$devicetype="RG"}
else
{$devicetype="PC"}
$Verifyname="DeviceType Verification"
$installedType=($env:COMPUTERNAME).Substring(9,2)
if ($devicetype -eq $installedType){
if($global:languageOption -eq "ENG")
{return “[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="设备类型验证"
return “[Info]$Verifyname --passed,"}
}
else{
if($global:languageOption -eq "ENG")
{$Verifyname="DeviceType Verification"
$Manu=$devicemodel.Manufacturer
$Model=$devicemodel.Model
return “[Info]$Verifyname --failed,[Error]you can not installed $Manu $Model with name $installedType 00X ,[Tips]reimage with the RNAP0xxxx$devicetype"+"00X"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="设备类型验证"
return “[Info]$Verifyname --failed,[Error]你不能在 $Manu $Model 使用名称 $installedType 00X 进行安装 ,[Tips]请使用主机名RNAP0xxxx$devicetype"+"00X重新安装镜像"}
}
} 

function Check-Domain
{
$ADDomain=(gwmi win32_computersystem).domain
$Verifyname="Domain Join Verification"
If ($ADDomain-eq "ad.nike.com")
{
if($global:languageOption -eq "ENG")
{return “[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="加域验证"
return “[Info]$Verifyname --passed,"}
}
else
{
if($global:languageOption -eq "ENG")
{return “[Info]$Verifyname --failed,[Error]the devices is not in ad.nike.com,[Tips]Join it to ad.nike.com"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="加域验证"
return “[Info]$Verifyname --failed,[Error]主机不在Ad.nike.com域中,[Tips]请加域"}
}
}


function Check-IPAddress
{
param ($devicename)
$Nic=Get-WmiObject -Class Win32_NetworkAdapter -ComputerName $devicename -Filter "netconnectionid='eth0'"
$NicMac=$Nic.macaddress
$NicCfg=Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "macaddress='$Nicmac'" -ComputerName $devicename 
$Verifyname="IPAddress Configuration  Verification"
If ($NicCfg.DHCPEnabled)
{
if($global:languageOption -eq "ENG")
{return “[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="网卡地址验证"
return “[Info]$Verifyname --passed,"}
}
else{
if($global:languageOption -eq "ENG")
{return “[Info]$Verifyname --failed,[Error]DHCP unconfiged on eth 0 or unable to find eth0,[Tips]enable DHCP on eth0"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="网卡地址验证"
return “[Info]$Verifyname --failed,[Error]未启用DHCP在eth0网卡或者找不到名称为eth0的网卡,[Tips]请在eth0上启用DHCP"}
}
}


function check-AdminGrpMembers
{
param ([String] $devicename)
$group = [ADSI]"WinNT://localhost/Administrators,group"
$members=@($group.invoke("Members"))
$adminGroups=@()
$Verifyname="Local Administrators Members Verification"
foreach ($m in $members)
    {
    $adminGroups+=$m.GetType.Invoke().InvokeMember("name","getproperty",$null,$m,$null)
    
    }

$envname=switch ($devicename.Substring(2,2)){
"LQ" {".QA"}
"AP" {""}
}


$storecode=$devicename.Substring(4,5)
$Admin1="Retail.AP.Stores.L1.Support$envname"
$Admin2="Retail.AP.Stores.L2.Support$envname"
$Admin3="Retail.AP.Stores.L3.Support$envname"
$Admin4="Retail.AP.Stores.SysAdm$envname"

$moduleType=($env:COMPUTERNAME).Substring(9,2)
$Admin5=switch ($moduleType) {
"RG" {"S."+$devicename.substring(0,4)+$storecode+"REGSVC00"+$devicename.substring(13,1)}
"PC" {$null}
}

$Admin6=switch ($moduleType) {
"RG" {"A."+$devicename.substring(0,4)+$storecode+"REG00"+$devicename.substring(13,1)}
"PC" {$null}
}

$flag=switch ($moduleType)
{
"RG" {($adminGroups -contains $Admin1) -and ($adminGroups -contains $Admin2) -and ($adminGroups -contains $Admin3) -and ($adminGroups -contains $Admin4) -and ($adminGroups -contains $Admin5) -and ($adminGroups -contains $Admin6)}
"PC" {($adminGroups -contains $Admin1) -and ($adminGroups -contains $Admin2) -and ($adminGroups -contains $Admin3) -and ($adminGroups -contains $Admin4)}
}

$Admins="<"+$Admin1+" "+$Admin2+" "+$Admin3+" "+$Admin4+" "+$Admin5+" "+$Admin6+">"

if ($flag){
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="本地管理员组成员验证"
return "[Info]$Verifyname --passed,"}
}
else{
if($global:languageOption -eq "ENG")
{return “[Info]$Verifyname --failed,[Error]missing memebers in Local Admin Group[Tips]Add $Admins in local adminstrators group"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="本地管理员组成员验证"
return “[Info]$Verifyname --failed,[Error]缺少本地管理组成员[Tips]请添加如下成员到 $Admins 到本地管理员组"}
}
}

function check-Partition
{

$DiskCapcity=(gwmi Win32_DiskDrive -Filter "index=0").Size
$Partition=Gwmi Win32_LogicalDisk -Filter "DeviceID='C:'"
$Verifyname="Partition Verification"
if ($Partition.Size -gt $DiskCapcity*0.99)
{
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="磁盘分区验证"
return "[Info]$Verifyname --passed,"}
}
else{
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --failed,[Error]Disk Partiton is not correct[Tips]change the disk Partition or Reimage,PC/RG only have Driver C with Full capcity"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="磁盘分区验证"
return "[Info]$Verifyname --failed,[Error]分区错误[Tips]修改分区或者重新安装分区,PC/RG 只有一个C盘分区，容量为整个磁盘大小"}
}
}


function check-retailPSmodule
{
$Verifyname="RetailPSmodule Verification"
try {Import-Module retail -ErrorAction Stop;
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{
$Verifyname="RetailPS模块导入验证"
return "[Info]$Verifyname --passed,"}
}
catch {
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --failed,[Error]unabe to import retail ps module,[Tips]install the retail PS module"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="RetailPS模块导入验证"
return "[Info]$Verifyname --failed,[Error]无法导入retail ps模块,[Tips]请安装retailPS 模块"}
}
}


function check-driver
{
#$ScriptRoot="C:\work\script\CrossOver"
$DeviceManagerModule=$PSScriptRoot+"\DeviceManagement\Release\DeviceManagement.psd1"
$Verifyname="Device Driver Verification"
Import-Module $DeviceManagerModule
$unknownDevices=get-device | sort-object -Property Name | where-object { ($_.configurationflags -ne 0) -and  ($_.name -eq $null) }
if ($unknownDevices -eq $null)
{
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="驱动验证"
return "[Info]$Verifyname --passed,"}
}
else
{
$unknownHDs=$unknowndevices|%{$_.hardwareids}
$count=$unknownDevices.count
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --failed,[Error]find $count unknown device(s) missing drivers,[Tips]install drives on hardware,id is:$unknownHDs"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="驱动验证"
return "[Info]$Verifyname --failed,[Error]发现$count未知设备没有驱动[Tips]请安装如下设备的驱动，id is:$unknownHDs"}
}
}

function check-LocalGroup
{
$computer=[ADSI]"WinNT://localhost"
$Groupsobj = $Computer.psbase.Children | Where {$_.psbase.schemaClassName -eq "group"}
$Groups=@()
foreach($g in $groupsobj)
{
$Groups+=$g.name
}

$Localgrp1="L1.Support"
$Localgrp2="L2.Support"
$Localgrp3="L3.Support"
$Localgrp4="Recovery"
$Localgrp5="RegisterServices"
$Localgrp6="RegisterUsers"
$Localgrp7="ServerServices"
$Localgrp8="RemotewareClient"
$Localgrps="<"+$Localgrp1+" "+$Localgrp2+" "+$Localgrp3+" "+$Localgrp4+" "+$Localgrp5+" "+$Localgrp6+" "+$Localgrp7+" "+$Localgrp8+">"
$Verifyname="Local Group Verification"
$flag=($Groups -contains $Localgrp1) -and ($Groups -contains $Localgrp2) -and ($Groups -contains $Localgrp3) -and ($Groups -contains $Localgrp4) -and ($Groups -contains $Localgrp5) -and ($Groups -contains $Localgrp6) -and ($Groups -contains $Localgrp7) -and ($Groups -contains $Localgrp8)
if($flag){
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="本地组验证"
return "[Info]$Verifyname --passed,"}
}
else{
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --failed,[Error]missing localgroup,[Tips]Create local group $Localgrps"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="本地组验证"
return "[Info]$Verifyname --failed,[Error]缺失本地组,[Tips]请创建如下本地组 $Localgrps"}
}
}

function check-installedSoftware
{

$installedSoftwareCustomerObject= Get-WmiObject -class Win32_Product|Select-Object -Property Name
$installedSoftware=$installedSoftwareCustomerObject.name
$moduleType=($env:COMPUTERNAME).Substring(9,2)
$Verifyname="installedSoftware Verification"
$mandatorySoftware = switch ($moduleType) {
"RG" {"Microsoft SQL Server 2012 Setup (English)","Microsoft POS for .NET 1.12","Toshiba UnifiedPOS for Windows"}
"PC" {"Microsoft Office Professional Plus 2013"}
}
$mandatorySoftwareRG="Microsoft SQL Server 2012 Setup (English),Microsoft POS for .NET 1.12,Toshiba UnifiedPOS for Windows"
$mandatorySoftwarePC="Microsoft Office Professional Plus 2013"
$flag=$false
$flagtemp=$true
$index=0
foreach($s in $mandatorySoftware)
{$flagtemp=$installedSoftware -contains $s
if($index -eq 0)
{$flag=$flagtemp}
else{$flag=$flagtemp -and $flag}
$index++
}
if($flag){
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="已安装程序验证"
return "[Info]$Verifyname --passed,"}
}
else{
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --failed,[Error]missing software on RG/PC,[Tips]install $mandatorySoftwareRG on RG or $mandatorySoftwarePC on PC"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="已安装程序验证"
return "[Info]$Verifyname --failed,[Error]缺失必要安装程序,[Tips]请在RG上安装 $mandatorySoftwareRG 或者在PC上 $mandatorySoftwarePC 安装"}
}  
}

function check-fileandFolder
{
$JenkinShortcut=Get-Item "c:\ReleaseCheckin\JenkinsCheckin.lnk"
$Verifyname="jenkin shortcut and NikeLog folder check"
if($JenkinShortcut -eq $null)
{$JenkinShortcutexist=$false}
else{$JenkinShortcutexist=$true}
$Nikefolderexist=Test-Path "C:\nike\logs"
$flag=$JenkinShortcutexist -and $Nikefolderexist
if($flag){
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="jenkin 快捷方式以及NikeLog文件夹验证"
return "[Info]$Verifyname --passed,"}
}
else{
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --failed,[Error]missing JenkinsCheckin.lnk or NikeLog folder ,[Tips]copy JenkinsCheckin.lnk to c:\ReleaseCheckin on RG and create NikeLog on C:\nike\log"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="jenkin 快捷方式以及NikeLog文件夹验证"
return "[Info]$Verifyname --failed,[Error]缺失jenkins快捷方式或者NikeLog文件夹,[Tips]请复制JenkinsCheckin.lnk到c:\ReleaseCheckin文件夹并创建C:\nike\log文件夹"}
}  
}

function check-CharacterSetlist
{
$Verifyname="POSCharacterSet check"

$Posdisplay=New-Object -ComObject "OPOS.LineDisplay"
$orc=$Posdisplay.Open("NSBOPOSLINEDISPLAY")
$crc=$Posdisplay.ClaimDevice(1000)
$PosdisplayChar=$Posdisplay.CharacterSetlist 
$orc=$Posdisplay.DeviceEnabled='TRUE'
$orc=$Posdisplay.DeviceEnabled='FALSE'
$orc=$Posdisplay.ReleaseDevice()
$orc=$Posdisplay.Close()

$posPrint=New-Object -ComObject "OPOS.POSPrinter"
$orc=$posPrint.Open("NSBOPOSPRINTER")
$crc=$posPrint.ClaimDevice(1000)
$orc=$posPrint.DeviceEnabled='TRUE'
$orc=$posPrintchar=$posPrint.CharacterSetlist
$orc=$posPrint.DeviceEnabled='FALSE'
$orc=$posPrint.ReleaseDevice()
$orc=$posPrint.Close()
$CHposPrintchar=("775","848","867","872","1255","1256")
$CHPosdisplayChar=("936")
$finPrintresult=$True
$findisplayresult=$True
foreach($c in $CHposPrintchar)
{
$result=$posPrintchar.contains($c)
$finPrintresult=$finPrintresult -and $result
}

foreach($c in $CHPosdisplayChar)
{
$result=$posdisplayChar.contains($c)
$findisplayresult=$findisplayresult -and $result
}
$flag=$finPrintresult -and $findisplayresult
if($flag){
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="字符集验证"
return "[Info]$Verifyname --passed,"}
}
else{
if($global:languageOption -eq "ENG")
{
if(!$finPrintresult)
{
foreach($c in $CHposPrintchar)
{$charsetprint=$c+","+$charsetprint}
$errmsg="missing the charset $charsetprint on POSPrint "
}
if(!$findisplayresult)
{
foreach($c in $CHPosdisplayChar)
{$charsetprint=$c+","+$charsetprint}
$errmsg+="missing the charset $charsetdiplay on POSlinedisplay"
}
return "[Info]$Verifyname --failed,[Error]$errmsg[Tips]import the charaset on related peripheral,$errmsg"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="字符集验证"
if(!$finPrintresult)
{
foreach($c in $CHposPrintchar)
{$charsetprint=$c+","+$charsetprint}
$errmsg="缺失字符集 $charsetprint 在小票打印机上 "
}

if(!$findisplayresult)
{
foreach($c in $CHPosdisplayChar)
{$charsetdisplay=$c+","+$charsetdisplay}
if ($errmsg -ne $null)
{$errmsg+=";"}
$errmsg+="缺失字符集 $charsetdisplay 在客显"
}
return "[Info]$Verifyname --failed,[Error]$errmsg,[Tips]导入中文字符到设备,$errmsg"}
}  
}


function check-performanceandNICpowersaving
{
$performancesetting=POWERCFG -GETACTIVESCHEME
$eng_tips=@()
$eng_errormsg=@()
$cn_errormsg=@()
$cn_tips=@()

$strperformancesetting=$performancesetting.substring($performancesetting.indexof("("))
if ($strperformancesetting -eq "(High performance)")
{$performancesettingvalue=$true}
else 
{
$performancesettingvalue=$false
$eng_errormsg+="PC performance setting is not current, current setting is $strperformancesetting"
$eng_tips+="set power plan  to high performance in control panel"
$cn_errormsg+="电脑性能设置错误，当前设置为$strperformancesetting"
$cn_tips+="请在电源选项中设置为高性能"
}

$Nic=Get-WmiObject -Class Win32_NetworkAdapter -Filter "netconnectionid='eth0'"
$DeviceID = $Nic.DeviceID
If([Int32]$DeviceID -lt 10)
{$AdapterDeviceNumber = "000"+$DeviceID}
Else
{$AdapterDeviceNumber = "00"+$DeviceID}
$KeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\$AdapterDeviceNumber"
$PnPCapabilitiesValue = (Get-ItemProperty -Path $KeyPath).PnPCapabilities

if ($PnPCapabilitiesValue -eq 24)
{$PnPCapabilitiesValue=$true}
else
{$PnPCapabilitiesValue=$false
$eng_errormsg+="eth0 NIC power saving setting is set save power"
$eng_tips+="uncheck the eth0 NIC power saving setting in device management"
$cn_errormsg+="eth0网卡设置为允许设备节省电源"
$cn_tips+="在设备管理器里取消勾选网卡eth0的省电模式设置"
}


$flag=$PnPCapabilitiesValue -and $performancesettingvalue
$Verifyname="PC Power option setting  and NIC power manager setting check"

if($flag){
if($global:languageOption -eq "ENG")
{return "[Info]$Verifyname --passed,"}
elseif($global:languageOption -eq "CHN")
{$Verifyname="PC电源设置和网卡电源设置检查"
return "[Info]$Verifyname --passed,"}
}
else{
if($global:languageOption -eq "ENG")
{
$count=0
foreach ($msg in $eng_errormsg)
{
if($count -eq ($eng_errormsg.Length-1))
{$strerrormsgs+=$msg}
else{$strerrormsgs+=$msg+","}
$count++}
$count=0
foreach ($tip in $eng_tips)
{
if($count -eq ($eng_tips.Length-1))
{$strtips+=$tip}
else{$strtips+=$tip+","}
$count++}
return "[Info]$Verifyname --failed,[Error]$strerrormsgs,[Tips]$strtips"
}
elseif($global:languageOption -eq "CHN")
{$Verifyname="PC电源设置和网卡电源设置检查"
$count=0
foreach ($msg in $cn_errormsg)
{
if($count -eq ($cn_errormsg.Length-1))
{$strerrormsgs+=$msg}
else{$strerrormsgs+=$msg+","}
$count++}
$count=0
foreach ($tip in $cn_tips)
{
if($count -eq ($cn_tips.Length-1))
{$strtips+=$tip}
else{$strtips+=$tip+","}
$count++}
return "[Info]$Verifyname --failed,[Error]$strerrormsgs,[Tips]$strtips"}
}  
}




#region Import the Assemblies 
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null 
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null 



#endregion
function GenerateForm 
{
#region Generated Form Objects 
$CrossOverBMBVerificationForm = New-Object System.Windows.Forms.Form 
$CheckButton = New-Object System.Windows.Forms.Button 
$CheckItemLabel = New-Object System.Windows.Forms.Label 
$HostnameTextBox = New-Object System.Windows.Forms.TextBox
$OutputTextBox= New-Object system.windows.Forms.richTextBox
$TextBox= New-Object system.windows.Forms.TextBox
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
$rightImagebox=New-Object system.windows.Forms.PictureBox 
$errorImagebox=New-Object system.windows.Forms.PictureBox 
$StatusBar = New-Object System.Windows.Forms.StatusBar
$progressBar1 = New-Object System.Windows.Forms.ProgressBar
$timer1 = New-Object 'System.Windows.Forms.Timer'
$LanguageButton = New-Object System.Windows.Forms.Button
$clockLbl = New-Object 'System.Windows.Forms.Label'
$global:LanguageOption="ENG"
$ResultLabel = New-Object System.Windows.Forms.Label 
#---------------------------------------------- 
#Generated Event Script Blocks 
#---------------------------------------------- 
#Provide Custom Code for events specified in PrimalForms. 
$handler_CheckButton_Click= 
{ 
#TODO: Place custom script here
$errorImagebox.Visible=$false
$rightImagebox.Visible=$false
$OutputTextBox.Text=""
$result=@()
$currentresult=""
$totaltestItems=12
$currentVerifyItems=0
$summary=@()
$currentsummary=""
$tips=@()
$currentTip=“”
$LanguageButton.Visible=$false

$result+=Check-Devicename -devicename $env:COMPUTERNAME
$currentresult=$result[$currentVerifyItems]
$currentsummary=$currentresult.substring(6,$currentresult.indexof(",")-6)
$order=$currentVerifyItems+1
$summary+=[string]$order+":"+$currentsummary+"`r`n"
$currentsummary=""
$OutputTextBox.Text=$summary
$infoindex=$currentresult.indexof("-")
$StatusBar.Text=($result[$currentVerifyItems]).substring(6,$infoindex-7)
if($currentresult -like "*--failed*")
{
$infoindex2=$currentresult.indexof("[Tips]")
$currentTip=$currentresult.substring($infoindex2+6)
if ($tips.count -eq 0)
{
if($global:languageOption -eq "ENG")
{$tiphead="Solutioin on failure Verification"}
elseif($global:languageOption -eq "CHN")
{$tiphead="解决方案"}
$tips+=$tiphead+" `r`nNo "+[string]$order+":"+$currentTip+"`r`n"}
else
{$tips+="No "+[string]$order+":"+$currentTip+"`r`n"}
}
$TextBox.Text=$tips
$currentVerifyItems++
$progressBar1.Value = ($currentVerifyItems/$totaltestItems)*100

$result+=Check-DeviceType
$currentresult=$result[$currentVerifyItems]
$currentsummary=$currentresult.substring(6,$currentresult.indexof(",")-6)
$order=$currentVerifyItems+1
$summary+=[string]$order+":"+$currentsummary+"`r`n"
$currentsummary=""
$OutputTextBox.Text=$summary
$infoindex=$currentresult.indexof("-")
$StatusBar.Text=($result[$currentVerifyItems]).substring(6,$infoindex-7)
if($currentresult -like "*--failed*")
{
$infoindex2=$currentresult.indexof("[Tips]")
$currentTip=$currentresult.substring($infoindex2+6)
if ($tips.count -eq 0)
{
if($global:languageOption -eq "ENG")
{$tiphead="Solutioin on failure Verification"}
elseif($global:languageOption -eq "CHN")
{$tiphead="解决方案"}
$tips+=$tiphead+" `r`nNo "+[string]$order+":"+$currentTip+"`r`n"}
else
{$tips+="No "+[string]$order+":"+$currentTip+"`r`n"}
}
$TextBox.Text=$tips
$currentVerifyItems++
$progressBar1.Value = ($currentVerifyItems/$totaltestItems)*100


$result+=Check-Domain
$currentresult=$result[$currentVerifyItems]
$currentsummary=$currentresult.substring(6,$currentresult.indexof(",")-6)
$order=$currentVerifyItems+1
$summary+=[string]$order+":"+$currentsummary+"`r`n"
$currentsummary=""
$OutputTextBox.Text=$summary
$infoindex=$currentresult.indexof("-")
$StatusBar.Text=($result[$currentVerifyItems]).substring(6,$infoindex-7)
if($currentresult -like "*--failed*")
{
$infoindex2=$currentresult.indexof("[Tips]")
$currentTip=$currentresult.substring($infoindex2+6)
if ($tips.count -eq 0)
{
if($global:languageOption -eq "ENG")
{$tiphead="Solutioin on failure Verification"}
elseif($global:languageOption -eq "CHN")
{$tiphead="解决方案"}
$tips+=$tiphead+" `r`nNo "+[string]$order+":"+$currentTip+"`r`n"}
else
{$tips+="No "+[string]$order+":"+$currentTip+"`r`n"}
}
$TextBox.Text=$tips
$currentVerifyItems++
$progressBar1.Value = ($currentVerifyItems/$totaltestItems)*100

$result+=Check-IPAddress -devicename $env:COMPUTERNAME
$currentresult=$result[$currentVerifyItems]
$currentsummary=$currentresult.substring(6,$currentresult.indexof(",")-6)
$order=$currentVerifyItems+1
$summary+=[string]$order+":"+$currentsummary+"`r`n"
$OutputTextBox.Text=$summary
$currentsummary=""
$infoindex=$currentresult.indexof("-")
$StatusBar.Text=($result[$currentVerifyItems]).substring(6,$infoindex-7)
if($currentresult -like "*--failed*")
{
$infoindex2=$currentresult.indexof("[Tips]")
$currentTip=$currentresult.substring($infoindex2+6)
if ($tips.count -eq 0)
{
if($global:languageOption -eq "ENG")
{$tiphead="Solutioin on failure Verification"}
elseif($global:languageOption -eq "CHN")
{$tiphead="解决方案"}
$tips+=$tiphead+" `r`nNo "+[string]$order+":"+$currentTip+"`r`n"}
else
{$tips+="No "+[string]$order+":"+$currentTip+"`r`n"}
}
$TextBox.Text=$tips
$currentVerifyItems++
$progressBar1.Value = ($currentVerifyItems/$totaltestItems)*100

$result+=check-AdminGrpMembers -devicename $env:computername
$currentresult=$result[$currentVerifyItems]
$currentsummary=$currentresult.substring(6,$currentresult.indexof(",")-6)
$order=$currentVerifyItems+1
$summary+=[string]$order+":"+$currentsummary+"`r`n"
$currentsummary=""
$OutputTextBox.Text=$summary
$infoindex=$currentresult.indexof("-")
$StatusBar.Text=($result[$currentVerifyItems]).substring(6,$infoindex-7)
if($currentresult -like "*--failed*")
{
$infoindex2=$currentresult.indexof("[Tips]")
$currentTip=$currentresult.substring($infoindex2+6)
if ($tips.count -eq 0)
{
if($global:languageOption -eq "ENG")
{$tiphead="Solutioin on failure Verification"}
elseif($global:languageOption -eq "CHN")
{$tiphead="解决方案"}
$tips+=$tiphead+" `r`nNo "+[string]$order+":"+$currentTip+"`r`n"}
else
{$tips+="No "+[string]$order+":"+$currentTip+"`r`n"}
}
$TextBox.Text=$tips
$currentVerifyItems++
$progressBar1.Value = ($currentVerifyItems/$totaltestItems)*100

$result+=check-partition
$currentresult=$result[$currentVerifyItems]
$currentsummary=$currentresult.substring(6,$currentresult.indexof(",")-6)
$order=$currentVerifyItems+1
$summary+=[string]$order+":"+$currentsummary+"`r`n"
$currentsummary=""
$OutputTextBox.Text=$summary
$infoindex=$currentresult.indexof("-")
$StatusBar.Text=($result[$currentVerifyItems]).substring(6,$infoindex-7)
if($currentresult -like "*--failed*")
{
$infoindex2=$currentresult.indexof("[Tips]")
$currentTip=$currentresult.substring($infoindex2+6)
if ($tips.count -eq 0)
{
if($global:languageOption -eq "ENG")
{$tiphead="Solutioin on failure Verification"}
elseif($global:languageOption -eq "CHN")
{$tiphead="解决方案"}
$tips+=$tiphead+" `r`nNo "+[string]$order+":"+$currentTip+"`r`n"}
else
{$tips+="No "+[string]$order+":"+$currentTip+"`r`n"}
}
$TextBox.Text=$tips
$currentVerifyItems++
$progressBar1.Value = ($currentVerifyItems/$totaltestItems)*100

$result+=check-retailPSmodule
$currentresult=$result[$currentVerifyItems]
$currentsummary=$currentresult.substring(6,$currentresult.indexof(",")-6)
$order=$currentVerifyItems+1
$summary+=[string]$order+":"+$currentsummary+"`r`n"
$currentsummary=""
$OutputTextBox.Text=$summary
$infoindex=$currentresult.indexof("-")
$StatusBar.Text=($result[$currentVerifyItems]).substring(6,$infoindex-7)
if($currentresult -like "*--failed*")
{
$infoindex2=$currentresult.indexof("[Tips]")
$currentTip=$currentresult.substring($infoindex2+6)
if ($tips.count -eq 0)
{
if($global:languageOption -eq "ENG")
{$tiphead="Solutioin on failure Verification"}
elseif($global:languageOption -eq "CHN")
{$tiphead="解决方案"}
$tips+=$tiphead+" `r`nNo "+[string]$order+":"+$currentTip+"`r`n"}
else
{$tips+="No "+[string]$order+":"+$currentTip+"`r`n"}
}
$TextBox.Text=$tips
$currentVerifyItems++
$progressBar1.Value = ($currentVerifyItems/$totaltestItems)*100

$result+=check-driver
$currentresult=$result[$currentVerifyItems]
$currentsummary=$currentresult.substring(6,$currentresult.indexof(",")-6)
$order=$currentVerifyItems+1
$summary+=[string]$order+":"+$currentsummary+"`r`n"
$currentsummary=""
$OutputTextBox.Text=$summary
$infoindex=$currentresult.indexof("-")
$StatusBar.Text=($result[$currentVerifyItems]).substring(6,$infoindex-7)
if($currentresult -like "*--failed*")
{
$infoindex2=$currentresult.indexof("[Tips]")
$currentTip=$currentresult.substring($infoindex2+6)
if ($tips.count -eq 0)
{
if($global:languageOption -eq "ENG")
{$tiphead="Solutioin on failure Verification"}
elseif($global:languageOption -eq "CHN")
{$tiphead="解决方案"}
$tips+=$tiphead+" `r`nNo "+[string]$order+":"+$currentTip+"`r`n"}
else
{$tips+="No "+[string]$order+":"+$currentTip+"`r`n"}
}
$TextBox.Text=$tips
$currentVerifyItems++
$progressBar1.Value = ($currentVerifyItems/$totaltestItems)*100

$result+=check-LocalGroup
$currentresult=$result[$currentVerifyItems]
$currentsummary=$currentresult.substring(6,$currentresult.indexof(",")-6)
$order=$currentVerifyItems+1
$summary+=[string]$order+":"+$currentsummary+"`r`n"
$currentsummary=""
$OutputTextBox.Text=$summary
$infoindex=$currentresult.indexof("-")
$StatusBar.Text=($result[$currentVerifyItems]).substring(6,$infoindex-7)
if($currentresult -like "*--failed*")
{
$infoindex2=$currentresult.indexof("[Tips]")
$currentTip=$currentresult.substring($infoindex2+6)
if ($tips.count -eq 0)
{
if($global:languageOption -eq "ENG")
{$tiphead="Solutioin on failure Verification"}
elseif($global:languageOption -eq "CHN")
{$tiphead="解决方案"}
$tips+=$tiphead+" `r`nNo "+[string]$order+":"+$currentTip+"`r`n"}
else
{$tips+="No "+[string]$order+":"+$currentTip+"`r`n"}
}
$TextBox.Text=$tips
$currentVerifyItems++
$progressBar1.Value = ($currentVerifyItems/$totaltestItems)*100


$result+=check-installedSoftware
$currentresult=$result[$currentVerifyItems]
$currentsummary=$currentresult.substring(6,$currentresult.indexof(",")-6)
$order=$currentVerifyItems+1
$summary+=[string]$order+":"+$currentsummary+"`r`n"
$currentsummary=""
$OutputTextBox.Text=$summary
$infoindex=$currentresult.indexof("-")
$StatusBar.Text=($result[$currentVerifyItems]).substring(6,$infoindex-7)
if($currentresult -like "*--failed*")
{
$infoindex2=$currentresult.indexof("[Tips]")
$currentTip=$currentresult.substring($infoindex2+6)
if ($tips.count -eq 0)
{
if($global:languageOption -eq "ENG")
{$tiphead="Solutioin on failure Verification"}
elseif($global:languageOption -eq "CHN")
{$tiphead="解决方案"}
$tips+=$tiphead+" `r`nNo "+[string]$order+":"+$currentTip+"`r`n"}
else
{$tips+="No "+[string]$order+":"+$currentTip+"`r`n"}
}
$TextBox.Text=$tips
$currentVerifyItems++
$progressBar1.Value = ($currentVerifyItems/$totaltestItems)*100


$result+=check-fileandFolder
$currentresult=$result[$currentVerifyItems]
$currentsummary=$currentresult.substring(6,$currentresult.indexof(",")-6)
$order=$currentVerifyItems+1
$summary+=[string]$order+":"+$currentsummary+"`r`n"
$currentsummary=""
$OutputTextBox.Text=$summary
$infoindex=$currentresult.indexof("-")
$StatusBar.Text=($result[$currentVerifyItems]).substring(6,$infoindex-7)
if($currentresult -like "*--failed*")
{
$infoindex2=$currentresult.indexof("[Tips]")
$currentTip=$currentresult.substring($infoindex2+6)
if ($tips.count -eq 0)
{
if($global:languageOption -eq "ENG")
{$tiphead="Solutioin on failure Verification"}
elseif($global:languageOption -eq "CHN")
{$tiphead="解决方案"}
$tips+=$tiphead+" `r`nNo "+[string]$order+":"+$currentTip+"`r`n"}
else
{$tips+="No "+[string]$order+":"+$currentTip+"`r`n"}
}
$TextBox.Text=$tips
$currentVerifyItems++
$progressBar1.Value = ($currentVerifyItems/$totaltestItems)*100


$DeviceType=($env:COMPUTERNAME).Substring(9,2)
if($DeviceType -eq "RG")
{$result+=check-CharacterSetlist}
elseif($DeviceType -eq "PC")
{$result+=check-performanceandNICpowersaving}

$currentresult=$result[$currentVerifyItems]
$currentsummary=$currentresult.substring(6,$currentresult.indexof(",")-6)
$order=$currentVerifyItems+1
$summary+=[string]$order+":"+$currentsummary
$currentsummary=""
$OutputTextBox.Text=$summary
$infoindex=$currentresult.indexof("-")
$StatusBar.Text=($result[$currentVerifyItems]).substring(6,$infoindex-7)
if($currentresult -like "*--failed*")
{
$infoindex2=$currentresult.indexof("[Tips]")
$currentTip=$currentresult.substring($infoindex2+6)
if ($tips.count -eq 0)
{
if($global:languageOption -eq "ENG")
{$tiphead="Solutioin on failure Verification"}
elseif($global:languageOption -eq "CHN")
{$tiphead="解决方案"}
$tips+=$tiphead+" `r`nNo "+[string]$order+":"+$currentTip+"`r`n"}
else
{$tips+="No "+[string]$order+":"+$currentTip+"`r`n"}
}
$TextBox.Text=$tips
$currentVerifyItems++
$progressBar1.Value = ($currentVerifyItems/$totaltestItems)*100




if ($result -match "fail")
{$errorImagebox.Visible=$true}
else
{$rightImagebox.Visible=$true}

$lines=$OutputTextBox.Lines
$selstart=0
foreach($line in $Lines)
{
if($line -match "failed")
    {
    $OutputTextBox.Select($selstart,$line.length)
    $OutputTextBox.SelectionColor=[Drawing.Color]::Red
    }
if($line -match "passed")
    {
    $OutputTextBox.Select($selstart,$line.length)
    $OutputTextBox.SelectionColor=[Drawing.Color]::Green
    }
$selstart+=$line.length+1
}

}

#$OnLoadForm_StateCorrection= 
{#Correct the initial state of the form to prevent the .Net maximized form issue 
$CrossOverBMBVerificationForm.WindowState = $InitialFormWindowState 
}


$handler_LanguageButton_Click=
{
$global:LanguageOption="CHN"
$CheckItemLabel.Text="检查总结“
$HostnameTextBox.Text=”计算机名：$env:computername"

$CrossOverBMBVerificationForm.Text="CrossOver BMB 安装验证工具"
#$LanguageButton.Text ="swith English"
$checkbutton.Text="开始检查"
$StatusBar.Text = "准备就绪"
$ResultLabel.Text ="结果:"
}
#---------------------------------------------- 
#region Generated Form Code 
$CrossOverBMBVerificationForm.Text = "CrossOver Verification Tools" 
$CrossOverBMBVerificationForm.Name = "CrossOver Verification Tools" 
$CrossOverBMBVerificationForm.DataBindings.DefaultDataSourceUpdateMode = 0 
$System_Drawing_Size = New-Object System.Drawing.Size 
$formwidth=600
$formheight=600
$formleft=40
$formright=40
$System_Drawing_Size.Width = $formwidth
$System_Drawing_Size.Height = $formheight
$CrossOverBMBVerificationForm.ClientSize = $System_Drawing_Size



$CheckItemLabel.Text = "Verification Summary"
$CheckItemLabel.AutoSize=$true
#CheckItemLabel.Width=$formwidth
#CheckItemLabel.Height=$formheight*0.01
#$CheckItemLabel.TextAlign=Topleft
$CheckItemLabel.Location= New-Object System.Drawing.Point($formleft,20)
$CheckItemLabel.Font="Microsoft Sans Serif,20"

$HostnameTextBox.Text = "ComputerName:$env:computername"
$HostnameTextBox.Width=160
$HostnameTextBox.Height=33
$HostnameTextBox.ReadOnly=$True
$HostnameTextBox.AutoSize=$True
$HostnameTextBox.BackColor=[Drawing.Color]::Blue
$HostnameTextBox.ForeColor=[Drawing.Color]::White
$HostnameTextBox.Location= New-Object System.Drawing.Point($formleft,0)
$HostnameTextBox.Font="Microsoft Sans Serif,8"


$OutputTextBox.Text = ""
$OutputTextBox.Width = ($formwidth-$formleft-$formright)
$OutputTextBox.Height = $formheight*0.3
$OutputTextBox.AutoSize=$true
$OutputTextBox.location = new-object system.drawing.point($formleft,60)
$OutputTextBox.Font = "Microsoft Sans Serif,10"
$OutputTextBox.MultiLine = $true
$OutputTextBox.ScrollBars = "Vertical" 




$TextBox.Text = ""
$TextBox.Width = ($formwidth-$formleft-$formright)
$TextBox.Height = $formheight*0.4
$TextBox.AutoSize=$True
$TextBoxX=$formleft
$TextBoxY=60+40+$formheight*0.3
$TextBox.location = new-object system.drawing.point($TextBoxX,$TextBoxY)
$TextBox.Font = "Microsoft Sans Serif,10"
$TextBox.MultiLine = $true
$TextBox.ScrollBars = "Vertical" 
 

$rightImagebox.ImageLocation=".\right.gif"
$rightImagebox.Visible=$false
$rightImagebox.Width=33
$rightImagebox.Height=33
$rightImagebox.Name="right"
$ImageboxX=$formleft+100
$ImageboxY=60+$formheight*0.3
$rightImagebox.Location = New-Object System.Drawing.Point($ImageboxX,$imageboxY) 


$errorImagebox.ImageLocation=".\error.gif"
$errorImagebox.Visible=$false
$errorImagebox.Width=33
$errorImagebox.Height=33
$errorImagebox.Name="error"
$errorImagebox.Location = New-Object System.Drawing.Point($ImageboxX,$imageboxY) 


$ResultLabel.Text="Result:"
$ResultLabel.AutoSize=$true
#$ResultLabel.TextAlign=Topleft
$ResultLabel.Location= New-Object System.Drawing.Point(40,$ImageboxY)
$ResultLabel.Font="Microsoft Sans Serif,20"

$CheckButton.TabIndex = 0 
$CheckButton.Name = "Check" 
$CheckButton.UseVisualStyleBackColor = $True
$CheckItemLabel.AutoSize=$true
$CheckButton.BackColor="Gray"
$CheckButton.Text = "Check"
$CheckButton.Font="Microsoft Sans Serif,8"
$CheckButtonY=$formheight-60
$CheckButton.Location = New-Object System.Drawing.Point($formleft,$CheckButtonY) 
$CheckButton.DataBindings.DefaultDataSourceUpdateMode = 0 
$CheckButton.add_Click($handler_CheckButton_Click)


$StatusBar.Text = "ready to go"
$StatusBar.Height = 20
$StatusBar.Width = 50
#$StatusBar.Location = New-Object System.Drawing.Point(90,230)

$progressBar1.Name = 'progressBar1'
$progressBar1.Value = 0
$progressBar1.Style="Continuous"
$progressBar1Y=$formheight-30
$progressBar1.size = new-object System.Drawing.Size($formwidth,10)
$progressBar1.Location = New-Object System.Drawing.Point(0,$progressBar1Y)

$clockLbl.Text =(Get-Date)
$clockLbl.AutoSize = $True
$clockLbl.ForeColor = [Drawing.Color]::White
$clockLbl.BackColor = [Drawing.Color]::Black 
$clockLbl.Height=33
$clockLbl.Width=160
$clockLbl.AutoSize=$true
$clockLbl.Font="Microsoft Sans Serif,10"
$clockLblx=$formwidth-$formright-135
$clockLbl.Location = New-Object System.Drawing.Point($clockLblx,0)
$CrossOverBMBVerificationForm.Controls.Add($clockLbl)
$timer1_Tick={
    $clockLbl.Text = (Get-Date)
}
$timer1.Enabled = $True
$timer1.Interval = 1000
$timer1.add_Tick($timer1_Tick)

$LanguageButton.TabIndex = 0 
$LanguageButton.Name = "切换中文" 
$LanguageButton.UseVisualStyleBackColor = $True
$LanguageButton.AutoSize=$true
$LanguageButton.BackColor="orange"
$LanguageButton.Text = "切换中文"
$LanguageButton.Font="Microsoft Sans Serif,6"

$LanguageButton.Location = New-Object System.Drawing.Point($clockLblx,$CheckButtonY) 
$LanguageButton.DataBindings.DefaultDataSourceUpdateMode = 0 
$LanguageButton.add_Click($handler_LanguageButton_Click)


$CrossOverBMBVerificationForm.Controls.Add($CheckButton)
$CrossOverBMBVerificationForm.Controls.Add($CheckItemLabel)
$CrossOverBMBVerificationForm.Controls.Add($OutputTextBox)
$CrossOverBMBVerificationForm.Controls.Add($rightImagebox)
$CrossOverBMBVerificationForm.Controls.Add($errorImagebox)
$CrossOverBMBVerificationForm.Controls.Add($TextBox)
$CrossOverBMBVerificationForm.Controls.Add($StatusBar)
$CrossOverBMBVerificationForm.Controls.Add($progressBar1)
$CrossOverBMBVerificationForm.Controls.Add($HostnameTextBox)
$CrossOverBMBVerificationForm.Controls.Add($clockLbl)
$CrossOverBMBVerificationForm.Controls.Add($LanguageButton)
$CrossOverBMBVerificationForm.Controls.Add($ResultLabel)
#endregion Generated Form Code

#Save the initial state of the form 
$InitialFormWindowState = $CrossOverBMBVerificationForm.WindowState 
#Init the OnLoad event to correct the initial state of the form 
$CrossOverBMBVerificationForm.add_Load($OnLoadForm_StateCorrection) 
#Show the Form 
$CrossOverBMBVerificationForm.ShowDialog()| Out-Null

} #End Function

#Call the Function 
GenerateForm 


