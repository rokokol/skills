#!/usr/bin/env bash
# The gate for this repository. The manifest is the whole product here: a file that does
# not parse, or that names a repository nobody can clone, breaks /plugin for everyone who
# added this marketplace, and it breaks silently — the reader sees an install refuse
# Needs bash 3.2, jq and POSIX tools, so it runs unchanged under the bash macOS ships.
# The remote mode needs git and reaches the network, which is why it is a mode of its own
set -euo pipefail

usage() {
  cat <<'EOF'
check.sh — hold the marketplace manifest to what /plugin will read, and prove each of
these checks able to fail on a planted copy before it reads the real one

  check.sh [manifest|remote|all]

manifest reads .claude-plugin/marketplace.json and decides what a file alone decides:
that it parses, that it carries the fields Claude Code requires, that no two entries
claim one name, that every entry names a github repository, and that the entries are in
order. It touches no network, so it is safe on a pull request

remote asks whether every repository the manifest names is there and readable. It
reaches the network, so it belongs on a schedule and on the default branch rather than
in a pull request: a repository going private is not a change to this one

all, the default, is both

Exit 0 when everything holds, 1 on a finding, 2 on an unknown mode or a missing tool
EOF
}

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$HERE"

manifest=.claude-plugin/marketplace.json

fail() {
  echo "check: $1" >&2
  exit 1
}
die() {
  echo "check: $1" >&2
  exit 2
}

work=$(mktemp -d "${TMPDIR:-/tmp}/check.XXXXXX")
trap 'rm -rf "$work"' EXIT

mode="${1:-all}"
case "$mode" in
  manifest | remote | all) ;;
  -h | --help | help)
    usage
    exit 0
    ;;
  *) die "no such mode: '$mode' — manifest, remote or all" ;;
esac

command -v jq >/dev/null || die "jq is missing, and every check here reads the manifest through it"

# read_manifest FILE -> nothing, or the first thing wrong with it on stdout. One jq
# program rather than one per rule: the rules all read the same document, and a second
# program is a second parse of a file that may not parse at all
read_manifest() {
  jq -r '
    def problem:
      if type != "object" then "the manifest is not a JSON object"
      elif (.name | type) != "string" or (.name | length) == 0 then "the manifest has no name, and /plugin install addresses the marketplace by it"
      elif (.owner | type) != "object" then "the manifest has no owner object"
      elif (.plugins | type) != "array" then "the manifest has no plugins array"
      elif (.plugins | length) == 0 then "the manifest lists no plugin"
      else
        ([.plugins[] | select((.name | type) != "string" or (.name | length) == 0)] | length) as $unnamed
        | ([.plugins[].name] | length) as $n
        | ([.plugins[].name] | unique | length) as $u
        | [.plugins[].name] as $names
        | ([.plugins[] | select((.source | type) != "object" or (.source.repo | type) != "string" or (.source.repo | test("^[^/ ]+/[^/ ]+$") | not))] | length) as $sourceless
        | ([.plugins[] | select((.description | type) != "string" or (.description | length) == 0)] | length) as $mute
        | if $unnamed > 0 then "\($unnamed) entr(y|ies) with no name"
          elif $n != $u then "two entries claim one name: \($names | group_by(.) | map(select(length > 1) | .[0]) | join(", "))"
          elif $sourceless > 0 then "\($sourceless) entr(y|ies) whose source is not a github owner/repo"
          elif $mute > 0 then "\($mute) entr(y|ies) with no description, which is all a reader sees before installing"
          elif $names != ($names | sort) then "the entries are out of order; sorted by name, a duplicate cannot hide"
          else ""
          end
      end;
    problem
  ' "$1"
}

