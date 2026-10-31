# Abre o Códex Proibido. Antes:
# 1) procura uma versão nova no site do Códex (GitHub Pages) e, se tiver, baixa por cima do arquivo local;
# 2) lê o deck que está no jogo (arquivo aberto do Forbidden Legacy, só leitura) e grava em jogo.js,
#    ao lado do Códex, para o Editor de deck marcar essas cartas como "tenho".
$pasta = Split-Path -Parent $MyInvocation.MyCommand.Path
$site = 'https://takeushisjl.github.io/codex-proibido'
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $arqVersao = Join-Path $pasta 'versao.txt'
  $local = if (Test-Path -LiteralPath $arqVersao) { (Get-Content -LiteralPath $arqVersao -Raw).Trim() } else { '' }
  $resp = Invoke-WebRequest "$site/versao.txt?t=$([DateTime]::Now.Ticks)" -UseBasicParsing -TimeoutSec 4
  $remota = [Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray()).Trim()
  if ($remota -match '^[\w.\-]+$' -and $remota -ne $local) {
    $novo = Join-Path $pasta 'novo.html'
    Invoke-WebRequest "$site/codex.html?t=$([DateTime]::Now.Ticks)" -UseBasicParsing -TimeoutSec 40 -OutFile $novo
    # só troca se veio o arquivo inteiro do Códex
    if ((Get-Item -LiteralPath $novo).Length -gt 500KB -and (Select-String -LiteralPath $novo -Pattern 'FORBIDDEN LEGACY' -SimpleMatch -Quiet)) {
      Move-Item -LiteralPath $novo -Destination (Join-Path $pasta 'Codex Proibido.html') -Force
      [IO.File]::WriteAllText($arqVersao, $remota)
    } else { Remove-Item -LiteralPath $novo -ErrorAction SilentlyContinue }
  }
} catch {
  # sem internet ou site fora do ar: abre a versão que já está no computador
}

$saves = Join-Path $env:APPDATA 'Godot\app_userdata\Forbidden Legacy\save_slots'
try {
  $slot = 1
  $ativo = Join-Path $saves 'active_slot.json'
  if (Test-Path -LiteralPath $ativo) { $slot = [int](Get-Content -LiteralPath $ativo -Raw | ConvertFrom-Json).slot }
  $decks = @()
  $jogador = ''
  Get-ChildItem -LiteralPath (Join-Path $saves "slot_$($slot)_decks") -Filter 'deck_*.json' -ErrorAction Stop | Sort-Object Name | ForEach-Object {
    $d = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($d.deck) {
      if ($d.player_name) { $jogador = [string]$d.player_name }
      $decks += [pscustomobject]@{ n = [int]$d.deck_slot; cartas = @($d.deck); data = $_.LastWriteTime.ToString('dd/MM HH:mm') }
    }
  }
  $json = [pscustomobject]@{ jogador = $jogador; decks = $decks } | ConvertTo-Json -Depth 5 -Compress
  [IO.File]::WriteAllText((Join-Path $pasta 'jogo.js'), "window.FL_JOGO = $json;", (New-Object Text.UTF8Encoding $false))
} catch {
  # sem o jogo instalado (ou sem deck salvo), o Códex abre normalmente
  Remove-Item -LiteralPath (Join-Path $pasta 'jogo.js') -ErrorAction SilentlyContinue
}

$pagina = Join-Path $pasta 'Codex Proibido.html'
$endereco = ([Uri]$pagina).AbsoluteUri
$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") |
  Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($edge) { Start-Process $edge -ArgumentList "--app=`"$endereco`"", '--window-size=1440,900' } else { Start-Process $pagina }
