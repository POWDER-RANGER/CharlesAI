# CharlesAI Windows EXE Build Guide

## Overview

This document explains how to build CharlesAI as a production-grade Windows executable (`.exe`) using PowerShell and the `ps2exe-ng` tool.

## Prerequisites

- **Windows 10/11** (or Windows Server 2016+)
- **PowerShell 5.1+** (included with Windows 10+)
- **.NET Framework 4.5+** (usually pre-installed)
- **Git** (for cloning/pushing)
- **Administrator privileges** (to install modules)

## Quick Start: Local Build

### 1. Install ps2exe-ng

Open PowerShell as Administrator:

```powershell
Install-Module -Name ps2exe -Force -Scope CurrentUser
```

Verify installation:

```powershell
Get-Module ps2exe -ListAvailable
```

### 2. Clone CharlesAI

```powershell
git clone https://github.com/POWDER-RANGER/CharlesAI.git
cd CharlesAI
```

### 3. Run Build Script

```powershell
.\Build-CharlesAI-EXE.ps1 -OutputPath "./build" -Version "3.0.0" -Console
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-OutputPath` | string | `./build` | Directory for output files |
| `-Version` | string | `3.0.0` | Version number (e.g., `3.0.1`) |
| `-Console` | switch | `false` | Show console window when running |
| `-RequireAdmin` | switch | `false` | Require administrator privileges |
| `-IconPath` | string | `./assets/charles-icon.ico` | Path to custom icon file |

### 4. Test the EXE

```powershell
.\build\CharlesAI.exe --help
.\build\CharlesAI.exe --version
.\build\CharlesAI.exe start
```

### 5. Distribute

The `./build/CharlesAI-Portable/` folder contains everything needed:

```
CharlesAI-Portable/
├── CharlesAI.exe          # Main executable
├── modules/               # PowerShell modules
├── config.json            # Configuration template
└── README.txt             # Quick reference
```

## Automated CI/CD Build

CharlesAI uses GitHub Actions to automatically build Windows EXEs:

### Trigger Methods

#### Option 1: Git Tag (Recommended)

```bash
git tag v3.0.1
git push --tags
```

This will:
1. Trigger the GitHub Actions workflow
2. Build `CharlesAI.exe` v3.0.1
3. Create a GitHub Release with the EXE as an attachment

#### Option 2: Manual Workflow Dispatch

Go to: `Actions` → `Build CharlesAI Windows EXE` → `Run workflow`

Specify a version number (e.g., `3.0.1`) and trigger the build.

#### Option 3: Push to Main

Any push to the `main` branch will trigger a build, but it won't create a release automatically.

### Build Workflow Details

The GitHub Actions workflow (`.github/workflows/build-exe.yml`):

1. **Checkout** - Clones the repository
2. **Extract Version** - Determines version from tag or input
3. **Setup Environment** - Installs `ps2exe-ng` module
4. **Build EXE** - Runs `Build-CharlesAI-EXE.ps1`
5. **Verify** - Tests the output EXE
6. **Run Tests** - Executes `--help`, `--version` flags
7. **Create Bundle** - Packages portable distribution
8. **Upload Artifacts** - Stores in GitHub Actions artifacts
9. **Create Release** - Publishes GitHub Release (on tag)

### Artifacts Location

After a successful build:

- **Build Artifacts**: GitHub Actions → Workflow → Artifacts → `CharlesAI-v{VERSION}-Windows`
- **Releases**: GitHub → Releases → Download `CharlesAI.exe`

## Build Customization

### Adding a Custom Icon

1. Create an icon file: `./assets/charles-icon.ico` (256×256 recommended)
2. Run build script (it will automatically use the icon):

```powershell
.\Build-CharlesAI-EXE.ps1 -IconPath "./assets/charles-icon.ico"
```

### Bundling Additional Files

Edit `Build-CharlesAI-EXE.ps1` to include additional files in the portable bundle:

```powershell
# Around line 150, add:
if (Test-Path "./config/custom") {
    Copy-Item -Path "./config/custom" -Destination (Join-Path $bundlePath "config") -Recurse -Force
}
```

### Requiring Administrator Privileges

To make the EXE require admin on startup:

```powershell
.\Build-CharlesAI-EXE.ps1 -RequireAdmin
```

The manifest will be embedded in the EXE.

## Output Structure

After building, you'll have:

```
build/
├── CharlesAI-Wrapper.ps1         # Entry point script
├── CharlesAI.exe                 # Final executable
├── version.txt                   # Version metadata
└── CharlesAI-Portable/           # Portable distribution
    ├── CharlesAI.exe             # Copy of EXE
    ├── modules/                  # PowerShell modules (if present)
    ├── config.json               # Config template (if present)
    └── README.txt                # Usage guide
```

