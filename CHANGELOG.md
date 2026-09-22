# Changelog

This repository is read at whatever revision you have checked out, so its entries are dated rather than numbered

## 2026-09-22

- The marketplace exists: `rokokol-skills`, listing seventeen skills, each pointing at its own repository
- `check.sh manifest` holds the manifest to what `/plugin` reads — it parses, it carries the required fields, no two entries claim one name, every entry names a GitHub repository and carries a description, and the entries are in order
- `check.sh remote` asks GitHub anonymously whether a stranger can clone every repository listed, behind a control request that stops a dead network reading as a dead manifest
