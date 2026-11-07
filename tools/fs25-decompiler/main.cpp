#include <stdexcept>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>
#include "shim/utils/shader_decompiler_dxc.hpp"
int main(int argc, char** argv) {
  std::ifstream f(argv[1]); std::stringstream ss; ss << f.rdbuf();
  auto d = renodx::utils::shader::decompiler::dxc::Decompiler();
  std::cout << d.Decompile(ss.str(), {.flatten = false, .use_do_while = false, .state_machine = (argc > 2)});
}
