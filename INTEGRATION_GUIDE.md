# Kai Slideshow - Platform Integration Guide

This guide explains how to set up context menu integration for Windows, Linux, and Android Share functionality.

## 📋 Overview

Kai Slideshow supports:
- **Windows**: Right-click context menu for files and folders
- **Linux**: Right-click context menu via .desktop file
- **Android**: Share intent for single or multiple images
- **Command-line**: Direct file/folder arguments

## 🪟 Windows - Context Menu Integration

### Method 1: Manual Registry Setup (Recommended)

Create a file `setup_windows_context_menu.bat`:

```batch
@echo off
setlocal

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Please run this script as Administrator!
    pause
    exit /b
)

:: Get the path to the Kai Slideshow executable
set "APP_PATH=%~dp0\..\build\windows\runner\Release\kai_slideshow.exe"

:: Check if app exists
if not exist "%APP_PATH%" (
    echo Kai Slideshow executable not found at: %APP_PATH%
    echo Please build the app first with: flutter build windows
    pause
    exit /b
)

:: Register for files (images)
echo Adding context menu for image files...
reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.jpg\Shell\KaiSlideshow" /ve /t REG_SZ /d "Open with Kai Slideshow" /f
reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.jpg\Shell\KaiSlideshow\command" /ve /t REG_SZ /d "\"%APP_PATH%\" \"%%1\"" /f

reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.jpeg\Shell\KaiSlideshow" /ve /t REG_SZ /d "Open with Kai Slideshow" /f
reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.jpeg\Shell\KaiSlideshow\command" /ve /t REG_SZ /d "\"%APP_PATH%\" \"%%1\"" /f

reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.png\Shell\KaiSlideshow" /ve /t REG_SZ /d "Open with Kai Slideshow" /f
reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.png\Shell\KaiSlideshow\command" /ve /t REG_SZ /d "\"%APP_PATH%\" \"%%1\"" /f

reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.webp\Shell\KaiSlideshow" /ve /t REG_SZ /d "Open with Kai Slideshow" /f
reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.webp\Shell\KaiSlideshow\command" /ve /t REG_SZ /d "\"%APP_PATH%\" \"%%1\"" /f

reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.bmp\Shell\KaiSlideshow" /ve /t REG_SZ /d "Open with Kai Slideshow" /f
reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.bmp\Shell\KaiSlideshow\command" /ve /t REG_SZ /d "\"%APP_PATH%\" \"%%1\"" /f

reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.gif\Shell\KaiSlideshow" /ve /t REG_SZ /d "Open with Kai Slideshow" /f
reg add "HKEY_CLASSES_ROOT\SystemFileAssociations\.gif\Shell\KaiSlideshow\command" /ve /t REG_SZ /d "\"%APP_PATH%\" \"%%1\"" /f

:: Register for folders (directory background)
echo Adding context menu for folders...
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\KaiSlideshow" /ve /t REG_SZ /d "Open Folder with Kai Slideshow" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\KaiSlideshow\command" /ve /t REG_SZ /d "\"%APP_PATH%\" \"%%V\"" /f

:: Register for folders (right-click on folder itself)
reg add "HKEY_CLASSES_ROOT\Directory\shell\KaiSlideshow" /ve /t REG_SZ /d "Open with Kai Slideshow" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\KaiSlideshow\command" /ve /t REG_SZ /d "\"%APP_PATH%\" \"%%1\"" /f

echo Context menu integration complete!
echo You can now right-click on images or folders and select "Open with Kai Slideshow"
pause
```

### Method 2: Using a PowerShell Script

Create `setup_windows_context_menu.ps1`:

```powershell
# Requires Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    Start-Sleep -Seconds 3
    exit
}

$appPath = Join-Path $PSScriptRoot "..\build\windows\runner\Release\kai_slideshow.exe"

if (-not (Test-Path $appPath)) {
    Write-Error "Kai Slideshow executable not found at: $appPath`nPlease build the app first with: flutter build windows"
    Start-Sleep -Seconds 5
    exit
}

# Image file types
$imageExtensions = @(".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif")

