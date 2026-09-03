#!/usr/bin/env bash
#
# G.A Design — 自己検査
#
#   ./check.sh
#
# STYLE-GUIDE.md が主張していることが、実際のファイルでも成り立つかを確かめる。
# 1つでも崩れていたら 1 で終わる。要るのは python3 と node だけ。
# node は figure/ の生成器を、実際に走らせて確かめるために使う。

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
         "表": ["gad-table"], "図の枠": ["gad-figure"], "番号の付く並び": ["gad-ordered"],
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

# 9. 図の系列5色。文書へ漏れていないこと、明暗差が STYLE-GUIDE と合うこと
figure = pathlib.Path("tokens-figure.css").read_text()

leaked = re.findall(r'var\(--gad-series-\d\)', doc)
check("document.css が図の色を参照していない", not leaked, f"見つかった: {leaked}")
check("見本が図の色を参照していない",
      not re.findall(r'--gad-series-\d', html), "見本は文書の側なので図の色を使わない")

def figure_token(name):
    m = re.search(rf'^\s*{re.escape(name)}\s*:\s*(#[0-9a-fA-F]{{6}})', figure, re.M)
    assert m, f"tokens-figure.css に {name} が無い"
    return m.group(1)

series = re.findall(
    r'^\|\s*`(--gad-series-\d)`\s*\|[^|]*\|\s*`(#[0-9a-fA-F]{6})`\s*\|'
    r'\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|', guide, re.M)
check("STYLE-GUIDE の系列の表が5色ある", len(series) == 5, f"読めた行: {len(series)}")

ink = token("--gad-ink")
for name, hexv, w, i, k in series:
    real = figure_token(name)
    check(f"{name} の値が STYLE-GUIDE と tokens-figure.css で同じ", real == hexv, f"{hexv} と {real}")
    check(f"{name} の白地への明暗差 {w}", ratio(real, paper) == float(w), f"実測 {ratio(real, paper)}")
    check(f"{name} の沈んだ地への明暗差 {i}", ratio(real, inset) == float(i), f"実測 {ratio(real, inset)}")
    check(f"{name} に載る墨の明暗差 {k}", ratio(ink, real) == float(k), f"実測 {ratio(ink, real)}")
    check(f"{name} は印として置ける（沈んだ地でも 3.0 以上）", ratio(real, inset) >= 3.0)
    check(f"{name} の上に墨を載せられる（4.5 以上）", ratio(ink, real) >= 4.5)

# 白黒で潰れる事実が STYLE-GUIDE に書いてあること（形と併用する根拠）
check("STYLE-GUIDE に、色だけで区別しない理由が書いてある",
      "二重の手がかり" in guide and "白黒" in guide)

# 10. 図の生成器。STYLE-GUIDE の「図の記法」が、figure/ の実物と合っているか
import json, subprocess, tempfile, os, shutil

NODE = shutil.which("node")

class NoNode:
    """node が無いときの、走らせなかったことを表す結果。"""
    returncode, stdout, stderr = 127, "", "node が PATH に無い"

def run(args):
    return subprocess.run(args, capture_output=True, text=True) if NODE else NoNode()

def node(js):
    return run([NODE, "-e", js])

def deliver(*args):
    return run([NODE, "figure/deliver.mjs", *args])

check("node がある", NODE is not None, "figure/ の生成器を走らせるのに要る")

probe = node('import("./figure/render.mjs").then(m=>console.log(JSON.stringify({'
             'spec:m.SPEC,kinds:m.KINDS,gaps:m.schemaGaps(),'
             'wide:m.toPx(m.SPEC.capWide),hex:m.toPx(m.SPEC.capHex)})))')
check("figure/render.mjs が読める", probe.returncode == 0,
      (probe.stderr.strip().splitlines() or ["理由が出ていない"])[-1])

