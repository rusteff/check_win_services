Param(
    [Parameter(Mandatory=$false)][String]$Name
    )

Function Check-driftservices{

$Return = @{}
    [Int]$Return.ExitCode = 3
    [String]$Return.Returnstring = "Output creation failed, something is not working!"

$Services = ForEach-Object {Get-Service $ServiceArray -ErrorAction SilentlyContinue | 
            Where-Object {$_.Status -eq 'Stopped'}}

$Nondeleyedstart = foreach ($Service in $Services.Name) {Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$Service" | 
                Where-Object {$_.Start -eq 2 -and $_.DelayedAutoStart -ne 2} | 
                Select-Object -Property @{label='ServiceName';expression={$_.PSChildName}} |
                Get-Service
                }

$Deleyedstart = foreach ($Service in $Services.Name) {Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$Service" | 
                Where-Object {$_.Start -eq 2} | 
                Select-Object -Property @{label='ServiceName';expression={$_.PSChildName}} |
                Get-Service
                }

 if ($Deleyedstart) {
    $Return.Returnstring = " CRITICAL: Stopped services: $($Deleyedstart.Name)"
    $Return.ExitCode = 2
 }

  Else {
    $Return.Returnstring = " OK: No stopped services"
    $Return.ExitCode = 0
 }
 
 return $Return
 }
Function Check-nonsupported {

$Return = @{}
    [Int]$Return.ExitCode = 3
    [String]$Return.Returnstring = "Output creation failed, something is not working!"

$Services = ForEach-Object {Get-Service -ErrorAction SilentlyContinue | 
            Where-Object {$_.Status -eq 'Stopped'}} | 
            where ({ $ExcludedServices -notcontains $_.Name })

$Nondeleyedstart = foreach ($Service in $Services.Name) { 
                Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$Service" | 
                Where-Object {$_.Start -eq 2 -and $_.DelayedAutoStart -ne 2} | 
                Select-Object -Property @{label='ServiceName';expression={$_.PSChildName}} |
                Get-Service
                }

$Deleyedstart = foreach ($Service in $Services.Name) { 
                Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$Service" | 
                Where-Object {$_.Start -eq 2} | 
                Select-Object -Property @{label='ServiceName';expression={$_.PSChildName}} |
                Get-Service
                }

 if ($Deleyedstart) {
    $Return.Returnstring = " CRITICAL: Stopped services: $($Deleyedstart.Name)"
    $Return.ExitCode = 2
 }

  Else {
    $Return.Returnstring = " OK: No stopped services"
    $Return.ExitCode = 0
 }
 
 return $Return
 }

## Start Main Script

$Output = New-object PSObject -Property @{
    Exitcode = 3
    Returnstring = 'UNKNOWN: Please debug the script...'
}

if (!(Test-Path "c:\dcsto\excluded_services.txt"))
{
   New-Item -path c:\dcsto -name excluded_services.txt -type "file"
}

# List of Operating system services
$Servicelist = ",Spooler,Schedule,SamSs,SENS,RpcSs,MSDTC,KA0ITSPC06582794740826,Dhcp,SNMP,NSClientpp,EventSystem,Dnscache,DcomLaunch,CryptSvc,WinRM,ekrn,TSM Client Acceptor,nsi,lmhosts,iphlpsvc,gpsvc,Winmgmt,ProfSvc,NlaSvc,LanmanWorkstation,LanmanServer,IKEEXT,FontCache,DPS,BFE,TSM Journal Service,MpsSvc,TrkWks,PlugPlay,Netlogon,RpcEptMapper,Power,VMTools,UxSms,eventlog,AppHostSvc,W32Time,EventLog,seclogon,Dfs,PolicyAgent,DFSR,Themes,IsmServ,AeLookupSvc,NTDS,UALSVC,LSM,BrokerInfrastructure,NetPipeActivator,NetTcpActivator,SQLBrowser,BITS,MSSQLSERVER,MSMFramework,Browser,TermService,AudioSrv,Wcmsvc,SystemEventsBroker,Pml Driver HPZ12,NtFrs,lanmanworkstation,lanmanserver,dmserver,ProtectedStorage,LmHosts,Eventlog,winmgmt,slsvc,netprofm,WerSvc,Net Driver HPZ12,KtmRm,ERSvc,SQLSERVERAGENT,DHCPServer,WZCSVC,WSearch,EFS,helpsvc,Kdc,MSMQ,ERA_SERVER,WinDefend,Wecsvc,NetTcpPortSharing,MegaMonitorSrv,sysdown,MsDtsServer100,ftpsvc,NetMsmqActivator,SrmSvc,CertSvc,cpqvcagent,WMSVC,Syslog Agent,ReportServer,SysMgmtHp,MsDepSvc,HidServ,CqMgHost"
$ServiceArray = @($Servicelist.split(",")) 

# List of excluded services
$strFileText = Get-Content "c:\dcsto\excluded_services.txt"
$strFileText = $strFileText + ",clr_optimization_v4.0.30319_32,clr_optimization_v4.0.30319_64,RemoteRegistry,sppsvc,stisvc,ShellHWDetection,TBS,gupdate,SysmonLog,wuauserv,MapsBroker,WbioSrvc" + $Servicelist
$ExcludedServices = @($strFileText.split(",")) 


if ($Name -eq "driftservices") {
    $driftservices = Check-driftservices
    $Output.Returnstring = $driftservices.Returnstring
    $Output.ExitCode = $driftservices.ExitCode
}

if ($Name -eq "nonsupported") {
    $nonsupported = Check-nonsupported
    $Output.Returnstring = $nonsupported.Returnstring
    $Output.ExitCode = $nonsupported.ExitCode
}

Write-Output $Output.Returnstring

Exit $Output.ExitCode