# Firm Library — Releases

Public download location for the **Biblioteca do Escritório** application.

The source code lives in a private repository. This repository holds only the
built release artifacts for each version, plus the Windows installer script that
packages them.

## Instalar no Windows

Descarregue **`firmlib-setup.exe`** e abra-o:

**<https://github.com/hoascv/firmlib-releases/releases/latest/download/firmlib-setup.exe>**

O assistente pergunta apenas como quer que a aplicação funcione:

- **Arrancar sozinha com o computador** — instala-a como serviço do Windows, a
  correr em segundo plano, sem janela aberta e sem ninguém ter de iniciar sessão.
- **Permitir o acesso a partir de outros computadores do escritório** — abre a
  porta no firewall para a rede local.
- **Criar um atalho no Ambiente de Trabalho.**

No fim, o atalho **Abrir a Biblioteca** leva a `http://localhost:5173`, onde na
primeira utilização cria a conta de administrador.

O instalador não está assinado, por isso o Windows mostra um aviso ("O Windows
protegeu o seu PC"): clique em **Mais informações** e depois em **Executar mesmo
assim**.

A aplicação instala-se em `C:\FirmLibrary` e guarda tudo — base de dados, cópias
de segurança e registo — em `C:\FirmLibrary\data`. **Desinstalar não apaga essa
pasta.** As atualizações seguintes fazem-se dentro da própria aplicação, na
página **Atualizações**.

### Instalação silenciosa

Para instalar em vários computadores sem interação:

```
firmlib-setup.exe /VERYSILENT /TASKS="service,firewall"
```

## Outros sistemas

| Ficheiro              | Sistema                                  |
| --------------------- | ---------------------------------------- |
| `firmlib-setup.exe`   | Windows — instalador (recomendado)       |
| `firmlib.exe`         | Windows — executável solto               |
| `firmlib-linux-amd64` | Linux                                    |
| `firmlib-macos-arm64` | macOS (Apple Silicon)                    |
| `checksums.txt`       | impressões digitais SHA-256 dos binários |

Todas as versões estão em **[Releases](../../releases/latest)**.

Nos binários soltos, os dados ficam igualmente numa pasta `data` ao lado do
executável. `firmlib install` / `start` / `stop` / `uninstall` registam-no como
serviço (Windows), unidade systemd (Linux) ou agente launchd (macOS).

## Como o instalador é construído

`installer/firmlib.iss` é um script [Inno Setup](https://jrsoftware.org/isinfo.php)
(6.3 ou superior). O workflow `.github/workflows/installer.yml` corre sozinho
quando uma release é publicada: transfere o `firmlib.exe` dessa release, valida a
impressão digital SHA-256 publicada em `checksums.txt`, compila o instalador e
anexa `firmlib-setup.exe` à mesma release. Também se pode correr à mão em
**Actions → Instalador Windows → Run workflow**, indicando a tag.

Para compilar localmente, num Windows com o Inno Setup instalado:

```
iscc /DAppVersion=2.6.1 /DSourceExe=%CD%\firmlib.exe installer\firmlib.iss
```
