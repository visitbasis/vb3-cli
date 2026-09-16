# VisitBasis command-line client

Use `vb3` to read your VisitBasis account and propose changes from a terminal or an AI
assistant. You decide proposed changes on the approval page. Requires macOS or Linux on
Intel/AMD 64-bit or ARM64. No Go installation is needed.

## Install

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

Set `VB3_MCP_URL` to your VisitBasis HTTPS `/mcp` endpoint and `VB3_BEARER` to your existing
session credential in the terminal that launches the assistant. Keep the credential out
of command arguments and transcripts. Help, updates and skill installation need no
VisitBasis credential. Device-code sign-in is not included in this release.

Local commands (`update` and `skill install`) are English-only. `--language` applies
to registry commands; each local command's `--help` lists its supported options.

## Update or pin

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

After signature verification, compare your archive's SHA-256 hash to its exact entry in
`checksums.txt` (`sha256sum` on Linux, `shasum -a 256` on macOS).

This repository distributes the client binaries, installer and documentation. Application
source code is not published here.
