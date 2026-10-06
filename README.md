# VisitBasis command-line client

Use `vb3` to read your VisitBasis account and propose changes from a terminal or an AI
assistant. You decide proposed changes on the approval page. Files are available for macOS, Linux and Windows on
Intel/AMD 64-bit or ARM64. Windows is checked by hand; see below. No Go installation is needed.

## Install on macOS or Linux

```sh
curl -fsSL https://github.com/visitbasis/vb3-cli/releases/latest/download/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
vb3 --help
vb3 skill install claude
# Or: vb3 skill install codex
```

The installer verifies the archive's SHA-256 checksum and installs to `~/.local/bin/vb3`.
Running it again with the same binary leaves the installation unchanged. It prints the
PATH command when needed; a piped script cannot change the parent shell's PATH.

The skill is embedded in the binary. Claude Code installs to
`~/.claude/skills/vb3-cli/SKILL.md`; Codex installs to `~/.agents/skills/vb3-cli/SKILL.md`.
An identical skill is left alone. If installation reports "differs from installed at",
review the named file. Use `vb3 skill install claude --force` (or `codex`) only if you
intend to replace that differing copy. Start a fresh host session
after installation and invoke `/vb3-cli` in Claude Code or `$vb3-cli` in Codex.

## Connect

Set `VB3_MCP_URL` to the HTTPS `/mcp` address supplied for your account, then sign in
with an emailed code on the browser page opened from the verification address:

```sh
printf "Account connection address: "
read -r VB3_MCP_URL
export VB3_MCP_URL
unset VB3_BEARER
vb3 login
vb3 whoami --json
vb3 logout
```

Check the displayed connection code, choose your account and press Connect. The command
remembers that connection privately for your operating-system user. No credential is
pasted into the terminal. Logout removes it even offline and reports when remote
revocation cannot be confirmed. Help and skill installation work offline. Windows update instructions work offline; macOS and Linux updates need a network connection.
Local help lists supported options. Command-line wording is available in English,
Spanish and Russian; new Windows Spanish and Russian wording is provisional.

## Update or pin on macOS or Linux

```sh
vb3 update
vb3 update --json
```

Update downloads the latest release, verifies its checksum and atomically replaces the
running executable. A failed download or verification leaves the installed binary intact.
Restart the command afterward. Run `vb3 skill install claude` (or `codex`) after updating
to refresh its embedded guidance. Use `--force` only after a difference is reported and
you have decided to replace the named file; identical content does not need it.

`vb3 update` refuses to replace a dev/source build. If you intend to replace that
source-built executable with a public release, use `vb3 update --force`.

To keep an exact release, set `VB3_VERSION` in your shell configuration:

```sh
export VB3_VERSION=v0.4.0
curl -fsSL https://github.com/visitbasis/vb3-cli/releases/latest/download/install.sh | sh
vb3 update
```

Both installer and updater honor that exact tag, including when selecting an older
release explicitly. With no pin, update never downgrades to an older latest release.
Use `unset VB3_VERSION` to follow latest again. The release tag is visible in
`vb3 --help --json`; the build SHA identifies its source build.

If api.github.com rate-limits an update check, retry later: unauthenticated requests
share a limit of 60 per hour per IP, and temporary secondary limits can also apply.
Alternatively, pin `VB3_VERSION` to a known published release and run the installer
above, which skips the API lookup when pinned. A pinned `vb3 update` still needs the
API unless that exact release is already installed.

## Windows

Windows files are provided and checked by hand by our team. A manual check of the
public build on an ordinary Intel/AMD laptop must pass before Windows 10 and 11
on those PCs are described as supported. Automatic checks do not test a Windows
installation or its account connection; a separate check started by hand tests
only the connection files.
The ARM64 file is supplied but has not been tried on an ARM64 PC. Windows failures
are fixed in the next release; they do not hold macOS or Linux publication.

