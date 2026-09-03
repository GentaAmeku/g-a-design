# Issue tracker: Local Markdown

チケットと仕様はこのリポジトリ内の markdown として `docs/todos/` に置き、git で版管理する。

## Conventions

- 案件ごとに1ディレクトリ: `docs/todos/<topic-slug>/`
- 仕様(PRD)は `docs/todos/<topic-slug>/spec.md`
- チケットは1件1ファイル: `docs/todos/<topic-slug>/issues/<NN>-<slug>.md`、依存順に `01` から。1ファイルにまとめない
- triage の状態は各ファイル先頭付近の `Status:` 行
- 各チケットは完了条件を2つに分けて持つ:
  - `検証:` 実行して exit code が出るコマンド。無ければ「なし」
  - `受入確認:` 人間が目で見て決めること。無ければ省く
- やり取りはファイル末尾の `## Comments` に追記する
- 1枚の予算は本文 300 字。`検証:` `受入確認:` と受入条件の箇条は、どれも構造の欄なので字数外

## When a skill says "publish to the issue tracker"

`docs/todos/<topic-slug>/` にファイルを作る(ディレクトリが無ければ作る)。

## When a skill says "fetch the relevant ticket"

参照されたパスのファイルを読む。

## Wayfinding operations

`/wayfinder` が使う。**map** が1ファイル、**child** がチケット1件1ファイル。

- **Map**: `docs/todos/<effort>/map.md` — Notes / Decisions-so-far / Fog
- **Child ticket**: `docs/todos/<effort>/issues/<NN>-<slug>.md`。`Type:` に `research`/`prototype`/`grilling`/`task`、`Status:` に `claimed`/`resolved`
- **Blocking**: 先頭付近の `Blocked by: NN, NN` 行。列挙先が全て `resolved` になれば解除
- **Frontier**: `docs/todos/<effort>/issues/` を走査し、open・未block・未claim のものを番号順に。最小番号が勝つ
- **Claim**: 作業前に `Status: claimed` にして保存
- **Resolve**: `## Answer` に答えを追記して `Status: resolved`。map.md の Decisions-so-far に要約とリンクを追記
