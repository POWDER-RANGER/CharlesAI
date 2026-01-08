# ============================================================================
# CharlesAI PowerShell EXE Build Script
# Converts CharlesAI PowerShell scripts to standalone Windows executable
# ============================================================================

param(
    [string]$OutputPath = "./build",
    [string]$Version = "3.0.0",
    [switch]$Console = $false,
    [switch]$RequireAdmin = $false,
    [string]$IconPath = "./assets/charles-icon.ico"
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Info { Write-Host $args -ForegroundColor Cyan }

Write-Info "[*] CharlesAI PS2EXE Build Process"
Write-Info "[*] Version: $Version"

# Step 1: Verify PS2EXE is installed
Write-Info "\n[Step 1] Checking for PS2EXE-ng..."
try {
    $ps2exe = Get-Command ps2exe -ErrorAction Stop
    Write-Success "[+] PS2EXE found at: $($ps2exe.Source)"
} catch {
    Write-Error "[-] PS2EXE not found. Installing PS2EXE-ng..."
    Install-Module -Name ps2exe -Force -Scope CurrentUser
    Write-Success "[+] PS2EXE installed successfully"
}

# Step 2: Create output directory
Write-Info "\n[Step 2] Setting up output directory..."
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
    Write-Success "[+] Created output directory: $OutputPath"
} else {
    Write-Info "[*] Output directory already exists"
}

# Step 3: Create wrapper entry point
Write-Info "\n[Step 3] Creating wrapper entry point..."
$wrapperScript = @"
# CharlesAI v$Version
# Production PowerShell Agent

# Ensure we're using the correct execution context
#Requires -Version 5.1

# Get script root for relative paths
\$scriptRoot = \$PSScriptRoot

# Dot-source all core modules (adjust paths as needed)
if (Test-Path "\$scriptRoot\modules\core.ps1") {
    . "\$scriptRoot\modules\core.ps1"
}

if (Test-Path "\$scriptRoot\modules\agents.ps1") {
    . "\$scriptRoot\modules\agents.ps1"
}

if (Test-Path "\$scriptRoot\modules\memory.ps1") {
    . "\$scriptRoot\modules\memory.ps1"
}

# Main entry point
function Invoke-CharlesAI {
    param(
        [string]\$Command,
        [string[]]\$Arguments
    )
    
    # Version and help
    if (-not \$Command -or \$Command -eq "--help" -or \$Command -eq "-h") {
        Write-Host @"
CharlesAI v$Version - COMET Agent
Production PowerShell AI Orchestration Platform

Usage: CharlesAI.exe [command] [options]

Commands:
  start              Start the CharlesAI daemon
  status             Show current status and loaded agents
  exec <script>      Execute a PowerShell script through the agent
  vault              Manage encryption vault
  memory             Manage AI memory systems
  help               Show this help message
  version            Show version information

Options:
  --config <path>    Use custom configuration file
  --debug            Enable debug output
  --no-color         Disable colored output

Examples:
  CharlesAI.exe start --config ./config.json
  CharlesAI.exe exec ./automation.ps1
"@
        return
    }
    
    if (\$Command -eq "--version" -or \$Command -eq "-v") {
        Write-Host "CharlesAI v$Version"
        return
    }
    
    # Route to appropriate handler
    switch (\$Command.ToLower()) {
        "start" {
            Write-Host "Starting CharlesAI daemon..."
            # Call your daemon start function
            # Start-CharlesAIDaemon -Arguments \$Arguments
        }
        "status" {
            Write-Host "CharlesAI Status Report"
            # Call your status function
            # Get-CharlesAIStatus
        }
        "exec" {
            # Execute script
            # Invoke-AgentScript -Path \$Arguments[0]
        }
        "vault" {
            # Vault management
            # Invoke-VaultManagement -Arguments \$Arguments
        }
        "memory" {
            # Memory management
            # Invoke-MemoryManagement -Arguments \$Arguments
        }
        default {
            Write-Host "Unknown command: \$Command" -ForegroundColor Red
            Write-Host "Use 'CharlesAI.exe --help' for usage information"
        }
    }
}

# Parse command line arguments
\$params = \$args
if (\$params.Count -gt 0) {
    Invoke-CharlesAI -Command \$params[0] -Arguments \$params[1..\$params.Count]
} else {
    Invoke-CharlesAI
}
"@

