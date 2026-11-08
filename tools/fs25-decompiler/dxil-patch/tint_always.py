import re,sys,struct
def f(x):
    d=struct.unpack('<f',struct.pack('<f',x))[0]; return '0x%016X'%struct.unpack('<Q',struct.pack('<d',d))[0]
src,dst,r,g,b=sys.argv[1],sys.argv[2],float(sys.argv[3]),float(sys.argv[4]),float(sys.argv[5])
s=open(src).read(); col=(r,g,b)
def rep(m):
    c=int(m.group(1))
    if c==3: return m.group(0)
    return f'  call void @dx.op.storeOutput.f32(i32 5, i32 0, i32 0, i8 {c}, float {f(col[c])})'
s,n=re.subn(r'  call void @dx\.op\.storeOutput\.f32\(i32 5, i32 0, i32 0, i8 (\d), float [^)]+\)',rep,s)
assert n>=3; open(dst,'w').write(s)
