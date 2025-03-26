# CLIスクリプト制作コーディング指示書（Deno + TypeScript環境）

## 基本ルール
- Deno最新版とTypeScriptを使用し、型安全性を徹底。
- v1/ディレクトリ内は、ユーザーからの指示があるまで修正しない

## 推奨ディレクトリ構成
```
project-root/
├── scripts/         （スクリプトファイル配置）
│    ├── command/    （CLIサブコマンド実装）
│    ├── components/ （再利用可能な共通処理）
│    ├── schema/     （引数や出力のスキーマ定義）
│    ├── utils/      （汎用ユーティリティ関数）
│    ├── logs/       （ロガーインスタンスが作るログ）
│    ├── v1/         （古いコード）
│    ├── input/      （入力用CSVファイル）
│    └── output/     （処理結果CSVファイル出力）
├── logs/            （ログファイル出力）
└── deno.json
```
## ロギングについて

### 🔸 基本ルール

- ロギングには **`LogTape`** を利用します。
- 出力先は常に**コンソールとファイル両方**に設定します。
  - コンソールへのログはCLI引数で指定された`logLevel`に従います。
  - ファイルへのログは常に`info`（成功）以上のログのみを記録します。
- メッセージには必ずプレースホルダーを使用し、構造化データの内容が分かるようにします。
- 構造化ロギングを活用し、特にエラー時には詳細な情報を含めます。

### 🔸 ロガーユーティリティ（`utils/logger.ts`）

各コマンドファイルで共通に使用されるロガーユーティリティを配置しています。LogTapeを使用して、コンソールとファイルの両方にログを出力します。コンソールには見やすいカラー表示とプレースホルダー置換されたメッセージ、ファイルにはJSONL形式で構造化データを保存します。

### 🔸 コマンド側での利用方法

各コマンドファイルでは、以下のようにLogTapeロガーを初期化し、ロギングはこのインスタンスを利用して行います：

```typescript
import { logConfigure } from "@/scripts/utils/logger.ts";
import { getLogger } from "@logtape/logtape";
import { basename } from "jsr:@std/path";

const scriptName = basename(new URL(import.meta.url).pathname).replace(".ts", "");

const { logLevel } = result.data;

// LogTapeロガーの初期設定
const logFilePath = await logConfigure(scriptName, logLevel);

// ロガーの作成
const logger = getLogger(scriptName);

// 以下、loggerを使用したメイン処理
logger.info("処理 {processName} を開始しました", { processName: "データ検証" });

// プレースホルダーを使用した構造化ロギングの例
try {
  // 処理内容...
  logger.info("処理 {processName} が完了しました（所要時間: {duration}ms、処理件数: {count}件）", { 
    processName: "データ検証",
    duration: performance.now() - startTime,
    count: results.length
  });
} catch (error) {
  logger.error("処理 {processName} でエラーが発生しました: {errorMessage}", { 
    processName: "データ検証",
    errorMessage: error.message,
    error,
    stackTrace: error.stack,
    context: { /* 関連するコンテキスト情報 */ }
  });
}
```

### 🔸 プレースホルダーと構造化ロギングのガイドライン

LogTapeでは、メッセージ内にプレースホルダーを使用して構造化データの内容を表示できます。これにより、コンソール出力でも重要な情報が一目で分かるようになります。

#### プレースホルダーの使用方法

メッセージ内に `{キー名}` の形式でプレースホルダーを配置し、第2引数のオブジェクトに同じキー名で値を渡します：

```typescript
// プレースホルダーを使用したログ出力の例
logger.info("ファイル {fileName} を処理しています（サイズ: {fileSize}バイト）", {
  fileName: "data.csv",
  fileSize: 1024,
  processId: "abc-123" // メッセージに表示されないが構造化データとして記録される
});
```

#### エラーログのガイドライン

エラーログには必ずプレースホルダーを使用し、エラーの内容が分かるようにしてください：

```typescript
// エラー情報を詳細に記録する例
logger.error("CSVファイル {filePath} の読み込みに失敗しました: {errorMessage}", {
  filePath: inputFilePath,
  errorMessage: error.message,
  fileSize: fileStats.size,
  error: error,
  stack: error.stack,
  userId: currentUser.id,
  timestamp: new Date().toISOString()
});
```

