import re,sys
s=open(sys.argv[1]).read()
s=re.sub(r'(%dx\.types\.[A-Za-z0-9_.]+?)\.\d+\b',r'\1',s)
s=re.sub(r'(%"?[A-Za-z0-9_.<>, ]+"?)\.\d{3,}\b',r'\1',s)
s=re.sub(r'= fneg (fast )?float (%\w+)',r'= fsub \1float -0.000000e+00, \2',s)
open(sys.argv[2],'w').write(s)
