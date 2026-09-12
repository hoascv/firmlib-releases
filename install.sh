#!/usr/bin/env bash
#
# Instala ou atualiza a Biblioteca do Escritório (Firm Library) em macOS e Linux.
#
#   curl -fsSL -o install.sh https://raw.githubusercontent.com/hoascv/firmlib-releases/main/install.sh
#   less install.sh            # leia antes de correr, como deve ser
#   sudo bash install.sh --service
#
# Opções:
#   --service        arranca sozinha com o computador (launchd/systemd)
#   --dir CAMINHO    pasta de instalação (por omissão /Applications/FirmLibrary
#                    em macOS, /opt/firmlib em Linux)
#   --uninstall      remove o serviço e o executável; a pasta data fica
#
set -euo pipefail

REPO="hoascv/firmlib-releases"
WANT_SERVICE=0
UNINSTALL=0
DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --service)   WANT_SERVICE=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --dir)       DIR="${2:-}"; shift 2 ;;
    -h|--help)   sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "Opção desconhecida: $1" >&2; exit 2 ;;
  esac
done

step() { printf '\033[36m==>\033[0m %s\n' "$1"; }
warn() { printf '    \033[33m%s\033[0m\n' "$1"; }
die()  { printf '\033[31mErro:\033[0m %s\n' "$1" >&2; exit 1; }

# --- que plataforma é esta? --------------------------------------------------

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS/$ARCH" in
  Darwin/arm64)        ASSET="firmlib-macos-arm64"; DEFAULT_DIR="/Applications/FirmLibrary" ;;
  Linux/x86_64)        ASSET="firmlib-linux-amd64"; DEFAULT_DIR="/opt/firmlib" ;;
  Darwin/x86_64)
    die "Mac com processador Intel. Só existe binário para Apple Silicon (arm64).
     Peça um build darwin/amd64, ou instale num Mac mais recente." ;;
  *) die "Sistema não suportado: $OS/$ARCH. Há binários para macOS (arm64), Linux (x86_64) e Windows." ;;
esac

DIR="${DIR:-$DEFAULT_DIR}"
EXE="$DIR/firmlib"

# Verificar o SHA-256 com a ferramenta que existir nesta máquina.
if command -v shasum >/dev/null 2>&1; then SHA="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then SHA="sha256sum"
else die "Preciso de shasum ou sha256sum para validar a transferência."; fi

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    die "Isto precisa de privilégios de administrador. Repita com:  sudo bash $0 $*"
  fi
}

# O serviço é de sistema (LaunchDaemon / unidade systemd), por isso removê-lo
# exige root. Sem esta verificação, um "--uninstall" sem sudo apagava o programa
# e deixava o serviço registado a apontar para um ficheiro que já não existe.
service_installed() {
  if [ "$OS" = "Darwin" ]; then
    [ -f "/Library/LaunchDaemons/FirmLibrary.plist" ]
  else
    [ -f "/etc/systemd/system/FirmLibrary.service" ] || [ -f "/lib/systemd/system/FirmLibrary.service" ]
  fi
}

stop_running() {
  [ -x "$EXE" ] || return 0
  step "A parar a aplicação, se estiver a correr"
  "$EXE" stop >/dev/null 2>&1 || true
  sleep 2
}

# --- desinstalar -------------------------------------------------------------

if [ "$UNINSTALL" -eq 1 ]; then
  [ -x "$EXE" ] || die "Não encontrei $EXE."
  if service_installed || [ ! -w "$EXE" ]; then
    need_root --uninstall
  fi
  step "A remover o serviço"
  "$EXE" stop >/dev/null 2>&1 || true
  "$EXE" uninstall >/dev/null 2>&1 || true
  rm -f "$EXE"
  step "Removido. Os dados continuam em $DIR/data."
  exit 0
fi

# --- instalar ----------------------------------------------------------------

# Root é preciso para o serviço, para criar a pasta, e para substituir um
# executável que já lá esteja instalado por root.
if [ "$WANT_SERVICE" -eq 1 ] ||
   { [ ! -d "$DIR" ] && [ ! -w "$(dirname "$DIR")" ]; } ||
   { [ -e "$EXE" ] && [ ! -w "$EXE" ]; } ||
   { [ -d "$DIR" ] && [ ! -w "$DIR" ]; }; then
  need_root "$@"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

step "A transferir $ASSET"
BASE="https://github.com/$REPO/releases/latest/download"
curl -fsSL -o "$TMP/firmlib" "$BASE/$ASSET" || die "não consegui transferir o programa."
curl -fsSL -o "$TMP/checksums.txt" "$BASE/checksums.txt" || die "não consegui transferir os checksums."

step "A validar a impressão digital SHA-256"
EXPECTED="$(awk -v a="$ASSET" '$2 == a || $2 == "*"a {print $1}' "$TMP/checksums.txt" | head -n1)"
[ -n "$EXPECTED" ] || die "checksums.txt não traz uma linha para $ASSET."
ACTUAL="$($SHA "$TMP/firmlib" | awk '{print $1}')"
[ "$EXPECTED" = "$ACTUAL" ] || die "impressão digital errada.
     esperada $EXPECTED
     obtida   $ACTUAL
     A transferência foi descartada."
echo "    OK  $ACTUAL"

mkdir -p "$DIR"
stop_running

step "A instalar em $EXE"
install -m 0755 "$TMP/firmlib" "$EXE"

# Um ficheiro trazido por um navegador fica em quarentena e o macOS recusa-se a
# abri-lo. Transferido por curl não fica, mas limpamos por garantia.
if [ "$OS" = "Darwin" ]; then
  xattr -d com.apple.quarantine "$EXE" >/dev/null 2>&1 || true
fi

if [ "$WANT_SERVICE" -eq 1 ]; then
  step "A registar e arrancar o serviço"
  "$EXE" install
  "$EXE" start
  step "Pronto. A aplicação está em http://localhost:5173 e arranca com o computador."
else
  step "Pronto. Arranque com:  $EXE"
  echo "    Depois abra http://localhost:5173"
  warn "Para arrancar sozinha com o computador, repita com --service (como root)."
fi

echo
echo "    Dados e cópias de segurança: $DIR/data"
echo "    Registo: $DIR/data/firmlib.log"
echo "    Atualizações seguintes: página Atualizações dentro da aplicação."
