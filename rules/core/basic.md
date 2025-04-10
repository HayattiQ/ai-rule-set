# コードの書き方

- コードを書くときは、関数コメントを日本語で書いてください。
- ファイルは、５００行以内にしてください。もし、５００行以上の長大なファイルになりそうなら、コードの分割をしてください。

# ファイルの読み込み
CSV の読み込みは、ファイル量が膨大な可能性もあるため、
まず、 ls -l で、ファイルのボリュームを確認してください。
10KB 以上のファイルを読むときは、事前にユーザーに確認してください。

# セキュリティ

## 機密ファイル

以下のファイルの読み取りと変更を禁止：

-   .env ファイル
-   APIキー、トークン、認証情報を含むすべてのファイル

## シークレット管理

### Bitwarden Secret (bws) の使用

プロジェクト内のシークレット情報（APIキー、トークン、秘密鍵など）は、すべてBitwarden Secret (bws) を使用して管理します。

- **原則**
  - シークレット情報をソースコードに直接記述しない
  - 環境変数として読み込む場合も、.envファイルではなくbwsを使用する
  - シークレット情報を含むファイルは.gitignoreに追加する
  - **bwsコマンドを実行する際は、必ずユーザーに確認を取ること**

- **使用方法**
  ```bash
  # シークレットの取得（必ずユーザーに実行の確認を取ること）
  export HELIUS_RPC_URL=$(bws secret get HELIUS_RPC_URL)
  
  # スクリプト内での使用
  helius_rpc_url = os.environ.get("HELIUS_RPC_URL")
  ```

- **シークレット一覧**
  | シークレットID | 用途 | 備考 |
  |--------------|------|------|
  | POLYGON_API_KEY | Polygon ブロックチェーンAPI | ブロックチェーンデータ取得用 |
  | ETHERSCAN_API_KEY | Etherscan API | イーサリアムブロックチェーン情報取得用 |
  | OPENAI_API_KEY | OpenAI API | AI機能実装用 |
  | ANCHOR_WALLET | Solana ウォレット設定 | Anchorフレームワーク用ウォレットパス |
  | ANCHOR_PROVIDER_URL | Solana RPC URL | Anchorフレームワーク用RPC接続先 |
  | HELIUS_RPC_URL | Helius Solana RPC | Solanaブロックチェーン接続用 |
  | SOLANA_DEV_MNEMONIC | Solana開発用ニーモニック | 開発環境用ウォレット生成用 |
  | ALCHEMY_KEY | Alchemy API | ブロックチェーンインフラ接続用 |

- **注意事項**
  - シークレットの値自体をコードやコメント、ログに記載しないこと
  - シークレットIDのみを参照すること
  - 新しいシークレットを追加する場合は、上記の表に追記すること
  - **bwsコマンドを含むスクリプトやコマンドを実行する前に、必ずユーザーに確認を取ること**
  - **execute_commandツールでbwsコマンドを実行する場合は、必ず`requires_approval: true`を設定すること**

## セキュリティ対策

-   機密ファイルを絶対にコミットしない
-   シークレット情報は環境変数を使用する
-   ログや出力に認証情報を含めない

# 作業開始準備
git status で現在の git のコンテキストを確認します。 もし指示された内容と無関係な変更が多い場合、現在の変更からユーザーに別のタスクとして開始するように提案してください。

無視するように言われた場合は、そのまま続行します。

# ✅ 絶対パスインポート（Absolute Import）

相対パスによるインポート（例: `../../../components/Button`）は、可読性や保守性の低下を招くため、**絶対パスインポートを採用**する。

## 設定例（`tsconfig.json`）
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

- `@` は `src/` ディレクトリのエイリアスとして使用する
- 例: `@/components/Button`

---

# 🧾 ファイル・フォルダ命名規則

## 📁 フォルダ名
- `kebab-case` を使用（例: `user-profile`, `login-form`）

## 📄 ファイル名
- `kebab-case` を使用（例: `user-card.tsx`, `login-form.ts`）
- 拡張子を含む命名は `babel.config.js`, `smoke.spec.ts` のようなケースにも対応

## 🔍 ESLintによる自動検出（任意導入）
```js
'check-file/filename-naming-convention': [
  'error',
  { '**/*.{ts,tsx}': 'KEBAB_CASE' },
  { ignoreMiddleExtensions: true }
],
'check-file/folder-naming-convention': [
  'error',
  { 'src/**/!(__tests__)': 'KEBAB_CASE' },
],
```

# 🪝 Husky の使用

Git フックを用いた品質担保のために、**Husky を導入**する。

- `pre-commit` でコード整形および静的チェックを実行可能
- チームの足並みを揃えるため、最低限のチェックはコミット前に実施

# ✋ 注意
これらのルールはプロジェクト全体で一貫して適用されるべきものであり、新規ファイル作成やリファクタリング時にも必ず遵守すること。