$wrapperPath = Join-Path $OutputPath "CharlesAI-Wrapper.ps1"
Set-Content -Path $wrapperPath -Value $wrapperScript -Force
Write-Success "[+] Wrapper created at: $wrapperPath"

# Step 4: Build version info
Write-Info "\n[Step 4] Creating version metadata..."
$versionInfo = @"
[version]FileVersion="$Version"
[version]ProductVersion="$Version"
[version]CompanyName="POWDER-RANGER"
[version]ProductName="CharlesAI"
[version]LegalCopyright="MIT License"
[version]OriginalFilename="CharlesAI.exe"
"@

$versionPath = Join-Path $OutputPath "version.txt"
Set-Content -Path $versionPath -Value $versionInfo -Force
Write-Success "[+] Version info created"

# Step 5: Convert PS1 to EXE
Write-Info "\n[Step 5] Converting to EXE (ps2exe)..."
$exePath = Join-Path $OutputPath "CharlesAI.exe"

$ps2exeParams = @{
    InputFile = $wrapperPath
    OutputFile = $exePath
    Version = $Version
    Company = "POWDER-RANGER"
    Product = "CharlesAI"
    Copyright = "MIT License"
    RequireAdmin = $RequireAdmin
}

# Add console mode if specified
if ($Console) {
    $ps2exeParams.Console = $true
}

# Add icon if available
if ((Test-Path $IconPath) -and $IconPath) {
    $ps2exeParams.Icon = $IconPath
}

try {
    Invoke-ps2exe @ps2exeParams
    Write-Success "[+] EXE created successfully: $exePath"
} catch {
    Write-Error "[-] Failed to create EXE: $_"
    exit 1
}

# Step 6: Create portable bundle
Write-Info "\n[Step 6] Creating portable bundle..."
$bundlePath = Join-Path $OutputPath "CharlesAI-Portable"
if (-not (Test-Path $bundlePath)) {
    New-Item -ItemType Directory -Path $bundlePath | Out-Null
}

# Copy EXE
Copy-Item -Path $exePath -Destination (Join-Path $bundlePath "CharlesAI.exe") -Force

# Copy modules if they exist
if (Test-Path "./modules") {
    Copy-Item -Path "./modules" -Destination (Join-Path $bundlePath "modules") -Recurse -Force
    Write-Success "[+] Copied modules directory"
}

# Copy config template if it exists
if (Test-Path "./config.template.json") {
    Copy-Item -Path "./config.template.json" -Destination (Join-Path $bundlePath "config.json") -Force
    Write-Success "[+] Copied configuration template"
}

# Create README for portable version
$readmePath = Join-Path $bundlePath "README.txt"
@"
CharlesAI v$Version - Portable Package
=====================================

USAGE:
  CharlesAI.exe [command] [options]

COMMANDS:
  --help              Show help information
  --version           Show version
  start               Start daemon
  status              Show status

EXAMPLES:
  CharlesAI.exe --help
  CharlesAI.exe start

FOR MORE INFO:
  Visit: https://github.com/POWDER-RANGER/CharlesAI
"@ | Set-Content -Path $readmePath

Write-Success "[+] Portable bundle created: $bundlePath"

# Step 7: Summary and verification
Write-Info "\n[Step 7] Build Summary"
Write-Info "========================================"

if (Test-Path $exePath) {
    $exeSize = (Get-Item $exePath).Length / 1MB
    Write-Success "[+] EXE File: $exePath"
    Write-Success "[+] Size: $([math]::Round($exeSize, 2)) MB"
    
    # Get file version
    $fileVersion = (Get-Item $exePath).VersionInfo
    Write-Success "[+] Version: $($fileVersion.FileVersion)"
    Write-Success "[+] Product: $($fileVersion.ProductName)"
    
    Write-Success "\n[✓] Build completed successfully!"
    Write-Info "\nNext steps:"
    Write-Info "1. Test the EXE on a clean Windows machine"
    Write-Info "2. Place in: $bundlePath"
    Write-Info "3. Distribute or upload to releases"
} else {
    Write-Error "[!] Build failed: EXE not created"
    exit 1
}

Write-Info "========================================"
