# XMLCLI
<img src=https://github.com/cannaseedus-bot/XMLCLI/blob/main/K%CE%BCh%CE%BCl.png>

K'UHUL Power Shell: Quantum SVG CLI artifacts for generating SVG-driven PowerShell experiences.

## Files

- `Kμhμl.ps1` is the canonical T-UI entrypoint, merging the K'UHUL core, Micronaut AGL runtime,
  and extended system emitters into a single script.
- `kuhul-schema-core.v1.md` defines the frozen `kuhul://schema/core.v1` execution law.
- `profile.ps1` provides a profile wrapper for loading the canonical entrypoint and setting up the prompt.

Remaining batch SVG runner scripts: none.

## Mx2LM Object Law Additions

`Kμhμl.ps1` now includes object-law helpers for Mx2LM and SCXQ2:

- `Get-Mx2LMEquation` prints the unified architecture definition.
- `Get-QuantizationSchema` emits the quantization object schema.
- `New-QuantizedTensorObject` builds a quantized tensor object manifest.
- `Show-SCXQ2Lanes` renders the quantized geometry/weight lane definitions.
- `Show-ObjectServerPipeline` prints the deterministic object server pipeline.

## K'UHUL Unified System

The unified system XML (v5.0) is available via:

- `Show-KuhulUnifiedSystem` (alias: `kunified`) to emit the complete unified architecture.

## PrimeOS Micronaut Factory

The PrimeOS Micronaut Factory PowerShell edition can be emitted via:

- `Show-PrimeOSMicronautFactory` (alias: `kprimeos`) to output the full script.

## ASX RAM Database

The ASX RAM Database PowerShell implementation can be emitted via:

- `Show-ASXRamDatabase` (alias: `kasxram`) to output the full script.

## ASX T-UI Workstation

The ASX T-UI Terminal AI Workstation PowerShell implementation can be emitted via:

- `Show-ASXTuiWorkstation` (alias: `kastui`) to output the full script from `asx-tui.ps1`.

To run it directly from this repo:

- `./run-asx-tui.ps1` (PowerShell entrypoint)
- Or execute `./asx-tui.ps1` if you want to call the script directly.

## K'UHUL Micronaut Factory

The K'UHUL Micronaut Factory PowerShell module can be emitted via:

- `Show-KuhulMicronautFactory` (alias: `kmicro`) to output the full script.

## K'UHUL Quantum Agent System

The K'UHUL Quantum Agent System PowerShell implementation can be emitted via:

- `Show-KuhulQuantumAgentSystem` (alias: `kagent`) to output the full script.

## World Computer Manifesto

The World Computer manifesto and PowerShell adapter specification can be emitted via:

- `Show-WorldComputerManifesto` (alias: `kworld`) to output the full adapter spec and summary.
