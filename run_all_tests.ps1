$env:PATH = "C:\Users\Admin\AppData\Local\Android\Sdk\platform-tools;" + $env:PATH

$PATROL = "dart C:/Users/Admin/.gemini/antigravity/brain/be9c8aec-2a2a-4813-9aed-d5221243c0db/scratch/patrol_cli-4.4.0_patched/bin/main.dart"
$DEVICE  = "emulator-5554"

$tests = @(
    @{ label = "TC01 - Google Sign-In";                            file = "integration_test/authentication_test.dart" },
    @{ label = "TC02 + TC03 - Topic Search & Publication Details"; file = "integration_test/publication_test.dart" },
    @{ label = "TC04 + TC05 - Journals Navigation & Details";      file = "integration_test/journal_test.dart" },
    @{ label = "TC06 - Keywords Navigation";                       file = "integration_test/keyword_test.dart" },
    @{ label = "TC07 - Keyword Details";                           file = "integration_test/keyword_detail_test.dart" },
    @{ label = "TC08 - Profile Navigation";                        file = "integration_test/profile_test.dart" },
    @{ label = "TC09 - PDF Export";                                file = "integration_test/export_test.dart" },
    @{ label = "TC10 - Remote Config";                             file = "integration_test/remote_config_test.dart" },
    @{ label = "TC11 - Logout";                                    file = "integration_test/logout_test.dart"; delay = 10 }
)

$totalPassed = 0
$totalFailed = 0
$results = @()

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "   PRM393 - Integration Test Suite     " -ForegroundColor Cyan
Write-Host "   11 Test Cases | Device: $DEVICE    " -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

foreach ($t in $tests) {
    # Clean build artifacts to avoid file lock issues between tests
    Remove-Item -Recurse -Force "build\app\outputs\androidTest-results" -ErrorAction SilentlyContinue
    
    # Extra delay for specific tests
    $extraDelay = if ($t.ContainsKey('delay')) { $t.delay } else { 0 }
    if ($extraDelay -gt 0) {
        Write-Host "  Waiting ${extraDelay}s before next test..." -ForegroundColor Gray
        Start-Sleep -Seconds $extraDelay
    } else {
        Start-Sleep -Seconds 3
    }

    Write-Host "Running $($t.label)..." -ForegroundColor Yellow
    $output = Invoke-Expression "$PATROL test -d $DEVICE -t $($t.file)" 2>&1

    $passed = ($output | Select-String "Successful: (\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }) -as [int]
    $dartFailed = ($output | Select-String "^\s+- Test Case" | Measure-Object).Count
    $totalTests = ($output | Select-String "Total: (\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }) -as [int]

    if ($dartFailed -gt 0) {
        Write-Host "  FAILED ($dartFailed failed)" -ForegroundColor Red
        $results += "FAILED  $($t.label)"
        $totalFailed += $dartFailed
    } elseif ($totalTests -eq 0 -and $passed -eq 0) {
        Write-Host "  BUILD/INSTALL ERROR" -ForegroundColor Red
        $results += "ERROR   $($t.label)"
        $totalFailed += 1
    } else {
        Write-Host "  PASSED ($passed passed)" -ForegroundColor Green
        $results += "PASSED  $($t.label)"
        $totalPassed += $passed
    }
    Write-Host ""
}

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "         FINAL SUMMARY                 " -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
foreach ($r in $results) {
    if ($r -match "^PASSED") {
        Write-Host "  [OK] $r" -ForegroundColor Green
    } else {
        Write-Host "  [XX] $r" -ForegroundColor Red
    }
}
Write-Host ""
Write-Host "  Total passed : $totalPassed / $($totalPassed + $totalFailed)" -ForegroundColor $(if ($totalFailed -eq 0) { "Green" } else { "Red" })
Write-Host "  Total failed : $totalFailed" -ForegroundColor $(if ($totalFailed -eq 0) { "Green" } else { "Red" })
Write-Host "=======================================" -ForegroundColor Cyan
