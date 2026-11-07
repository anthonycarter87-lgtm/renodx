import struct,sys
for p in sys.argv[1:]:
    d=open(p,'rb').read(); n=struct.unpack_from('<I',d,28)[0]
    offs=struct.unpack_from('<%dI'%n,d,32)
    print(p.split('/')[-1],[ (d[o:o+4].decode(), struct.unpack_from('<I',d,o+4)[0]) for o in offs])
