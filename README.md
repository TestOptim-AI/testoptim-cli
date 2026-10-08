# testoptim CLI

Command-line tool for [TestOptim](https://testoptim.ai). This repository only hosts release binaries.

## Install

```bash
brew install testoptim-ai/tap/testoptim
# or
curl -fsSL https://raw.githubusercontent.com/TestOptim-AI/testoptim-cli/main/install.sh | sh
# or
docker run --rm ghcr.io/testoptim-ai/testoptim-cli version
```

## Use

```bash
testoptim auth                        # paste an API token once
testoptim tunnel --project <id>       # test apps on your private network
```

See [Test apps on a private network](https://testoptim.ai/docs/integrations/run-tests-on-a-private-network).
