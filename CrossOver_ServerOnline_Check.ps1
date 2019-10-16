<#
--------------------------------------------
version:1.3
update:2018.1.18
Creator:George
description: check the server online status for crossover Project.
function: ping more than once if the pingloss is between 1%-70%
automatically check the sccm server  by rtap0xxxxxcm001,rtap0xxxxsc001, or rnap0xxxxcm001
ping loss and server model(shared or new ) will be showed as an useful information
update on 2018.1.18
enable the validatioin on  IP assignment rule for DNS records.
#2018.3.2 function required-need to chcck the share mode SC001 ipaddr 
need to check if  the hostname and DNS name match 
need to check all server dns is in the same subnet
--------------------------------------------
#>
#check the store server has dns enties and online
$global:pingcount=1
$global:maxretries=2
function hlight
{
param ($string)
    
    if($string -match "dismatch the IP assignment rule")
    {
    $index=$string.indexof("dismatch the IP assignment rule")
    $StrA=$string.substring(0,$index)
    $StrB=$string.substring($index)
        if (($strA -match "offline") -or ($strA -match "unable to resolve dns"))
        {
        write-host $strA -ForegroundColor Red -NoNewline
        }
        elseif(($strA -match "unable to dertermine the CM") -or ($strA -match ”DNS not update“))
        {
        write-host $strA -ForegroundColor yellow -NoNewline
        }
        else
        {
        write-host $strA -ForegroundColor green -NoNewline
        }
        write-host $strB -ForegroundColor Gray
        }
    else 
    {
        if (($string -match "offline") -or ($string -match "unable to resolve dns"))
        {
        write-host $string -ForegroundColor Red
        }
        elseif(($string -match "unable to dertermine the CM") -or ($string -match ”DNS not update“))
        {
        write-host $string -ForegroundColor yellow 
        }
        else
        {
        write-host $string -ForegroundColor green 
        }
    }    
}

function mulitecolur()
{


}

function OnlineCheck
{
param($devname)
    try {
        $devip=Resolve-DnsName $devname -ea Stop

        if($devip.ipaddress -match "^10.79.144.*")
        {
        return $devname+" unable to check as the DNS not update,Staging DNS is:"+$devip.ipaddress+","+$match
        }
        else
        {
        $A1NStoreUSstand=3864,3821,3865,3863,3867,3868,3869,3870,3871,3872,3879,3880,3881,3391,4904
        $A1NStoreEUstand=3854,3392,3861,3859,3844,3852,3860,3857,4901

        $storeNo=$devname.substring(5,4)


        if ($storeNo -in $A1NStoreUSstand)
        {
            if ($devip.ipaddress -match ".31$")
            {$type="RI"}
            elseif ($devip.ipaddress -match ".32$")
            {$type="HV"} 
            elseif ($devip.ipaddress -match ".33$")
            {$type="SV"} 
            elseif ($devip.ipaddress -match ".34$" )
            {$type="CM"} 
            elseif ($devip.ipaddress -match ".18$" )
            {$type="PR"}
            elseif ($devip.ipaddress -match ".5$")
            {$type="SP"}  
            else 
            {$type="OT"}  
        }
        elseif ($storeNo -in $A1NStoreEUstand) 
        {
            if ($devip.ipaddress -match ".160$")
            {$type="RI"}
            elseif ($devip.ipaddress -match ".161$")
            {$type="HV"} 
            elseif ($devip.ipaddress -match ".162$" )
            {$type="SV"} 
            elseif ($devip.ipaddress -match ".163$")
            {$type="CM"} 
            elseif ($devip.ipaddress -match ".31$" )
            {$type="PR"}
            elseif ($devip.ipaddress -match ".5$")
            {$type="SP"}  
            else 
            {$type="OT"}  
        }
        else
        {
            if ($devip.ipaddress -match ".26$")
            {$type="RI"}
            elseif ($devip.ipaddress -match ".27$")
            {$type="HV"} 
            elseif ($devip.ipaddress -match ".28$")
            {$type="SV"} 
            elseif ($devip.ipaddress -match ".29$")
            {$type="CM"} 
            elseif ($devip.ipaddress -match ".31$")
            {$type="PR"}
            elseif ($devip.ipaddress -match ".5$")
            {$type="SP"}  
            else 
            {$type="OT"}  
        }

        $dnstype=$devname.substring(9,2)

        if ($dnstype -eq  $type) 
        {$match="match the IP assignment rule for $devname"}
        else 
        {$match="dismatch the IP assignment rule for $devname"}


            try{            
                $pingtimes=4
                $successrate=0
                $onlinecheck=test-connection $devip.ipaddress  -Count $pingtimes  -ea SilentlyContinue
                foreach ($ping in $onlinecheck)
                {
                if($ping.statuscode -eq 0)
                    {
                    $successrate++
                    }
                }
                if ($onlinecheck -eq $null)
                    {
                    $rate=0
                    }
                else
                    {
                    $rate=$successrate/$pingtimes
                    } 
                
                if ($rate -eq 0) 
                    {
                    return $devname+“ is offline, DNS is:"+$devip.ipaddress+",unable to ping,"+"pingloss is "+"{0:P0}" -f (1-$rate)+","+$match
                    }

                elseif ($rate -ge 0.7 )
                    {
                    return $devname+" is online with DNS:"+$devip.ipaddress+",pingloss is "+"{0:P0}" -f (1-$rate)+","+$match
                    }                
                else 
                    {
                        if ($global:pingcount -lt $global:maxretries)
                            {               
                            $global:pingcount=$global:pingcount+1
                            Write-Host "$global:pingcount th ping test to $devname,ping loss greater than 30%  last time"  -ForegroundColor Yellow 
                            OnlineCheck -devname $devname
                            }
                        elseif ($global:pingcount -eq $global:maxretries)
                             {
                                $global:pingcount=1
                                return $devname+" is offline, DNS is:"+$devip.ipaddress+",unable to ping,"+"pingloss is "+"{0:P0}" -f (1-$rate)+","+$match               
                             }
                        else
                             {#do nothing  }
                    }                   
                }
            }
            catch 
            {
            return $devname+“ is offline, DNS is:"+$devip.ipaddress+",unable to ping "+","+$match 
            }
    }
    }
    catch 
    {
    return $devname+“ is not online, unable to resolve dns "
    } 
}

