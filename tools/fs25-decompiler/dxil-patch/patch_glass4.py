# FS25 vehicle glass 0x9A8652D9 (single-sided): game droplets on glass + lens drops (sky refraction) + running drops.
import re,sys
src,dirll,compll,dst=sys.argv[1:5]
s=open(src).read()
def once(a,b):
    global s
    assert s.count(a)==1,(a[:70],s.count(a)); s=s.replace(a,b)
def splice(ll,inmap,prefix):
    p=open(ll).read()
    body=re.search(r'define void @main\(\) \{\n(.*?)\n  ret void',p,re.S).group(1).split('\n')
    sub={}; out={}; code=[]
    for l in body:
        l=l.split('  ;')[0].rstrip()
        mm=re.match(r'\s*(%\d+) = call float @dx\.op\.loadInput\.f32\(i32 4, i32 (\d+), i32 0, i8 (\d+), i32 undef\)',l)
        if mm: sub[mm.group(1)]=inmap[(int(mm.group(2)),int(mm.group(3)))]; continue
        mm=re.match(r'\s*call void @dx\.op\.storeOutput\.f32\(i32 5, i32 (\d+), i32 0, i8 (\d+), float (\S+)\)',l)
        if mm: out[(int(mm.group(1)),int(mm.group(2)))]=mm.group(3); continue
        assert not re.match(r'\s*br |^; <label>',l)
        code.append(re.sub(r'%(\d+)\b',lambda q: sub.get('%'+q.group(1),f'%{prefix}_'+q.group(1)),l))
    out={k:(sub.get(v) or (f'%{prefix}_'+v[1:] if re.match(r'%\d+$',v) else v)) for k,v in out.items()}
    for fn in set(re.findall(r'@(dx\.op\.[\w.]+)',' '.join(code))):
        assert re.search(r'declare [^\n]*@'+re.escape(fn)+r'\(',s), fn
    return code,out
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
once('  %91 = fmul fast float %88, %90',
     '  %rdx_w0 = fmul fast float %88, %90\n'
     '  %rdx_wm = call float @dx.op.binary.f32(i32 35, float %88, float %rdx_cw)\n'
     '  %91 = select i1 %rdx_on, float %rdx_wm, float %rdx_w0')
once('  %323 = fmul fast float %130, 5.000000e-01\n  %324 = fmul fast float %131, 5.000000e-01',
     '  %rdx_ds = select i1 %rdx_on, float 1.000000e+00, float 5.000000e-01\n'
     '  %323 = fmul fast float %130, %rdx_ds\n  %324 = fmul fast float %131, %rdx_ds')
resample=['  %rdx_ob = call %dx.types.ResRet.f32 @dx.op.rawBufferLoad.f32(i32 139, %dx.types.Handle %2, i32 %168, i32 0, i8 15, i32 4)',
      '  %rdx_tw = extractvalue %dx.types.ResRet.f32 %rdx_ob, 3',
      '  %rdx_ti = bitcast float %rdx_tw to i32',
      '  %rdx_th = call %dx.types.Handle @dx.op.createHandle(i32 57, i8 0, i32 0, i32 %rdx_ti, i1 false)',
      '  %rdx_smp = call %dx.types.ResRet.f32 @dx.op.sample.f32(i32 60, %dx.types.Handle %rdx_th, %dx.types.Handle %12, float %130, float %131, float undef, float undef, i32 0, i32 0, i32 undef, float undef)',
      '  %rdx_nx = extractvalue %dx.types.ResRet.f32 %rdx_smp, 0',
      '  %rdx_ny = extractvalue %dx.types.ResRet.f32 %rdx_smp, 1']
dcode,dout=splice(dirll,{(0,0):'%36',(0,1):'%37',(0,2):'%38',(1,0):'%28',(1,1):'%29',(1,2):'%30',
                         (2,0):'%32',(2,1):'%33',(2,2):'%34',(2,3):'%35',(3,0):'%rdx_nx',(3,1):'%rdx_ny',
                         (4,0):'%130',(4,1):'%131',(4,2):'%rdx_t'},'ld')
env=[f'  %rdx_env = call %dx.types.ResRet.f32 @dx.op.sampleLevel.f32(i32 62, %dx.types.Handle %9, %dx.types.Handle %10, float {dout[(0,0)]}, float {dout[(0,1)]}, float {dout[(0,2)]}, float undef, i32 undef, i32 undef, i32 undef, float {dout[(0,3)]})',
     '  %rdx_er = extractvalue %dx.types.ResRet.f32 %rdx_env, 0',
     '  %rdx_eg = extractvalue %dx.types.ResRet.f32 %rdx_env, 1',
     '  %rdx_eb = extractvalue %dx.types.ResRet.f32 %rdx_env, 2',
     f'  %rdx_smp2 = call %dx.types.ResRet.f32 @dx.op.sample.f32(i32 60, %dx.types.Handle %rdx_th, %dx.types.Handle %12, float {dout[(1,0)]}, float {dout[(1,1)]}, float undef, float undef, i32 0, i32 0, i32 undef, float undef)',
     '  %rdx_nx2 = extractvalue %dx.types.ResRet.f32 %rdx_smp2, 0',
     '  %rdx_ny2 = extractvalue %dx.types.ResRet.f32 %rdx_smp2, 1']
ccode,cout=splice(compll,{(0,0):'%91',(0,1):'%rdx_s',(0,2):'%rdx_t',(1,0):'%rdx_nx',(1,1):'%rdx_ny',(1,2):'%130',(1,3):'%131',
                          (2,0):'%1562',(2,1):'%1563',(2,2):'%1564',(2,3):'%523',(3,0):'%rdx_er',(3,1):'%rdx_eg',(3,2):'%rdx_eb',
                          (4,0):'%rdx_nx2',(4,1):'%rdx_ny2',(4,2):dout[(1,2)]},'lc')
anchor='  call void @dx.op.storeOutput.f32(i32 5, i32 0, i32 0, i8 0, float %1562)'
assert s.count(anchor)==1
s=s.replace(anchor,'\n'.join(resample+dcode+env+ccode)+'\n'+anchor)
for col,orig in ((0,'%1562'),(1,'%1563'),(2,'%1564'),(3,'%523')):
    once(f'  call void @dx.op.storeOutput.f32(i32 5, i32 0, i32 0, i8 {col}, float {orig})',
         f'  %rdx_o{col} = select i1 %rdx_on, float {cout[(0,col)]}, float {orig}\n  call void @dx.op.storeOutput.f32(i32 5, i32 0, i32 0, i8 {col}, float %rdx_o{col})')
open(dst,'w').write(s)
print('ok dir',len(dcode),'compose',len(ccode))
