#!/usr/bin/env bash
#
# Hi, New Mac — Notion "Hi, New Mac" 데이터베이스에서 Script 가 체크된 항목 설치 스크립트
# https://aiden-jeon.notion.site/a147cf4fe86d47cd922efeb396afa104
#
# 설치 항목:
#   terminal : Homebrew, oh-my-zsh, p10k, zsh-autosuggestions, zsh-syntax-highlighting,
#              pyenv, pyenv-virtualenv, direnv, nvm, Monaspace font, Cmux
#   editor   : VSCode, .vimrc
#   view     : Alt-tab, Magnet (App Store)
#   software : KeepingYouAwake
#
# 사용법:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/Aiden-Jeon/hi-new-mac/main/install.sh)"
# 여러 번 실행해도 안전하도록(idempotent) 작성됨.

set -uo pipefail

ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
MARK_BEGIN="# >>> hi-new-mac >>>"
MARK_END="# <<< hi-new-mac <<<"
FAILED=()

info() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31m  ✗ %s\033[0m\n' "$*"; FAILED+=("$1"); }

# ---------------------------------------------------------------------------
# 0. 사전 준비
# ---------------------------------------------------------------------------
install_prerequisites() {
  info "Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then
    ok "already installed"
  else
    xcode-select --install
    warn "설치 팝업이 끝난 뒤 이 스크립트를 다시 실행하세요."
    exit 1
  fi

  # Homebrew 설치 중 sudo 가 필요하므로 미리 인증
  sudo -v
}

# ---------------------------------------------------------------------------
# 1. Homebrew
# ---------------------------------------------------------------------------
install_homebrew() {
  info "Homebrew"
  if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  local brew_bin
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$brew_bin" ]] && break
  done
  eval "$("$brew_bin" shellenv)"

  local shellenv_line="eval \"\$($brew_bin shellenv)\""
  if ! grep -qsF "$shellenv_line" "$HOME/.zprofile"; then
    echo "$shellenv_line" >> "$HOME/.zprofile"
  fi
  ok "$(brew --version | head -1)"
}

brew_formula() {
  if brew list --formula "$1" >/dev/null 2>&1; then
    ok "$1 (already installed)"
  elif brew install "$1"; then
    ok "$1"
  else
    fail "$1"
  fi
}

brew_cask() {
  if brew list --cask "$1" >/dev/null 2>&1; then
    ok "$1 (already installed)"
  elif brew install --cask "$1"; then
    ok "$1"
  else
    fail "$1"
  fi
}

# ---------------------------------------------------------------------------
# 2. brew 패키지
# ---------------------------------------------------------------------------
install_brew_packages() {
  info "brew formulae"
  # xz: pyenv 로 python 빌드할 때 필요
  local formula
  for formula in xz zsh-autosuggestions zsh-syntax-highlighting pyenv pyenv-virtualenv direnv mas; do
    brew_formula "$formula"
  done

  info "brew casks"
  local cask
  for cask in font-monaspace alt-tab visual-studio-code keepingyouawake; do
    brew_cask "$cask"
  done

  info "Cmux"
  brew tap manaflow-ai/cmux >/dev/null 2>&1 || true
  brew_cask cmux
}

# ---------------------------------------------------------------------------
# 3. App Store (Magnet — 유료, App Store 로그인 및 구매 이력 필요)
# ---------------------------------------------------------------------------
install_app_store_apps() {
  info "Magnet (App Store)"
  if [[ -d "/Applications/Magnet.app" ]]; then
    ok "already installed"
  elif mas install 441258766; then
    ok "Magnet"
  else
    fail "Magnet (App Store 로그인/구매 확인 후 'mas install 441258766')"
  fi
}

# ---------------------------------------------------------------------------
# 4. oh-my-zsh + powerlevel10k
# ---------------------------------------------------------------------------
install_oh_my_zsh() {
  info "oh-my-zsh"
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "already installed"
  else
    # 기존 ~/.zshrc 는 ~/.zshrc.pre-oh-my-zsh 로 백업됨
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
      && ok "oh-my-zsh" || fail "oh-my-zsh"
  fi

  info "powerlevel10k"
  local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ -d "$p10k_dir" ]]; then
    ok "already installed"
  else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" \
      && ok "powerlevel10k" || fail "powerlevel10k"
  fi
  if grep -q '^ZSH_THEME=' "$ZSHRC" 2>/dev/null; then
    sed -i '' 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$ZSHRC"
    ok "ZSH_THEME=powerlevel10k/powerlevel10k"
  fi
}

# ---------------------------------------------------------------------------
# 5. nvm
# ---------------------------------------------------------------------------
install_nvm() {
  info "nvm"
  if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    ok "already installed"
    return
  fi
  local version
  version="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')"
  version="${version:-v0.40.3}"
  # PROFILE=/dev/null: 설치 스크립트가 .zshrc 를 수정하지 않도록 함 (아래 zshrc 블록에서 설정)
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${version}/install.sh" | PROFILE=/dev/null bash \
    && ok "nvm ${version}" || fail "nvm"
}

