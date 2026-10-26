# testoptim CLI

Command-line tool for [TestOptim](https://testoptim.ai). This repository only hosts release binaries.

## Install

macOS or Linux:

```bash
brew install testoptim-ai/tap/testoptim
# or
curl -fsSL https://raw.githubusercontent.com/TestOptim-AI/testoptim-cli/main/install.sh | sh
```

Windows (PowerShell, no admin rights needed):

```powershell
irm https://raw.githubusercontent.com/TestOptim-AI/testoptim-cli/main/install.ps1 | iex
```

It installs `testoptim.exe` in `%LOCALAPPDATA%\Programs\testoptim` and adds it to your user `PATH`. You can also download the `windows_amd64` or `windows_arm64` `.zip` from the [latest release](https://github.com/TestOptim-AI/testoptim-cli/releases/latest).

Docker:

```bash
docker run --rm ghcr.io/testoptim-ai/testoptim-cli version
```

## Use

```bash
testoptim auth                        # paste an API token once
testoptim run --project <id>          # run your tests and list the issues they find
testoptim run --changed /checkout     # re-test only the pages or flows you changed
testoptim tunnel --project <id>       # test apps on your private network
```

`testoptim run` exits non-zero when the run finds a high or critical issue (`--fail-on` changes the level), so CI jobs and coding agents such as Claude Code, Cursor and Copilot can gate on it.

See [Test apps on a private network](https://testoptim.ai/docs/integrations/run-tests-on-a-private-network).
