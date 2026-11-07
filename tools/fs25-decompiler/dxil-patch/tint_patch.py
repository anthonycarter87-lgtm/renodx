# Generic debug-tint DXIL patch: adds RenoDX injection CBV and overrides SV_Target0.rgb by debug mode (c6.z).
# mode 1: tint by group colour (index % 8); mode 2+g: shaders in group g tinted by member colour (index // 8).
import re,sys
PAL=[(1,0,0),(0,1,0),(0,0.3,1),(1,1,0),(0,1,1),(1,0,1),(1,1,1),(1,0.4,0)]
import struct
def f(x):
    d=struct.unpack('<d',struct.pack('<d',struct.unpack('<f',struct.pack('<f',x))[0]))[0]
    return '0x%016X'%struct.unpack('<Q',struct.pack('<d',d))[0]
def patch(s,idx):
    g,m=idx%8,idx//8
    def once(a,b):
        nonlocal s
        assert s.count(a)==1,(a[:60],s.count(a)); s=s.replace(a,b)
    # type
    first_type=re.search(r'^%[^\n]* = type [^\n]*\n',s,re.M)
    s=s[:first_type.start()]+'%RenoDXShaderInjection = type { [28 x float] }\n'+s[first_type.start():]
    if '%dx.types.CBufRet.f32 = type' not in s:
        s=s[:first_type.start()]+'%dx.types.CBufRet.f32 = type { float, float, float, float }\n'+s[first_type.start():]
    if 'declare %dx.types.CBufRet.f32 @dx.op.cbufferLoadLegacy.f32' not in s:
        s=s.replace('\ndeclare void @dx.op.storeOutput.f32','\ndeclare %dx.types.CBufRet.f32 @dx.op.cbufferLoadLegacy.f32(i32, %dx.types.Handle, i32) #2\n\ndeclare void @dx.op.storeOutput.f32',1)
    # resources
    m4=re.search(r'^!dx\.resources = !\{!(\d+)\}',s,re.M); rn=m4.group(1)
    mr=re.search(r'^!'+rn+r' = !\{(.*)\}$',s,re.M)
    parts=[p.strip() for p in mr.group(1).split(',')]
    while len(parts)<4: parts.append('null')
    mx=max(int(x) for x in re.findall(r'^!(\d+) = ',s,re.M))+1
    new_cb=f'!{mx} = !{{i32 RID, %RenoDXShaderInjection* undef, !"", i32 50, i32 13, i32 1, i32 112, null}}'
    if parts[2]=='null':
        rid=0; parts[2]=f'!{mx+1}'; extra=[new_cb.replace('RID','0'), f'!{mx+1} = !{{!{mx}}}']
    else:
        cbn=parts[2][1:]; mc=re.search(r'^!'+cbn+r' = !\{(.*)\}$',s,re.M)
        items=[p.strip() for p in mc.group(1).split(',')]; rid=len(items)
        s=s[:mc.start()]+f'!{cbn} = !{{{", ".join(items+[f"!{mx}"])}}}'+s[mc.end():]
        extra=[new_cb.replace('RID',str(rid))]
    mr=re.search(r'^!'+rn+r' = !\{(.*)\}$',s,re.M)
    s=s[:mr.start()]+f'!{rn} = !{{{", ".join(parts)}}}'+s[mr.end():]
    s=s.rstrip('\n')+'\n'+'\n'.join(extra)+'\n'
    # handle + mode at function entry
    md=re.search(r'^define void @\w+\(\) \{\n',s,re.M)
    ins=(f'  %rdx_h = call %dx.types.Handle @dx.op.createHandle(i32 57, i8 2, i32 {rid}, i32 13, i1 false)\n'
         f'  %rdx_cb = call %dx.types.CBufRet.f32 @dx.op.cbufferLoadLegacy.f32(i32 59, %dx.types.Handle %rdx_h, i32 6)\n'
         f'  %rdx_d = extractvalue %dx.types.CBufRet.f32 %rdx_cb, 2\n'
         f'  %rdx_m1 = fcmp fast oeq float %rdx_d, 1.000000e+00\n'
         f'  %rdx_mg = fcmp fast oeq float %rdx_d, {f(2+g)}\n')
    s=s[:md.end()]+ins+s[md.end():]
    # outputs
    k=[0]
    def rep(mo):
        col=int(mo.group(1)); val=mo.group(2); k[0]+=1; n=k[0]
        if col==3: return mo.group(0)
        a=PAL[g][col]; b=PAL[m%8][col]
        return (f'  %rdx_t{n} = select i1 %rdx_mg, float {f(b)}, float {val}\n'
                f'  %rdx_u{n} = select i1 %rdx_m1, float {f(a)}, float %rdx_t{n}\n'
                f'  call void @dx.op.storeOutput.f32(i32 5, i32 0, i32 0, i8 {col}, float %rdx_u{n})')
    s,cnt=re.subn(r'  call void @dx\.op\.storeOutput\.f32\(i32 5, i32 0, i32 0, i8 (\d), float ([^)]+)\)[^\n]*',rep,s)
    assert cnt>=3
    return s
if __name__=='__main__':
    src,idx,dst=sys.argv[1],int(sys.argv[2]),sys.argv[3]
    open(dst,'w').write(patch(open(src).read(),idx))