## Troubleshooting

### Issue: "ps2exe module not found"

**Solution:** Install as Administrator:

```powershell
Install-Module -Name ps2exe -Force -Scope CurrentUser
```

### Issue: "Access denied" when running script

**Solution:** Enable script execution:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: EXE crashes on startup

**Solution:**

1. Check PowerShell version:
   ```powershell
   $PSVersionTable.PSVersion
   ```
   (Must be 5.1 or higher)

2. Test wrapper script directly:
   ```powershell
   . .\Build-CharlesAI-EXE.ps1 -OutputPath "./build" -Console
   # Then run: .\build\CharlesAI.exe
   ```

3. Enable debug mode in wrapper to see errors:
   ```powershell
   $DebugPreference = "Continue"
   & .\build\CharlesAI.exe --help
   ```

### Issue: Module imports fail in EXE

**Solution:** Ensure modules are relative to `$PSScriptRoot`:

```powershell
# In Invoke-CharlesAI-Wrapper.ps1:
if (Test-Path "$PSScriptRoot\modules\core.ps1") {
    . "$PSScriptRoot\modules\core.ps1"
}
```

## Distribution

### Option 1: Standalone EXE

Simply distribute `build/CharlesAI.exe`. It requires:
- PowerShell 5.1 (pre-installed on Windows 10+)
- .NET Framework 4.5+ (pre-installed on most Windows machines)

### Option 2: Portable Bundle

Zip the entire `build/CharlesAI-Portable/` folder:

```powershell
Compress-Archive -Path "build/CharlesAI-Portable" -DestinationPath "CharlesAI-Portable.zip"
```

Users can extract and run directly.

### Option 3: GitHub Releases

Tag releases automatically publish to GitHub:

```bash
git tag v3.0.1
git push --tags
```

Users download from: `github.com/POWDER-RANGER/CharlesAI/releases`

## Version Management

### Semantic Versioning

Use semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR** (3.0.0): Major feature or breaking change
- **MINOR** (3.1.0): New feature, backward compatible
- **PATCH** (3.0.1): Bug fix

### Updating Version

1. Update in `Build-CharlesAI-EXE.ps1`:
   ```powershell
   [string]$Version = "3.0.1"  # Default parameter
   ```

2. Tag and push:
   ```bash
   git tag v3.0.1
   git push --tags
   ```

3. The GitHub Actions workflow will use `3.0.1` automatically.

## Performance Notes

- **EXE Size**: Typically 5-15 MB (compressed by ps2exe)
- **Startup Time**: < 2 seconds (includes PowerShell runtime initialization)
- **Memory**: Minimal overhead beyond PowerShell baseline (~50-100 MB)

## Security Considerations

1. **Code Signing**: For production distribution, sign the EXE:
   ```powershell
   Set-AuthenticodeSignature -FilePath "build/CharlesAI.exe" -Certificate (Get-ChildItem cert:\CurrentUser\My)
   ```

2. **Virus Scanner**: Windows Defender may flag ps2exe builds initially. This is normal; submit to Microsoft for whitelisting.

3. **Sensitive Data**: Do not embed credentials in the wrapper. Use vault system or environment variables.

## Advanced: Nuitka vs ps2exe

### ps2exe (Current)
- ✅ Pros: Simple, direct PowerShell → EXE, no external runtime
- ✅ Cons: Larger EXE, relies on .NET Framework

### Nuitka Alternative (Python)
- ✅ Pros: Smaller binary, faster startup, true compilation
- ✅ Cons: Requires Python conversion layer

For now, ps2exe is the best fit for CharlesAI's PowerShell-centric design.

## References

- [ps2exe-ng GitHub](https://github.com/MScholtes/PS2EXE)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Windows Installer Best Practices](https://docs.microsoft.com/en-us/windows/win32/msi/installation-guide)

## Support

For issues with the build process:

1. Check [GitHub Issues](https://github.com/POWDER-RANGER/CharlesAI/issues)
2. Review [GitHub Discussions](https://github.com/POWDER-RANGER/CharlesAI/discussions)
3. Submit a new issue with:
   - Windows version
   - PowerShell version (`$PSVersionTable.PSVersion`)
   - Error output
   - Build script used

---

**Last Updated:** January 2026
**Build System:** GitHub Actions + PS2EXE-ng
**Compatible Platforms:** Windows 7+, Windows Server 2016+