# Register for each image type
foreach ($ext in $imageExtensions) {
    $regPath = "HKCR:\SystemFileAssociations\$ext\Shell\KaiSlideshow"
    New-Item -Path $regPath -Force | Out-Null
    Set-ItemProperty -Path $regPath -Name "(Default)" -Value "Open with Kai Slideshow"
    
    $commandPath = "$regPath\command"
    New-Item -Path $commandPath -Force | Out-Null
    Set-ItemProperty -Path $commandPath -Name "(Default)" -Value `"$appPath`" `"%1`""
}

# Register for folders (background)
$folderBgPath = "HKCR:\Directory\Background\shell\KaiSlideshow"
New-Item -Path $folderBgPath -Force | Out-Null
Set-ItemProperty -Path $folderBgPath -Name "(Default)" -Value "Open Folder with Kai Slideshow"

$folderBgCommand = "$folderBgPath\command"
New-Item -Path $folderBgCommand -Force | Out-Null
Set-ItemProperty -Path $folderBgCommand -Name "(Default)" -Value `"$appPath`" `"%V`""

# Register for folders (direct)
$folderPath = "HKCR:\Directory\shell\KaiSlideshow"
New-Item -Path $folderPath -Force | Out-Null
Set-ItemProperty -Path $folderPath -Name "(Default)" -Value "Open with Kai Slideshow"

$folderCommand = "$folderPath\command"
New-Item -Path $folderCommand -Force | Out-Null
Set-ItemProperty -Path $folderCommand -Name "(Default)" -Value `"$appPath`" `"%1`""

Write-Host "Context menu integration complete!"
Write-Host "You can now right-click on images or folders and select 'Open with Kai Slideshow'"
Start-Sleep -Seconds 5
```

### Uninstall Script

Create `uninstall_windows_context_menu.bat`:

```batch
@echo off
setlocal

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Please run this script as Administrator!
    pause
    exit /b
)

:: Remove context menu for image files
echo Removing context menu for image files...
reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\.jpg\Shell\KaiSlideshow" /f
reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\.jpeg\Shell\KaiSlideshow" /f
reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\.png\Shell\KaiSlideshow" /f
reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\.webp\Shell\KaiSlideshow" /f
reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\.bmp\Shell\KaiSlideshow" /f
reg delete "HKEY_CLASSES_ROOT\SystemFileAssociations\.gif\Shell\KaiSlideshow" /f

:: Remove context menu for folders
echo Removing context menu for folders...
reg delete "HKEY_CLASSES_ROOT\Directory\Background\shell\KaiSlideshow" /f
reg delete "HKEY_CLASSES_ROOT\Directory\shell\KaiSlideshow" /f

echo Context menu integration removed!
pause
```

## 🐧 Linux - Context Menu Integration

### Method 1: Using .desktop File

Create or modify `linux/kai_slideshow.desktop`:

```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=Kai Slideshow
Comment=Fullscreen Image Slideshow
Exec=kai_slideshow %F
Icon=kai_slideshow
Terminal=false
Categories=Graphics;Viewer;Slideshow;
MimeType=image/jpeg;image/png;image/webp;image/bmp;image/gif;inode/directory;
StartupNotify=true

[Desktop Action OpenWithKaiSlideshow]
Name=Open with Kai Slideshow
Exec=kai_slideshow %F

[Desktop Action OpenFolderWithKaiSlideshow]
Name=Open Folder with Kai Slideshow
Exec=kai_slideshow %F
```

Then install it:

```bash
# Copy to applications directory
cp linux/kai_slideshow.desktop ~/.local/share/applications/

# Update desktop database
update-desktop-database ~/.local/share/applications/

# For system-wide installation (requires root):
sudo cp linux/kai_slideshow.desktop /usr/share/applications/
sudo update-desktop-database
```

### Method 2: Nautilus Script (for GNOME)

Create `~/.local/share/nautilus/scripts/Kai Slideshow`:

```bash
#!/bin/bash
# Kai Slideshow Nautilus script
# Save as: ~/.local/share/nautilus/scripts/Kai Slideshow
# Make executable: chmod +x ~/.local/share/nautilus/scripts/Kai Slideshow

# Get the path to kai_slideshow executable
APP_PATH="$HOME/.local/bin/kai_slideshow"

# If app not found in local bin, try the build directory
if [ ! -f "$APP_PATH" ]; then
    APP_PATH="$HOME/development/kai_slideshow/build/linux/x64/release/bundle/kai_slideshow"
fi

# Pass all selected files/directories to the app
"$APP_PATH" "$@"
```

Make it executable:
```bash
chmod +x ~/.local/share/nautilus/scripts/Kai\ Slideshow
```

Restart Nautilus:
```bash
nautilus -q
```

## 🤖 Android - Share Integration

The Android integration is already set up in the code:

1. **AndroidManifest.xml** has intent filters for:
   - `ACTION_SEND` - Single image
   - `ACTION_SEND_MULTIPLE` - Multiple images

2. **MainActivity.kt** handles the incoming intents and extracts URIs

3. **Dart code** processes the URIs and starts the slideshow

### Testing Android Share

1. Build the app: `flutter build apk`
2. Install on device: `flutter install`
3. Open Gallery app
4. Select one or more images
5. Tap Share button
6. Select "Kai Slideshow" from the app list
7. The slideshow should start automatically with the selected images

## 📁 Command-Line Usage

### Windows
```cmd
kai_slideshow.exe "C:\Path\To\Image.jpg"
kai_slideshow.exe "C:\Path\To\Folder"
kai_slideshow.exe "C:\Path\To\Image1.jpg" "C:\Path\To\Image2.png"
```

### Linux
```bash
kai_slideshow /path/to/image.jpg
kai_slideshow /path/to/folder
kai_slideshow /path/to/image1.jpg /path/to/image2.png
```

### macOS
```bash
open -a KaiSlideshow /path/to/image.jpg
open -a KaiSlideshow /path/to/folder
```

## 🔧 Building the App

### Windows
```bash
flutter build windows
```
The executable will be at: `build\windows\runner\Release\kai_slideshow.exe`

### Linux
```bash
flutter build linux
```
The executable will be at: `build/linux/x64/release/bundle/kai_slideshow`

### Android
```bash
flutter build apk
```
The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## 📝 Notes

1. **Windows Context Menu**: The registry changes require Administrator privileges
2. **Linux .desktop File**: May need to log out and back in for changes to take effect
3. **Android Share**: Works with any app that supports the standard Share intent
4. **File Associations**: The app will automatically start in fullscreen mode when opened via context menu or share
5. **Multiple Files**: When multiple files are selected, they will all be added to the slideshow

## 🎉 Usage

Once set up:
- **Windows**: Right-click on any image or folder → "Open with Kai Slideshow"
- **Linux**: Right-click on any image or folder → "Open with Kai Slideshow" (or via Nautilus script)
- **Android**: Select images in Gallery → Share → "Kai Slideshow"
- **Command Line**: Just pass file/folder paths as arguments

The slideshow will:
- Start automatically in fullscreen mode
- Maintain proper aspect ratio (no stretching)
- Hide UI after 3 seconds
- Support keyboard controls (Space, Arrow keys, F for fullscreen, Esc to exit)
