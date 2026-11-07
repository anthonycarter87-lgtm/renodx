# Stage 2: splice the compiled puddle block (puddle/puddle.ll) into the Wet-Ground-patched terrain shader.
import re,sys
src,pud,dst=sys.argv[1:4]
s=open(src).read(); p=open(pud).read()
body=re.search(r'define void @main\(\) \{\n(.*?)\n  ret void',p,re.S).group(1).split('\n')
assert not any(re.match(r'\s*br |^; <label>',l) for l in body), 'puddle block must be branch-free'
inmap={(0,0):'%rdx_wpx',(0,1):'%rdx_wpy',(0,2):'%rdx_wpz',(0,3):'%1621',
       (1,0):'%1175',(1,1):'%1176',(1,2):'%1177',(1,3):'%rdx_r',
       (2,0):'%1641',(2,1):'%1642',(2,2):'%1643',(2,3):'%rdx_p'}
sub={}; out={}; code=[]
for l in body:
    l=l.split('  ;')[0].rstrip()
    m=re.match(r'\s*(%\d+) = call float @dx\.op\.loadInput\.f32\(i32 4, i32 (\d+), i32 0, i8 (\d+), i32 undef\)',l)
    if m: sub[m.group(1)]=inmap[(int(m.group(2)),int(m.group(3)))]; continue
    m=re.match(r'\s*call void @dx\.op\.storeOutput\.f32\(i32 5, i32 (\d+), i32 0, i8 (\d+), float (\S+)\)',l)
    if m: out[(int(m.group(1)),int(m.group(2)))]=m.group(3); continue
    code.append(l)
def ren(t):
    t=re.sub(r'%(\d+)\b',lambda m: sub.get('%'+m.group(1),'%pdl_'+m.group(1)),t)
    return t
code=[ren(l) for l in code]
out={k:(sub.get(v) or ('%pdl_'+v[1:] if re.match(r'%\d+$',v) else v)) for k,v in out.items()}
# every dx.op used must already be declared in the game shader
for fn in set(re.findall(r'@(dx\.op\.[\w.]+)',' '.join(code))):
    assert ('declare' in s and re.search(r'declare [^\n]*@'+re.escape(fn)+r'\(',s)), fn
pre=['  %rdx_p = extractvalue %dx.types.CBufRet.f32 %rdx_cb, 1']
for i,c in zip((16,17,18),'xyz'):
    pre.append(f'  %rdx_c{c} = call %dx.types.CBufRet.f32 @dx.op.cbufferLoadLegacy.f32(i32 59, %dx.types.Handle %26, i32 {i})')
    pre.append(f'  %rdx_cam{c} = extractvalue %dx.types.CBufRet.f32 %rdx_c{c}, 3')
pre+=['  %rdx_wpx = fadd fast float %30, %rdx_camx','  %rdx_wpy = fadd fast float %31, %rdx_camy','  %rdx_wpz = fadd fast float %32, %rdx_camz']
anchor='  %1645 = call float @dx.op.binary.f32(i32 35, float %rdx_r, float 0x3FA47AE140000000)'
assert s.count(anchor)==1
head,tail=s.split(anchor)
# replace uses after the insertion point
rep={'%1175':out[(0,0)],'%1176':out[(0,1)],'%1177':out[(0,2)],'%1641':out[(1,0)],'%1642':out[(1,1)],'%1643':out[(1,2)]}
fn_end=tail.index('\n}\n')
tbody=tail[:fn_end]
for k,v in rep.items():
    tbody=re.sub(re.escape(k)+r'\b',v,tbody)
newanchor=anchor.replace('float %rdx_r,','float '+out[(0,3)]+',')
s=head+'\n'.join(pre+code)+'\n'+newanchor+tbody+tail[fn_end:]
open(dst,'w').write(s)
print('spliced',len(code),'instructions; outputs',out)