function OnlineCheckSCCM
{
param($devname)


$hvname=$devname.replace("CM","HV")
$gb2svname1=($devname.replace("CM","sc")).replace("RNAP","RTAP").substring(0,14)
$gb2svname2=($devname).replace("RNAP","RTAP").substring(0,14)
$gb2svname=($gb2svname1,$gb2svname2)

try {
$vms=Invoke-Command -ComputerName $hvname -ScriptBlock {get-vm} -ErrorAction stop
    foreach ($vm in $vms)
    {
            if ($vm.vmname -in $gb2svname)
            {
            $Model="shared"
            break
            }

    $Model="new"
    }
}
catch 
{
$Model="unknown"
}


if ($model -eq "new")
{
$r1=OnlineCheck -devname $devname
return $r1+" in "+$model+" Server mode"
}
elseif ($model -eq "shared")
{
$olddevname1=$devname.replace("RNAP","RTAP")
#$olddevname1
$olddevname2=$olddevname1.replace("CM","SC")
#$olddevname2
$r2=OnlineCheck -devname $olddevname2
$r3=OnlineCheck -devname $olddevname1

$res=@()
$res+=$r2
$res+=$r3
$index=0
    foreach ($r in $res)
    {
        if ($r -match "is online with DNS")
        {
    
        return $r+" in "+$model+" Server mode"
        break
        }
    
        if ($index -eq 1)
        {
           return  $olddevname2+","+$olddevname1+" all are offline in "+$model+" Server mode"
           break
        }
        $index++
    }
    

}
else 
{
$r1=OnlineCheck -devname $devname
return  $r1+",unable to dertermine the CM hostnanme for "+$devname+",using default conversion RNAP0xxxxCM001" 
{

}

    
}
}

#OnlineCheckSCCM -devname RNAP03799CM001

$storeslist="""
3203
3205
3207
3263
3264
3265
3267
3268
3269
3270
4901
4904
3305
3306
3307
3348
3362
3364
3366
3369
3373
3374
3375
3379
3381
3382
3383
3388
3389
3390
3392
3310
3391
"""


$arstoreslist=$storeslist.Split("`n")
$stores=@()
$count=0
foreach ($s in $arstoreslist)
{
if(($count -ne 0) -and ($count -ne $arstoreslist.Length-1))
{$stores+=$s.tostring().Trim()
}
$count++
}

foreach ($s in $stores)

{
$sv_name=(("RNAP0"+$s+”SV001")+".nike.com")
$cm_name=(("RNAP0"+$s+”CM001")+".nike.com")
$HV_name=(("RNAP0"+$s+”HV001")+".nike.com")
$RI_name=(("RNAP0"+$s+”RI001")+".nike.com")
$PR_name=(("RNAP0"+$s+”PR001")+".nike.com")
$SP_name=(("RNAP0"+$s+”SP001")+".nike.com")
#function ping dns entries
hlight -string (OnlineCheck -devname $sv_name)
hlight -string (OnlineCheckSCCM -devname $cm_name)
hlight -string (OnlineCheck -devname $hv_name)
hlight -string (OnlineCheck -devname $RI_name)
hlight -string (OnlineCheck -devname $PR_name)
hlight -string (OnlineCheck -devname $SP_name)

}


