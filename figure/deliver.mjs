#!/usr/bin/env node
/*
 * G.A Design — 図を出す
 *
 *   node figure/deliver.mjs <入力.json> [--as snippet|page] [--out <書き出し先>]
 *
 * 検査を通らなければ何も書かず、診断を出して 1 で終わる。
 * 「書けた」と言えるのは 0 で終わったときだけ。
 *
 *   0  出せた
 *   1  入力が検査に落ちた
 *   2  使い方が違う / ファイルが読めない
 */

import { readFileSync, writeFileSync } from "node:fs";
import { validate, formatDiagnostics, snippet, page, render } from "./render.mjs";

const USAGE = `使い方: node figure/deliver.mjs <入力.json> [--as snippet|page] [--out <書き出し先>]

  --as snippet   文書へ貼り込む <figure class="gad-figure"> の断片(既定)
  --as page      単体で開ける HTML。tokens.css と document.css を埋め込む
  --out <path>   書き出し先。省くと標準出力へ出す

入力の形は figure/schema.json にある。`;

const die = (code, text) => {
  (code === 0 ? console.log : console.error)(text);
  process.exit(code);
};

const parse = (argv) => {
  const opts = { as: "snippet", out: null, input: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--help" || a === "-h") die(0, USAGE);
    else if (a === "--as") opts.as = argv[++i];
    else if (a === "--out") opts.out = argv[++i];
    else if (a.startsWith("-")) die(2, `知らない指定: ${a}\n\n${USAGE}`);
    else if (opts.input === null) opts.input = a;
    else die(2, `入力は1つだけ: ${opts.input} と ${a}\n\n${USAGE}`);
  }
  if (!opts.input) die(2, USAGE);
  if (!["snippet", "page"].includes(opts.as)) die(2, `--as は snippet か page: ${opts.as}`);
  return opts;
};

const opts = parse(process.argv.slice(2));

let input;
try {
  input = JSON.parse(readFileSync(opts.input, "utf8"));
} catch (e) {
  die(2, `入力が読めない: ${opts.input}\n  ${e.message}`);
}

const diagnostics = validate(input);
if (diagnostics.length) {
  die(1, `${opts.input} は検査に落ちた(${diagnostics.length} 件)\n\n${formatDiagnostics(diagnostics)}`);
}

const out = opts.as === "page" ? page(input) : `${snippet(input)}\n`;

if (opts.out) {
  writeFileSync(opts.out, out);
  const { nodes, width, height } = render(input);
  console.log(`${opts.out} へ書いた(${opts.as} / ノード ${nodes} / ${width}×${height}px)`);
} else {
  process.stdout.write(out);
}
