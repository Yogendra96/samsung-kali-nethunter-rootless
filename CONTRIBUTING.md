# Contributing to samsung-kali-nethunter-rootless

First off, thank you for taking the time to contribute! 🎉

This project is the result of a 3-day debugging session trying to get Kali NetHunter Rootless working on a Samsung Galaxy S26 Ultra. **Every issue we hit was a first-time discovery** because the existing projects (jorexdeveloper, xiv3r) all assume XFCE works — which it doesn't on 2026+ Android devices due to a `glycin`/`bwrap` incompatibility.

Your contributions help the next person avoid that 3-day war.

---

## Code of conduct

Be respectful, be kind. We're all here to learn and build cool stuff.

---

## How can I contribute?

### 🐛 Reporting a bug

Open a [bug report](https://github.com/Yogendra96/samsung-kali-nethunter-rootless/issues/new?template=bug_report.md) with:

- **Your device** (model, Android version, One UI version if Samsung)
- **What you expected** vs **what happened**
- **Step-by-step** to reproduce
- **Relevant logs** (`adb logcat` output, chroot error messages)
- **Screenshots** if relevant

The more detail, the better.

### 💡 Suggesting a feature

Open a [feature request](https://github.com/Yogendra96/samsung-kali-nethunter-rootless/issues/new?template=feature_request.md) describing:

- **What you want** (e.g., "add a flag to install a specific metapackage like kali-linux-default")
- **Why** it would be useful
- **Any alternatives** you considered

### 📝 Improving documentation

The docs are at `docs/INSTALL.md`, `docs/SAMSUNG.md`, `docs/TROUBLESHOOTING.md`, and `references/*.md`. Typos, clarifications, more examples — all welcome.

### 🐧 Adding support for a new device

Tested on something new? Add it to the README's [Tested on](#tested-on) table:

1. Edit `README.md`
2. Add your device with the `✅ Verified end-to-end` or `🟡 Should work (untested)` status
3. Open a PR with the change

### 🪟 Adding a termux-x11 path

We currently use KeX VNC. There's an alternative: [termux-x11](https://github.com/termux/termux-x11) (a native X11 server for Android, no VNC needed). A PR adding termux-x11 as an option in the installer would be very welcome.

### 🛠️ Adding new tools

The default tool list in `scripts/install-tools.sh` covers 30+ offensive security tools. To add more:

1. Edit `scripts/install-tools.sh`
2. Add the package name to the `apt install` list
3. Add it to the README's [What you get](#what-you-get) section
4. Open a PR

### 🐞 Fixing a known issue

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for the list of known issues. If you find a fix for any of them, open a PR with the fix and update the troubleshooting doc.

---

## Development setup

### Prerequisites

- A Samsung Galaxy phone (or any Android 13+ device — Samsung is just the main tested one)
- A Mac (or Linux) for adb + scrcpy
- 8 GB free storage on the phone
- USB-C cable

### Local dev workflow

```bash
# 1. Fork the repo on GitHub
#    Go to https://github.com/Yogendra96/samsung-kali-nethunter-rootless
#    Click "Fork" → creates YOUR-NAME/samsung-kali-nethunter-rootless

# 2. Clone your fork
git clone https://github.com/YOUR-NAME/samsung-kali-nethunter-rootless.git
cd samsung-kali-nethunter-rootless

# 3. Add the upstream as a remote (so you can sync later)
git remote add upstream https://github.com/Yogendra96/samsung-kali-nethunter-rootless.git

# 4. Create a feature branch
git checkout -b feature/my-improvement

# 5. Make your changes

# 6. Test on your phone (carefully — these scripts run apt on the phone):
adb -d push install.sh /sdcard/Download/
# Then on the phone, in Termux:
bash /sdcard/Download/install.sh

# 7. Commit
git add .
git commit -m "Add my improvement"

# 8. Push to your fork
git push origin feature/my-improvement

# 9. Open a Pull Request on GitHub
#    Go to https://github.com/Yogendra96/samsung-kali-nethunter-rootless
#    Click "Compare & pull request"
```

### Syncing with upstream

```bash
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

---

## Coding style

### Bash

- Use `set -euo pipefail` at the top of every script
- Use lowercase variable names with underscores: `device_ip`, not `deviceIP` or `DeviceIP`
- Quote your variables: `"$device_ip"`, not `$device_ip`
- Use `$(...)` for command substitution, not backticks
- Use `[[ ... ]]` for tests, not `[ ... ]`
- Use `log()`, `warn()`, `err()` helpers for output (see `install.sh` for the pattern)
- Indent with 4 spaces
- Add comments for non-obvious code

### Markdown

- Use ATX-style headers (`#`, `##`, `###`)
- Reference links: `[text](URL)` not inline `[text][1]`
- Use code fences with language hints: ` ```bash ` not just ` ``` `
- Indent code blocks 4 spaces inside lists

### Commit messages

- Use the present tense: "Add feature" not "Added feature"
- Use the imperative mood: "Fix bug" not "Fixed bug"
- Keep the first line under 72 characters
- Reference issues and PRs when relevant: "Fix #123"

Examples:
- ✅ `Add termux-x11 path as alternative to KeX VNC`
- ✅ `Fix postgresql-18 nuclear fix when dpkg is missing`
- ✅ `Update README to mention Galaxy A55 testing`
- ❌ `fixed some bugs`
- ❌ `WIP`
- ❌ `asdfgh`

---

## Testing

Before opening a PR, test your changes on a real device. The minimum test is:

1. **Fresh install:** wipe the chroot, run the installer, verify it works end-to-end
2. **Existing install:** run the install on a chroot that already has the chroot, verify it doesn't break
3. **Mac control:** run `control-from-mac.sh` on a Mac, verify all 9 options work

Document any new device you test on in the README's "Tested on" table.

---

## Project structure

```
samsung-kali-nethunter-rootless/
├── install.sh                  # The main installer (run on the phone)
├── control-from-mac.sh         # scrcpy + adb menu (run on the Mac)
├── fluxbox/                    # Fluxbox configuration
├── scripts/                    # Individual installation steps
├── docs/                       # Detailed documentation
├── references/                 # Background reading
├── screenshots/                # Screenshots for the README
└── downloads/                  # Drop your APKs here
```

If you're adding a new feature, put it in the appropriate directory:
- Bash functions → `install.sh` (or a new file in `scripts/`)
- Documentation → `docs/`
- Background info → `references/`
- Screenshots → `screenshots/`

---

## Release process

We use [semantic versioning](https://semver.org/):

- `MAJOR` version when you make incompatible changes
- `MINOR` version when you add functionality in a backward-compatible manner
- `PATCH` version when you make backward-compatible bug fixes

The current version is `v1.0.0`.

When cutting a release:

```bash
# Tag the release
git tag -a v1.1.0 -m "v1.1.0: add termux-x11 support"
git push origin v1.1.0
```

The release will be auto-published to GitHub Releases. We follow the format:

```
v1.1.0 (2026-07-XX)
- Add termux-x11 path as alternative to KeX VNC
- Fix postgresql-18 nuclear fix when dpkg is missing
- Update README with new device test results
```

---

## Questions?

Open a [discussion](https://github.com/Yogendra96/samsung-kali-nethunter-rootless/discussions) — not an issue — for general questions about how to use the project, or for design discussions.

For bugs, use the bug report template. For features, use the feature request template.

---

Thank you for contributing! 🎉🔓📱
