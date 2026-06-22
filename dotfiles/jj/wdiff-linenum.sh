#!/usr/bin/env bash
# jj external diff formatter: git word-diff (plain markers) with a jj-style
# old/new line-number gutter. Invoked by `[merge-tools.wdiff]` with $left/$right.
#
# Colors mirror jj's colors."diff added"/"diff removed" (#a6e3a1 / #f38ba8);
# keep these in sync with ~/.jjconfig.toml if you retune them.
set -u

left=$1
right=$2

git -c color.diff.new='#a6e3a1' -c color.diff.old='#f38ba8' \
  diff --no-index --word-diff=plain --word-diff-regex=. --color=always -- "$left" "$right" |
awk '
  BEGIN {
    esc  = sprintf("%c", 27)
    dim  = esc "[2m"
    red  = esc "[38;2;243;139;168m"
    grn  = esc "[38;2;166;227;161m"
    rst  = esc "[0m"
    ANSI = esc "\\[[0-9;]*m"
  }
  { line = $0; plain = line; gsub(ANSI, "", plain) }

  # Hunk header: reset old/new counters, pass the line through.
  plain ~ /^@@ / {
    h = plain; sub(/^@@ -/, "", h)
    split(h, parts, " ")            # parts[1]="81,6"  parts[2]="+81,7"
    split(parts[1], o, ",")
    np = parts[2]; sub(/^\+/, "", np)
    split(np, n, ",")
    old = o[1] + 0; new = n[1] + 0
    print line; next
  }

  # File headers: pass through, no gutter.
  plain ~ /^(diff --git|index |--- |\+\+\+ |old mode|new mode|new file|deleted file|similarity|dissimilarity|rename |copy |Binary files)/ {
    print line; next
  }

  # Content: prepend the gutter. A line is single-sided (exists in only one
  # version) iff git wrapped its *entire* content in one marker run, i.e. no
  # unchanged text remains outside the markers. Inline word edits leave context
  # outside the markers, so they exist on both sides and take both numbers.
  {
    hasadd = index(plain, "{+")
    hasdel = index(plain, "[-")
    rem = plain
    gsub(/\{\+([^+]|\+[^}])*\+\}/, "", rem)
    gsub(/\[-([^-]|-[^]])*-\]/, "", rem)
    single = (rem == "")
    ln = ""; rn = ""
    if (single && hasadd && !hasdel)      { rn = new; new++ }            # added line
    else if (single && hasdel && !hasadd) { ln = old; old++ }            # deleted line
    else                                  { ln = old; rn = new; old++; new++ }
    printf "%s%s%4s%s %s%s%4s%s: %s\n", dim, red, ln, rst, dim, grn, rn, rst, line
  }
'
