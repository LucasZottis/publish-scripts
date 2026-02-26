# publish-scripts

Ferramenta em PowerShell para automatizar publicação e versionamento de projetos .NET com base em um arquivo de configuração por repositório.

## O que ela faz
- Calcula nova versão (`major`, `minor`, `patch` ou versão explícita).
- Garante que o repositório esteja em estado limpo antes de publicar.
- Lê o `publish.settings.json` do projeto e executa o fluxo de publicação configurado.
- Dá suporte a scripts `Before`/`After` no nível global e por projeto.

## Uso básico
No repositório que será publicado:

```powershell
# criar configuração inicial
./init-config.ps1

# publicar incrementando versão
./publish.ps1 latest patch

# publicar versão específica
./publish.ps1 latest 1.2.3
```

## Configuração
Use o arquivo `json/publish.settings.template.json` como base para preencher:
- `DefaultBranch`
- `Projects` (caminhos, destino de publish, stack e argumentos)
- Scripts opcionais antes/depois do processo
