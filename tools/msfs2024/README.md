# MSFS 2024 shader tools (no DXC needed)

The cloud sandbox couldn't download DXC on 10 Nov 2026 (GitHub releases/NuGet blocked).
`dxil2ll.py` reads DevKit `.cso` dumps with `llvmlite` (pip) instead:
- extracts the DXIL bitcode from the DXBC container,
- patches the data layout string (VBR6-encoded `i1:32-i8:32` -> `i8:8-i1:8:8`, same bit length) so modern LLVM accepts it,
- writes LLVM text IR (`.ll`, modern syntax: opaque `ptr`, `fneg`).

Usage: `pip install llvmlite numpy` then `python3 -I dxil2ll.py <dump_dir> <out_dir>`.
2386 of 2388 shaders convert (2 are DXBC SM5).

`shader_names_2026-11-10.txt` = entry-point name per hash (Asobo keeps names: `ph_tonemapping`, `ch_updateColorGradingLUT`, ...).

The RenoDX decompiler (fs25-tools branch) needs real `dxc -dumpbin` text (comment headers, typed pointers),
so this IR is for reading/grepping. `norm.py` is a first step at converting it, not finished.
