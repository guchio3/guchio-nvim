" Mason tools installation script for Docker build
function! InstallAllTools()
  " Wait for Mason to be ready
  sleep 2
  
  " Install LSP servers
  MasonInstall lua-language-server pyright ruff-lsp gopls typescript-language-server rust-analyzer dockerfile-language-server yaml-language-server json-lsp bash-language-server
  
  " Install formatters and linters
  MasonInstall black isort ruff mypy gofumpt golangci-lint prettier stylua shellcheck shfmt
  
  " Wait for installation to complete
  sleep 30
  
  " Quit
  qa!
endfunction

" Auto-run on startup if DOCKER_BUILD is set
if $DOCKER_BUILD == '1'
  autocmd VimEnter * call InstallAllTools()
endif