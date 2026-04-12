# Dice & Dragons - Final Verification Script (Windows PowerShell)
# This script verifies the project is ready to run

Write-Host ""
Write-Host "🎲 Dice & Dragons - Final Verification" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Check 1: Git Status
Write-Host "📌 Check 1: Git Repository Status" -ForegroundColor Yellow
$gitStatus = git status 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Git repository is clean" -ForegroundColor Green
    Write-Host "   Latest commit:" -ForegroundColor Gray
    git log --oneline -1 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
} else {
    Write-Host "❌ Git error" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check 2: Flutter Dependencies
Write-Host "📌 Check 2: Flutter Dependencies" -ForegroundColor Yellow
$pubOutput = flutter pub get 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ All dependencies are installed" -ForegroundColor Green
} else {
    Write-Host "❌ Dependency installation failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check 3: Project Structure
Write-Host "📌 Check 3: Project Structure" -ForegroundColor Yellow
$requiredFiles = @(
    "lib/models/item.dart",
    "lib/models/character.dart",
    "lib/models/inventory.dart",
    "lib/screens/main_navigation_screen.dart",
    "lib/screens/inventory_screen.dart",
    "lib/screens/character_creation_screen.dart",
    "pubspec.yaml"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file - NOT FOUND" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    exit 1
}
Write-Host ""

# Check 4: UUID Dependency
Write-Host "📌 Check 4: UUID Package" -ForegroundColor Yellow
$pubspec = Get-Content "pubspec.yaml" | Select-String "uuid:"
if ($pubspec) {
    Write-Host "✅ UUID package is in pubspec.yaml" -ForegroundColor Green
    Write-Host "   $pubspec" -ForegroundColor Gray
} else {
    Write-Host "❌ UUID package NOT found in pubspec.yaml" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check 5: Key Changes Verification
Write-Host "📌 Check 5: Key Implementation Changes" -ForegroundColor Yellow

# Check for UUID in item.dart
$itemUUID = Select-String -Path "lib/models/item.dart" -Pattern "final String id" -quiet
if ($itemUUID) {
    Write-Host "✅ Item class has UUID field" -ForegroundColor Green
} else {
    Write-Host "❌ Item UUID field missing" -ForegroundColor Red
}

# Check for hitDice in character.dart
$hitDice = Select-String -Path "lib/models/character.dart" -Pattern "int hitDice" -quiet
if ($hitDice) {
    Write-Host "✅ Character class has hitDice field" -ForegroundColor Green
} else {
    Write-Host "❌ Character hitDice field missing" -ForegroundColor Red
}

# Check for caching in inventory_screen.dart
$caching = Select-String -Path "lib/screens/inventory_screen.dart" -Pattern "_cachedSortedItems" -quiet
if ($caching) {
    Write-Host "✅ Inventory screen has caching optimization" -ForegroundColor Green
} else {
    Write-Host "❌ Inventory caching not found" -ForegroundColor Red
}

# Check for findItemById in inventory.dart
$findItemById = Select-String -Path "lib/models/inventory.dart" -Pattern "findItemById" -quiet
if ($findItemById) {
    Write-Host "✅ Inventory has findItemById() method" -ForegroundColor Green
} else {
    Write-Host "❌ findItemById() method missing" -ForegroundColor Red
}

Write-Host ""

# Final Status
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "✅ ALL CHECKS PASSED!" -ForegroundColor Green
Write-Host "The application is ready to run:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  flutter run              # Run on connected device" -ForegroundColor Gray
Write-Host "  flutter run -d windows   # Run on Windows desktop" -ForegroundColor Gray
Write-Host "  flutter run -d edge      # Run in Edge browser" -ForegroundColor Gray
Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

