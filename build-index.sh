#!/usr/bin/env bash
# Regenerates index.html: a linked list of every .html file in this repo.
# Page titles come from each file's <title> tag, falling back to its path.
set -euo pipefail
cd "$(dirname "$0")"

OUT=index.html

# Pull the <title> out of an HTML file (first one wins), or echo nothing.
page_title() {
  tr '\n' ' ' < "$1" \
    | sed -n 's/.*<[Tt][Ii][Tt][Ll][Ee][^>]*>\(.*\)<\/[Tt][Ii][Tt][Ll][Ee]>.*/\1/p' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | head -c 200
}

# Full HTML escaping -- for paths/filenames, where every char is literal.
esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'; }

# Escaping for text lifted out of a <title> tag: it may already contain
# entities (&amp;, &#39;, &mdash;), so escape everything then restore those,
# otherwise "&amp;" would render as the literal text "&amp;".
esc_title() {
  esc | sed -E 's/&amp;(#[0-9]{1,7};|#[xX][0-9a-fA-F]{1,6};|[A-Za-z][A-Za-z0-9]{1,31};)/\&\1/g'
}

{
cat <<'HEAD'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>tech-analysis</title>
<style>
  :root {
    color-scheme: light dark;
    --bg: #fbfbf9;
    --fg: #1a1a18;
    --muted: #6b6b66;
    --line: #e2e2dc;
    --link: #2f5fd0;
    --card: #ffffff;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #16161a;
      --fg: #e9e9e4;
      --muted: #9a9a93;
      --line: #2c2c32;
      --link: #8ab0ff;
      --card: #1d1d22;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    padding: 3rem 1.25rem 5rem;
    background: var(--bg);
    color: var(--fg);
    font: 16px/1.6 ui-sans-serif, -apple-system, "Segoe UI", Roboto, sans-serif;
  }
  main { max-width: 46rem; margin: 0 auto; }
  h1 { font-size: 1.6rem; margin: 0 0 .25rem; letter-spacing: -.01em; }
  .sub { color: var(--muted); margin: 0 0 2.25rem; font-size: .95rem; }
  ul { list-style: none; margin: 0; padding: 0; }
  li {
    border: 1px solid var(--line);
    border-radius: 10px;
    background: var(--card);
    margin-bottom: .6rem;
  }
  li a {
    display: block;
    padding: .85rem 1rem;
    color: var(--link);
    text-decoration: none;
    font-weight: 550;
  }
  li a:hover { text-decoration: underline; }
  li a .path {
    display: block;
    color: var(--muted);
    font: .8rem/1.4 ui-monospace, SFMono-Regular, Menlo, monospace;
    font-weight: 400;
    margin-top: .15rem;
    word-break: break-all;
  }
  .empty { color: var(--muted); font-style: italic; }
  footer {
    margin-top: 2.5rem; padding-top: 1.25rem;
    border-top: 1px solid var(--line);
    color: var(--muted); font-size: .85rem;
  }
</style>
</head>
<body>
<main>
<h1>tech-analysis</h1>
<p class="sub">Static pages published from this repository.</p>
<ul>
HEAD

count=0
while IFS= read -r f; do
  rel="${f#./}"
  [ "$rel" = "$OUT" ] && continue
  t="$(page_title "$f")"
  [ -z "$t" ] && t="$rel"
  printf '<li><a href="%s">%s<span class="path">%s</span></a></li>\n' \
    "$(printf '%s' "$rel" | esc)" \
    "$(printf '%s' "$t" | esc_title)" \
    "$(printf '%s' "$rel" | esc)"
  count=$((count + 1))
done < <(find . -name '*.html' -not -path './.git/*' | LC_ALL=C sort)

if [ "$count" -eq 0 ]; then
  echo '<li class="empty" style="padding:.85rem 1rem">No pages yet — add an .html file and run ./sync.sh</li>'
fi

cat <<FOOT
</ul>
<footer>$count page(s) &middot; updated $(date -u '+%Y-%m-%d %H:%M UTC')</footer>
</main>
</body>
</html>
FOOT
} > "$OUT.tmp"

mv "$OUT.tmp" "$OUT"
echo "built $OUT"
