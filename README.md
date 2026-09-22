<div align="center">

# rokokol-skills

**One marketplace for skills that each live in their own repository ฅ^•ﻌ•^ฅ**

[![license](https://img.shields.io/badge/MIT-3DA639?style=flat)](LICENSE)

</div>

A Claude Code marketplace is a list, not a container: every entry here points at the repository that holds the skill, so each one keeps its own gate, its own changelog and its own issues, while you add the list once

```
/plugin marketplace add rokokol/skills
/plugin install tests@rokokol-skills
```

One marketplace rather than one per skill, because a marketplace is addressed by the name it declares and a user can register only one per name — a second repository declaring `rokokol-skills` would replace the first, silently, and the plugin installed from it would go with it

Every skill here is also a plain directory with a `SKILL.md`, which is an open format more than one agent reads. Each repository's readme carries the other ways in: `npx skills add`, or a clone straight into whichever skills directory your agent reads

An entry's `name` is an identifier and its `description` is not. The name is checked against the frontmatter of the skill it points at, because `/plugin install <name>@rokokol-skills` addresses the plugin by it and a rename breaks the install silently. The description is written for someone reading a list of plugins and deliberately differs from the skill's own: a skill's description is matched by meaning against what a user says, which makes it long and full of triggers, and most of them open on "What it is". Reading one against the other and closing the gap is a change for the worse

## What is listed

| Plugin | What it is |
|---|---|
| [3x-ui-admin](https://github.com/rokokol/3x-ui-admin-skill) | administer a 3x-ui panel over its HTTP API |
| [ai-commit-trailers](https://github.com/rokokol/ai-commit-trailers-skill) | which AI-disclosure trailer a commit carries, and why never `Co-authored-by` |
| [bash-best-practices](https://github.com/rokokol/bash-best-practices-skill) | a standard for shell utilities, with a checker that holds the help to the code |
| [ci](https://github.com/rokokol/ci-skill) | CI that stays green for the right reasons |
| [close-session](https://github.com/rokokol/close-session-skill) | close a working session and leave nothing hanging |
| [code-comments](https://github.com/rokokol/code-comments-skill) | what a comment in code says, and a checker that reads comments out of the syntax tree |
| [companion](https://github.com/rokokol/companion-skill) | a template for an assistant persona and the dossiers behind it |
| [contributing](https://github.com/rokokol/contributing-skill) | everything published under your GitHub identity, approved one payload at a time |
| [create-readme](https://github.com/rokokol/create-readme-skill) | the house rules for a readme |
| [huix-standard](https://github.com/rokokol/huix-standard-skill) | making Nix-flake-first repositories installable without Nix |
| [maintainer-docs](https://github.com/rokokol/maintainer-docs-skill) | where repository-wide maintainer rationale lives |
| [obsidian-cli](https://github.com/rokokol/obsidian-cli-skill) | drive a running Obsidian vault from the terminal |
| [papers](https://github.com/rokokol/papers-skill) | find, read and compare scientific papers without spending the context on them |
| [skill-authoring](https://github.com/rokokol/skill-authoring-skill) | the house rules for text an agent loads whole, and the gate that checks a skill |
| [super-productivity](https://github.com/rokokol/super-productivity-skill) | manage Super Productivity tasks through its Local REST API |
| [tests](https://github.com/rokokol/tests-skill) | tests that mean something when they are green |
| [versioning](https://github.com/rokokol/versioning-skill) | what a repository says about itself over time |

## Tests

The manifest is the whole product here, and a manifest that does not parse breaks `/plugin` for everyone who added it, so [`check.sh`](check.sh) is what the gate runs

```sh
./check.sh manifest   # what a file alone decides; no network, safe on a pull request
./check.sh remote     # whether a stranger can clone every repository listed
```

`manifest` proves each of its own rules able to fail before it reads the real file: nine copies, each with one thing broken, each of which must be rejected for its own reason. `remote` is a detector rather than a gate — a repository going private is not a change to this one — so it runs on a schedule and on the default branch, asks GitHub anonymously, and starts with a control request to a repository known to be public, since a run where everything fails for one reason would otherwise read as everything being private
