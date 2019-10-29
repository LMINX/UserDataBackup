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
        3.business data : excel report 
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
            $ComputerName=$env:COMPUTERNAME, # if not special,it will backup  the localhost, the backup the all users  c:\users
            $UserName
        )
        
    # Verify the PC is online or not
    #at the very beginning, backup all users data on PC and then do individual increatment backup for each user by ways below 
        # give the message to user when backup start and finished ***
        # give the user to choose the addition file he want to backup *****  funture fuction
        # compare the capcity of the server share to see if we can  upload the backup
        # import the task schedule to run daily
    Add-Type -AssemblyName PresentationFramework
    
    <#This module is not compatibility with win7, only for win10  
    Install-Module BurntToast -Force
    Import-Module BurntToast
    #>
    <#as the script is runned  locally on pc,dont need to check the online or not)
    if ($ComputerName -ne $null){
        if( -Not (Test-Connection $ComputerName)){
            #throw ("Exception:Unable to connect the $($computername)")
        }
    }
    #>
    
    
    #stare the copy process 
    $UserName=$env:USERNAME
    #need to chagne the computername parameter
    #$ComputerName='RNLQ03404PC001'
    $StoreNumber=$COMPUTERNAME.Substring(4,5)
    $StoreNamePrefix=$COMPUTERNAME.Substring(0,4)
    $StoreServer=$StoreNamePrefix+$StoreNumber+'SV001'
    $StoreShare='\\'+$StoreServer+'\StoreShared$'+'\BackupForWin7Upgrade\'+$StoreNumber+'\'+$UserName+'\'
    #userdate should be \\rnlq03404pc001\C$\xxx
    $UserHomeFolders='C:\Users\'+$UserName+'\'
    $UserDesktop=$UserHomeFolders+'Desktop'
    $UserDownloads=$UserHomeFolders+'Downloads'
    $UserDocuments=$UserHomeFolders+'Documents'
    #$UserCustomerFolder='C:\Backup\'
    $UserDataFolders=($UserDesktop,$UserDownloads,$UserDocuments)
    #$UserDataFolders.Count
    $Logfile="/Log+:C:\UseDataBackup\robocopy.log"
    
    $wsh = New-Object -ComObject Wscript.Shell
    $wsh.Popup("Backup Start",5,"Win7Upgrade")
    #[System.Windows.MessageBox]::Show('Backup Start')
    mkdir C:\UseDataBackup
    
    
    foreach ($Folders in $UserDataFolders){
        #ERROR : You do not have the Backup and Restore Files user rights.
        $Dest=$StoreShare+$Folders.Substring($UserHomeFolders.Length)
        robocopy $Folders $Dest /R:1 /W:1   /TEE  /COPY:DAT  $Logfile  /lev:2 #/NP /ZB /CopyALL
    }
    #[System.Windows.MessageBox]::Show('Backup Ended')
    #New-BurntToastNotification -Text "Backup END"
    $wsh.Popup("Backup End",5,"Win7Upgrade")
    }
    
    
    #Get-UserData -ComputerName $env:COMPUTERNAME
    
    Get-UserData #-ComputerName rnlq03404pc001

    #pull test from vscode