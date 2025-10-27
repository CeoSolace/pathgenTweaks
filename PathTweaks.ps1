if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    try { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs } catch { [System.Windows.Forms.MessageBox]::Show("Run as Administrator.", "PathTweaks", "OK", "Error") }
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Security
Add-Type -AssemblyName System.Net.Http

$API_BASE = "https://pathgenTweaks.onrender.com/api"
$GITHUB_RAW_URL = "https://raw.githubusercontent.com/ceoSolace/pathgenTweaks/main/PathTweaks.ps1"

function Get-LocalIP {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike "127.*" -and $_.AddressState -eq "Preferred" } | Select-Object -First 1).IPAddress
    return if ($ip) { $ip } else { "127.0.0.1" }
}

function Check-For-Update {
    try {
        $webClient = New-Object System.Net.WebClient
        $remoteContent = $webClient.DownloadString($GITHUB_RAW_URL)
        $localContent = Get-Content -Path $PSCommandPath -Raw
        if ($remoteContent -ne $localContent) {
            $result = [System.Windows.Forms.MessageBox]::Show("Update available. Download and restart?", "Update", "YesNo", "Question")
            if ($result -eq "Yes") {
                $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
                $webClient.DownloadFile($GITHUB_RAW_URL, $tempFile)
                Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$tempFile`""
                exit
            }
        }
    } catch { }
}

function Show-UsernamePrompt {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "PathTweaks – Enter Username"
    $form.Size = New-Object System.Drawing.Size(350, 180)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Enter your registered username:"
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(300, 20)
    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point(20, 50)
    $textbox.Size = New-Object System.Drawing.Size(300, 25)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "Continue"
    $btn.Location = New-Object System.Drawing.Point(125, 90)
    $btn.Size = New-Object System.Drawing.Size(100, 30)
    $btn.Add_Click({
        $script:USERNAME = $textbox.Text.Trim()
        if ($script:USERNAME -ne "") { $form.DialogResult = "OK"; $form.Close() }
    })
    $form.Controls.Add($label)
    $form.Controls.Add($textbox)
    $form.Controls.Add($btn)
    $result = $form.ShowDialog()
    $form.Dispose()
    return ($result -eq "OK")
}

function Register-User {
    param($username)
    $ip = Get-LocalIP
    try {
        $body = @{ username = $username; ip = $ip } | ConvertTo-Json
        $req = Invoke-WebRequest -Uri "$API_BASE/register" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10
        return $true
    } catch { return $false }
}

function Test-Subscription {
    param($username)
    try {
        $req = Invoke-WebRequest -Uri "$API_BASE/validate?username=$([System.Web.HttpUtility]::UrlEncode($username))" -UseBasicParsing -TimeoutSec 10
        $res = $req.Content | ConvertFrom-Json
        if ($res.valid -eq $false) {
            [System.Windows.Forms.MessageBox]::Show("Subscription expired or invalid. Access denied.", "Access Denied", "OK", "Error")
            return $false
        }
        return $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to validate subscription. Check internet.", "Error", "OK", "Error")
        return $false
    }
}

$TweakMap = @{ "fn1" = "Low-End FPS Maximizer"; "fn2" = "Network & Ping Stabilizer"; "fn3" = "CPU/GPU Synergy Tuner"; "vl1" = "Competitive Input Optimizer"; "vl2" = "FPS Consistency & Stability Suite"; "vl3" = "Silent Background Cleaner"; "cd1" = "GPU & Shader Performance Suite"; "cd2" = "Memory & System Responsiveness Tuner"; "cd3" = "Multiplayer Network Prioritizer" }

$HashToTweak = @{
    "f3a1d8e9c7b6a5f4e3d2c1b0a9f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1f0" = "fn1"
    "a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3" = "fn2"
    "c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5" = "fn3"
    "e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7" = "vl1"
    "b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0" = "vl2"
    "d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2" = "vl3"
    "f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4" = "cd1"
    "a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5" = "cd2"
    "c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7" = "cd3"
}

function Get-SHA256 { param($text); $bytes = [System.Text.Encoding]::UTF8.GetBytes($text); $sha = [System.Security.Cryptography.SHA256]::Create(); $hash = $sha.ComputeHash($bytes); return [System.BitConverter]::ToString($hash).Replace("-", "").ToLower() }

function Show-SafetyModal { param($tweakID)
    $desc = switch ($tweakID) {
        "fn1" { "Optimizes low-end systems for Fortnite: sets Ultimate Performance power plan, disables visual effects, forces DX11, disables Game Bar, and sets high CPU priority." }
        "fn2" { "Stabilizes network: flushes DNS, resets Winsock, disables QoS, tweaks TCP ACK, clears net cache." }
        "fn3" { "Tunes CPU/GPU synergy: enables GPU scheduling, suspends non-essential services, disables Game DVR, optimizes GPU registry settings." }
        "vl1" { "Enhances input responsiveness: disables mouse acceleration, USB suspend, Game Mode, enforces raw input, reduces keyboard delay." }
        "vl2" { "Stabilizes FPS: sets High Performance plan, kills non-Riot apps, disables animations, excludes from Defender, tweaks pagefile." }
        "vl3" { "Cleans background: suspends Print Spooler/Themes, stops UWP tasks, clears temp/prefetch. Never touches Riot/Vanguard." }
        "cd1" { "Boosts GPU/shader perf: enables GPU scheduling, clears shader cache, forces max GPU perf, disables HDR, enforces exclusive fullscreen." }
        "cd2" { "Improves memory & responsiveness: configures pagefile, disables memory compression, defrags working set, disables SuperFetch." }
        "cd3" { "Prioritizes multiplayer net: applies DSCP QoS (46), restricts TCP auto-tuning, disables LSO, flushes ARP, optimizes RWIN." }
        default { "Performance optimization tweak." }
    }
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "⚠️ Safety Disclosure – $($TweakMap[$tweakID])"
    $form.Size = New-Object System.Drawing.Size(500, 400)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(440, 250)
    $label.Text = @"
This tweak performs multiple system-level optimizations:

$desc

⚠️ Windows may show SmartScreen warnings.
✅ All changes are standard Windows optimizations.
🔄 Reversible via Windows Settings.

Proceed?
"@
    $label.AutoSize = $false
    $label.TextAlign = "TopLeft"
    $btnYes = New-Object System.Windows.Forms.Button
    $btnYes.Location = New-Object System.Drawing.Point(100, 300)
    $btnYes.Size = New-Object System.Drawing.Size(100, 30)
    $btnYes.Text = "Yes"
    $btnYes.DialogResult = "OK"
    $btnNo = New-Object System.Windows.Forms.Button
    $btnNo.Location = New-Object System.Drawing.Point(250, 300)
    $btnNo.Size = New-Object System.Drawing.Size(100, 30)
    $btnNo.Text = "No"
    $btnNo.DialogResult = "Cancel"
    $form.Controls.Add($label)
    $form.Controls.Add($btnYes)
    $form.Controls.Add($btnNo)
    $result = $form.ShowDialog()
    $form.Dispose()
    return ($result -eq "OK")
}

function Invoke-Tweak { param($tweakID)
    $tweakFolder = Join-Path (Get-Location) "t120"
    if (-not (Test-Path $tweakFolder)) {
        [System.Windows.Forms.MessageBox]::Show("⚠️ PathTweaks: Missing t120 folder.", "Error", "OK", "Error")
        return
    }
    $files = Get-ChildItem -Path $tweakFolder -File | Where-Object { $_.Name -like "*$tweakID*" }
    if ($files.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("⚠️ PathTweaks: Missing or corrupted tweak file for $tweakID.", "Error", "OK", "Error")
        return
    }
    if (-not (Show-SafetyModal -tweakID $tweakID)) { return }
    try {
        & $files[0].FullName
        [System.Windows.Forms.MessageBox]::Show("$($TweakMap[$tweakID]) applied successfully!", "Success", "OK", "Info")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to run tweak: $_", "Error", "OK", "Error")
    }
}

function Show-TweakModal { param($gamePrefix)
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Select Tweak – " + ($gamePrefix -eq "fn" ? "Fortnite" : ($gamePrefix -eq "vl" ? "Valorant" : "Call of Duty"))
    $form.Size = New-Object System.Drawing.Size(400, 300)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $y = 20
    foreach ($key in $TweakMap.Keys | Where-Object { $_.StartsWith($gamePrefix) }) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Location = New-Object System.Drawing.Point(50, $y)
        $btn.Size = New-Object System.Drawing.Size(300, 30)
        $btn.Text = $TweakMap[$key]
        $btn.Add_Click({
            $code = [Microsoft.VisualBasic.Interaction]::InputBox("Enter activation code for '$($TweakMap[$key])':", "Activation")
            if ([string]::IsNullOrWhiteSpace($code)) { return }
            $hash = Get-SHA256 -text $code
            if (-not $HashToTweak.ContainsKey($hash)) {
                [System.Windows.Forms.MessageBox]::Show("Invalid activation code.", "Error", "OK", "Error")
                return
            }
            if ($HashToTweak[$hash] -ne $key) {
                [System.Windows.Forms.MessageBox]::Show("Code mismatch.", "Error", "OK", "Error")
                return
            }
            try {
                $approvedPath = Join-Path (Get-Location) "approved.txt"
                $approved = Get-Content $approvedPath -ErrorAction SilentlyContinue
                if ($approved -notcontains $code) {
                    [System.Windows.Forms.MessageBox]::Show("Code not found in approved.txt.", "Error", "OK", "Error")
                    return
                }
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to read approved.txt.", "Error", "OK", "Error")
                return
            }
            Invoke-Tweak -tweakID $key
        })
        $form.Controls.Add($btn)
        $y += 40
    }
    $form.ShowDialog()
    $form.Dispose()
}

if (-not (Show-UsernamePrompt)) { exit }
if (-not (Test-Subscription -username $USERNAME)) { exit }
$null = Register-User -username $USERNAME
Check-For-Update

$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "PathTweaks"
$mainForm.Size = New-Object System.Drawing.Size(600, 350)
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = "FixedDialog"
$mainForm.MaximizeBox = $false
$mainForm.MinimizeBox = $false
$mainForm.TopMost = $true

$logoSize = New-Object System.Drawing.Size(180, 180)
$fnPic = New-Object System.Windows.Forms.PictureBox
$fnPic.Image = ([System.Drawing.Bitmap]::new(180, 180))
$g = [System.Drawing.Graphics]::FromImage($fnPic.Image)
$g.Clear([System.Drawing.Color]::LightGray)
$g.Dispose()
$fnPic.Size = $logoSize
$fnPic.Location = New-Object System.Drawing.Point(20, 40)
$fnPic.SizeMode = "Zoom"

$vlPic = New-Object System.Windows.Forms.PictureBox
$vlPic.Image = ([System.Drawing.Bitmap]::new(180, 180))
$g = [System.Drawing.Graphics]::FromImage($vlPic.Image)
$g.Clear([System.Drawing.Color]::LightGray)
$g.Dispose()
$vlPic.Size = $logoSize
$vlPic.Location = New-Object System.Drawing.Point(210, 40)
$vlPic.SizeMode = "Zoom"

$cdPic = New-Object System.Windows.Forms.PictureBox
$cdPic.Image = ([System.Drawing.Bitmap]::new(180, 180))
$g = [System.Drawing.Graphics]::FromImage($cdPic.Image)
$g.Clear([System.Drawing.Color]::LightGray)
$g.Dispose()
$cdPic.Size = $logoSize
$cdPic.Location = New-Object System.Drawing.Point(400, 40)
$cdPic.SizeMode = "Zoom"

$btnFN = New-Object System.Windows.Forms.Button
$btnFN.Text = "Select Fortnite"
$btnFN.Size = New-Object System.Drawing.Size(150, 30)
$btnFN.Location = New-Object System.Drawing.Point(20, 230)
$btnFN.Add_Click({ Show-TweakModal -gamePrefix "fn" })

$btnVL = New-Object System.Windows.Forms.Button
$btnVL.Text = "Select Valorant"
$btnVL.Size = New-Object System.Drawing.Size(150, 30)
$btnVL.Location = New-Object System.Drawing.Point(225, 230)
$btnVL.Add_Click({ Show-TweakModal -gamePrefix "vl" })

$btnCD = New-Object System.Windows.Forms.Button
$btnCD.Text = "Select COD"
$btnCD.Size = New-Object System.Drawing.Size(150, 30)
$btnCD.Location = New-Object System.Drawing.Point(430, 230)
$btnCD.Add_Click({ Show-TweakModal -gamePrefix "cd" })

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Exit"
$btnExit.Size = New-Object System.Drawing.Size(100, 30)
$btnExit.Location = New-Object System.Drawing.Point(250, 280)
$btnExit.ForeColor = [System.Drawing.Color]::Red
$btnExit.FlatStyle = "Flat"
$btnExit.FlatAppearance.BorderColor = [System.Drawing.Color]::Red
$btnExit.Add_Click({ $mainForm.Close() })

$mainForm.Controls.Add($fnPic)
$mainForm.Controls.Add($vlPic)
$mainForm.Controls.Add($cdPic)
$mainForm.Controls.Add($btnFN)
$mainForm.Controls.Add($btnVL)
$mainForm.Controls.Add($btnCD)
$mainForm.Controls.Add($btnExit)

[void]$mainForm.ShowDialog()
