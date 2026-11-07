Linux build of RenoDX's DXIL decompiler with an extra `state_machine` output mode
(every basic block becomes a state), used for FS25 shaders whose loops the structured
decompiler can't handle (cloud raymarch 0x5C10EFD0, cloud reprojection, apply-sky).

Build: g++ -std=c++20 -O1 -I <dir containing utils/> -o decomp_sm main.cpp
(main.cpp includes "shim/utils/shader_decompiler_dxc.hpp" - adjust the include path.)
Use:   dxc -dumpbin shader.cso > shader.ll ; ./decomp_sm shader.ll sm > shader.hlsl
