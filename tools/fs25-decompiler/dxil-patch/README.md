# DXIL patching (for shaders too big/slow to decompile)

FS25's terrain material shader (0x1EB3A314) decompiles only via state-machine mode, which runs ~10x slower.
Instead we patch the game's own DXIL text and reassemble it.

1. Disassemble: `dxc -dumpbin 0xHASH.ps_6_4.cso > 0xHASH.ps_6_4.ll` (DevKit dumps already include .ll).
2. Patch: `python3 patch_ground.py in.ll out.ll` - adds the RenoDX injection cbuffer (b13, space50, CBV range 1)
   plus the Wet Ground instructions. Use non-numeric SSA names (`%rdx_*`) so numbering is untouched.
3. Assemble + validate + sign: `g++ -std=c++17 -I<dxc>/include dxasm.cpp -L<dxc>/lib -ldxcompiler -o dxasm`,
   then `LD_LIBRARY_PATH=<dxc>/lib ./dxasm out.ll out.cso` (IDxcAssembler + IDxcValidator in-place sign).
4. Check: `dxc -dumpbin out.cso` op counts vs original should differ only by the added ops.
5. Embed as a byte array header and add `CustomShaderEntry(0xHASH)` in addon.cpp.

The reassembled container drops RTS0 (embedded root signature), same as RenoDX's HLSL replacements.
