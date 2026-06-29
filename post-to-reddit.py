#!/usr/bin/env python3
"""
post-to-reddit.py — post the samsung-kali-nethunter-rootless announcement
to multiple subreddits using the Reddit API (via praw).

Setup (one-time):
    1. Go to https://www.reddit.com/prefs/apps
    2. Click "create another app" at the bottom
    3. Choose "script" as the type
    4. Name: "samsung-kali-nethunter-rootless-poster"
    5. Redirect URI: http://localhost:8080 (anything works for scripts)
    6. Note the client_id (under the app name) and client_secret
    7. Put them in a file called ~/.config/samsung-kali-nethunter-rootless/reddit.env:
         REDDIT_CLIENT_ID=your_client_id
         REDDIT_CLIENT_SECRET=your_client_secret
         REDDIT_USERNAME=your_reddit_username
         REDDIT_PASSWORD=your_reddit_password

Usage:
    python3 post-to-reddit.py --dry-run    # show what would be posted
    python3 post-to-reddit.py             # actually post (will prompt for confirmation)
    python3 post-to-reddit.py --subreddit Kalilinux    # post to one specific sub
"""

import argparse
import os
import sys
from pathlib import Path
from textwrap import dedent

try:
    import praw
except ImportError:
    print("praw not installed. Run: pip3 install --user praw")
    sys.exit(1)


# --- Configuration ---

CONFIG_DIR = Path.home() / ".config" / "samsung-kali-nethunter-rootless"
CONFIG_FILE = CONFIG_DIR / "reddit.env"

# Subreddits to post to, with category tags
DEFAULT_SUBREDDITS = [
    # Primary targets — Kali Linux community
    ("Kalilinux", "primary"),
    ("netsecstudents", "primary"),

    # Termux community (we use Termux + proot)
    ("termux", "primary"),

    # Android community
    ("AndroidRoot", "secondary"),
    ("Android", "secondary"),

    # Samsung / S26 Ultra specific
    ("samsung", "secondary"),
    ("galaxys26", "secondary"),

    # Broader security communities
    ("cybersecurity", "secondary"),
    ("netsec", "secondary"),
    ("HowToHack", "secondary"),
    ("hacking", "secondary"),
]


# --- Post content ---

POST_TITLE = (
    "I built a one-liner installer for Kali NetHunter Rootless on the S26 Ultra "
    "(and other 2026+ Android devices) — no root, no Knox trip, no warranty void"
)

POST_BODY = dedent("""\
Hey everyone,

I just spent the better part of a week trying to get **Kali NetHunter Rootless**
working on my new **Samsung Galaxy S26 Ultra** (SM-S948B, Snapdragon 8 Elite
Gen 5, Android 16). The official docs are 2 years out of date and assume XFCE
works. **It doesn't on any 2026+ Android device** because of a `glycin`/`bwrap`
regression in proot.

So I wrote a project that does the whole thing for you:

**`samsung-kali-nethunter-rootless`**
🔗 https://github.com/Yogendra96/samsung-kali-nethunter-rootless

## What it does

A one-liner install (in Termux on the phone) that:

- Bootstraps the Kali chroot via the official NetHunter rootless installer
- Fixes the wedged `postgresql-18` package that breaks `apt install` in proot
- Writes public DNS to the chroot's `/etc/resolv.conf` (proot doesn't inherit it)
- Installs 30+ offensive security tools (nmap, msfconsole, burpsuite, seclists, etc.)
- Sets up **Fluxbox** as the desktop (the only DE that works in 2026 proot)
- Configures the VNC server + NetHunter KeX app
- Gives you a Mac control script (`control-from-mac.sh`) that uses `scrcpy` for
  screen mirroring + full keyboard/mouse control from your laptop

## What's special

- **No root, no bootloader unlock, no Knox trip** — Knox warranty bit stays at 0x0000
- **Verified end-to-end on S26 Ultra** (SM-S948B, Android 16)
- **Mac control via scrcpy** — see the phone screen on your Mac, type commands
  from your laptop, drag & drop files
- **Why Fluxbox, not XFCE** — the README has a full root-cause analysis with
  upstream links to the proot fix that's in master
- **Samsung-specific docs** — Auto Blocker, battery whitelist, Knox verification

## Tested on

- ✅ **Samsung Galaxy S26 Ultra** (SM-S948B, Snapdragon 8 Elite Gen 5, Android 16)
- 🟡 Should work on any Android 13+ device with Termux (S24/S25, OnePlus, Pixel)

## Quick start (3 commands)

```bash
# On your Mac:
brew install android-platform-tools scrcpy
adb -d install termux.apk
adb -d install NetHunterStore.apk

# On the phone, in Termux:
wget -qO install.sh https://raw.githubusercontent.com/Yogendra96/samsung-kali-nethunter-rootless/main/install.sh
bash install.sh
```

That's it. ~25 minutes later you have a full Kali chroot with a graphical desktop
running on the phone, and you can mirror the screen to your Mac via scrcpy.

## Screenshots

The README has real-device screenshots from the S26 Ultra:
- Fluxbox desktop with the Kali dragon wallpaper
- Metasploit loaded with 2,654 exploits
- Rofi app launcher
- Hacker's Keyboard in Termux

## What I learned

The 3 existing rootless NetHunter projects (jorexdeveloper, xiv3r, AnLinux) all
assume XFCE works. They don't on 2026 devices. I documented the full root cause
(glycin-loaders using bwrap --unshare-all which proot can't fake) in
`references/glycin-bwrap-analysis.md`. The proot upstream has a fix
([termux/proot#359](https://github.com/termux/proot/pull/359)) but it's in master,
not yet in a Termux release.

## Try it

```bash
git clone https://github.com/Yogendra96/samsung-kali-nethunter-rootless.git
cd samsung-kali-nethunter-rootless
cat README.md
```

PRs welcome — especially tests on other devices (S24/S25/OnePlus/Pixel) and the
termux-x11 path as an alternative to KeX VNC.

## License

GPL-3.0.

Happy to answer questions. If you try it on a device that's not in the
"Tested on" list, please open an issue and let me know how it goes.
""")


