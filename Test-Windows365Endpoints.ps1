$ScriptName = 'Test-Windows365Endpoints'
$ScriptVer = 'v0.05'

# Test network connectivity to Windows 365 Services (including AVD and Intune)
# Run from the Cloud PC or a VM connected to an Azure VNet where CPCs will be provisioned

# Run this script directly from this gist using the command below
# powershell -ex bypass "iex (irm https://aka.ms/testw365vnet)"

# Host/Ports were taken from the link below on 2024-May-08 - Check for newer lists and update as necessary
# https://learn.microsoft.com/en-us/windows-365/enterprise/requirements-network?tabs=enterprise%2Cent#windows-365-service
$endpoints_w365 = @(
    '*.infra.windows365.microsoft.com',
    '*.cmdagent.trafficmanager.net',
    'login.microsoftonline.com',
    'login.live.com',
    'enterpriseregistration.windows.net',
    'global.azure-devices-provisioning.net:443,5671',
    'hm-iot-in-prod-prap01.azure-devices.net:443,5671',
    'hm-iot-in-prod-prau01.azure-devices.net:443,5671',
    'hm-iot-in-prod-preu01.azure-devices.net:443,5671',
    'hm-iot-in-prod-prna01.azure-devices.net:443,5671',
    'hm-iot-in-prod-prna02.azure-devices.net:443,5671',
    'hm-iot-in-2-prod-preu01.azure-devices.net:443,5671',
    'hm-iot-in-2-prod-prna01.azure-devices.net:443,5671',
    'hm-iot-in-3-prod-preu01.azure-devices.net:443,5671',
    'hm-iot-in-3-prod-prna01.azure-devices.net:443,5671',
    'hm-iot-in-4-prod-prna01.azure-devices.net:443,5671'
)

# These were the endpoints required before 2024-May-08
$endpoints_w365_old = @(
    '*.infra.windows365.microsoft.com:443',
    'cpcsaamssa1prodprap01.blob.core.windows.net:443',
    'cpcsaamssa1prodprau01.blob.core.windows.net:443',
    'cpcsaamssa1prodpreu01.blob.core.windows.net:443',
    'cpcsaamssa1prodpreu02.blob.core.windows.net:443',
    'cpcsaamssa1prodprna01.blob.core.windows.net:443',
    'cpcsaamssa1prodprna02.blob.core.windows.net:443',
    'cpcstcnryprodprap01.blob.core.windows.net:443',
    'cpcstcnryprodprau01.blob.core.windows.net:443',
    'cpcstcnryprodpreu01.blob.core.windows.net:443',
    'cpcstcnryprodpreu02.blob.core.windows.net:443',
    'cpcstcnryprodprna01.blob.core.windows.net:443',
    'cpcstcnryprodprna02.blob.core.windows.net:443',
    'cpcstprovprodpreu01.blob.core.windows.net:443',
    'cpcstprovprodpreu02.blob.core.windows.net:443',
    'cpcstprovprodprna01.blob.core.windows.net:443',
    'cpcstprovprodprna02.blob.core.windows.net:443',
    'cpcstprovprodprap01.blob.core.windows.net:443',
    'cpcstprovprodprau01.blob.core.windows.net:443',
    'prna01.prod.cpcgateway.trafficmanager.net:443',
    'prna02.prod.cpcgateway.trafficmanager.net:443',
    'preu01.prod.cpcgateway.trafficmanager.net:443',
    'preu02.prod.cpcgateway.trafficmanager.net:443',
    'prap01.prod.cpcgateway.trafficmanager.net:443',
    'prau01.prod.cpcgateway.trafficmanager.net:443',
    'endpointdiscovery.cmdagent.trafficmanager.net:443',
    'registration.prna01.cmdagent.trafficmanager.net:443',
    'registration.preu01.cmdagent.trafficmanager.net:443',
    'registration.prap01.cmdagent.trafficmanager.net:443',
    'registration.prau01.cmdagent.trafficmanager.net:443',
    'registration.prna02.cmdagent.trafficmanager.net:443',
    'login.microsoftonline.com:443',
    'login.live.com:443',
    'enterpriseregistration.windows.net:443',
    'global.azure-devices-provisioning.net:443,5671',
    'hm-iot-in-prod-prap01.azure-devices.net:443,5671',
    'hm-iot-in-prod-prau01.azure-devices.net:443,5671',
    'hm-iot-in-prod-preu01.azure-devices.net:443,5671',
    'hm-iot-in-prod-prna01.azure-devices.net:443,5671',
    'hm-iot-in-prod-prna02.azure-devices.net:443,5671',
    'hm-iot-in-2-prod-preu01.azure-devices.net:443,5671',
    'hm-iot-in-2-prod-prna01.azure-devices.net:443,5671',
    'hm-iot-in-3-prod-preu01.azure-devices.net:443,5671',
    'hm-iot-in-3-prod-prna01.azure-devices.net:443,5671',
    'hm-iot-in-4-prod-prna01.azure-devices.net:443,5671'
)