- **エラーログには必ず以下の情報を含める**：
  - エラーメッセージ（`error.message`）をプレースホルダーで表示
  - 関連するファイルパスやIDをプレースホルダーで表示
  - スタックトレース（`error.stack`）を構造化データとして記録
  - 関連するコンテキスト情報（操作内容、パラメータなど）

- **プレースホルダーと構造化データの命名規則**：
  - キー名はキャメルケースで統一（例：`userId`, `fileSize`）
  - プレースホルダーに使用するキーは、メッセージ内で意味が分かる名前にする
  - 一般的な情報には標準的な名前を使用（`error`, `message`, `timestamp`など）
  - 複雑なオブジェクトは入れ子にせず、フラットな構造を優先

### 🔸 ログレベルのガイドライン

- `debug`: 開発用の詳細ログ
- `info`: 通常の成功ログ（処理開始や終了）
- `warn`: 注意すべき状態や推奨されない処理
- `error`: 処理が失敗した、または障害時に記録

## Args引数管理

### 📌 ライブラリ設定ルール（import map）

Denoの`deno.jsonc`において、npmライブラリを一元管理します。zodcliとプロジェクトで使用するZodのバージョンを明確に分離します。

#### 🔹 import mapの例（`deno.jsonc`）

```jsonc
{
  "imports": {
    "@mizchi/zodcli": "jsr:@mizchi/zodcli@^0.2.0",
    "zod": "npm:zod@^3.24.2",
    "zodcli-zod": "npm:zod@3.22.4"
  }
}
```

### 📌 引数スキーマの定義

引数スキーマはZodを使って定義します。各コマンドに共通する引数（Solana関連、バッチ処理用chunkなど）は、予め定義したスキーマをスプレッド演算子（...）を用いて統合します。
引数スキーマは、 schema/ ディレクトリに作っています。 command においては、 schemaに作ったものをimport してください。
base schema は必ずインポートしてください。

- base-args-schema.ts 共通引数スキーマ
- solana-args-schema.ts Solana 通信用引数スキーマ
- batch-args-schema.ts CSV 処理用バッチスキーマ


#### 🔹 Base基本スキーマ（`schema/base-args-schema.ts`）

```typescript
import { z } from "zodcli-zod";

export const BaseArgsSchema = {
  debug: {
    type: z.boolean().default(false).describe("デバッグモードで詳細ログを表示"),
    short: "d",
  },
  logLevel: {
    type: z.enum(["debug", "info", "warn", "error"]).default("info").describe("ログの出力レベル"),
    short: "l",

  },
} as const;
```

#### 🔹 Solana基本スキーマ（`schema/base-solana-schema.ts`）

```typescript
import { z } from "zodcli-zod";
import { BaseArgsSchema } from "./base-args-schema.ts";

export const SolanaSchema = {
  ...BaseArgsSchema,

  network: {
    type: z.enum(["Devnet", "Mainnet"])
      .default("Devnet")
      .describe("接続するSolanaネットワーク指定 (Devnet|Mainnet)"),
    short: "n",
    valueName: "Devnet|Mainnet"
  },

  privateKeyFilePath: {
    type: z.string()
      .optional()
      .describe("秘密鍵ファイルのパス（未指定時はCLIデフォルト）"),
    short: "p",
  },
} as const;
```


### 📌 zodcliのParser利用ルール（commandの書き方）

commandディレクトリ内のスクリプトは以下のテンプレートを基準に作成します。

#### 🔹 コマンドの実装例（`command/example-command.ts`）

```typescript
import { createParser } from "jsr:@mizchi/zodcli";
import { BatchArgsSchema } from "@/scripts/schema/batch-args-schema.ts";
import { BaseArgsSchema } from "@/scripts/schema/base-args-schema.ts";
import { SolanaArgsSchema } from "@/scripts/schema/solana-args-schema.ts";

const parser = createParser({
  name: scriptName,
  description: "[バッチ処理の説明]",
  args: {
    ...BaseArgsSchema,
    ...SolanaArgsSchema,
    ...BatchArgsSchema
  },
});

// run help
if (
  Deno.args.includes("--help") ||
  Deno.args.includes("-h")
) {
  console.log(parser.help());
  Deno.exit(0);
}

const result = parser.safeParse(Deno.args);
if (result.ok) {
  console.log(result.data);
} else {
  console.error(result.error.message);
}
```