if probe.returncode == 0:
    info  = json.loads(probe.stdout)
    spec  = info["spec"]
    kinds = info["kinds"]

    schema = json.loads(pathlib.Path("figure/schema.json").read_text())
    check("figure/schema.json が、render.mjs の検査器で読める書き方だけでできている",
          not info["gaps"], " / ".join(info["gaps"]))

    # 守りそのものを試す。名前だけでなく、値の形のずれも捕まえられるか
    probes = node('import("./figure/render.mjs").then(m=>console.log(JSON.stringify(['
                  '{name:"additionalProperties を schema で書く",node:{additionalProperties:{type:"string"}}},'
                  '{name:"items をタプル形で書く",node:{items:[{},{}]}},'
                  '{name:"type に integer を書く",node:{type:"integer"}},'
                  '{name:"$ref の隣にキーワードを書く",node:{$ref:"#/$defs/kind",minLength:1}},'
                  '{name:"引けない $ref を書く",node:{$ref:"#/$defs/nowhere"}},'
                  '{name:"実装していないキーワードを書く",node:{pattern:"^a$"}},'
                  '{name:"schema でないものを置く",node:{properties:{x:42}}}'
                  '].map(c=>({name:c.name,gaps:m.schemaGaps(c.node).length})))))')
    if probes.returncode == 0:
        for c in json.loads(probes.stdout):
            check(f"守りが捕まえる: {c['name']}", c["gaps"] > 0, "素通りした")
    else:
        check("守りそのものを試せる", False, probes.stderr.strip().splitlines()[-1][:160])
    check("schema の kind が4種", len(schema["$defs"]["kind"]["enum"]) == 4,
          f"{schema['$defs']['kind']['enum']}")
    check("schema の kind と render.mjs の KINDS が同じ",
          set(schema["$defs"]["kind"]["enum"]) == set(kinds),
          f"{sorted(schema['$defs']['kind']['enum'])} と {sorted(kinds)}")
    check("schema の枝の上限が SPEC と同じ",
          schema["$defs"]["node"]["properties"]["fork"]["maxItems"] == spec["maxSiblings"])
    check("schema が caption を必須にしている", "caption" in schema["required"])

    # STYLE-GUIDE の種別の表
    rows = re.findall(r'^\|\s*`(step|branch|outside|store)`\s*\|\s*(\S+)\s*\|\s*(\S+)\s*\|\s*(\d+)\s*字幅\s*\|',
                      guide, re.M)
    check("STYLE-GUIDE の種別の表が4行ある", len(rows) == 4, f"読めた行: {len(rows)}")
    for name, ja, shape, cap in rows:
        k = kinds[name]
        check(f"{name} の呼び名・形・上限が render.mjs と同じ",
              (ja, shape, int(cap)) == (k["ja"], k["shape"], k["cap"]),
              f"STYLE-GUIDE は {(ja, shape, int(cap))}、render.mjs は {(k['ja'], k['shape'], k['cap'])}")

    # STYLE-GUIDE の寸法の表
    SIZES = {"箱": ["boxW", "boxH"], "縦の間隔": ["gapV"], "横の間隔": ["gapH"],
             "箱の内側の余白": ["padX"], "六角形の尖り": ["hexPoint"], "円筒の楕円": ["cylinderRy"],
             "矢印の頭": ["arrow"], "ノードの上限": ["maxNodes"], "横に並ぶ枝": ["maxSiblings"]}
    written = dict(re.findall(r'^\|\s*(箱|縦の間隔|横の間隔|箱の内側の余白|六角形の尖り|円筒の楕円|矢印の頭|ノードの上限|横に並ぶ枝)\s*\|\s*(.+?)\s*\|\s*$',
                              guide, re.M))
    check("STYLE-GUIDE の寸法の表が9行ある", len(written) == 9, f"読めた行: {sorted(written)}")
    for label, keys in SIZES.items():
        if label not in written:
            continue
        nums = [int(n) for n in re.findall(r'\d+', written[label])]
        check(f"寸法「{label}」が render.mjs の SPEC と同じ",
              nums == [spec[k] for k in keys],
              f"STYLE-GUIDE は {nums}、SPEC は {[spec[k] for k in keys]}")

    # 数字の裏取り。箱に収まること、本文の幅に収まること
    inner     = spec["boxW"] - 2 * spec["padX"]
    inner_hex = spec["boxW"] - 2 * spec["hexPoint"] - 2 * spec["padX"]
    row3      = 3 * spec["boxW"] + 2 * spec["gapH"]
    frame     = 640 - 2 - 48  # .gad-measure − 枠 1px×2 − .gad-figure-frame の余白 24px×2

    m = re.search(r'上限 10 字幅は ([\d.]+)px で、箱の内寸 (\d+)px に収まる', guide)
    check("STYLE-GUIDE に、上限 10 字幅が箱に収まる根拠が書いてある", bool(m))
    if m:
        check(f"10 字幅 = {m.group(1)}px", round(info["wide"], 1) == float(m.group(1)),
              f"実測 {round(info['wide'], 1)}")
        check(f"箱の内寸 = {m.group(2)}px", inner == int(m.group(2)), f"実測 {inner}")
        check("10 字幅が箱の内寸に収まる", info["wide"] <= inner, f"{info['wide']} > {inner}")

    m = re.search(r'六角形の 8 字幅は ([\d.]+)px で、尖りを引いた内寸 (\d+)px に収まる', guide)
    check("STYLE-GUIDE に、六角形の上限が内寸に収まる根拠が書いてある", bool(m))
    if m:
        check(f"8 字幅 = {m.group(1)}px", round(info["hex"], 1) == float(m.group(1)),
              f"実測 {round(info['hex'], 1)}")
        check(f"六角形の内寸 = {m.group(2)}px", inner_hex == int(m.group(2)), f"実測 {inner_hex}")
        check("8 字幅が六角形の内寸に収まる", info["hex"] <= inner_hex, f"{info['hex']} > {inner_hex}")

    m = re.search(r'3つ横に並べた (\d+)px が `\\?\.gad-figure-frame` の内寸 (\d+)px', guide)
    check("STYLE-GUIDE に、枝3つが本文に収まる根拠が書いてある", bool(m))
    if m:
        check(f"枝3つの幅 = {m.group(1)}px", row3 == int(m.group(1)), f"実測 {row3}")
        check(f".gad-figure-frame の内寸 = {m.group(2)}px", frame == int(m.group(2)), f"実測 {frame}")
        check("枝3つが本文の幅に収まる", row3 + 2 <= frame, f"{row3 + 2} > {frame}")

    # 図の語彙が document.css にある
    for cls in ("gad-node", "gad-link", "gad-arrow"):
        check(f".{cls} が document.css にある", f".{cls}" in doc)

    # STYLE-GUIDE に載せた診断の例が、生成器が実際に出す文と一字一句同じか
    m = re.search(r'```\n(\[label/width\] [^\n]*\n {4}直し方: [^\n]*)\n```', guide)
    check("STYLE-GUIDE に診断の例が載っている", bool(m))
    if m:
        written_diag = m.group(1)
        label = re.search(r'「(.+?)」 ', written_diag).group(1)
        with tempfile.TemporaryDirectory() as d:
            src = os.path.join(d, "doc-example.json")
            pathlib.Path(src).write_text(json.dumps({
                "figure": 1, "caption": "STYLE-GUIDE に載せている診断の例",
                "flow": [{"label": label, "kind": "branch",
                          "fork": [{"label": "直す"}, {"label": "作る"}]}]}, ensure_ascii=False))
            r = deliver(src)
            got = "\n".join(l for l in r.stderr.splitlines() if l.startswith("[label/width]") or l.startswith("    直し方:"))
        check("STYLE-GUIDE の診断の例が、実際の出力と同じ", got == written_diag,
              f"実際は:\n{got}")

    # deliver の終了コード。0 でないものを「出せた」と呼ばないための線引き
    good = "figure/examples/triage.json"
    with tempfile.TemporaryDirectory() as d:
        cases = [
            ("値の無い --out は 2 で終わる（黙って標準出力へ流さない）",
             [good, "--as", "page", "--out"], 2),
            ("値の無い --as は 2 で終わる", [good, "--as"], 2),
            ("書き出せない先は 2 で終わる（検査落ちの 1 と混ぜない）",
             [good, "--as", "page", "--out", os.path.join(d, "no", "such", "x.html")], 2),
            ("読めない入力は 2 で終わる", [os.path.join(d, "無い.json")], 2),
            ("正しい入力は 0 で終わる", [good], 0),
        ]
        for name, args, want in cases:
            r = deliver(*args)
            check(name, r.returncode == want, f"終了コード {r.returncode}（{want} のはず）")
        # 値を取り落としたときに、黙って書いたことにしない
        r = deliver(good, "--as", "page", "--out")
        check("値の無い --out のとき、中身を標準出力へ出さない", r.stdout == "",
              "標準出力に中身が出た")

    # 改行と制御文字は版付けを崩すので、検査で落とす
    with tempfile.TemporaryDirectory() as d:
        for name, doc in [
            ("ラベルの改行", {"figure": 1, "caption": "改行の検査",
                              "flow": [{"label": "あ\nい"}, {"label": "x"}]}),
            ("caption の改行", {"figure": 1, "caption": "改行\nする",
                                "flow": [{"label": "x"}]}),
        ]:
            src = os.path.join(d, "nl.json")
            pathlib.Path(src).write_text(json.dumps(doc, ensure_ascii=False))
            r = deliver(src)
            check(f"{name}が検査で落ちる", r.returncode == 1 and "[text/control]" in r.stderr,
                  f"終了コード {r.returncode} / {r.stderr.strip()[:120]}")

    # 見本の入力。broken.json は落ちるためにある
    inputs = sorted(p.name for p in pathlib.Path("figure/examples").glob("*.json"))
    check("figure/examples に入力がある", len(inputs) >= 2, f"{inputs}")
    ALLOWED = {"gad-figure", "gad-figure-frame", "gad-node", "gad-link", "gad-arrow"}
    for name in inputs:
        src = f"figure/examples/{name}"
        r = deliver(src)
        if name == "broken.json":
            check("broken.json は検査に落ちて 1 で終わる", r.returncode == 1, f"終了コード {r.returncode}")
            check("broken.json は落ちたとき何も書き出さない", r.stdout == "", "標準出力に中身が出た")
            check("broken.json の診断が規則idと直し方を持つ",
                  bool(re.search(r'^\[[a-z-]+/[a-z-]+\] ', r.stderr, re.M)) and "直し方:" in r.stderr,
                  r.stderr.strip()[:160])
            continue
        check(f"{name} が検査を通る", r.returncode == 0, r.stderr.strip()[:200])
        if r.returncode != 0:
            continue
        raw = HEX.findall(r.stdout) + re.findall(r'\brgba?\(', r.stdout)
        check(f"{name} の出力に生の色が無い", not raw, f"見つかった: {raw}")
        check(f"{name} の出力に色の presentation attribute が無い",
              not re.findall(r'\b(?:fill|stroke)="(?!none")', r.stdout),
              "SVG に色を直接書いている")
        used = {c for mm in re.finditer(r'class="([^"]+)"', r.stdout) for c in mm.group(1).split()}
        check(f"{name} の出力が使う class が図の語彙だけ", used <= ALLOWED,
              f"外にあるもの: {sorted(used - ALLOWED)}")
        # 通った出力は凍結する。作り直して同じでなければ、どちらかが手で触られている
        page_path = pathlib.Path(f"figure/examples/{name[:-5]}.html")
        check(f"{name} の出力 {page_path.name} が repo にある", page_path.exists())
        if page_path.exists():
            with tempfile.TemporaryDirectory() as d:
                fresh = os.path.join(d, "fresh.html")
                rr = deliver(src, "--as", "page", "--out", fresh)
                same = rr.returncode == 0 and pathlib.Path(fresh).read_text() == page_path.read_text()
                check(f"{page_path.name} が作り直しても同じ（凍結）", same,
                      f"作り直すと変わる。生成物を手で直したか、tokens.css / document.css を触った。"
                      f"直すなら node figure/deliver.mjs {src} --as page --out {page_path}")

print()
if fail:
    print(f"崩れている: {len(fail)} 件")
    for f in fail:
        print(f"  - {f}")
    sys.exit(1)
print("すべて成り立っている")
PY