The executable has no Windows publisher certificate. SmartScreen can warn about
an unfamiliar download; Windows 11 Smart App Control or company policy can block
the install line itself or the program entirely. A checksum or cosign signature is not a Windows publisher certificate,
and the ZIP route has the same executable restrictions. If blocked, stop and report
the warning; do not change Windows protection. See
[Microsoft's Smart App Control guidance](https://learn.microsoft.com/windows/apps/develop/smart-app-control/overview)
and [SmartScreen guidance](https://learn.microsoft.com/en-us/defender-endpoint/defender-endpoint-demonstration-app-reputation).

### Install with ordinary Windows PowerShell

This line works only for a release that includes Windows files. Choose such a
release from the public releases page. Paste this whole line into Windows PowerShell 5.1. It runs downloaded UTF-8 text,
enables TLS 1.2 in this process and does not change saved-script execution policy.
No administrator rights, WSL, Go or extra software are needed.

<!-- windows-bootstrap-start -->
```powershell
$BootstrapMessages = ConvertFrom-Json '{"windows_download_blocked":"The release download was refused by the service or a security check. Contact your support team; keep Windows protection on.","windows_download_failed":"The release download failed. Try again later.","windows_download_network":"The release download could not be reached. Check your network connection and try again.","windows_release_name_invalid":"That release name is not valid. Copy the release tag exactly from the release page; it must look like v0.4.2.","windows_release_unavailable":"Windows files are unavailable for this release. Choose a release that includes Windows files, or try again later."}'; $VB3DownloadErrorKeys = ConvertFrom-Json '{"403":"windows_download_blocked","404":"windows_release_unavailable","407":"windows_download_blocked","451":"windows_download_blocked","network":"windows_download_network","other":"windows_download_failed","security":"windows_download_blocked"}'; function Get-VB3DownloadErrorKey($Failure) {;     while ($Failure.InnerException -and $Failure -isnot [Net.WebException]) {;         $Failure = $Failure.InnerException;     };     $code = 0;     if ($Failure.Response) {;         $code = [int]$Failure.Response.StatusCode;     };     $key = $VB3DownloadErrorKeys."$code";     if ($key) {;         return $key;     };     $reason = 'other';     if ($code -eq 0) {;         if ($Failure -is [Security.SecurityException] -or [string]$Failure.Status -in @('TrustFailure','SecureChannelFailure')) {;             $reason = 'security';         } elseif ([string]$Failure.Status -in @('ConnectFailure','NameResolutionFailure','ProxyNameResolutionFailure','Timeout','SendFailure','ReceiveFailure','ConnectionClosed')) {;             $reason = 'network';         };     };     return $VB3DownloadErrorKeys.$reason; }; function Get-VB3InstallScriptURL([string]$Pin) {;     if ($Pin) {;         if ($Pin -cnotmatch '^v0\.4\.(0|[1-9][0-9]*)$') {;             throw $BootstrapMessages.'windows_release_name_invalid';         };         return ('https://github.com/visitbasis/vb3-cli/releases/download/' + $Pin + '/install.ps1');     };     return 'https://github.com/visitbasis/vb3-cli/releases/latest/download/install.ps1'; }; [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; try {;     $url = Get-VB3InstallScriptURL $env:VB3_VERSION; } catch {;     Write-Warning $_.Exception.Message;     return; }; $wc = New-Object Net.WebClient; $wc.Encoding = [Text.Encoding]::UTF8; try {;     try {;         $script = $wc.DownloadString($url);     } catch {;         $key = Get-VB3DownloadErrorKey $_.Exception;         Write-Warning $BootstrapMessages.$key;         return;     };     & ([scriptblock]::Create($script)) -Language en; } finally {;     $wc.Dispose(); }
```
<!-- windows-bootstrap-end -->

The installer checks the release ZIP's SHA-256 before copying the native executable
to `%LOCALAPPDATA%\VisitBasis\vb3\bin\vb3.exe`, and adds that exact folder to your
User PATH once. A small `.vb3-path-entry.json` file records an entry it added;
removal leaves a pre-existing entry alone and preserves other entries and their type. Run it again safely; open a new terminal and run `vb3 --help`.
If another copy wins on PATH, use the printed full path or adjust your User PATH.
If saving PATH fails, the installed full path still works. Close running `vb3`
commands before reinstalling. Downloads/checksum errors happen before copying;
a disk error, interrupted copy or power cut while copying can require reinstalling.
There is no rollback or backup executable; the same line repairs the installation.

To choose another release when the latest has no Windows files, open
[the release list](https://github.com/visitbasis/vb3-cli/releases). Find a release
listing install.ps1, the Windows ZIPs and windows-checksums.txt, then enter its
release tag using this command and run the full install line above again. The
line downloads both the installer and ZIP from that selected release:

```powershell
$env:VB3_VERSION = Read-Host 'Release tag with Windows files'
```

Clear the choice with
`Remove-Item Env:VB3_VERSION -ErrorAction SilentlyContinue` to follow latest again.
Choosing a release this way skips the automatic release lookup. A release without
its matching windows-checksums.txt and ZIP is unavailable; wait for the files or the next release.
For installer messages in Spanish or Russian, replace `-Language en` in the line
with `-Language es` or `-Language ru`. Those new translations are provisional.

### Install a ZIP by hand

Open [the public releases](https://github.com/visitbasis/vb3-cli/releases/latest)
in your browser. From the SAME release download `windows-checksums.txt` and
`vb3_windows_amd64.zip` for an Intel/AMD PC, or `vb3_windows_arm64.zip` for ARM64,
to Downloads. Replace older copies. The commands below are for Intel/AMD; on ARM64
change the first filename to `vb3_windows_arm64.zip`. They check that exact entry
before unpacking into your personal folder and running directly. If a check prints a file path and stops, stop there and inspect that file; do not run an unchecked download.

<!-- windows-zip-start -->
```powershell
& {
    $ErrorActionPreference = 'Stop'
    $zipName = 'vb3_windows_amd64.zip'
    $zip = Join-Path $env:USERPROFILE ('Downloads\' + $zipName)
    $manifest = Join-Path $env:USERPROFILE 'Downloads\windows-checksums.txt'
    $entries = @(Get-Content -LiteralPath $manifest | Where-Object {
        $_ -match ('^([0-9a-fA-F]{64})\s+\*?' + [regex]::Escape($zipName) + '$')
    })
    if ($entries.Count -ne 1) {
        throw $manifest
    }
    $expectedHash = ($entries[0] -split '\s+')[0]
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash -ne $expectedHash) {
        throw $zip
    }
    $manual = Join-Path $env:LOCALAPPDATA 'VisitBasis\vb3-manual'
    Expand-Archive -LiteralPath $zip -DestinationPath $manual -Force
    & (Join-Path $manual 'vb3.exe') --version --json
    & (Join-Path $manual 'vb3.exe') --help
}
```
<!-- windows-zip-end -->

Keep the ZIP and README together until you finish checking. To make this manual copy
available in new terminals, use the following optional User PATH commands. They remember whether they added the folder, just as the installer does. Choose
either this copy or the standard installation; adding both can select the older one.

For PATH and removal messages in Spanish or Russian, change `$PathLanguage = 'en'`
to `$PathLanguage = 'es'` or `$PathLanguage = 'ru'` in the complete block before
pasting it. These translations are provisional.

<!-- windows-path-start -->
```powershell
& {
    $ErrorActionPreference = 'Stop'
    $PathActions = ConvertFrom-Json '["append","keep","keep","keep","append","keep","keep","remove"]'
    $PathNotifications = ConvertFrom-Json '["unchanged","unchanged","warning","notified"]'
    $PathNotificationMessages = ConvertFrom-Json '{"en":"Your User PATH was saved, but Windows could not be notified. Sign out of Windows and sign back in before opening a new terminal.","es":"Se guardó tu PATH de usuario, pero no se pudo avisar a Windows. Cierra tu sesión de Windows y vuelve a entrar antes de abrir una nueva terminal.","ru":"PATH пользователя сохранён, но уведомить Windows не удалось. Выйдите из Windows и войдите снова перед открытием нового терминала."}'
    $PathLanguage = 'en'
    function Get-VB3PathChange([string]$Raw, [string]$Entry, [bool]$Remove, [bool]$Owned, [bool]$KeepTrailingSeparator = $false) {
        $parts = @()
        if ($Raw.Length -gt 0) {
            $parts = @($Raw.Split(';'))
        }
        $found = -1
        for ($i = 0; $i -lt $parts.Count; $i++) {
            if ($parts[$i].TrimEnd('\') -ieq $Entry.TrimEnd('\')) {
                $found = $i
            }
        }
        $index = 0
        if ($Owned) {
            $index += 4
        }
        if ($found -ge 0) {
            $index += 2
        }
        if ($Remove) {
            $index += 1
        }
        $action = $PathActions[$index]
        $value = $Raw
        if ($action -eq 'append') {
            $separator = ''
            if ($Raw.Length -gt 0 -and -not $Raw.EndsWith(';')) {
                $separator = ';'
            }
            $value = $Raw + $separator + $Entry
        }
        if ($action -eq 'remove') {
            $kept = @()
            for ($i = 0; $i -lt $parts.Count; $i++) {
                if ($i -ne $found) {
                    $kept += $parts[$i]
                }
            }
            $value = $kept -join ';'
            if ($KeepTrailingSeparator -and $found -eq $parts.Count - 1 -and $found -gt 0) {
                $value += ';'
            }
        }
        return [pscustomobject]@{ Action = $action; Value = $value }
    }
    function Send-VB3EnvironmentChange {
        if (-not ('VB3EnvironmentNotification' -as [type])) {
            Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class VB3EnvironmentNotification { [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)] public static extern IntPtr SendMessageTimeout( IntPtr window, uint message, UIntPtr parameter, string area, uint flags, uint timeout, out UIntPtr result); }'
        }
        $result = [UIntPtr]::Zero
        $sent = [VB3EnvironmentNotification]::SendMessageTimeout(
            [IntPtr]0xffff, 0x1a, [UIntPtr]::Zero, 'Environment',
            0x2, 1000, [ref]$result)
        return ($sent -ne [IntPtr]::Zero)
    }
    function Get-VB3PathNotification([bool]$Written, [bool]$Notified) {
        $index = 0
        if ($Written) {
            $index += 2
        }
        if ($Notified) {
            $index += 1
        }
        return $PathNotifications[$index]
    }
    function Complete-VB3PathChange {
        [CmdletBinding()]
        param([bool]$Written, [string]$FailureMessage = $PathNotificationMessages.$PathLanguage)
        $notified = $false
        if ($Written) {
            try {
                $notified = Send-VB3EnvironmentChange
            } catch {
                $notified = $false
            }
        }
        $result = Get-VB3PathNotification $Written $notified
        if ($result -eq 'warning') {
            Write-Warning $FailureMessage
        }
    }
    function Set-VB3UserPath([string]$Entry, [bool]$Remove, [string]$NotificationFailure = $PathNotificationMessages.$PathLanguage) {
        $marker = Join-Path $Entry '.vb3-path-entry.json'
        $record = $null
        if (Test-Path -LiteralPath $marker) {
            $record = [IO.File]::ReadAllText($marker) | ConvertFrom-Json
        }
        $owned = [bool]($record -and $record.entry -ieq $Entry)
        $written = $false
        $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment')
        try {
            $present = @($key.GetValueNames() | Where-Object { $_ -ieq 'Path' }).Count -gt 0
            $kind = [Microsoft.Win32.RegistryValueKind]::ExpandString
            if ($present) {
                $kind = $key.GetValueKind('Path')
            }
            $raw = [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            $keepSeparator = [bool]($record -and $record.trailingSeparator)
            $change = Get-VB3PathChange $raw $Entry $Remove $owned $keepSeparator
            if ($change.Action -eq 'append') {
                $newRecord = @{
                    entry = $Entry
                    originallyPresent = $present
                    trailingSeparator = $raw.EndsWith(';')
                }
                [IO.File]::WriteAllText($marker, ($newRecord | ConvertTo-Json -Compress))
                try {
                    $key.SetValue('Path', $change.Value, $kind)
                    $written = $true
                } catch {
                    Remove-Item -LiteralPath $marker -Force -ErrorAction Stop
                    throw
                }
            }
            if ($change.Action -eq 'remove') {
                if ($change.Value.Length -eq 0 -and -not $record.originallyPresent) {
                    $key.DeleteValue('Path', $false)
                    $written = $true
                } else {
                    $key.SetValue('Path', $change.Value, $kind)
                    $written = $true
                }
            }
            if ($Remove -and $owned) {
                Remove-Item -LiteralPath $marker -Force -ErrorAction Stop
            }
        } finally {
            $key.Dispose()
            Complete-VB3PathChange $written $NotificationFailure
        }
    }
    $manual = Join-Path $env:LOCALAPPDATA 'VisitBasis\vb3-manual'
    Set-VB3UserPath $manual $false
}
```
<!-- windows-path-end -->

### Connect, update and skills

```powershell
$env:VB3_MCP_URL = Read-Host 'Account connection address'
Remove-Item Env:VB3_BEARER -ErrorAction SilentlyContinue
vb3 login
vb3 whoami --json
vb3 outlets list --page-size 1 --json
vb3 update
```

Enter the connection address supplied for your account. Set it again in each new terminal. If you did not add the manual
copy to PATH, replace `vb3` with `& (Join-Path $env:LOCALAPPDATA 'VisitBasis\vb3-manual\vb3.exe')` in these commands.
Open the verification address shown by login, check its displayed connection code,
then enter the emailed sign-in code on that page, choose your account and Connect.
Never paste a credential into the terminal. After restart, set the same address and
run `vb3 whoami --json` again: the connection is remembered privately for your Windows
user. Different addresses have separate saved connections. Run `vb3 logout` to sign
out; offline sign-out removes local access but cannot confirm remote disconnection.

`vb3 update` only prints the full install line and the ZIP instruction. Exit success
means those instructions were delivered; JSON says `manual_update`, not updated.
For a standard install, close every vb3 command and paste the install line again.
For a manual copy, download/check the new ZIP and unpack it to the SAME manual folder
with vb3 closed. The install line updates only the standard copy, not your manual one.
Both retain saved sign-in. Restart any AI app that was using the old executable.

Optional skills use `%USERPROFILE%\.claude\skills\vb3-cli\SKILL.md` or
`%USERPROFILE%\.agents\skills\vb3-cli\SKILL.md`:

```powershell
vb3 skill install claude
vb3 skill install codex
```

Only install for the app you use. Reinstall after updating. Identical content is left
alone; review a reported difference before choosing `--force`. Start a fresh AI app
session and invoke `/vb3-cli` or `$vb3-cli`. Native skill installation has not yet been
tried on Windows.

### Recover a connection location

Damaged saved connections prompt a fresh sign-in. VB3 can repair your connection folder; it never reads another user's credentials. If the location itself cannot
be used safely, the message names it and supplies commands for a new personal folder:

```powershell
& {
    $ErrorActionPreference = 'Stop'
    $env:XDG_CONFIG_HOME = Join-Path $env:LOCALAPPDATA ('VisitBasis\connection-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $env:XDG_CONFIG_HOME -ErrorAction Stop | Out-Null
    vb3 login
}
```

Save that NON-secret folder path and set the same `XDG_CONFIG_HOME` in later terminals.
Optionally persist it for your user with this command; this affects other programs
that use that variable, so keep its previous value if you had one:

```powershell
[Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $env:XDG_CONFIG_HOME, 'User')
```

Your saved connections are in a private folder under your Windows configuration
folder, or under the personal folder you chose. Choosing a fresh folder does not
disconnect the old connection. Disconnect it on your account’s AI and command line
connections page if the old folder cannot be opened. A new personal folder does
not require changing permissions or asking an administrator.

### Remove either installation completely

First set the SAME account address and personal connection folder used for sign-in, then run
`vb3 logout` (or the full manual executable path). If offline or unreadable, check
remote access on the account connections page later. Close every running vb3 command.
The commands below remove only the exact files documented above, your saved connections in the chosen folder, the two optional skill folders
and the PATH entry added by this installation. They preserve unrelated files, users and other PATH entries. If a check prints a file path, it found a link or an unfamiliar file: stop and inspect it yourself.
Use your actual manual path if you chose another; do not guess a folder to delete.
Removing saved connections signs you out of every account connection saved in that folder.

<!-- windows-remove-start -->
```powershell
& {
    $ErrorActionPreference = 'Stop'
    $PathActions = ConvertFrom-Json '["append","keep","keep","keep","append","keep","keep","remove"]'
    $PathNotifications = ConvertFrom-Json '["unchanged","unchanged","warning","notified"]'
    $PathNotificationMessages = ConvertFrom-Json '{"en":"Your User PATH was saved, but Windows could not be notified. Sign out of Windows and sign back in before opening a new terminal.","es":"Se guardó tu PATH de usuario, pero no se pudo avisar a Windows. Cierra tu sesión de Windows y vuelve a entrar antes de abrir una nueva terminal.","ru":"PATH пользователя сохранён, но уведомить Windows не удалось. Выйдите из Windows и войдите снова перед открытием нового терминала."}'
    $PathLanguage = 'en'
    function Get-VB3PathChange([string]$Raw, [string]$Entry, [bool]$Remove, [bool]$Owned, [bool]$KeepTrailingSeparator = $false) {
        $parts = @()
        if ($Raw.Length -gt 0) {
            $parts = @($Raw.Split(';'))
        }
        $found = -1
        for ($i = 0; $i -lt $parts.Count; $i++) {
            if ($parts[$i].TrimEnd('\') -ieq $Entry.TrimEnd('\')) {
                $found = $i
            }
        }
        $index = 0
        if ($Owned) {
            $index += 4
        }
        if ($found -ge 0) {
            $index += 2
        }
        if ($Remove) {
            $index += 1
        }
        $action = $PathActions[$index]
        $value = $Raw
        if ($action -eq 'append') {
            $separator = ''
            if ($Raw.Length -gt 0 -and -not $Raw.EndsWith(';')) {
                $separator = ';'
            }
            $value = $Raw + $separator + $Entry
        }
        if ($action -eq 'remove') {
            $kept = @()
            for ($i = 0; $i -lt $parts.Count; $i++) {
                if ($i -ne $found) {
                    $kept += $parts[$i]
                }
            }
            $value = $kept -join ';'
            if ($KeepTrailingSeparator -and $found -eq $parts.Count - 1 -and $found -gt 0) {
                $value += ';'
            }
        }
        return [pscustomobject]@{ Action = $action; Value = $value }
    }
    function Send-VB3EnvironmentChange {
        if (-not ('VB3EnvironmentNotification' -as [type])) {
            Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class VB3EnvironmentNotification { [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)] public static extern IntPtr SendMessageTimeout( IntPtr window, uint message, UIntPtr parameter, string area, uint flags, uint timeout, out UIntPtr result); }'
        }
        $result = [UIntPtr]::Zero
        $sent = [VB3EnvironmentNotification]::SendMessageTimeout(
            [IntPtr]0xffff, 0x1a, [UIntPtr]::Zero, 'Environment',
            0x2, 1000, [ref]$result)
        return ($sent -ne [IntPtr]::Zero)
    }
    function Get-VB3PathNotification([bool]$Written, [bool]$Notified) {
        $index = 0
        if ($Written) {
            $index += 2
        }
        if ($Notified) {
            $index += 1
        }
        return $PathNotifications[$index]
    }
    function Complete-VB3PathChange {
        [CmdletBinding()]
        param([bool]$Written, [string]$FailureMessage = $PathNotificationMessages.$PathLanguage)
        $notified = $false
        if ($Written) {
            try {
                $notified = Send-VB3EnvironmentChange
            } catch {
                $notified = $false
            }
        }
        $result = Get-VB3PathNotification $Written $notified
        if ($result -eq 'warning') {
            Write-Warning $FailureMessage
        }
    }
    function Set-VB3UserPath([string]$Entry, [bool]$Remove, [string]$NotificationFailure = $PathNotificationMessages.$PathLanguage) {
        $marker = Join-Path $Entry '.vb3-path-entry.json'
        $record = $null
        if (Test-Path -LiteralPath $marker) {
            $record = [IO.File]::ReadAllText($marker) | ConvertFrom-Json
        }
        $owned = [bool]($record -and $record.entry -ieq $Entry)
        $written = $false
        $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment')
        try {
            $present = @($key.GetValueNames() | Where-Object { $_ -ieq 'Path' }).Count -gt 0
            $kind = [Microsoft.Win32.RegistryValueKind]::ExpandString
            if ($present) {
                $kind = $key.GetValueKind('Path')
            }
            $raw = [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            $keepSeparator = [bool]($record -and $record.trailingSeparator)
            $change = Get-VB3PathChange $raw $Entry $Remove $owned $keepSeparator
            if ($change.Action -eq 'append') {
                $newRecord = @{
                    entry = $Entry
                    originallyPresent = $present
                    trailingSeparator = $raw.EndsWith(';')
                }
                [IO.File]::WriteAllText($marker, ($newRecord | ConvertTo-Json -Compress))
                try {
                    $key.SetValue('Path', $change.Value, $kind)
                    $written = $true
                } catch {
                    Remove-Item -LiteralPath $marker -Force -ErrorAction Stop
                    throw
                }
            }
            if ($change.Action -eq 'remove') {
                if ($change.Value.Length -eq 0 -and -not $record.originallyPresent) {
                    $key.DeleteValue('Path', $false)
                    $written = $true
                } else {
                    $key.SetValue('Path', $change.Value, $kind)
                    $written = $true
                }
            }
            if ($Remove -and $owned) {
                Remove-Item -LiteralPath $marker -Force -ErrorAction Stop
            }
        } finally {
            $key.Dispose()
            Complete-VB3PathChange $written $NotificationFailure
        }
    }
    $standard = Join-Path $env:LOCALAPPDATA 'VisitBasis\vb3\bin'
    $manual = Join-Path $env:LOCALAPPDATA 'VisitBasis\vb3-manual'
    $base = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { $env:APPDATA }
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $profiles = Join-Path $base ('vb3-' + $sid)
    $claude = Join-Path $env:USERPROFILE '.claude\skills\vb3-cli'
    $codex = Join-Path $env:USERPROFILE '.agents\skills\vb3-cli'
    $plans = @(
        @{ Path = $standard; Pattern = '^(vb3\.exe|\.vb3-path-entry\.json)$' },
        @{ Path = $manual; Pattern = '^(vb3\.exe|README\.md|install\.ps1|\.vb3-path-entry\.json)$' },
        @{ Path = $profiles; Pattern = '^(oauth-[0-9a-f]{64}\.json(\.lock)?|\.oauth-[0-9a-f]{32})$' },
        @{ Path = $claude; Pattern = '^(SKILL\.md|\.vb3-install-.*)$' },
        @{ Path = $codex; Pattern = '^(SKILL\.md|\.vb3-install-.*)$' }
    )
    foreach ($plan in $plans) {
        if (-not (Test-Path -LiteralPath $plan.Path)) {
            continue
        }
        $item = Get-Item -LiteralPath $plan.Path -Force
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw $plan.Path
        }
        foreach ($child in Get-ChildItem -LiteralPath $plan.Path -Force) {
            if ($child.PSIsContainer -or ($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $child.Name -notmatch $plan.Pattern) {
                throw $child.FullName
            }
        }
    }
    foreach ($folder in @($standard, $manual)) {
        if (Test-Path -LiteralPath $folder) {
            Set-VB3UserPath $folder $true
        }
    }
    foreach ($plan in $plans) {
        if (Test-Path -LiteralPath $plan.Path) {
            Remove-Item -LiteralPath $plan.Path -Recurse -Force
        }
    }
    $root = Join-Path $env:LOCALAPPDATA 'VisitBasis\vb3'
    if ((Test-Path -LiteralPath $root) -and -not (Get-ChildItem -LiteralPath $root -Force)) {
        Remove-Item -LiteralPath $root
    }
    foreach ($name in @('vb3_windows_amd64.zip','vb3_windows_arm64.zip','windows-checksums.txt','windows-checksums.txt.sigstore.json')) {
        $download = Join-Path $env:USERPROFILE ('Downloads\' + $name)
        if (Test-Path -LiteralPath $download) {
            Remove-Item -LiteralPath $download -Force
        }
    }
}
```
<!-- windows-remove-end -->

If you chose a separate personal folder solely for VB3, remove it once empty and clear
only that User variable (or restore your old value), then open a new terminal:

```powershell
& {
    $ErrorActionPreference = 'Stop'
    if ($env:XDG_CONFIG_HOME -and (Test-Path -LiteralPath $env:XDG_CONFIG_HOME) -and -not (Get-ChildItem -LiteralPath $env:XDG_CONFIG_HOME -Force)) { Remove-Item -LiteralPath $env:XDG_CONFIG_HOME -ErrorAction Stop }
    [Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $null, 'User')
    Remove-Item Env:XDG_CONFIG_HOME -ErrorAction SilentlyContinue
}
```

If you saved connections in several personal folders, use the complete block below
once for each folder you know you used. Enter that exact folder path when asked.
It removes only the saved connections inside that folder. An unfamiliar file or
link stops the entire block. Removing files does not disconnect remote access;
use your account connections page if sign-out could not do that. Do not remove
`.claude`, `.agents`, your whole Windows configuration folder or another person's
saved connections.

<!-- windows-connections-start -->
```powershell
& {
    $ErrorActionPreference = 'Stop'
    $folder = Read-Host 'Personal folder used for saved connections'
    if (-not [IO.Path]::IsPathRooted($folder)) {
        throw $folder
    }
    $personal = Get-Item -LiteralPath $folder -Force
    if (-not $personal.PSIsContainer -or ($personal.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw $folder
    }
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $connections = Join-Path $folder ('vb3-' + $sid)
    if (Test-Path -LiteralPath $connections) {
        $item = Get-Item -LiteralPath $connections -Force
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw $connections
        }
        foreach ($file in Get-ChildItem -LiteralPath $connections -Force) {
            if ($file.PSIsContainer -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $file.Name -notmatch '^(oauth-[0-9a-f]{64}\.json(\.lock)?|\.oauth-[0-9a-f]{32})$') {
                throw $file.FullName
            }
        }
        Remove-Item -LiteralPath $connections -Recurse -Force
    }
}
```
<!-- windows-connections-end -->

## Verify the publisher signature

The installer and updater perform checksum verification over HTTPS. For an independent
publisher-identity check, use cosign and download `checksums.txt` plus
`checksums.txt.sigstore.json` from the same release:

```sh
VB3_TAG=v0.4.0
curl -fsSLO "https://github.com/visitbasis/vb3-cli/releases/download/$VB3_TAG/checksums.txt"
curl -fsSLO "https://github.com/visitbasis/vb3-cli/releases/download/$VB3_TAG/checksums.txt.sigstore.json"
cosign verify-blob \
  --certificate-identity "https://github.com/visitbasis/vb3/.github/workflows/release.yml@refs/tags/$VB3_TAG" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --bundle checksums.txt.sigstore.json checksums.txt
```

For Windows use `windows-checksums.txt` and `windows-checksums.txt.sigstore.json`
from that same tag instead of the two Unix filenames in the command above. This
checks the release publisher; it does not add a Windows certificate to the executable.

After signature verification, compare your archive's SHA-256 hash to its exact entry in
`checksums.txt` (`sha256sum` on Linux, `shasum -a 256` on macOS).

This repository distributes the client binaries, installer and documentation. Application
source code is not published here.