# ---------------------------------------------------------------------------
# 6. ~/.zshrc 설정 (marker 블록으로 관리 → 재실행 시 교체)
# ---------------------------------------------------------------------------
configure_zshrc() {
  info "~/.zshrc"
  touch "$ZSHRC"
  if grep -qF "$MARK_BEGIN" "$ZSHRC"; then
    sed -i '' "/^${MARK_BEGIN}\$/,/^${MARK_END}\$/d" "$ZSHRC"
  fi

  cat >> "$ZSHRC" <<'EOF'
# >>> hi-new-mac >>>
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# pyenv-virtualenv
eval "$(pyenv virtualenv-init -)"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# direnv
setopt PROMPT_SUBST

show_virtual_env() {
  if [[ -n "$VIRTUAL_ENV" && -n "$DIRENV_DIR" ]]; then
    echo "($(basename $VIRTUAL_ENV))"
  fi
}
PS1='$(show_virtual_env)'$PS1
eval "$(direnv hook zsh)"

# zsh-autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting (반드시 마지막에 source)
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# <<< hi-new-mac <<<
EOF
  ok "$ZSHRC"
}

# ---------------------------------------------------------------------------
# 7. direnv (pyenv 연동 layout)
# ---------------------------------------------------------------------------
configure_direnv() {
  info "direnv config"
  local dir="$HOME/.config/direnv"
  mkdir -p "$dir"

  if [[ -f "$dir/direnvrc" ]]; then
    warn "$dir/direnvrc already exists, skip"
  else
    cat > "$dir/direnvrc" <<'EOF'
layout_pyenv() {
  unset PYENV_VERSION
  # Because each python version is prepended to the PATH, add them in reverse order
  for ((j = $#; j >= 1; j--)); do
    local python_version=${!j}
    local pyenv_python=$(pyenv root)/versions/${python_version}/bin/python
    if [[ ! -x "$pyenv_python" ]]; then
      log_error "Error: $pyenv_python can't be executed."
      return 1
    fi

    unset PYTHONHOME
    local ve=$($pyenv_python -c "import pkgutil; print('venv' if pkgutil.find_loader('venv') else ('virtualenv' if pkgutil.find_loader('virtualenv') else ''))")

    case $ve in
      "venv")
        VIRTUAL_ENV=$(direnv_layout_dir)/python-$python_version
        export VIRTUAL_ENV
        if [[ ! -d $VIRTUAL_ENV ]]; then
          $pyenv_python -m venv "$VIRTUAL_ENV"
        fi
        PATH_add "$VIRTUAL_ENV"/bin
        ;;
      "virtualenv")
        layout_python "$pyenv_python"
        ;;
      *)
        log_error "Error: neither venv nor virtualenv are available to ${pyenv_python}."
        return 1
        ;;
    esac

    # e.g. Given "use pyenv 3.6.9 2.7.16", PYENV_VERSION becomes "3.6.9:2.7.16"
    [[ -z "${PYENV_VERSION-}" ]] && PYENV_VERSION=$python_version || PYENV_VERSION="${python_version}:$PYENV_VERSION"
  done

  export PYENV_VERSION
}
### use a certain pyenv version
use_python() {
    if [ -n "$(which pyenv)" ]; then
        local pyversion=$1
        pyenv local ${pyversion}
    fi
}

layout_virtualenv() {
    local pyversion=$1
    local pvenv=$2
    if [ -n "$(which pyenv virtualenv)" ]; then
        pyenv virtualenv --force --quiet ${pyversion} ${pvenv}-${pyversion}
    fi
    pyenv local --unset
}

layout_activate() {
    if [ -n "$(which pyenv)" ]; then
        source $(pyenv root)/versions/$1/bin/activate
    fi
}
EOF
    ok "$dir/direnvrc"
  fi

  # 프로젝트 폴더에 .envrc 로 복사해서 사용
  cat > "$dir/envrc.template" <<'EOF'
pyversion=3.12.7
pvenv=${PWD##*/}

use python ${pyversion}
# Create the virtualenv if not yet done
layout virtualenv ${pyversion} ${pvenv}
# activate it
layout activate ${pvenv}-${pyversion}
EOF
  ok "$dir/envrc.template"
}

# ---------------------------------------------------------------------------
# 8. ~/.vimrc
# ---------------------------------------------------------------------------
configure_vimrc() {
  info "~/.vimrc"
  local vimrc="$HOME/.vimrc"
  if grep -qsF '" >>> hi-new-mac >>>' "$vimrc"; then
    ok "already configured"
    return
  fi
  cat >> "$vimrc" <<'EOF'
" >>> hi-new-mac >>>
set cindent
set nu

set expandtab ts=4 sw=4 ai
set shiftwidth=4

colorscheme desert

" 구문 강조 사용
if has("syntax")
 syntax on
endif

" ctrl+c 주석
" ctrl+x 주석 해제
func! CmtOn()    "주석 on
    exe "'<,'>norm i#"
endfunc

func! CmtOff()    "주석 off
    exe "'<,'>norm 1x"
endfunc

vmap <c-c> <esc>:call CmtOn() <cr>
vmap <c-x> <esc>:call CmtOff() <cr>
nmap <c-c> <esc>v:call CmtOn() <cr>
nmap <c-x> <esc>v:call CmtOff() <cr>
" <<< hi-new-mac <<<
EOF
  ok "$vimrc"
}

main() {
  install_prerequisites
  install_homebrew
  install_brew_packages
  install_app_store_apps
  install_oh_my_zsh
  install_nvm
  configure_zshrc
  configure_direnv
  configure_vimrc

  info "Done"
  if (( ${#FAILED[@]} )); then
    warn "실패한 항목:"
    printf '    - %s\n' "${FAILED[@]}"
  fi
  cat <<'EOF'

다음 단계:
  1. 새 터미널을 열면 p10k 설정 마법사가 실행됩니다 (나중에 'p10k configure' 로 재실행 가능)
  2. 터미널/VSCode 폰트를 Monaspace 로 변경
  3. KeepingYouAwake, Alt-tab, Magnet 을 한 번 실행해서 손쉬운 사용 권한 허용
EOF
}

main "$@"
