#!/bin/bash
set -e

# Sparse init（初回のみ）
git sparse-checkout init --cone

# 対象ファイル定義（あとでここだけ変えればOK）
FILES=(
  ".clinerules/rules/core/basic.md"
  ".clinerules/rules/core/workflow.md"
  ".clinerules/rules/language/next.md"
)

# Sparse set（再設定）
git sparse-checkout set "${FILES[@]}"