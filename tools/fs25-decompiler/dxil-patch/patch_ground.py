import re,sys
src,dst=sys.argv[1],sys.argv[2]
s=open(src).read()
def once(old,new):
    global s
    assert s.count(old)==1,(old[:80],s.count(old))
    s=s.replace(old,new)
# 1. type for our injection cbuffer (shared.h ShaderInjectData, 28 floats = 112 bytes)
once('%struct.SamplerState = type { i32 }\n','%struct.SamplerState = type { i32 }\n%RenoDXShaderInjection = type { [28 x float] }\n')
# 2. handle for b13 space50 (CBV range id 1)
m=re.search(r'(  %26 = call %dx\.types\.Handle @dx\.op\.createHandle\(i32 57, i8 2, i32 0, i32 0, i1 false\)[^\n]*\n)',s)
once(m.group(1), m.group(1)+'  %rdx_h = call %dx.types.Handle @dx.op.createHandle(i32 57, i8 2, i32 1, i32 13, i1 false)\n')
# 3. Wet Ground: roughness = lerp(r, min(r, 0.08), saturate(wet) * strength) before the 0.04 floor
old='  %1645 = call float @dx.op.binary.f32(i32 35, float %1644, float 0x3FA47AE140000000)'
assert s.count('%1621 = phi float [ %1619, %1617 ], [ -1.000000e+00, %1369 ]')==1
new=('  %rdx_cb = call %dx.types.CBufRet.f32 @dx.op.cbufferLoadLegacy.f32(i32 59, %dx.types.Handle %rdx_h, i32 6)\n'
     '  %rdx_s = extractvalue %dx.types.CBufRet.f32 %rdx_cb, 0\n'
     '  %rdx_w = call float @dx.op.unary.f32(i32 7, float %1621)\n'
     '  %rdx_ws0 = fmul fast float %rdx_w, %rdx_s\n'
     '  %rdx_ws = fmul fast float %rdx_ws0, 7.500000e-01\n'
     '  %rdx_m = call float @dx.op.binary.f32(i32 36, float %1644, float 0x3FB47AE140000000)\n'
     '  %rdx_d = fsub fast float %rdx_m, %1644\n'
     '  %rdx_t = fmul fast float %rdx_d, %rdx_ws\n'
     '  %rdx_r = fadd fast float %rdx_t, %1644\n'
     '  %1645 = call float @dx.op.binary.f32(i32 35, float %rdx_r, float 0x3FA47AE140000000)')
once(old,new)
# 4. metadata: add CBV
mx=max(int(x) for x in re.findall(r'^!(\d+) = ',s,re.M))+1
once('!28 = !{!29}\n', f'!28 = !{{!29, !{mx}}}\n')
s=s.rstrip('\n')+f'\n!{mx} = !{{i32 1, %RenoDXShaderInjection* undef, !"", i32 50, i32 13, i32 1, i32 112, null}}\n'
open(dst,'w').write(s)
print('patched, new md', mx)
