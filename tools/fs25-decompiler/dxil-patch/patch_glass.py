# FS25 vehicle glass (vehicleShader, alpha-blended) 0x9A8652D9: enable the game's own water droplets on glass
# and make them visible. CUSTOM_GLASS_DROPS = injection c6.z.
import re,sys,struct
def f(x):
    d=struct.unpack('<f',struct.pack('<f',x))[0]
    return '0x%016X'%struct.unpack('<Q',struct.pack('<d',d))[0]
src,dst=sys.argv[1],sys.argv[2]
s=open(src).read()
def once(a,b):
    global s
    assert s.count(a)==1,(a[:70],s.count(a)); s=s.replace(a,b)
# --- injection CBV (range id 1, after RenderArgParameters) ---
once('%struct.SamplerState = type { i32 }\n','%struct.SamplerState = type { i32 }\n%RenoDXShaderInjection = type { [28 x float] }\n') if '%struct.SamplerState = type { i32 }\n' in s else None
mx=max(int(x) for x in re.findall(r'^!(\d+) = ',s,re.M))+1
once('!19 = !{!20}\n',f'!19 = !{{!20, !{mx}}}\n')
s=s.rstrip('\n')+f'\n!{mx} = !{{i32 1, %RenoDXShaderInjection* undef, !"", i32 50, i32 13, i32 1, i32 112, null}}\n'
m=re.search(r'(  %14 = call %dx\.types\.Handle @dx\.op\.createHandle\(i32 57, i8 2, i32 0, i32 0, i1 false\)[^\n]*\n)',s)
once(m.group(1), m.group(1)+
     '  %rdx_h = call %dx.types.Handle @dx.op.createHandle(i32 57, i8 2, i32 1, i32 13, i1 false)\n'
     '  %rdx_cb = call %dx.types.CBufRet.f32 @dx.op.cbufferLoadLegacy.f32(i32 59, %dx.types.Handle %rdx_h, i32 6)\n'
     '  %rdx_s = extractvalue %dx.types.CBufRet.f32 %rdx_cb, 2\n'
     '  %rdx_on = fcmp fast ogt float %rdx_s, 0.000000e+00\n'
     '  %rdx_c29 = call %dx.types.CBufRet.f32 @dx.op.cbufferLoadLegacy.f32(i32 59, %dx.types.Handle %14, i32 29)\n'
     '  %rdx_cw = extractvalue %dx.types.CBufRet.f32 %rdx_c29, 3\n')
# --- 1. wetness mask: game = objectWetness * (uv.y > 0). With drops on: max(objectWetness, global cWetness), no UV gate.
once('  %91 = fmul fast float %88, %90',
     '  %rdx_w0 = fmul fast float %88, %90\n'
     '  %rdx_wm = call float @dx.op.binary.f32(i32 35, float %88, float %rdx_cw)\n'
     '  %91 = select i1 %rdx_on, float %rdx_wm, float %rdx_w0')
# --- 2. visible drops: re-sample the game's waterDroplets normal map (same projected uvs * 0.5), rims raise alpha
#        (premultiplied blend -> darkens what is behind the drop rim, like a real lens edge)
end_anchor='  call void @dx.op.storeOutput.f32(i32 5, i32 0, i32 0, i8 0, float %1562)'
assert s.count(end_anchor)==1
code=('  %rdx_ob = call %dx.types.ResRet.f32 @dx.op.rawBufferLoad.f32(i32 139, %dx.types.Handle %2, i32 %168, i32 0, i8 15, i32 4)\n'
      '  %rdx_tw = extractvalue %dx.types.ResRet.f32 %rdx_ob, 3\n'
      '  %rdx_ti = bitcast float %rdx_tw to i32\n'
      '  %rdx_th = call %dx.types.Handle @dx.op.createHandle(i32 57, i8 0, i32 0, i32 %rdx_ti, i1 false)\n'
      '  %rdx_u = fmul fast float %130, 5.000000e-01\n'
      '  %rdx_v = fmul fast float %131, 5.000000e-01\n'
      '  %rdx_smp = call %dx.types.ResRet.f32 @dx.op.sample.f32(i32 60, %dx.types.Handle %rdx_th, %dx.types.Handle %12, float %rdx_u, float %rdx_v, float undef, float undef, i32 0, i32 0, i32 undef, float undef)\n'
      '  %rdx_nx = extractvalue %dx.types.ResRet.f32 %rdx_smp, 0\n'
      '  %rdx_ny = extractvalue %dx.types.ResRet.f32 %rdx_smp, 1\n'
      '  %rdx_dx = fadd fast float %rdx_nx, -5.000000e-01\n'
      '  %rdx_dy = fadd fast float %rdx_ny, -5.000000e-01\n'
      '  %rdx_ax = call float @dx.op.unary.f32(i32 6, float %rdx_dx)\n'
      '  %rdx_ay = call float @dx.op.unary.f32(i32 6, float %rdx_dy)\n'
      '  %rdx_e = fadd fast float %rdx_ax, %rdx_ay\n'
     f'  %rdx_e4 = fmul fast float %rdx_e, {f(5.0)}\n'
      '  %rdx_m = call float @dx.op.unary.f32(i32 7, float %rdx_e4)\n'
      '  %rdx_w = call float @dx.op.unary.f32(i32 7, float %91)\n'
      '  %rdx_ws = fmul fast float %rdx_w, %rdx_s\n'
      '  %rdx_m2 = fmul fast float %rdx_m, %rdx_ws\n'
     f'  %rdx_da = fsub fast float {f(0.7)}, %523\n'
      '  %rdx_dm = fmul fast float %rdx_da, %rdx_m2\n'
      '  %rdx_ap = fadd fast float %rdx_dm, %523\n'
      '  %rdx_a = call float @dx.op.unary.f32(i32 7, float %rdx_ap)\n')
s=s.replace(end_anchor, code+end_anchor)
once('  call void @dx.op.storeOutput.f32(i32 5, i32 0, i32 0, i8 3, float %523)','  call void @dx.op.storeOutput.f32(i32 5, i32 0, i32 0, i8 3, float %rdx_a)')
open(dst,'w').write(s)
print('ok, md',mx)
