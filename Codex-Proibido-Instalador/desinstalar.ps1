# Remove o Códex Proibido deste computador: pergunta antes, apaga os atalhos e a pasta onde ele foi instalado.
# Os decks salvos e a coleção ficam guardados no navegador e não são apagados.
Add-Type -AssemblyName System.Windows.Forms
$destino = Split-Path -Parent $MyInvocation.MyCommand.Path
$r = [Windows.Forms.MessageBox]::Show("Remover o Códex Proibido deste computador?`n`nPasta: $destino", 'Desinstalar o Códex Proibido', 'YesNo', 'Question')
if ($r -ne 'Yes') { return }
foreach ($atalho in @(
  (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Códex Proibido.lnk'),
  (Join-Path ([Environment]::GetFolderPath('Programs')) 'Códex Proibido.lnk'),
  (Join-Path ([Environment]::GetFolderPath('Programs')) 'Desinstalar Códex Proibido.lnk'))) {
  if (Test-Path -LiteralPath $atalho) { Remove-Item -LiteralPath $atalho -Force }
}
# só apaga a pasta se ela for mesmo a do Códex
if ((Split-Path $destino -Leaf) -eq 'CodexProibido' -and (Test-Path -LiteralPath (Join-Path $destino 'Codex Proibido.html'))) {
  Set-Location $env:TEMP
  Remove-Item -LiteralPath $destino -Recurse -Force
}
[void][Windows.Forms.MessageBox]::Show('O Códex Proibido foi removido deste computador.', 'Desinstalar o Códex Proibido', 'OK', 'Information')
