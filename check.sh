#!/usr/bin/env bash
#
# G.A Design — 自己検査
#
#   ./check.sh
#
# STYLE-GUIDE.md が主張していることが、実際のファイルでも成り立つかを確かめる。
# 1つでも崩れていたら 1 で終わる。python3 のほかに要るものは無い。

set -uo pipefail
cd "$(dirname "$0")"

python3 - "$@" <<'PY'
import re, sys, pathlib

fail = []
def check(name, ok, detail=""):
    print(f"{'OK  ' if ok else 'NG  '}{name}{('  — ' + detail) if (detail and not ok) else ''}")
    if not ok:
        fail.append(name)

tokens = pathlib.Path("tokens.css").read_text()
doc    = pathlib.Path("document.css").read_text()
html   = pathlib.Path("component-samples.html").read_text()
guide  = pathlib.Path("STYLE-GUIDE.md").read_text()

HEX = re.compile(r'#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})(?![0-9a-zA-Z])')

def strip_comments(css):
    return re.sub(r'/\*.*?\*/', '', css, flags=re.S)

# 1. 値は tokens.css にしかない
raw = HEX.findall(strip_comments(doc)) + re.findall(r'\brgba?\(', strip_comments(doc))
check("document.css に生の色が無い", not raw, f"見つかった: {raw}" if raw else "")

# 2. 見本にも生の色が無い（色を見せているコードの見本だけ除く）
body = re.sub(r'<pre class="gad-code">.*?</pre>', '', html, flags=re.S)
raw = HEX.findall(body) + re.findall(r'\brgba?\(', body)
check("見本に生の色が無い", not raw, f"見つかった: {raw}" if raw else "")

# 3. document.css が引く変数は全部 tokens.css にある
used     = set(re.findall(r'var\((--gad-[a-z0-9-]+)\)', doc))
declared = set(re.findall(r'^\s*(--gad-[a-z0-9-]+)\s*:', tokens, re.M))
check("document.css が引く変数が全部 tokens.css にある",
      not (used - declared), f"未定義: {sorted(used - declared)}")
check("tokens.css に使われていない宣言が無い",
      not (declared - used), f"未使用: {sorted(declared - used)}")

# 4. 見本が使う class は全部 document.css で定義されている（逆も）
shown   = {c for m in re.finditer(r'class="([^"]+)"', html)
             for c in m.group(1).split() if c.startswith("gad-")}
defined = set(re.findall(r'\.(gad-[a-z0-9-]+)', doc))
check("見本が使う class が全部 document.css にある",
      not (shown - defined), f"未定義: {sorted(shown - defined)}")
check("document.css の class が全部 見本に出ている",
      not (defined - shown), f"見本に無い: {sorted(defined - shown)}")

# 5. 部品12種が見本に全部ある
PARTS = {"署名行": ["gad-signature", "gad-foot"], "要約": ["gad-summary"], "目次": ["gad-toc"],
         "用語表": ["gad-glossary"], "引用": ["gad-quote"], "コード": ["gad-code"],
         "表": ["gad-table"], "図の枠": ["gad-figure"], "決定": ["gad-decided"],
         "未決": ["gad-open"], "注記": ["gad-note", "gad-alert"], "並置": ["gad-columns"]}
missing = [n for n, cs in PARTS.items() if not all(c in shown for c in cs)]
check(f"部品{len(PARTS)}種が見本に全部ある", not missing, f"欠け: {missing}")

# 6. STYLE-GUIDE の明暗差が tokens.css の値から計算し直しても一致する
def lum(h):
    h = h.lstrip('#')
    f = lambda v: v/12.92 if v <= 0.03928 else ((v+0.055)/1.055)**2.4
    r, g, b = (f(int(h[i:i+2], 16)/255) for i in (0, 2, 4))
    return 0.2126*r + 0.7152*g + 0.0722*b

def ratio(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return round((hi+0.05)/(lo+0.05), 2)

def token(name):
    m = re.search(rf'^\s*{re.escape(name)}\s*:\s*(#[0-9a-fA-F]{{6}})', tokens, re.M)
    assert m, f"tokens.css に {name} が無い"
    return m.group(1)

paper, inset = token("--gad-paper"), token("--gad-inset")

rows = re.findall(r'^\|\s*`(--gad-[a-z-]+)`\s*\|\s*`(#[0-9a-fA-F]{6})`\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|',
                  guide, re.M)
check("STYLE-GUIDE の墨の表が4段ある", len(rows) == 4, f"読めた行: {len(rows)}")
for name, hexv, w, i in rows:
    real = token(name)
    check(f"{name} の値が STYLE-GUIDE と tokens.css で同じ", real == hexv, f"{hexv} と {real}")
    check(f"{name} の白地への明暗差 {w}", ratio(real, paper) == float(w), f"実測 {ratio(real, paper)}")
    check(f"{name} の沈んだ地への明暗差 {i}", ratio(real, inset) == float(i), f"実測 {ratio(real, inset)}")

# 7. 有彩色2つ。本文中の数字も検算する
def prose(pattern, label):
    m = re.search(pattern, guide)
    check(f"STYLE-GUIDE に{label}の記述がある", bool(m))
    return m

m = prose(r'`--gad-sign`\s*`(#[0-9a-fA-F]{6})`[^—]*—\s*白地に\s*([\d.]+)', "署名の黄")
if m:
    check("--gad-sign の値が tokens.css と同じ", m.group(1) == token("--gad-sign"))
    check(f"--gad-sign の白地への明暗差 {m.group(2)}",
          ratio(token("--gad-sign"), paper) == float(m.group(2)),
          f"実測 {ratio(token('--gad-sign'), paper)}")
    check("--gad-sign は読ませる用途に使えない（4.5 未満）",
          ratio(token("--gad-sign"), paper) < 4.5)

m = prose(r'`--gad-alert`\s*`(#[0-9a-fA-F]{6})`[^—]*—\s*地として\s*([\d.]+)[^\d]+([\d.]+)', "危険の rose")
if m:
    alert = token("--gad-alert")
    check("--gad-alert の値が tokens.css と同じ", m.group(1) == alert)
    check(f"--gad-alert の地としての明暗差 {m.group(2)}",
          ratio(alert, paper) == float(m.group(2)), f"実測 {ratio(alert, paper)}")
    check(f"--gad-alert に載る墨の明暗差 {m.group(3)}",
          ratio(token("--gad-ink"), alert) == float(m.group(3)),
          f"実測 {ratio(token('--gad-ink'), alert)}")

# 8. しきい値そのもの
check("文字に使う一番薄い墨が、沈んだ地でも 4.5 以上",
      ratio(token("--gad-ink-quiet"), inset) >= 4.5,
      f"{ratio(token('--gad-ink-quiet'), inset)}")
check("線と印が 3.0 以上", ratio(token("--gad-mark"), paper) >= 3.0,
      f"{ratio(token('--gad-mark'), paper)}")
check("--gad-alert に載せる墨が 4.5 以上",
      ratio(token("--gad-ink"), token("--gad-alert")) >= 4.5,
      f"{ratio(token('--gad-ink'), token('--gad-alert'))}")

print()
if fail:
    print(f"崩れている: {len(fail)} 件")
    for f in fail:
        print(f"  - {f}")
    sys.exit(1)
print("すべて成り立っている")
PY