# --- Functions ---

def load_config():
    """Load Reddit API credentials from ~/.config/samsung-kali-nethunter-rootless/reddit.env"""
    if not CONFIG_FILE.exists():
        print(f"Config file not found: {CONFIG_FILE}")
        print()
        print("Setup instructions:")
        print("  1. Go to https://www.reddit.com/prefs/apps")
        print("  2. Click 'create another app'")
        print("  3. Choose type: 'script'")
        print("  4. Name: 'samsung-kali-nethunter-rootless-poster'")
        print("  5. Redirect URI: http://localhost:8080")
        print("  6. Note the client_id and client_secret")
        print(f"  7. Create {CONFIG_FILE} with:")
        print("       REDDIT_CLIENT_ID=your_client_id")
        print("       REDDIT_CLIENT_SECRET=your_client_secret")
        print("       REDDIT_USERNAME=your_reddit_username")
        print("       REDDIT_PASSWORD=your_reddit_password")
        sys.exit(1)

    config = {}
    with open(CONFIG_FILE) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, value = line.split("=", 1)
                config[key.strip()] = value.strip().strip('"').strip("'")
    return config


def make_reddit(config):
    """Create a praw Reddit instance with the given config."""
    return praw.Reddit(
        client_id=config["REDDIT_CLIENT_ID"],
        client_secret=config["REDDIT_CLIENT_SECRET"],
        username=config["REDDIT_USERNAME"],
        password=config["REDDIT_PASSWORD"],
        user_agent="samsung-kali-nethunter-rootless-poster/1.0 (by /u/" + config["REDDIT_USERNAME"] + ")",
    )


def show_post_preview(subreddit):
    """Print the post that would be submitted."""
    print("=" * 70)
    print(f"SUBREDDIT: r/{subreddit}")
    print("=" * 70)
    print(f"TITLE: {POST_TITLE}")
    print("=" * 70)
    print("BODY:")
    print(POST_BODY)
    print("=" * 70)


def post_to_subreddit(reddit, subreddit, dry_run=False):
    """Post the announcement to a single subreddit."""
    show_post_preview(subreddit)
    print()
    if dry_run:
        print("[DRY RUN] Would have posted. Skipping.")
        return None

    answer = input(f"Post to r/{subreddit}? [y/N] ")
    if answer.lower() not in ("y", "yes"):
        print("Skipping.")
        return None

    try:
        sub = reddit.subreddit(subreddit)
        submission = sub.submit(
            title=POST_TITLE,
            selftext=POST_BODY,
            flair_id=None,
            flair_text=None,
        )
        print(f"✅ Posted! https://reddit.com{submission.permalink}")
        return submission
    except Exception as e:
        print(f"❌ Failed to post to r/{subreddit}: {e}")
        return None


def main():
    parser = argparse.ArgumentParser(description="Post the samsung-kali-nethunter-rootless announcement to multiple subreddits")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be posted without actually posting")
    parser.add_argument("--subreddit", "-s", help="Post to one specific subreddit only")
    parser.add_argument("--primary-only", action="store_true", help="Post only to primary subreddits (skip secondary)")
    parser.add_argument("--secondary-only", action="store_true", help="Post only to secondary subreddits (skip primary)")
    args = parser.parse_args()

    config = load_config()
    reddit = make_reddit(config)

    # Verify authentication
    print(f"Authenticated as: /u/{reddit.user.me().name}")
    print(f"Account karma: {reddit.user.me().comment_karma} comment, {reddit.user.me().link_karma} link")
    print()

    if args.subreddit:
        subreddits = [(args.subreddit, "manual")]
    elif args.primary_only:
        subreddits = [(s, c) for s, c in DEFAULT_SUBREDDITS if c == "primary"]
    elif args.secondary_only:
        subreddits = [(s, c) for s, c in DEFAULT_SUBREDDITS if c == "secondary"]
    else:
        subreddits = DEFAULT_SUBREDDITS

    print(f"Will post to {len(subreddits)} subreddits:")
    for sub, cat in subreddits:
        marker = "🎯" if cat == "primary" else "📌"
        print(f"  {marker} r/{sub} ({cat})")
    print()

    if not args.dry_run:
        answer = input("Proceed? [y/N] ")
        if answer.lower() not in ("y", "yes"):
            print("Aborted.")
            return

    results = []
    for subreddit, category in subreddits:
        print()
        print(f"=== Posting to r/{subreddit} ({category}) ===")
        result = post_to_subreddit(reddit, subreddit, dry_run=args.dry_run)
        if result:
            results.append((subreddit, result.permalink))
        # Reddit rate limit: wait between posts
        import time
        if subreddit != subreddits[-1][0]:
            print("Waiting 30s for Reddit rate limit...")
            time.sleep(30)

    print()
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    if args.dry_run:
        print("DRY RUN: No posts were made.")
    else:
        if results:
            for sub, permalink in results:
                print(f"✅ r/{sub}: https://reddit.com{permalink}")
        else:
            print("No posts were made.")


if __name__ == "__main__":
    main()
