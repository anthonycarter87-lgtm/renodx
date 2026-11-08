# FS25 vehicle glass 0x9A8652D9: game droplets on outer panes + static/running drop rims, back faces drops-only.
import re,sys
src,dropsll,dst=sys.argv[1:4]
s=open(src).read(); p=open(dropsll).read()
def once(a,b):
    global s
    assert s.count(a)==1,(a[:70],s.count(a)); s=s.replace(a,b)
once('%struct.SamplerState = type { i32 }\n','%struct.SamplerState = type { i32 }\n%RenoDXShaderInjection = type { [28 x float] }\n')
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
     '  %rdx_cw = extractvalue %dx.types.CBufRet.f32 %rdx_c29, 3\n'
     '  %rdx_c40 = call %dx.types.CBufRet.f32 @dx.op.cbufferLoadLegacy.f32(i32 59, %dx.types.Handle %14, i32 40)\n'
     '  %rdx_t = extractvalue %dx.types.CBufRet.f32 %rdx_c40, 3\n')
# wetness: with drops on, outer panes (local normal . local pos >= 0) use max(vehicle wetness, cWetness), no UV gate
once('  %91 = fmul fast float %88, %90',
     '  %rdx_od = call float @dx.op.dot3.f32(i32 55, float %20, float %21, float %22, float %23, float %24, float %25)\n'
     '  %rdx_out = fcmp fast oge float %rdx_od, 0.000000e+00\n'
     '  %rdx_onout = and i1 %rdx_on, %rdx_out\n'
     '  %rdx_w0 = fmul fast float %88, %90\n'
     '  %rdx_wm = call float @dx.op.binary.f32(i32 35, float %88, float %rdx_cw)\n'
     '  %91 = select i1 %rdx_onout, float %rdx_wm, float %rdx_w0')
once('  %323 = fmul fast float %130, 5.000000e-01\n  %324 = fmul fast float %131, 5.000000e-01',
     '  %rdx_ds = select i1 %rdx_on, float 1.000000e+00, float 5.000000e-01\n'
     '  %323 = fmul fast float %130, %rdx_ds\n  %324 = fmul fast float %131, %rdx_ds')
# re-sample the droplet normal map at the end (same projected uv, 2x density)
resample=('  %rdx_ob = call %dx.types.ResRet.f32 @dx.op.rawBufferLoad.f32(i32 139, %dx.types.Handle %2, i32 %168, i32 0, i8 15, i32 4)\n'
      '  %rdx_tw = extractvalue %dx.types.ResRet.f32 %rdx_ob, 3\n'
      '  %rdx_ti = bitcast float %rdx_tw to i32\n'
      '  %rdx_th = call %dx.types.Handle @dx.op.createHandle(i32 57, i8 0, i32 0, i32 %rdx_ti, i1 false)\n'
      '  %rdx_smp = call %dx.types.ResRet.f32 @dx.op.sample.f32(i32 60, %dx.types.Handle %rdx_th, %dx.types.Handle %12, float %130, float %131, float undef, float undef, i32 0, i32 0, i32 undef, float undef)\n'
      '  %rdx_nx = extractvalue %dx.types.ResRet.f32 %rdx_smp, 0\n'
      '  %rdx_ny = extractvalue %dx.types.ResRet.f32 %rdx_smp, 1\n')
# splice drops block
body=re.search(r'define void @main\(\) \{\n(.*?)\n  ret void',p,re.S).group(1).split('\n')
inmap={(0,0):'%36',(0,1):'%37',(0,2):'%38',(0,3):'%91',(1,0):'%28',(1,1):'%29',(1,2):'%30',(1,3):'%rdx_s',
       (2,0):'%23',(2,1):'%24',(2,2):'%25',(2,3):'%rdx_t',(3,0):'%20',(3,1):'%21',(3,2):'%22',(3,3):'%523',
       (4,0):'%rdx_nx',(4,1):'%rdx_ny',(4,2):'%130',(4,3):'%131',(5,0):'%1562',(5,1):'%1563',(5,2):'%1564'}
sub={}; out={}; code=[]
for l in body:
    l=l.split('  ;')[0].rstrip()
    mm=re.match(r'\s*(%\d+) = call float @dx\.op\.loadInput\.f32\(i32 4, i32 (\d+), i32 0, i8 (\d+), i32 undef\)',l)
    if mm: sub[mm.group(1)]=inmap[(int(mm.group(2)),int(mm.group(3)))]; continue
    mm=re.match(r'\s*call void @dx\.op\.storeOutput\.f32\(i32 5, i32 (\d+), i32 0, i8 (\d+), float (\S+)\)',l)
    if mm: out[(int(mm.group(1)),int(mm.group(2)))]=mm.group(3); continue
    code.append(re.sub(r'%(\d+)\b',lambda q: sub.get('%'+q.group(1),'%gd_'+q.group(1)),l))
out={k:(sub.get(v) or ('%gd_'+v[1:] if re.match(r'%\d+$',v) else v)) for k,v in out.items()}
for fn in set(re.findall(r'@(dx\.op\.[\w.]+)',' '.join(code))):
    assert re.search(r'declare [^\n]*@'+re.escape(fn)+r'\(',s), fn
anchor='  call void @dx.op.storeOutput.f32(i32 5, i32 0, i32 0, i8 0, float %1562)'
assert s.count(anchor)==1
s=s.replace(anchor, resample+'\n'.join(code)+'\n'+anchor)
# outputs: only when drops on, else original values
for col,orig in ((0,'%1562'),(1,'%1563'),(2,'%1564'),(3,'%523')):
    old=f'  call void @dx.op.storeOutput.f32(i32 5, i32 0, i32 0, i8 {col}, float {orig})'
    once(old, f'  %rdx_o{col} = select i1 %rdx_on, float {out[(0,col)]}, float {orig}\n  call void @dx.op.storeOutput.f32(i32 5, i32 0, i32 0, i8 {col}, float %rdx_o{col})')
open(dst,'w').write(s)
print('ok',len(code),'spliced')
