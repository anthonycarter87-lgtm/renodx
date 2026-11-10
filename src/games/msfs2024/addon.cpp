/*
 * Copyright (C) 2026 Anthony Carter
 * SPDX-License-Identifier: MIT
 */

#define ImTextureID ImU64

#define DEBUG_LEVEL_0

#include <embed/0x197A5546.h>
#include <embed/0x1DD25DEF.h>
#include <embed/0x30025087.h>
#include <embed/0x3733DBA0.h>
#include <embed/0x4A7CE6EB.h>
#include <embed/0x5244E47D.h>
#include <embed/0x5C6F8EBF.h>
#include <embed/0x5C7EC887.h>
#include <embed/0x60DF2686.h>
#include <embed/0x745524AE.h>
#include <embed/0xA8ED1B31.h>
#include <embed/0xAAF09B70.h>
#include <embed/0xAF6475C7.h>
#include <embed/0xCC3D1E2B.h>
#include <embed/0xE5471AC6.h>
#include <embed/0xF02D607E.h>
#include <embed/0xF785A524.h>
#include <embed/0xF8DF7D97.h>

#include <deps/imgui/imgui.h>
#include <include/reshade.hpp>

#include "../../mods/shader.hpp"

namespace {

// Build 1: every ph_tonemapping variant, decompiled 1:1 plus a debug tint
// and variant-number bars (see debug.hlsli).
renodx::mods::shader::CustomShaders custom_shaders = {
    CustomShaderEntry(0x197A5546),  // ph_tonemapping #1
    CustomShaderEntry(0x1DD25DEF),  // ph_tonemapping #2
    CustomShaderEntry(0x30025087),  // ph_tonemapping #3
    CustomShaderEntry(0x3733DBA0),  // ph_tonemapping #4
    CustomShaderEntry(0x4A7CE6EB),  // ph_tonemapping #5
    CustomShaderEntry(0x5244E47D),  // ph_tonemapping #6
    CustomShaderEntry(0x5C6F8EBF),  // ph_tonemapping #7
    CustomShaderEntry(0x5C7EC887),  // ph_tonemapping #8
    CustomShaderEntry(0x60DF2686),  // ph_tonemapping #9
    CustomShaderEntry(0x745524AE),  // ph_tonemapping #10
    CustomShaderEntry(0xA8ED1B31),  // ph_tonemapping #11
    CustomShaderEntry(0xAAF09B70),  // ph_tonemapping #12
    CustomShaderEntry(0xAF6475C7),  // ph_tonemapping #13
    CustomShaderEntry(0xCC3D1E2B),  // ph_tonemapping #14
    CustomShaderEntry(0xE5471AC6),  // ph_tonemapping #15
    CustomShaderEntry(0xF02D607E),  // ph_tonemapping #16
    CustomShaderEntry(0xF785A524),  // ph_tonemapping #17
    CustomShaderEntry(0xF8DF7D97),  // ph_tonemapping #18
};

}  // namespace

extern "C" __declspec(dllexport) constexpr const char* NAME = "RenoDX";
extern "C" __declspec(dllexport) constexpr const char* DESCRIPTION = "RenoDX for Microsoft Flight Simulator 2024";

BOOL APIENTRY DllMain(HMODULE h_module, DWORD fdw_reason, LPVOID lpv_reserved) {
  switch (fdw_reason) {
    case DLL_PROCESS_ATTACH:
      if (!reshade::register_addon(h_module)) return FALSE;
      break;
    case DLL_PROCESS_DETACH:
      reshade::unregister_addon(h_module);
      break;
  }

  renodx::mods::shader::Use(fdw_reason, custom_shaders);

  return TRUE;
}
