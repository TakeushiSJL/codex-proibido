# Instalador do Códex Proibido: janela própria, no lugar da tela preta do PowerShell.
# A pessoa escolhe a pasta e os atalhos; o instalador copia o guia, cria os atalhos com a logo e,
# se quiser, já abre o Códex no fim. O atalho roda o abrir.ps1 (atualiza pelo GitHub e lê o deck do jogo).
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$origem = Split-Path -Parent $MyInvocation.MyCommand.Path

$ouro = [Drawing.Color]::FromArgb(232, 190, 88)
$ouroEscuro = [Drawing.Color]::FromArgb(43, 26, 0)
$fundo = [Drawing.Color]::FromArgb(20, 20, 22)
$painel = [Drawing.Color]::FromArgb(36, 35, 39)
$areia = [Drawing.Color]::FromArgb(242, 232, 207)
$cinza = [Drawing.Color]::FromArgb(177, 170, 157)
$vermelho = [Drawing.Color]::FromArgb(255, 107, 107)

function Rotulo($texto, $x, $y, $tam = 10, $estilo = 'Regular', $cor = $areia, $fonte = 'Segoe UI') {
  $l = New-Object Windows.Forms.Label
  $l.Text = $texto; $l.AutoSize = $true; $l.Location = New-Object Drawing.Point($x, $y)
  $l.Font = New-Object Drawing.Font($fonte, $tam, [Drawing.FontStyle]$estilo); $l.ForeColor = $cor; $l.BackColor = [Drawing.Color]::Transparent
  $l
}
function Botao($texto, $x, $y, $w, $h, $principal) {
  $b = New-Object Windows.Forms.Button
  $b.Text = $texto; $b.SetBounds($x, $y, $w, $h); $b.FlatStyle = 'Flat'; $b.Cursor = 'Hand'
  $b.Font = New-Object Drawing.Font('Segoe UI', 10.5, [Drawing.FontStyle]::Bold)
  if ($principal) { $b.BackColor = $ouro; $b.ForeColor = $ouroEscuro; $b.FlatAppearance.BorderColor = $ouro }
  else { $b.BackColor = $painel; $b.ForeColor = $areia; $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(70, 66, 58) }
  $b
}
function Marcar($texto, $y) {
  $c = New-Object Windows.Forms.CheckBox
  $c.Text = $texto; $c.Checked = $true; $c.AutoSize = $true; $c.Location = New-Object Drawing.Point(36, $y)
  $c.ForeColor = $areia; $c.Font = New-Object Drawing.Font('Segoe UI', 10); $c.Cursor = 'Hand'
  $c
}

$f = New-Object Windows.Forms.Form
$f.Text = 'Instalar o Códex Proibido'; $f.ClientSize = New-Object Drawing.Size(640, 470)
$f.StartPosition = 'CenterScreen'; $f.FormBorderStyle = 'FixedSingle'; $f.MaximizeBox = $false
$f.BackColor = $fundo; $f.ForeColor = $areia
$ico = Join-Path $origem 'codex.ico'
if (Test-Path -LiteralPath $ico) { $f.Icon = New-Object Drawing.Icon($ico) }

# topo: logo, nome em dourado e um filete de ouro
$logo = New-Object Windows.Forms.PictureBox
$logo.SizeMode = 'Zoom'; $logo.SetBounds(34, 26, 92, 92); $logo.BackColor = [Drawing.Color]::Transparent
$png = Join-Path $origem 'logo.png'
if (Test-Path -LiteralPath $png) { $logo.Image = [Drawing.Image]::FromFile($png) }
$titulo = Rotulo 'CÓDEX PROIBIDO' 140 34 26 'Bold' $ouro 'Georgia'
$sub = Rotulo 'O guia do Yu-Gi-Oh! Forbidden Legacy' 144 84 11 'Regular' $cinza
$filete = New-Object Windows.Forms.Panel
$filete.SetBounds(34, 140, 572, 1); $filete.BackColor = [Drawing.Color]::FromArgb(120, 232, 190, 88)

# pasta
$lPasta = Rotulo 'Onde instalar' 34 158 10.5 'Bold'
$pasta = New-Object Windows.Forms.TextBox
$pasta.SetBounds(36, 186, 448, 30); $pasta.Font = New-Object Drawing.Font('Segoe UI', 10.5)
$pasta.BackColor = $painel; $pasta.ForeColor = $areia; $pasta.BorderStyle = 'FixedSingle'
$pasta.Text = Join-Path $env:LOCALAPPDATA 'CodexProibido'
$procurar = Botao 'Procurar...' 494 184 112 31 $false
$procurar.Add_Click({
  $d = New-Object Windows.Forms.FolderBrowserDialog
  $d.Description = 'Escolha a pasta onde o Códex Proibido vai ficar'
  if ($d.ShowDialog($f) -eq 'OK') { $pasta.Text = Join-Path $d.SelectedPath 'CodexProibido' }
})

$cbArea = Marcar 'Criar atalho na Área de Trabalho' 232
$cbMenu = Marcar 'Criar atalho no menu Iniciar' 262
$cbAbrir = Marcar 'Abrir o Códex quando terminar' 292
$temCartas = Test-Path -LiteralPath (Join-Path $origem 'cartas')
$tamanho = if ($temCartas) { 'Ocupa cerca de 230 MB (com as imagens das cartas em alta).' } else { 'Ocupa cerca de 2 MB. Precisa de internet para as imagens das cartas.' }
$info = Rotulo $tamanho 34 330 9.5 'Regular' $cinza

