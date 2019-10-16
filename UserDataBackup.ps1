<#Date:2019/110/16
Author:George Liu
Description: Backup the user Data Before Reimaging
Detail:
Copy C:/UserData
#>
Function Get-UserData {
<#
.SYNOPSIS
    Backup the user Data Before Reimaging.
 
.DESCRIPTION
    common folder which need to backup:
    1.user data：c:\users\username  /ex c:\users\bob
        1.1 Desktop
        1.2 Document
    2.favorites from Chrome
    3.Outlook Mail file:.pst file
    4.Customre data: which should not in the build-in folder and change frequently   /ex:c:\trainning
    5.applicaiton config file including the login information /ex:configure file for wechat 
    6.software and hardware inventory 
 
.PARAMETER ComputerName
    Name of the computername to backup ,it will backup all users data

 .PARAMETER UserName
    Specail the user to backup 
 
.EXAMPLE
     Get-UserData -ComputerName RNAP03833PC001
 
.INPUTS
    None
 
.OUTPUTS
    Statistic all the UserDate  by folder 
 
.NOTES
    Author: George Liu
    Date:2019/110/16
#>
 
[CmdletBinding()]
    param (
        $ComputerName, # if not special,it will backup  the localhost, the backup the all users  c:\users
        $UserName
    )
    
# Verify the PC is online or not
# give the message to user when backup start and finished ***
# give the user to choose the addition file he want to backup *****  funture fuction
# compare the capcity of the server share to see if we can  upload the backup
# import the task schedule to run daily
Add-Type -AssemblyName PresentationFramework
Install-Module BurntToast -Force
Import-Module BurntToast

if ($ComputerName -ne $null){
    if( -Not (Test-Connection $ComputerName)){
        throw ("Exception:Unable to connect the $($computername)")
    }
}

#stare the copy process 
$UserName=$env:USERNAME
#need to chagne the computername parameter
$ComputerName='RNLQ03404PC001'
$StoreNumber=$COMPUTERNAME.Substring(4,5)
$StoreServer='RNLQ'+$StoreNumber+'SV001'
$StoreShare='\\'+$StoreServer+'\StoreShared$'
#userdate should be \\rnlq03404pc001\C$\xxx
$UserHomeFolders='C:\Users\'+$UserName+'\'
$UserCustomerFolder='C:\Backup\'
$UserDataFolders=($UserHomeFolders,$UserCustomerFolder)
#$UserDataFolders.Count
$Logfile="/Log+:C:\UseDataBackup\robocopy.log"
$UserDataFolders
#[System.Windows.MessageBox]::Show('Backup Start')
mkdir C:\UseDataBackup
New-BurntToastNotification -Text "Backup Start"
$UserDataFolders.count
foreach ($Folders in $UserDataFolders){
    #ERROR : You do not have the Backup and Restore Files user rights.
    robocopy $Folders $StoreShare /R:1 /W:1   /TEE  $Logfile  /lev:2 #/NP /ZB
}
#[System.Windows.MessageBox]::Show('Backup Ended')
New-BurntToastNotification -Text "Backup END"

}


Get-UserData -ComputerName 'RNAP03833PC001'