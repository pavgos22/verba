param([string]$OutDir = "$PSScriptRoot\..\assets\sounds")

function New-Silence {
  param([int]$DurMs, [int]$Rate = 44100)
  return ,(New-Object double[] ([int]($Rate * $DurMs / 1000.0)))
}

function New-Tone {
  param([double]$FreqStart, [double]$FreqEnd, [int]$DurMs, [double]$Amp = 0.35, [int]$Rate = 44100)
  $n = [int]($Rate * $DurMs / 1000.0)
  $out = New-Object double[] $n
  $phase = 0.0
  for ($i = 0; $i -lt $n; $i++) {
    $t = $i / [double]$n
    $f = $FreqStart + ($FreqEnd - $FreqStart) * $t
    $phase += 2 * [math]::PI * $f / $Rate
    $attack = [math]::Min(1.0, $i / ($Rate * 0.005))
    $env = $attack * [math]::Exp(-3.5 * $t)
    $out[$i] = [math]::Sin($phase) * $Amp * $env
  }
  return ,$out
}

function New-Wav {
  param([string]$Path, [double[]]$Samples, [int]$Rate = 44100)
  $dataSize = $Samples.Count * 2
  $ms = New-Object System.IO.MemoryStream
  $bw = New-Object System.IO.BinaryWriter($ms)
  $bw.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
  $bw.Write([int](36 + $dataSize))
  $bw.Write([System.Text.Encoding]::ASCII.GetBytes("WAVEfmt "))
  $bw.Write([int]16)
  $bw.Write([int16]1)
  $bw.Write([int16]1)
  $bw.Write([int]$Rate)
  $bw.Write([int]($Rate * 2))
  $bw.Write([int16]2)
  $bw.Write([int16]16)
  $bw.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
  $bw.Write([int]$dataSize)
  foreach ($s in $Samples) {
    $clamped = [math]::Max(-1.0, [math]::Min(1.0, $s))
    $bw.Write([int16][math]::Round($clamped * 32767))
  }
  $bw.Flush()
  [System.IO.File]::WriteAllBytes($Path, $ms.ToArray())
}

New-Item -ItemType Directory -Force $OutDir | Out-Null
$lead = New-Silence -DurMs 50
$correct = $lead + (New-Tone -FreqStart 660 -FreqEnd 660 -DurMs 80) + (New-Tone -FreqStart 880 -FreqEnd 880 -DurMs 150)
New-Wav -Path (Join-Path $OutDir "correct.wav") -Samples $correct
$almost = $lead + (New-Tone -FreqStart 392 -FreqEnd 392 -DurMs 150 -Amp 0.3)
New-Wav -Path (Join-Path $OutDir "almost.wav") -Samples $almost
$wrong = $lead + (New-Tone -FreqStart 175 -FreqEnd 130 -DurMs 200)
New-Wav -Path (Join-Path $OutDir "wrong.wav") -Samples $wrong
Get-ChildItem $OutDir | Select-Object Name, Length