# barra de progresso dourada (a do Windows só sai verde)
$barraFundo = New-Object Windows.Forms.Panel
$barraFundo.SetBounds(36, 362, 570, 8); $barraFundo.BackColor = $painel
$barraOuro = New-Object Windows.Forms.Panel
$barraOuro.SetBounds(0, 0, 0, 8); $barraOuro.BackColor = $ouro
$barraFundo.Controls.Add($barraOuro)
$barra = [pscustomobject]@{ Maximum = 1; Valor = 0 }
function Avancar($n) { $barra.Valor = [Math]::Min($n, $barra.Maximum); $barraOuro.Width = [int](570 * $barra.Valor / $barra.Maximum) }
$status = Rotulo '' 34 378 9.5 'Regular' $cinza

$instalar = Botao 'Instalar' 454 412 152 42 $true
$cancelar = Botao 'Cancelar' 328 412 116 42 $false
$cancelar.Add_Click({ $f.Close() })
$f.AcceptButton = $instalar

$script:pronto = $false
$script:destino = ''
$instalar.Add_Click({
  if ($script:pronto) {
    if ($cbAbrir.Checked) { Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', "`"$(Join-Path $script:destino 'abrir.ps1')`"" }
    $f.Close(); return
  }
  $destino = $pasta.Text.Trim()
  if (-not $destino) { $status.ForeColor = $vermelho; $status.Text = 'Escolha uma pasta para instalar.'; return }
  # sempre numa pasta própria "CodexProibido", para o desinstalador nunca apagar uma pasta da pessoa
  if ((Split-Path $destino -Leaf) -ne 'CodexProibido') { $destino = Join-Path $destino 'CodexProibido' }
  $script:destino = $destino
  foreach ($c in @($pasta, $procurar, $cbArea, $cbMenu, $cbAbrir, $instalar, $cancelar)) { $c.Enabled = $false }
  $status.ForeColor = $cinza
  try {
    New-Item -ItemType Directory -Force $destino | Out-Null
    $arquivos = @('Codex Proibido.html', 'codex.ico', 'logo.png', 'abrir.ps1', 'desinstalar.ps1', 'versao.txt') | Where-Object { Test-Path -LiteralPath (Join-Path $origem $_) }
    $cartas = @(); if ($temCartas) { $cartas = @(Get-ChildItem -LiteralPath (Join-Path $origem 'cartas') -File) }
    $total = $arquivos.Count + $cartas.Count + 2; $feito = 0
    $barra.Maximum = $total
    foreach ($a in $arquivos) {
      $status.Text = "Copiando $a..."; [Windows.Forms.Application]::DoEvents()
      Copy-Item -LiteralPath (Join-Path $origem $a) -Destination $destino -Force
      $feito++; Avancar $feito
    }
    if ($cartas.Count) {
      $dc = Join-Path $destino 'cartas'; New-Item -ItemType Directory -Force $dc | Out-Null
      $i = 0
      foreach ($c in $cartas) {
        Copy-Item -LiteralPath $c.FullName -Destination $dc -Force
        $i++; $feito++
        if ($i % 40 -eq 0) { Avancar $feito; $status.Text = "Copiando as imagens das cartas ($i de $($cartas.Count))..."; [Windows.Forms.Application]::DoEvents() }
      }
    }
    # arquivos baixados da internet vêm marcados; desmarca para o Windows não travar os scripts
    Get-ChildItem -LiteralPath $destino -Recurse -File | Unblock-File -ErrorAction SilentlyContinue
    $feito++; Avancar $feito; $status.Text = 'Criando os atalhos...'; [Windows.Forms.Application]::DoEvents()

    $shell = New-Object -ComObject WScript.Shell
    $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    function Atalho($arquivo, $script, $descricao) {
      $a = $shell.CreateShortcut($arquivo)
      $a.TargetPath = $ps
      $a.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$(Join-Path $destino $script)`""
      $a.WindowStyle = 7; $a.IconLocation = Join-Path $destino 'codex.ico'; $a.WorkingDirectory = $destino; $a.Description = $descricao
      $a.Save()
    }
    $area = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Códex Proibido.lnk'
    $menu = Join-Path ([Environment]::GetFolderPath('Programs')) 'Códex Proibido.lnk'
    $menuDes = Join-Path ([Environment]::GetFolderPath('Programs')) 'Desinstalar Códex Proibido.lnk'
    if ($cbArea.Checked) { Atalho $area 'abrir.ps1' 'Códex Proibido: guia do Yu-Gi-Oh! Forbidden Legacy' }
    if ($cbMenu.Checked) { Atalho $menu 'abrir.ps1' 'Códex Proibido: guia do Yu-Gi-Oh! Forbidden Legacy'; Atalho $menuDes 'desinstalar.ps1' 'Remove o Códex Proibido deste computador' }
    $feito++; Avancar $feito

    $status.ForeColor = $ouro; $status.Text = 'Pronto! O Códex Proibido foi instalado.'
    $instalar.Text = if ($cbAbrir.Checked) { 'Abrir o Códex' } else { 'Concluir' }
    $script:pronto = $true; $instalar.Enabled = $true; $cancelar.Visible = $false; $instalar.Focus()
  } catch {
    $status.ForeColor = $vermelho; $status.Text = 'Não deu para instalar: ' + $_.Exception.Message
    foreach ($c in @($pasta, $procurar, $cbArea, $cbMenu, $cbAbrir, $instalar, $cancelar)) { $c.Enabled = $true }
  }
})

$f.Controls.AddRange(@($logo, $titulo, $sub, $filete, $lPasta, $pasta, $procurar, $cbArea, $cbMenu, $cbAbrir, $info, $barraFundo, $status, $instalar, $cancelar))
$f.Add_Shown({ $f.ActiveControl = $instalar })
[void]$f.ShowDialog()
