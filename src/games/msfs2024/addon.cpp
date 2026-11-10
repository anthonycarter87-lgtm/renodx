/*
 * Copyright (C) 2026 Anthony Carter
 * SPDX-License-Identifier: MIT
 */

#define ImTextureID ImU64

#define DEBUG_LEVEL_0

#include <deps/imgui/imgui.h>
#include <include/reshade.hpp>

#include <embed/shaders.h>

#include <cstdint>
#include <format>
#include <mutex>
#include <shared_mutex>
#include <span>
#include <unordered_map>
#include <unordered_set>

#include "../../mods/shader.hpp"
#include "../../utils/date.hpp"
#include "../../utils/hash.hpp"
#include "../../utils/settings.hpp"
#include "../../utils/swapchain.hpp"
#include "./shared.h"

namespace {

// ph_tonemapping (6 HDR variants) + ph_2d_HDR10 (final HDR10 pass).
renodx::mods::shader::CustomShaders custom_shaders = {__ALL_CUSTOM_SHADERS};

ShaderInjectData shader_injection;

bool IsRenoDX() {
  return shader_injection.tone_map_type != 0.f;
}

// Crash investigation (build 2e). Injecting the settings buffer into MSFS's root signatures crashes the game
// while loading world data. MSFS has four kinds of root signature, told apart by parameter count:
// A = 23, B = 5, C = 7, D = anything else. "Injection Target" (read at startup) picks which kinds get the
// settings buffer, and the log records which kind each of our shaders' pipelines uses.
float injection_target = 0.f;  // 0 None, 1 A, 2 B, 3 C, 4 D, 5 All

char LayoutKind(size_t param_count) {
  switch (param_count) {
    case 23: return 'A';
    case 5:  return 'B';
    case 7:  return 'C';
    default: return 'D';
  }
}

bool ShouldInject(size_t param_count) {
  switch (static_cast<int>(injection_target)) {
    case 1: return LayoutKind(param_count) == 'A';
    case 2: return LayoutKind(param_count) == 'B';
    case 3: return LayoutKind(param_count) == 'C';
    case 4: return LayoutKind(param_count) == 'D';
    case 5: return true;
    default: return false;
  }
}

std::shared_mutex layout_mutex;
std::unordered_map<uint64_t, size_t> layout_param_counts;
std::unordered_set<uint64_t> logged_pipelines;

void OnInitPipelineLayoutLog(reshade::api::device* device, uint32_t param_count,
                             const reshade::api::pipeline_layout_param* params, reshade::api::pipeline_layout layout) {
  const std::unique_lock lock(layout_mutex);
  layout_param_counts.emplace(layout.handle, param_count);
}

bool OnCreatePipelineLog(reshade::api::device* device, reshade::api::pipeline_layout layout, uint32_t subobject_count,
                         const reshade::api::pipeline_subobject* subobjects) {
  for (uint32_t index = 0; index < subobject_count; ++index) {
    const auto& subobject = subobjects[index];
    if (subobject.type != reshade::api::pipeline_subobject_type::pixel_shader || subobject.count == 0u) continue;
    const auto* shader = static_cast<const reshade::api::shader_desc*>(subobject.data);
    if (shader == nullptr || shader->code == nullptr || shader->code_size == 0u) continue;
    const uint32_t hash = renodx::utils::hash::ComputeCRC32(static_cast<const uint8_t*>(shader->code), shader->code_size);
    if (!custom_shaders.contains(hash)) continue;

    size_t param_count = 0u;
    {
      const std::shared_lock lock(layout_mutex);
      if (auto pair = layout_param_counts.find(layout.handle); pair != layout_param_counts.end()) {
        param_count = pair->second;
      }
    }
    reshade::log::message(
        reshade::log::level::info,
        std::format("[msfs2024] shader 0x{:08X} -> layout 0x{:016X} params {} kind {}",
                    hash, layout.handle, param_count, LayoutKind(param_count))
            .c_str());
  }
  return false;
}

renodx::utils::settings::Settings settings = {
    new renodx::utils::settings::Setting{
        .key = "ToneMapType",
        .binding = &shader_injection.tone_map_type,
        .value_type = renodx::utils::settings::SettingValueType::INTEGER,
        .default_value = 1.f,
        .label = "Tone Mapper",
        .section = "Tone Mapping",
        .tooltip = "Vanilla is the untouched game output. RenoDX keeps the game's colour grading, replaces its "
                   "black lift and highlight roll-off, and uses the brightness sliders below.",
        .labels = {"Vanilla", "RenoDX"},
    },
    new renodx::utils::settings::Setting{
        .key = "ToneMapPeakNits",
        .binding = &shader_injection.peak_white_nits,
        .default_value = 1000.f,
        .can_reset = false,
        .label = "Peak Brightness",
        .section = "Tone Mapping",
        .tooltip = "Sets the value of peak white in nits",
        .min = 48.f,
        .max = 10000.f,
        .is_enabled = &IsRenoDX,
        .is_logarithmic = true,
    },
    new renodx::utils::settings::Setting{
        .key = "ToneMapGameNits",
        .binding = &shader_injection.diffuse_white_nits,
        .default_value = 203.f,
        .label = "Game Brightness",
        .section = "Tone Mapping",
        .tooltip = "Sets the value of 100% white in nits",
        .min = 48.f,
        .max = 500.f,
        .is_enabled = &IsRenoDX,
    },
    new renodx::utils::settings::Setting{
        .key = "ToneMapUINits",
        .binding = &shader_injection.graphics_white_nits,
        .default_value = 203.f,
        .label = "UI Brightness",
        .section = "Tone Mapping",
        .tooltip = "Sets the brightness of UI and HUD elements in nits",
        .min = 48.f,
        .max = 500.f,
        .is_enabled = &IsRenoDX,
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeExposure",
        .binding = &shader_injection.tone_map_exposure,
        .default_value = 1.f,
        .label = "Exposure",
        .section = "Color Grading",
        .max = 2.f,
        .format = "%.2f",
        .is_enabled = &IsRenoDX,
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeHighlights",
        .binding = &shader_injection.tone_map_highlights,
        .default_value = 50.f,
        .label = "Highlights",
        .section = "Color Grading",
        .max = 100.f,
        .is_enabled = &IsRenoDX,
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeShadows",
        .binding = &shader_injection.tone_map_shadows,
        .default_value = 50.f,
        .label = "Shadows",
        .section = "Color Grading",
        .max = 100.f,
        .is_enabled = &IsRenoDX,
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeContrast",
        .binding = &shader_injection.tone_map_contrast,
        .default_value = 50.f,
        .label = "Contrast",
        .section = "Color Grading",
        .max = 100.f,
        .is_enabled = &IsRenoDX,
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeSaturation",
        .binding = &shader_injection.tone_map_saturation,
        .default_value = 50.f,
        .label = "Saturation",
        .section = "Color Grading",
        .max = 100.f,
        .is_enabled = &IsRenoDX,
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeHighlightSaturation",
        .binding = &shader_injection.tone_map_highlight_saturation,
        .default_value = 50.f,
        .label = "Highlight Saturation",
        .section = "Color Grading",
        .tooltip = "Adds or removes color in the brightest parts of the image.",
        .max = 100.f,
        .is_enabled = &IsRenoDX,
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeBlowout",
        .binding = &shader_injection.tone_map_blowout,
        .default_value = 0.f,
        .label = "Blowout",
        .section = "Color Grading",
        .tooltip = "Pushes highlights toward white as they approach peak brightness.",
        .max = 100.f,
        .is_enabled = &IsRenoDX,
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .key = "DebugInjectionTarget",
        .binding = &injection_target,
        .value_type = renodx::utils::settings::SettingValueType::INTEGER,
        .default_value = 0.f,
        .label = "Injection Target (restart)",
        .section = "Debug",
        .tooltip = "Crash test: which kinds of MSFS root signature get the RenoDX settings buffer. "
                   "Takes effect after restarting the game.",
        .labels = {"None", "A", "B", "C", "D", "All"},
    },
    new renodx::utils::settings::Setting{
        .value_type = renodx::utils::settings::SettingValueType::BUTTON,
        .label = "Reset All",
        .section = "Options",
        .group = "button-line-0",
        .tooltip = "HDR fix only: the game's own look with correct brightness and highlights.",
        .on_change = []() { renodx::utils::settings::ResetSettings(); },
    },
    new renodx::utils::settings::Setting{
        .value_type = renodx::utils::settings::SettingValueType::BUTTON,
        .label = "Recommended",
        .section = "Options",
        .group = "button-line-0",
        .tooltip = "HDR fix plus a little extra depth: softer highlights, deeper shadows, more contrast and "
                   "slightly less saturation.",
        .on_change = []() {
          renodx::utils::settings::ResetSettings();
          renodx::utils::settings::UpdateSettings({
              {"ColorGradeHighlights", 45.f},
              {"ColorGradeShadows", 45.f},
              {"ColorGradeContrast", 60.f},
              {"ColorGradeSaturation", 47.f},
              {"ColorGradeHighlightSaturation", 45.f},
          });
        },
    },
    new renodx::utils::settings::Setting{
        .value_type = renodx::utils::settings::SettingValueType::TEXT,
        .label = "Requires HDR enabled in MSFS 2024. Flat screen only (VR not supported yet).",
        .section = "About",
    },
    new renodx::utils::settings::Setting{
        .value_type = renodx::utils::settings::SettingValueType::TEXT,
        .label = std::string("Build: ") + renodx::utils::date::ISO_DATE_TIME,
        .section = "About",
    },
};

void OnPresetOff() {
  renodx::utils::settings::UpdateSettings({
      {"ToneMapType", 0.f},
      {"ColorGradeExposure", 1.f},
      {"ColorGradeHighlights", 50.f},
      {"ColorGradeShadows", 50.f},
      {"ColorGradeContrast", 50.f},
      {"ColorGradeSaturation", 50.f},
      {"ColorGradeHighlightSaturation", 50.f},
      {"ColorGradeBlowout", 0.f},
  });
}

bool fired_on_init_swapchain = false;

void OnInitSwapchain(reshade::api::swapchain* swapchain, bool resize) {
  if (fired_on_init_swapchain) return;
  fired_on_init_swapchain = true;
  auto peak = renodx::utils::swapchain::GetPeakNits(swapchain);
  if (!peak.has_value()) return;

  auto* peak_setting = settings[1];
  const bool is_untouched = (peak_setting->GetValue() == peak_setting->default_value);
  peak_setting->default_value = peak.value();
  peak_setting->can_reset = true;
  // Follow the display's reported peak until the user picks their own value.
  if (is_untouched) {
    renodx::utils::settings::UpdateSetting(peak_setting->key, peak.value());
  }
}

bool initialized = false;

}  // namespace

