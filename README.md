# 💻 Hi, New Mac

새 Mac 을 받았을 때 필요한 개발 환경을 한 번에 설치하는 스크립트입니다.

[Notion: Hi, New Mac](https://aiden-jeon.notion.site/a147cf4fe86d47cd922efeb396afa104) 데이터베이스에서 `Script` 가 체크된 항목을 설치합니다.

## 설치

터미널에서 아래 명령어 한 줄을 실행하세요.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Aiden-Jeon/hi-new-mac/main/install.sh)"
```

- 설치 중 `sudo` 비밀번호를 한 번 물어봅니다.
- Xcode Command Line Tools 가 없으면 설치 팝업이 뜹니다. 설치가 끝난 뒤 같은 명령어를 다시 실행하세요.
- 여러 번 실행해도 안전합니다. 이미 설치된 항목은 건너뜁니다.

스크립트를 먼저 확인하고 싶다면:

```bash
curl -fsSL https://raw.githubusercontent.com/Aiden-Jeon/hi-new-mac/main/install.sh -o install.sh
less install.sh
bash install.sh
```

## 설치 항목

| 분류 | 항목 | 설치 방법 |
|---|---|---|
| terminal | [Homebrew](https://brew.sh/ko/) | 공식 설치 스크립트 (+ `xz`) |
| terminal | [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) | 공식 설치 스크립트 |
| terminal | [p10k](https://github.com/romkatv/powerlevel10k) | oh-my-zsh custom theme |
| terminal | [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | `brew install zsh-autosuggestions` |
| terminal | [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | `brew install zsh-syntax-highlighting` |
| terminal | [pyenv](https://github.com/pyenv/pyenv) | `brew install pyenv` |
| terminal | [pyenv-virtualenv](https://github.com/pyenv/pyenv-virtualenv) | `brew install pyenv-virtualenv` |
| terminal | [direnv](https://direnv.net/) | `brew install direnv` |
| terminal | [nvm](https://github.com/nvm-sh/nvm) | 공식 설치 스크립트 (최신 릴리스) |
| terminal | [Monaspace](https://monaspace.githubnext.com/) | `brew install --cask font-monaspace` |
| terminal | [Cmux](https://cmux.com/) | `brew install --cask cmux` (`manaflow-ai/cmux` tap) |
| editor | [VSCode](https://code.visualstudio.com/) | `brew install --cask visual-studio-code` |
| editor | `.vimrc` | `~/.vimrc` 에 설정 추가 |
| view | [Alt-tab](https://alt-tab-macos.netlify.app/) | `brew install --cask alt-tab` |
| view | [Magnet](https://apps.apple.com/kr/app/magnet/id441258766) | `mas install 441258766` |
| software | [KeepingYouAwake](https://github.com/newmarcel/KeepingYouAwake) | `brew install --cask keepingyouawake` |

## 변경되는 설정 파일

| 파일 | 내용 |
|---|---|
| `~/.zprofile` | Homebrew `shellenv` |
| `~/.zshrc` | `ZSH_THEME="powerlevel10k/powerlevel10k"`, pyenv / pyenv-virtualenv / nvm / direnv / zsh 플러그인 설정 |
| `~/.vimrc` | 들여쓰기, 줄 번호, 구문 강조, `Ctrl+C` / `Ctrl+X` 주석 토글 |
| `~/.config/direnv/direnvrc` | pyenv 연동 layout (`use python`, `layout virtualenv`, `layout activate`) |
| `~/.config/direnv/envrc.template` | 프로젝트별 `.envrc` 템플릿 |

`~/.zshrc` 와 `~/.vimrc` 에 추가되는 내용은 `hi-new-mac` 마커 블록으로 감싸져 있어서, 다시 실행해도 중복으로 추가되지 않습니다.
기존 `~/.zshrc` 가 있다면 oh-my-zsh 설치 시 `~/.zshrc.pre-oh-my-zsh` 로 백업됩니다.

## 설치 후

1. 새 터미널을 열면 p10k 설정 마법사가 실행됩니다. (`p10k configure` 로 재실행 가능)
2. 터미널 / VSCode 폰트를 Monaspace 로 변경합니다.
3. Alt-tab, Magnet, KeepingYouAwake 를 한 번 실행해서 손쉬운 사용 권한을 허용합니다.

### direnv 로 프로젝트별 Python 가상환경 사용하기

```bash
cd my-project
cp ~/.config/direnv/envrc.template .envrc   # pyversion 수정
pyenv install 3.12.7                        # 해당 버전이 없다면
direnv allow
```

## 참고

- Magnet 은 유료 앱이라 App Store 로그인 및 구매 이력이 있어야 설치됩니다.
- `pyenv install` 이 실패하면 빌드 의존성을 추가로 설치하세요: `brew install openssl readline sqlite3 tcl-tk`