check_manifest() {
  echo "== the manifest parses and says what /plugin needs"
  [[ -f "$manifest" ]] || fail "$manifest is missing — there is no marketplace without it"
  jq -e . "$manifest" >/dev/null 2>"$work/jq.err" ||
    fail "$manifest is not valid JSON: $(tr -d '\n' <"$work/jq.err")"
  found=$(read_manifest "$manifest")
  [[ -z "$found" ]] || fail "$manifest: $found"
  count=$(jq '.plugins | length' "$manifest")
  echo "   $count plugins, each named once, each pointing at a github repository"

  echo "== each of those checks can go red"
  # A copy with one thing broken must be rejected, and for that thing's own reason. A
  # check nothing has ever caught is a decoration, and this file is the whole product
  planted=0
  refuses() { # refuses NAME JQ-EDIT EXPECTED-FRAGMENT
    local name="$1" edit="$2" want="$3" out
    jq "$edit" "$manifest" >"$work/$name.json"
    out=$(read_manifest "$work/$name.json")
    [[ -n "$out" ]] || fail "a manifest with $name was accepted — that check proves nothing"
    case "$out" in
      *"$want"*) ;;
      *) fail "a manifest with $name was rejected for the wrong reason: $out" ;;
    esac
    planted=$((planted + 1))
  }
  refuses "no name" 'del(.name)' "no name"
  refuses "no owner" 'del(.owner)' "no owner"
  refuses "no plugins array" 'del(.plugins)' "no plugins array"
  refuses "an empty plugins array" '.plugins = []' "lists no plugin"
  refuses "a nameless entry" '.plugins[0] |= del(.name)' "with no name"
  refuses "a duplicated name" '.plugins[1].name = .plugins[0].name' "claim one name"
  refuses "a source that is not a repository" '.plugins[0].source.repo = "not-a-repo"' "not a github owner/repo"
  refuses "an entry with no description" '.plugins[0] |= del(.description)' "no description"
  refuses "entries out of order" '.plugins |= reverse' "out of order"
  # The faithful copy passes, or the planted ones prove nothing but that the reader works
  [[ -z "$(read_manifest "$manifest")" ]] ||
    fail "the unedited manifest was rejected — the planted copies prove nothing"
  echo "   $planted planted defects caught, the unedited manifest accepted"
}

check_remote() {
  echo "== every repository the manifest names is public"
  command -v git >/dev/null || die "git is missing, and the remote mode asks github for each repository"
  # A control, before the answers it qualifies: a run where every request fails for one
  # reason — no network, a proxy, a rate limit — would otherwise read as every repository
  # being private
  GIT_TERMINAL_PROMPT=0 git -c credential.helper= \
    ls-remote --exit-code -h https://github.com/github/gitignore >/dev/null 2>&1 ||
    die "a repository known to be public could not be read — this run would say nothing about the manifest"
  local missing=0 repo
  while IFS= read -r repo; do
    # Anonymously, and with no prompt: whoever runs this may have read access the reader
    # of the marketplace does not, and a private repository answers a signed-in request
    # exactly as a public one does. The question is what a stranger can clone
    if GIT_TERMINAL_PROMPT=0 git -c credential.helper= \
      ls-remote --exit-code -h "https://github.com/$repo" >/dev/null 2>&1; then
      echo "   ok   $repo"
    else
      echo "   gone $repo" >&2
      missing=$((missing + 1))
    fi
  done < <(jq -r '.plugins[].source.repo' "$manifest")
  ((missing == 0)) ||
    fail "$missing repositor(y|ies) the manifest names are private or gone — an entry a stranger cannot clone refuses at install"

  echo "== each entry is named as the skill names itself"
  # /plugin install addresses the plugin by the entry's name, and the skill answers to the
  # name in its own frontmatter. A skill renamed in its own repository leaves this file
  # pointing at a name nothing answers to, and the install refuses without saying why
  command -v curl >/dev/null || die "curl is missing, and the frontmatter is read over https"
  local wrong=0 entry repo want got
  while IFS=$'\t' read -r entry repo; do
    # The frontmatter only: a name: line in the body is prose, and the first block is what
    # an agent reads the skill's own name from. The reader takes the first match and then
    # keeps reading — an awk that exits early leaves curl writing into a closed pipe, and
    # under pipefail that SIGPIPE becomes the status of a pipeline that did its job
    got=$(curl -sfL --max-time 20 "https://raw.githubusercontent.com/$repo/HEAD/SKILL.md" |
      awk '/^---[ \t]*$/ { f++; next }
           f == 1 && /^name:/ && !seen { sub(/^name:[ \t]*/, ""); gsub(/^"|"$/, ""); print; seen = 1 }') || got=""
    want="$entry"
    if [[ "$got" == "$want" ]]; then
      echo "   ok   $entry"
    else
      echo "   $repo calls its skill '${got:-nothing readable}', this file calls it '$want'" >&2
      wrong=$((wrong + 1))
    fi
  done < <(jq -r '.plugins[] | "\(.name)\t\(.source.repo)"' "$manifest")
  ((wrong == 0)) ||
    fail "$wrong entr(y|ies) name a skill by a name it does not answer to"
}

case "$mode" in
  manifest) check_manifest ;;
  remote) check_remote ;;
  all)
    check_manifest
    check_remote
    ;;
esac

echo
echo "check: everything holds"