extern "C" __declspec(dllexport) constexpr const char* NAME = "RenoDX";
extern "C" __declspec(dllexport) constexpr const char* DESCRIPTION = "RenoDX for Microsoft Flight Simulator 2024";

BOOL APIENTRY DllMain(HMODULE h_module, DWORD fdw_reason, LPVOID lpv_reserved) {
  switch (fdw_reason) {
    case DLL_PROCESS_ATTACH:
      if (!reshade::register_addon(h_module)) return FALSE;

      if (!initialized) {
        // No force_pipeline_cloning: cloning every pipeline crashed MSFS while loading world data (build 2).
        renodx::mods::shader::on_create_pipeline_layout = [](reshade::api::device* device, auto params) {
          return device->get_api() == reshade::api::device_api::d3d12 && ShouldInject(params.size());
        };
        renodx::mods::shader::on_init_pipeline_layout = [](reshade::api::device* device, auto, auto) {
          return device->get_api() == reshade::api::device_api::d3d12;
        };
        renodx::mods::shader::use_root_signature_cbv = true;
        renodx::mods::shader::allow_multiple_push_constants = true;
        renodx::mods::shader::expected_constant_buffer_space = 50;
        renodx::mods::shader::expected_constant_buffer_index = 13;
        initialized = true;
      }
      reshade::register_event<reshade::addon_event::init_swapchain>(OnInitSwapchain);
      // Registered before mods::shader so the original shader code is seen.
      reshade::register_event<reshade::addon_event::init_pipeline_layout>(OnInitPipelineLayoutLog);
      reshade::register_event<reshade::addon_event::create_pipeline>(OnCreatePipelineLog);
      break;
    case DLL_PROCESS_DETACH:
      reshade::unregister_event<reshade::addon_event::init_swapchain>(OnInitSwapchain);
      reshade::unregister_event<reshade::addon_event::init_pipeline_layout>(OnInitPipelineLayoutLog);
      reshade::unregister_event<reshade::addon_event::create_pipeline>(OnCreatePipelineLog);
      reshade::unregister_addon(h_module);
      break;
  }

  renodx::utils::settings::Use(fdw_reason, &settings, &OnPresetOff);
  renodx::mods::shader::Use(fdw_reason, custom_shaders, &shader_injection);

  return TRUE;
}
