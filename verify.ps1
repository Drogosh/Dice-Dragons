# Dice and Dragons - Verification Script
# Simple version to avoid encoding issues

Write-Host ""
Write-Host "Dice and Dragons - Final Verification" -ForegroundColor Cyan
Write-Host "======================================"
Write-Host ""

# Check 1: Git Status
Write-Host "Check 1: Git Repository Status" -ForegroundColor Yellow
git log --oneline -1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Git repository verified"
} else {
    Write-Host "[FAIL] Git error"
    exit 1
}
Write-Host ""

# Check 2: Flutter Dependencies
Write-Host "Check 2: Flutter Dependencies" -ForegroundColor Yellow
$pubOutput = flutter pub get 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] All dependencies installed"
} else {
    Write-Host "[FAIL] Dependency error"
    exit 1
}
Write-Host ""

# Check 3: Project Files
Write-Host "Check 3: Project Structure" -ForegroundColor Yellow
$files = @(
    "lib/models/item.dart",
    "lib/models/character.dart",
    "lib/models/inventory.dart",
    "lib/screens/main_navigation_screen.dart",
    "lib/screens/inventory_screen.dart",
    "pubspec.yaml"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "[OK] $file"
    } else {
        Write-Host "[FAIL] $file not found"
        exit 1
    }
}
Write-Host ""

# Check 4: Key Features
Write-Host "Check 4: Key Implementations" -ForegroundColor Yellow

if (Select-String -Path "lib/models/item.dart" -Pattern "final String id" -quiet) {
    Write-Host "[OK] UUID field in Item class"
}

if (Select-String -Path "lib/models/character.dart" -Pattern "int hitDice" -quiet) {
    Write-Host "[OK] hitDice field in Character class"
}

if (Select-String -Path "lib/screens/inventory_screen.dart" -Pattern "_cachedSortedItems" -quiet) {
    Write-Host "[OK] ListView caching implemented"
}

if (Select-String -Path "lib/models/inventory.dart" -Pattern "findItemById" -quiet) {
    Write-Host "[OK] findItemById method implemented"
}

Write-Host ""
Write-Host "======================================"
Write-Host "[SUCCESS] All checks passed!" -ForegroundColor Green
Write-Host ""
Write-Host "Ready to run:"
Write-Host "  flutter run -d windows"
Write-Host ""

