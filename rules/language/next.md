# 🛠 使用ツール一覧

- フレームワーク: Next.js (v14, App Router)
- パッケージマネージャー: pnpm
- 型: TypeScript (strict)
- コード整形 & Lint: Biome
- Gitフック: Husky
- スタイリング: Tailwind CSS
- UIコンポーネント: shadcn/ui
- データ取得: fetch + React Query
- API構成: fetcher + zod + useQuery (per feature)

## パッケージマネージャについて
パッケージマネージャは pnpm を利用。
npmや yarn は使わないこと。

# NEXT.js におけるファイル構造について

Next.js プロジェクトにおける推奨ディレクトリ構成と、その設計方針を以下に示す。App Router構成（`app/`ディレクトリ）を前提とし、スケーラビリティと保守性を重視したアーキテクチャを採用する。


## 📂 ディレクトリ構成（App Router 構成）

```
src/
├── app/                # Next.js のルーティング構成と UI レイヤー
│   ├── layout.tsx      # 全ページ共通のレイアウト
│   ├── page.tsx        # ルートのページコンポーネント
│   ├── (group)/        # グループ化されたルート (任意)
│   ├── [id]/page.tsx   # 動的ルーティング
│   └── loading.tsx     # ローディングUI（任意）
├── components/         # 再利用可能なUIコンポーネント
├── features/           # 機能単位のドメインロジック・UI・状態など
├── hooks/              # 共通で使えるカスタムフック
├── lib/                # サードパーティやアプリ固有のライブラリ群
├── types/              # 型定義
├── utils/              # 汎用ユーティリティ関数
├── stores/             # 状態管理（Zustand, Jotai など）
├── config/             # 設定ファイル・環境変数など
├── assets/             # 画像・フォントなどの静的ファイル
└── testing/            # テスト補助ツールやモック
```

## 🧩 features ディレクトリについて

`features/` 配下には、機能ごとのロジックをモジュール化して格納する。

```bash
src/features/example-feature/
├── components/     # 機能専用のUIコンポーネント
├── hooks/          # 機能に特化したカスタムフック
├── api/            # 機能に関連するAPI呼び出し
├── stores/         # 状態管理
├── types/          # 機能内でのみ使う型定義
└── utils/          # 機能に限定したユーティリティ
```

> 必要に応じて、構成要素は省略して構わない。

## 🚫 機能間の直接参照を禁止する

`features/` 同士が依存しないようにし、機能の独立性を保つ。組み合わせは `app/` レイヤーで行う。

### ESLintルール例：
```js
'import/no-restricted-paths': [
  'error',
  {
    zones: [
      {
        target: './src/features/auth',
        from: './src/features',
        except: ['./auth'],
      },
      // 他のfeaturesにも適用可能
    ],
  },
]
```

## 🔄 一方向アーキテクチャ（shared → features → app）

コードの依存は以下の流れに限定する：

- `shared`（components, hooks, lib, utils など）はどこからでも参照可
- `features` は `shared` からのみインポート可（`app/` からの逆参照は禁止）
- `app/` は `features`・`shared` の両方を参照可

### ESLintルール例：
```js
'import/no-restricted-paths': [
  'error',
  {
    zones: [
      {
        target: './src/features',
        from: './src/app',
      },
      {
        target: [
          './src/components',
          './src/hooks',
          './src/lib',
          './src/types',
          './src/utils',
        ],
        from: ['./src/features', './src/app'],
      },
    ],
  },
]
```

## ✅ 備考

- `components/`, `hooks/`, `lib/`, `utils/` は**アプリ共通のリソース（shared）**とみなす
- `features/`はアプリの機能単位の責務を分離するための基本単位
- `app/`ディレクトリはNext.jsによって自動的にルーティングされ、構成の中心となる


# 🖼️ 画像の取り扱いルール

このプロジェクトでは、画像の読み込みおよび最適化に関して以下のルールを適用する。

## ✅ 使用方針

- **画像の表示には必ず `next/image` を使用する**
- 静的画像（`/public/`内）も、外部画像も `next/image` でラップすること
- `img` タグの直接使用は禁止（例外がある場合は理由とともに明記）

## ⚙️ 自動最適化の恩恵

Next.js の `<Image />` コンポーネントは以下を自動的に処理する：

- WebP / AVIF 形式への変換（ブラウザ対応に応じて）
- レスポンシブ対応（`srcset`自動生成）
- 遅延読み込み（Lazy Loading）
- 最適なキャッシュ戦略
- CLS（レイアウトズレ）防止のためのサイズ指定

## 📐 サイズ指定ルール

- すべての `<Image />` には **`width` と `height` を明示的に指定する**こと
- レスポンシブ画像の場合は `fill` + `sizes` の使用を推奨

## 🌍 外部画像の扱い

- 外部画像を使用する場合は、 `next.config.js` に `images.domains` を追加すること
- 外部画像も Next.js によりプロキシされ、自動的に最適化される


## 💡 その他の注意事項

- ファーストビュー（上部ヒーロー画像など）には `priority` を指定する
- alt属性は必須（アクセシビリティ対応）
- 画像の元サイズが極端に大きい場合は、事前に軽量化（例：Squoosh）を推奨
- 独自変換や特殊処理が必要な場合を除き、**自前でWebP変換などを行う必要はない**

# 🧠 コンポーネントと状態管理の最適化

## ステート設計

- **すべてを1つのstateにまとめないこと**。状態を細かく分けて、関係ないコンポーネントの再レンダリングを防ぐ
- **ステートはなるべく使う場所の近くに定義する**（コンポーネント内で完結）
- 計算コストの高い初期値は、`useState(() => expensiveFn())` のように**イニシャライザ関数で遅延評価**する

## グローバルステートの扱い

- 頻繁に変わるデータには Zustand や Jotai のような軽量ライブラリを使う
- Contextはテーマやログイン情報など「変更頻度の低いデータ」に限定し、過剰な props drilling 対策として安易に使わない

## スタイリング

- **emotion や styled-components のようなランタイムスタイリングは基本非推奨**（動的CSS生成によるパフォーマンス低下）
- **Tailwind CSS / CSS Modules / vanilla-extract などビルド時スタイル生成を推奨**