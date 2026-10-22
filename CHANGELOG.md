# Changelog

This repository is read at whatever revision you have checked out, so its entries are dated rather than numbered

## 2026-10-22

- `mail` is listed: reaching IMAP and SMTP mailboxes through a service that holds the passwords and decides by per-mailbox and per-address permissions the agent cannot grant itself, with new mail pushed over IDLE

## 2026-10-20

- `headless-gui` is listed: running, screenshotting and clicking through a GUI app in a private headless sway, so that nothing reaches the desktop the user works in

## 2026-10-19

- `phone-alert` is listed: calling a person to their Android phone through Termux, now with a vibration, the torch and a notification, or later with an alarm in the clock app
- `termux-api` is listed: using an Android phone's cameras, location, calls, messages and notifications through termux-api, with the commands that hang or exit 0 without an effect

## 2026-09-23

- `telegram` is listed: reaching a Telegram account over MTProto through a service that holds the session and decides by per-chat permissions the agent cannot grant itself

## 2026-09-22

- The marketplace exists: `rokokol-skills`, listing seventeen skills, each pointing at its own repository
- `check.sh manifest` holds the manifest to what `/plugin` reads — it parses, it carries the required fields, no two entries claim one name, every entry names a GitHub repository and carries a description, and the entries are in order
- `check.sh remote` asks GitHub anonymously whether a stranger can clone every repository listed, behind a control request that stops a dead network reading as a dead manifest