# Host/Ports were taken from the link below on 2023-Oct-24 - Check for newer lists and update as necessary
# https://learn.microsoft.com/en-us/azure/virtual-desktop/safe-url-list?tabs=azure#session-host-virtual-machines
$endpoints_avd = @(
    'login.microsoftonline.com:443',
    '*.wvd.microsoft.com:443',
    '*.prod.warm.ingest.monitor.core.windows.net:443',
    'catalogartifact.azureedge.net:443',
    'gcs.prod.monitoring.core.windows.net:443',
    'kms.core.windows.net:1688',
    'azkms.core.windows.net:1688',
    'mrsglobalsteus2prod.blob.core.windows.net:443',
    'wvdportalstorageblob.blob.core.windows.net:443',
    '169.254.169.254:80',
    '168.63.129.16:80',
    'oneocsp.microsoft.com:80',
    'www.microsoft.com:80'
)

function Test-HostPortList {
    param (
        [string]$Hostname,
        [string]$PortList = ''
    )

    if ($Hostname.StartsWith('*')) {
        Write-Host "Cannot test $Hostname" -ForegroundColor DarkYellow
        return
    }

    Write-Host -NoNewline "Testing $Hostname"

    # Manually override port to test for certain hosts...
    if ($Hostname -eq 'time.windows.com') { $PortList = "80"; }

    # Use 443 when port is NOT specified
    if ($PortList -eq '') {
        $PortList = "443"
    }

    foreach ($TestPort in $PortList.split(',')) {
        Write-Host -NoNewline " ...($TestPort) "
        if (Test-NetConnection $Hostname -Port $TestPort -InformationLevel Quiet -WarningAction SilentlyContinue) {
            Write-Host -NoNewline "OK" -ForegroundColor Green
        }
        else {
            Write-Host -NoNewline "FAIL" -ForegroundColor Red
        }
    }
    Write-Host ''
}

###########################
Write-Host "$ScriptName $ScriptVer" -ForegroundColor Blue

Write-Host "Loading Windows 365 host list" -ForegroundColor Cyan
foreach ($hostport in $endpoints_w365) {
    $hostport = $hostport.split(':');
    Test-HostPortList -Hostname $hostport[0] -PortList $hostport[1]
}

Write-Host "Loading AVD host list" -ForegroundColor Cyan
foreach ($hostport in $endpoints_avd) {
    $hostport = $hostport.split(':');
    Test-HostPortList -Hostname $hostport[0] -PortList $hostport[1]
}

Write-Host "Loading Intune host list" -ForegroundColor Cyan
foreach ($hostport in (invoke-restmethod -Uri ("https://endpoints.office.com/endpoints/WorldWide?ServiceAreas=MEM`&clientrequestid=" + ([GUID]::NewGuid()).Guid)) | Where-Object { $_.ServiceArea -eq "MEM" -and $_.urls } | Select-Object -unique -ExpandProperty urls) {
    Test-HostPortList -Hostname $hostport
}

Write-Host "Done." -ForegroundColor Blue