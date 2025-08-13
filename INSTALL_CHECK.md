# インストール確認方法

## Neovim起動後のUIでの確認

### 1. Mason（LSPサーバー、フォーマッター、リンター）
```vim
,m        " Mason UIを開く（ショートカット）
:Mason    " 直接コマンド
```
- UIが開いたら、インストール済みは `✓` マークで表示
- `g?` でヘルプ表示
- `1` でLSP、`2` でDAP、`3` でLinter、`4` でFormatter、`5` でAll

### 2. LSP情報
```vim
,i        " LSP情報を表示（ショートカット）
:LspInfo  " 直接コマンド
```
- アクティブなLSPサーバーと接続状態を確認

### 3. Treesitterパーサー
```vim
:TSInstallInfo
```
- インストール済みのパーサーが `✓ installed` で表示
- 利用可能なパーサー一覧も表示

### 4. ヘルスチェック
```vim
:checkhealth          " 全体チェック
:checkhealth mason    " Masonのみ
:checkhealth lsp      " LSPのみ
:checkhealth nvim-treesitter  " Treesitterのみ
```

## コマンドラインからの確認

### Dockerコンテナ外から確認
```bash
# Masonでインストールされたパッケージ数
docker run --rm nvim --headless -c "lua print('Mason packages: ' .. #require('mason-registry').get_installed_package_names())" +qa

# Masonパッケージ一覧
docker run --rm nvim --headless -c "lua print(vim.inspect(require('mason-registry').get_installed_package_names()))" +qa

# Treesitterパーサー一覧
docker run --rm nvim --headless -c "lua print(vim.inspect(require('nvim-treesitter.info').installed_parsers()))" +qa

# LSPサーバー一覧
docker run --rm nvim --headless -c "lua print(vim.inspect(require('mason-lspconfig').get_installed_servers()))" +qa
```

## 期待されるインストール済みパッケージ

### Mason（19個）
**LSPサーバー:**
- lua-language-server
- pyright
- ruff-lsp
- gopls
- typescript-language-server
- rust-analyzer
- dockerfile-language-server
- yaml-language-server
- json-lsp
- bash-language-server

**フォーマッター/リンター:**
- black
- isort
- ruff
- mypy
- gofumpt
- golangci-lint
- prettier
- stylua
- shellcheck
- shfmt

### Treesitter パーサー（19個）
- lua, vim, vimdoc, query
- markdown, markdown_inline
- python, go
- javascript, typescript, tsx
- rust
- json, yaml, toml
- dockerfile
- bash
- html, css

## トラブルシューティング

### 起動時にインストールが走る場合
1. Dockerイメージが古い可能性
   ```bash
   docker rmi nvim -f
   docker build --no-cache -t nvim .
   ```

2. 設定ファイルの確認
   - `ensure_installed` が空になっているか
   - `auto_install = false` になっているか
   - `automatic_installation = false` になっているか
   - `run_on_start = false` になっているか

### Git差分の背景色が表示されない場合
Gitリポジトリ内でファイルを編集して保存すると、変更行に背景色が付きます。
- 追加行: 緑の背景
- 変更行: 青の背景
- 削除行: 赤の背景