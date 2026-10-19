# Install the testoptim CLI on Windows: irm <url>/install.ps1 | iex
# Env: TESTOPTIM_VERSION (e.g. 1.2.3, default latest), INSTALL_DIR (default %LOCALAPPDATA%\Programs\testoptim),
#      TESTOPTIM_REPO (GitHub owner/repo hosting the releases).

# A function, not top-level code, so errors under `iex` throw instead of exiting the user's shell.
function Install-Testoptim {
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

  $repo = if ($env:TESTOPTIM_REPO) { $env:TESTOPTIM_REPO } else { 'TestOptim-AI/testoptim-cli' }
  $tagPrefix = 'cli-v'

  # The machine-scope value is the native architecture, also when this PowerShell runs emulated (x64 on ARM64).
  $machine = [Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE', 'Machine')
  $arch = switch ($machine) {
    'AMD64' { 'amd64' }
    'ARM64' { 'arm64' }
    default { throw "install: unsupported architecture $machine" }
  }

  $version = "$env:TESTOPTIM_VERSION" -replace '^v', '' -replace '^cli-v', ''
  if ($version -and $version -notmatch '^[0-9A-Za-z.+-]+$') { throw "install: invalid version: $version" }
  if (-not $version) {
    $releases = Invoke-RestMethod -UseBasicParsing "https://api.github.com/repos/$repo/releases?per_page=50"
    $latest = $releases | Where-Object { $_.tag_name -match "^$tagPrefix[0-9][0-9.]*$" } | Select-Object -First 1
    if (-not $latest) { throw 'install: could not determine the latest version; set TESTOPTIM_VERSION' }
    $version = $latest.tag_name.Substring($tagPrefix.Length)
  }

  $archive = "testoptim_${version}_windows_${arch}.zip"
  $checksums = "testoptim_${version}_checksums.txt"
  $base = "https://github.com/$repo/releases/download/$tagPrefix$version"

  $tmp = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
  New-Item -ItemType Directory -Path $tmp | Out-Null
  try {
    Write-Host "Downloading testoptim $version (windows/$arch)..."
    Invoke-WebRequest -UseBasicParsing "$base/$archive" -OutFile (Join-Path $tmp $archive)
    Invoke-WebRequest -UseBasicParsing "$base/$checksums" -OutFile (Join-Path $tmp $checksums)

    $expected = Get-Content (Join-Path $tmp $checksums) |
      ForEach-Object { $f = -split $_; if ($f[1] -eq $archive) { $f[0] } } | Select-Object -First 1
    if (-not $expected) { throw "install: no checksum listed for $archive" }
    $actual = (Get-FileHash -Algorithm SHA256 (Join-Path $tmp $archive)).Hash
    if ($actual -ne $expected) { throw "install: checksum mismatch for $archive" }

    Expand-Archive -Path (Join-Path $tmp $archive) -DestinationPath (Join-Path $tmp 'out')

    $dir = if ($env:INSTALL_DIR) { $env:INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'Programs\testoptim' }
    $dir = (New-Item -ItemType Directory -Force -Path $dir).FullName.TrimEnd('\')
    $exe = Join-Path $dir 'testoptim.exe'
    try { Copy-Item -Force (Join-Path $tmp 'out\testoptim.exe') $exe }
    catch { throw "install: cannot write $exe; stop any running testoptim and try again ($_)" }
  }
  finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
  }

  Write-Host "Installed $exe"
  # Read and write the raw registry value so entries like %JAVA_HOME%\bin stay unexpanded.
  $envKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment')
  $userPath = $envKey.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
  $entries = @($userPath -split ';' | Where-Object { $_ })
  if ($entries -notcontains $dir) {
    $envKey.SetValue('Path', (($entries + $dir) -join ';'), [Microsoft.Win32.RegistryValueKind]::ExpandString)
    # Setting a user variable through .NET broadcasts WM_SETTINGCHANGE, so new terminals see the new PATH.
    [Environment]::SetEnvironmentVariable('TESTOPTIM_INSTALL', '1', 'User')
    [Environment]::SetEnvironmentVariable('TESTOPTIM_INSTALL', $null, 'User')
    Write-Host "Added $dir to your user PATH. Open a new terminal to use it everywhere."
  }
  $envKey.Close()
  if (($env:Path -split ';') -notcontains $dir) { $env:Path = "$env:Path;$dir" }
  Write-Host 'Next: testoptim auth'
}

Install-Testoptim
