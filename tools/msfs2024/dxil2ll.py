import sys, struct, os
import numpy as np
import llvmlite.binding as llvm

OLD=b"i1:32-i8:32"; NEW=b"i8:8-i1:8:8"
def bits(b): return np.unpackbits(np.frombuffer(b,dtype=np.uint8),bitorder='little')

def fix_layout(bc):
    OB=enc_vbr6(OLD); NB=enc_vbr6(NEW)
    a=bits(bc)
    # find OB at any bit offset (Fixed(8) array elements are contiguous)
    n=len(OB)
    # candidate positions where first byte matches
    first=OB[:12]
    idx=np.where(np.all(np.lib.stride_tricks.sliding_window_view(a,12)==first,axis=1))[0]
    for i in idx:
        if i+n<=len(a) and np.array_equal(a[i:i+n],OB):
            a=a.copy(); a[i:i+n]=NB
            return np.packbits(a,bitorder='little').tobytes()
    return bc

def dxil_bitcode(data):
    count=struct.unpack_from('<I',data,28)[0]
    for o in struct.unpack_from('<%dI'%count,data,32):
        if data[o:o+4]==b'DXIL':
            part=data[o+8:o+8+struct.unpack_from('<I',data,o+4)[0]]
            off,size=struct.unpack_from('<II',part,16)
            return part[8+off:8+off+size]

def to_ll(path):
    return str(llvm.parse_bitcode(fix_layout(dxil_bitcode(open(path,'rb').read()))))

def vbr6(v):
    out=[]
    while True:
        c=v&31; v>>=5
        out.append(c|(32 if v else 0))
        if not v: break
    return out
def enc_vbr6(s):
    return np.array([(c>>i)&1 for ch in s for c in vbr6(ch) for i in range(6)],dtype=np.uint8)

if __name__=='__main__':
    src,dst=sys.argv[1],sys.argv[2]; os.makedirs(dst,exist_ok=True); ok=fail=0
    for f in sorted(os.listdir(src)):
        try:
            open(os.path.join(dst,f.replace('.cso','.ll')),'w').write(to_ll(os.path.join(src,f))); ok+=1
        except Exception as e:
            fail+=1
            if fail<4: print(f,repr(e)[:200])
    print('ok',ok,'fail',fail)