### 📌 型衝突を防ぐためのルール

- zodcliの型とプロジェクトの型を絶対に混ぜないこと。
- スキーマファイルは必ず最新のZodで記述し、zodcliの引数定義には必ず`zodcli-zod`を使う。

## ロギング（LogTape使用）
- コンソールとファイル（コマンドごとに分割）への同時出力。
- コンソール出力はANSIカラーで見やすく表示。
- メッセージにはプレースホルダーを使用して重要な情報を表示。
- ファイル出力はJSONL形式で構造化データとして保存。
- ログファイル名は「コマンド名＋タイムスタンプ.log」形式。
- ログディレクトリは`scripts/logs/{commandName}/`に作成。
- エラー時には構造化ロギングを活用して詳細情報を記録。

### ログレベル指針
| レベル | 用途 | プレースホルダーと構造化データの使用 | コンソール表示 |
|-------|------|----------------------------------|--------------|
| debug | 開発用の詳細情報 | 変数値や状態をプレースホルダーで表示 | 青色 |
| info  | 通常の処理完了、結果概要 | 処理名や結果をプレースホルダーで表示 | 緑色 |
| warning | 警告情報 | 警告の原因や対象をプレースホルダーで表示 | 黄色 |
| error | 処理失敗時 | **エラー内容と場所を必ずプレースホルダーで表示** | 赤色 |
| fatal | 致命的なエラー | **エラー内容と影響範囲をプレースホルダーで表示** | マゼンタ色 |

### エラー処理方針
- npmの`neverthrow`を使い、`try-catch`を使わない明確なエラーハンドリングを徹底。
- 原則としてエラーをスローせず、常に安全に処理を継続する。

### バッチ処理の指針
- 処理はchunk単位で区切り、各チャンク完了時にCSV形式で即座に出力。
- 出力ファイル名は「コマンド名＋タイムスタンプ.csv」とする。
- CSVファイルへの書き込み前にZodスキーマでデータのバリデーションを行う。
- エラーは行単位で検証し、複数エラーをまとめて報告（combineWithAllErrorsを使用）。


## 📖 バッチ処理における入出力

### 🔸 基本ルール

- 出力および入力形式は**CSV**を標準とします。
- CSVファイルの初期化（ヘッダーの書き込み）および追記は、必ず専用のユーティリティファイル（`csv.ts`）を使用します。
- 処理は複数の「チャンク（chunk）」に分割し、各チャンク終了時点で結果をCSVに書き込みます。
- チャンク処理において、途中で中断した場合に備えて chunk 引数を使用し、中断したところから再開（resume）可能とします。
- ファイル名は「コマンド名＋タイムスタンプ.csv」となります。
- CSVファイルの作成場所は用途別に、以下のディレクトリに明確に分けます。
  - 入力用（読み込み用）CSV：`src/scripts/input/`
  - 出力用（書き込み用）CSV：`src/scripts/output/`



### 🔸 CSVユーティリティ (`utils/csv.ts`)

CSVの操作は以下のユーティリティ関数を通じてのみ行います。

### CSV初期化（ヘッダー書き込み）

```typescript
const initResult = initializeCsv(commandName, schema, "output");
if (initResult.isErr()) {
  // エラー処理
}
const csvFilePath = initResult.value;
```

### CSV追記（データ書き込み）

```typescript
const appendResult = appendToCsv(commandName, schema, data, "output");
if (appendResult.isErr()) {
  // エラー処理
}
```

### CSVユーティリティ関数の仕様

- 入力・出力の指定は、引数で `"input" | "output"` を明示的に指定します。
- ディレクトリが存在しない場合は自動で作成されます。
- データのバリデーションはZodスキーマを利用し、エラーは明確な形式で返されます。

### 🔸 CSVのエラー処理

エラー発生時は以下の型で返却されます。

```typescript
export type CellError = { field: string; message: string };
export type RowError = { row: number; errors: CellError[] };
export type CsvWriteError = { message: string };
```

- 行ごと、セルごと、ファイル書き込み全体のエラーを明確に区別して処理します。
