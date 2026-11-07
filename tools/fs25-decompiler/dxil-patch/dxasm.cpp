// Assemble DXIL LLVM text (.ll) -> DXIL container, then validate+sign with dxil.dll validator.
#include <dxc/WinAdapter.h>
#include <dxc/dxcapi.h>
#include <cstdio>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
int main(int argc, char** argv) {
  if (argc < 3) { fprintf(stderr, "usage: dxasm in.ll out.cso\n"); return 2; }
  std::ifstream f(argv[1], std::ios::binary); std::stringstream ss; ss << f.rdbuf(); std::string src = ss.str();
  CComPtr<IDxcUtils> utils; DxcCreateInstance(CLSID_DxcUtils, IID_PPV_ARGS(&utils));
  CComPtr<IDxcBlobEncoding> blob; utils->CreateBlob(src.data(), (UINT32)src.size(), CP_UTF8, &blob);
  CComPtr<IDxcAssembler> as; HRESULT hr = DxcCreateInstance(CLSID_DxcAssembler, IID_PPV_ARGS(&as));
  if (FAILED(hr)) { fprintf(stderr, "no assembler %x\n", hr); return 1; }
  CComPtr<IDxcOperationResult> res; as->AssembleToContainer(blob, &res);
  res->GetStatus(&hr);
  if (FAILED(hr)) { CComPtr<IDxcBlobEncoding> e; res->GetErrorBuffer(&e); fprintf(stderr, "assemble failed: %.*s\n", (int)e->GetBufferSize(), (char*)e->GetBufferPointer()); return 1; }
  CComPtr<IDxcBlob> out; res->GetResult(&out);
  // validate + sign in place
  CComPtr<IDxcValidator> val; hr = DxcCreateInstance(CLSID_DxcValidator, IID_PPV_ARGS(&val));
  if (SUCCEEDED(hr)) {
    CComPtr<IDxcOperationResult> vr; val->Validate(out, DxcValidatorFlags_InPlaceEdit, &vr);
    vr->GetStatus(&hr);
    if (FAILED(hr)) { CComPtr<IDxcBlobEncoding> e; vr->GetErrorBuffer(&e); fprintf(stderr, "validation failed: %.*s\n", (int)e->GetBufferSize(), (char*)e->GetBufferPointer()); return 1; }
  } else fprintf(stderr, "warning: no validator\n");
  std::ofstream o(argv[2], std::ios::binary); o.write((char*)out->GetBufferPointer(), out->GetBufferSize());
  printf("ok %zu bytes\n", (size_t)out->GetBufferSize());
}
