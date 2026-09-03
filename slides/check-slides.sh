#!/usr/bin/env bash
#
# G.A Design — 面から溢れていないかを機械で見る。
#
#   slides/check-slides.sh <html-file>
#
# 各面を順に出して、中身が面の内寸を超えていないかを測る。
# 溢れていれば診断を出して 1 で終わる。溢れが無ければ 0。使い方と入出力の間違いは 2。
#
# 目で見る検査だと、下端の署名行に重なる程度の溢れを見落とす。ここは機械に任せる。
# 図の生成器が node で済むのは座標が決まった計算だから。溢れは実際の版と書体で
# しか出ないので、ブラウザ以外に測る手が無い。

set -uo pipefail

USAGE="使い方: slides/check-slides.sh <html-file>

  面から溢れた中身があるかを見る。0 = 溢れ無し / 1 = 溢れている / 2 = 使い方・入出力"

die() { printf '%s\n' "$2" >&2; exit "$1"; }

INPUT="${1:-}"
[[ -z "$INPUT" ]] && die 2 "入力が無い

$USAGE"
[[ $# -gt 1 ]] && die 2 "入力は1つだけ: $1 と $2

$USAGE"
[[ -f "$INPUT" ]] || die 2 "読めない入力: $INPUT"

CHROME=""
for c in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium"; do
  [[ -x "$c" ]] && CHROME="$c" && break
done
[[ -z "$CHROME" ]] && die 2 "Chrome / Chromium が /Applications に見つからない。"

INPUT_ABS="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"
WORK="$(dirname "$INPUT_ABS")/.gad-probe-$$"
trap 'rm -f "$WORK.html" "$WORK.dom"' EXIT

# 測る仕掛けを末尾に足した写しを、入力と同じ場所へ置く。
# 相対で読んでいる CSS と JS が、写しからも同じように引けるようにするため。
python3 - "$INPUT_ABS" "$WORK.html" <<'PY' || die 2 "検査用の写しを作れない($INPUT に </body> が無い)"
import pathlib, sys
src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
text = src.read_text()
if "</body>" not in text:
    sys.exit(1)
dst.write_text(text.replace("</body>", """
<script>
/*
 * 溢れは、面の内側と中身の外形を突き合わせて測る。
 *
 * scrollHeight は使えない。表紙は中身を上下中央に置くので、溢れは上と下へ
 * 等しく出る。上へ出たぶんは scrollHeight に入らないため、同じ中身でも表紙
 * だけ半分しか報告されない(実測: ふつうの面 151px に対して表紙 73px)。
 *
 * 下端の署名行は絶対配置で面の余白の上に載るので、外形から外す。
 */
const spill = (el) => {
  const box = el.getBoundingClientRect();
  const cs = getComputedStyle(el);
  const kids = Array.from(el.children)
    .filter((c) => getComputedStyle(c).position !== 'absolute')
    .map((c) => c.getBoundingClientRect());
  if (!kids.length) return 0;
  const above = (box.top + parseFloat(cs.paddingTop)) - Math.min(...kids.map((r) => r.top));
  const below = Math.max(...kids.map((r) => r.bottom)) - (box.bottom - parseFloat(cs.paddingBottom));
  return Math.round(Math.max(0, above) + Math.max(0, below));
};

const out = [];
document.querySelectorAll('.gad-slide').forEach((el, i) => {
  const was = el.classList.contains('is-current');
  el.classList.add('is-current');
  const over = spill(el);
  if (over > 0) {
    const head = el.querySelector('h1, h2');
    const row = el.querySelector('.gad-table tr');
    const unit = row ? row.getBoundingClientRect().height
                     : parseFloat(getComputedStyle(el).lineHeight);
    const cs = getComputedStyle(el);
    const inner = Math.round(el.getBoundingClientRect().height
      - parseFloat(cs.paddingTop) - parseFloat(cs.paddingBottom));
    out.push({ n: i + 1, title: head ? head.textContent.trim() : '',
               over, inner, content: inner + over,
               unit: Math.round(unit), kind: row ? '表の行' : '本文の行' });
  }
  if (!was) el.classList.remove('is-current');
});
document.body.dataset.gadOverflow = JSON.stringify(out);
</script>
</body>"""))
PY

"$CHROME" --headless=new --disable-gpu --virtual-time-budget=6000 \
  --window-size=1600,900 --dump-dom "file://$WORK.html" > "$WORK.dom" 2>/dev/null
[[ -s "$WORK.dom" ]] || die 2 "Chrome が何も返さない: $INPUT"

python3 - "$INPUT" "$WORK.dom" <<'PY'
import html, json, pathlib, re, sys

name, dom = sys.argv[1], pathlib.Path(sys.argv[2]).read_text()
m = re.search(r'data-gad-overflow="([^"]*)"', dom)
if not m:
    print(f"面の測定が返ってこない: {name}", file=sys.stderr)
    raise SystemExit(2)

over = json.loads(html.unescape(m.group(1)))
if not over:
    print(f"面から溢れている面は無い: {name}")
    raise SystemExit(0)

# 診断は図の生成器と同じ4つを持つ — 規則id・場所・数値・直し方
for d in over:
    subject = f" 「{d['title']}」" if d["title"] else ""
    lines = d["over"] / d["unit"]
    print(f"[slide/overflow] /slide/{d['n']}{subject} +{d['over']}px"
          f"(中身 {d['content']}px / 面の内寸 {d['inner']}px)", file=sys.stderr)
    print(f"    直し方: あと {d['over']}px 縮める。{d['kind']}"
          f"{lines:.1f}行ぶんにあたる。削れないなら面を分ける", file=sys.stderr)
raise SystemExit(1)
PY
