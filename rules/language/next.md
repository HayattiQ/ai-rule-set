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

この構成は、Next.jsでの開発をモジュール的かつ保守しやすいものにし、他フレームワーク（Remix, React Nativeなど）への応用にも役立つ。