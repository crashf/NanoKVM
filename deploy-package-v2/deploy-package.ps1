# NanoKVM Package Deployer
param(
    [string]$DeviceIP,
    [string]$Password
)

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " NanoKVM Package Deployer            " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

if (-not $DeviceIP) {
    $DeviceIP = Read-Host "Enter NanoKVM device IP address (e.g., 10.24.69.63)"
    if ([string]::IsNullOrWhiteSpace($DeviceIP)) {
        Write-Host "[!] ERROR: Device IP is required" -ForegroundColor Red
        exit 1
    }
}

if (-not $Password) {
    $SecurePassword = Read-Host "Enter SSH password for root@${DeviceIP}" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}

Write-Host "Target Device: $DeviceIP" -ForegroundColor Cyan
Write-Host ""

# Test connection
Write-Host "[*] Testing connection..." -ForegroundColor Cyan
$pingResult = Test-Connection -ComputerName $DeviceIP -Count 1 -Quiet -ErrorAction SilentlyContinue
if ($pingResult) {
    Write-Host "[+] Device is reachable" -ForegroundColor Green
} else {
    Write-Host "[!] Device not responding to ping (continuing anyway)" -ForegroundColor Yellow
}

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check package contents
Write-Host ""
Write-Host "[*] Verifying package contents..." -ForegroundColor Cyan
if (-not (Test-Path "$ScriptDir\web")) {
    Write-Host "[!] ERROR: Frontend files not found" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "$ScriptDir\server\NanoKVM-Server")) {
    Write-Host "[!] ERROR: Backend binary not found" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "$ScriptDir\wireguard\wireguard-go")) {
    Write-Host "[!] ERROR: WireGuard binary not found" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "$ScriptDir\wireguard\S40wireguard")) {
    Write-Host "[!] ERROR: WireGuard init script not found" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Package contents verified" -ForegroundColor Green

Write-Host ""
Write-Host "Ready to deploy to $DeviceIP" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Continue with deployment? (Y/n)"
if ($confirm -eq "n" -or $confirm -eq "N") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

# Helper function to run SSH commands with password
function Invoke-SSHCommand {
    param(
        [string]$Command,
        [string]$IP,
        [string]$Pass
    )
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "ssh"
    $psi.Arguments = "root@$IP `"$Command`""
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    
    # Send password if prompted
    Start-Sleep -Milliseconds 500
    $process.StandardInput.WriteLine($Pass)
    $process.StandardInput.Close()
    
    $output = $process.StandardOutput.ReadToEnd()
    $error = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    
    return @{
        ExitCode = $process.ExitCode
        Output = $output
        Error = $error
    }
}

# Helper function to run SCP with password
function Invoke-SCPCopy {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Pass,
        [switch]$Recursive
    )
    
    $args = if ($Recursive) { "-r" } else { "" }
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "scp"
    $psi.Arguments = "$args `"$Source`" `"$Destination`""
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    
    # Send password if prompted
    Start-Sleep -Milliseconds 500
    $process.StandardInput.WriteLine($Pass)
    $process.StandardInput.Close()
    
    $output = $process.StandardOutput.ReadToEnd()
    $error = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    
    return $process.ExitCode
}

# Deploy frontend
Write-Host ""
Write-Host "[*] Deploying frontend..." -ForegroundColor Cyan
$exitCode = Invoke-SCPCopy -Source "$ScriptDir\web\*" -Destination "root@${DeviceIP}:/kvmapp/server/web/" -Pass $Password -Recursive
if ($exitCode -ne 0) {
    Write-Host "[!] ERROR: Frontend deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Frontend deployed" -ForegroundColor Green

# Deploy backend
Write-Host ""
Write-Host "[*] Deploying backend..." -ForegroundColor Cyan
$exitCode = Invoke-SCPCopy -Source "$ScriptDir\server\NanoKVM-Server" -Destination "root@${DeviceIP}:/kvmapp/server/" -Pass $Password
if ($exitCode -ne 0) {
    Write-Host "[!] ERROR: Backend deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Backend deployed" -ForegroundColor Green

# Deploy WireGuard
Write-Host ""
Write-Host "[*] Deploying WireGuard..." -ForegroundColor Cyan
$exitCode = Invoke-SCPCopy -Source "$ScriptDir\wireguard\wireguard-go" -Destination "root@${DeviceIP}:/usr/bin/" -Pass $Password
if ($exitCode -ne 0) {
    Write-Host "[!] ERROR: WireGuard binary deployment failed" -ForegroundColor Red
    exit 1
}

$exitCode = Invoke-SCPCopy -Source "$ScriptDir\wireguard\S40wireguard" -Destination "root@${DeviceIP}:/etc/init.d/" -Pass $Password
if ($exitCode -ne 0) {
    Write-Host "[!] ERROR: WireGuard init script deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "[*] Setting permissions..." -ForegroundColor Cyan
$result = Invoke-SSHCommand -Command "chmod +x /usr/bin/wireguard-go && chmod +x /etc/init.d/S40wireguard" -IP $DeviceIP -Pass $Password

Write-Host "[*] Creating resolvconf stub..." -ForegroundColor Cyan
$result = Invoke-SSHCommand -Command "if [ ! -f /usr/bin/resolvconf ]; then echo '#!/bin/sh' > /usr/bin/resolvconf && echo 'exit 0' >> /usr/bin/resolvconf && chmod +x /usr/bin/resolvconf; fi" -IP $DeviceIP -Pass $Password

Write-Host "[+] WireGuard deployed and configured for autostart" -ForegroundColor Green

# Restart service
Write-Host ""
Write-Host "[*] Restarting service..." -ForegroundColor Cyan
Write-Host "[!] Service restart may show warnings - this is normal" -ForegroundColor Yellow
$result = Invoke-SSHCommand -Command "/etc/init.d/S95nanokvm restart" -IP $DeviceIP -Pass $Password

Start-Sleep -Seconds 3

$result = Invoke-SSHCommand -Command "ps | grep NanoKVM-Server | grep -v grep" -IP $DeviceIP -Pass $Password
if ($result.Output -and $result.Output.Trim()) {
    Write-Host "[+] Service restarted successfully" -ForegroundColor Green
    $pid = ($result.Output -split '\s+')[0]
    Write-Host "[+] Service running with PID: $pid" -ForegroundColor Green
} else {
    Write-Host "[!] Could not verify service is running" -ForegroundColor Yellow
}

# Success
Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host " DEPLOYMENT SUCCESSFUL!              " -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your NanoKVM at: http://${DeviceIP}" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open http://${DeviceIP} in browser" -ForegroundColor White
Write-Host "  2. Hard refresh (Ctrl+F5)" -ForegroundColor White
Write-Host "  3. Login and verify features" -ForegroundColor White
Write-Host ""
