/*
 * Copyright (C) 2026 Anthony Carter
 * SPDX-License-Identifier: MIT
 */

#define ImTextureID ImU64

#define DEBUG_LEVEL_0

#include <deps/imgui/imgui.h>
#include <include/reshade.hpp>

#include <embed/shaders.h>

#include <cstddef>
#include <cstdint>
#include <vector>

#include "../../mods/shader.hpp"
#include "../../utils/date.hpp"
#include "../../utils/resource.hpp"
#include "../../utils/resource_upgrade.hpp"
#include "../../utils/settings.hpp"
#include "../../utils/swapchain.hpp"
#include "./shared.h"

namespace {

// ph_tonemapping (6 HDR variants) + ph_2d_HDR10 (final HDR10 pass) + ph_volumetric_clouds_merge (6 variants).
renodx::mods::shader::CustomShaders custom_shaders = {__ALL_CUSTOM_SHADERS};

ShaderInjectData shader_injection;

bool IsRenoDX() {
  return shader_injection.tone_map_type != 0.f;
}

// Set once at startup: true when the 16-bit render target upgrade is running this session.
bool wide_colour_active = false;

bool IsWideColour() {
  return IsRenoDX() && wide_colour_active;
}

renodx::utils::settings::Setting* upgrade_setting = nullptr;

// MSFS 2024 has four kinds of root signature. All of our shaders use the one with 23 parameters; injecting the
// settings buffer into the others crashes the game while loading world data (builds 2-2d, bisected in 2e).
constexpr size_t SHADER_ROOT_SIGNATURE_PARAM_COUNT = 23u;

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
        .tooltip = "Sets the value of 100% white in nits. 203 matches the game's own brightness.",
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
        .key = "ColorGradeGamutExpansion",
        .binding = &shader_injection.gamut_expansion,
        .default_value = 0.f,
        .label = "Gamut Expansion",
        .section = "Color Grading",
        .tooltip = "Spreads saturated colours into the wider HDR colour range. Needs the 16-bit upgrade (Advanced).",
        .max = 100.f,
        .is_enabled = &IsWideColour,
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .key = "CloudBrightness",
        .binding = &shader_injection.cloud_brightness,
        .default_value = 100.f,
        .label = "Cloud Brightness",
        .section = "Clouds (test)",
        .tooltip = "Test slider: scales the brightness of the volumetric clouds. 100 = game default.",
        .max = 200.f,
        .parse = [](float value) { return value * 0.01f; },
    },
    upgrade_setting = new renodx::utils::settings::Setting{
        .key = "UpgradeRenderTargets",
        .value_type = renodx::utils::settings::SettingValueType::INTEGER,
        .default_value = 1.f,
        .label = "Render Format",
        .section = "Advanced",
        .tooltip = "16-bit upgrades the game's 11-bit colour buffers: smoother gradients (sky) and room for wider "
                   "colour. NVIDIA only. Restart the game after changing.",
        .labels = {"Game (11-bit)", "16-bit"},
        .is_global = true,
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
        .tooltip = "HDR fix plus brighter, more cinematic highlights: a bigger sun glow and highlights that "
                   "fade to white near peak brightness.",
        .on_change = []() {
          // Keep the player's Peak: it belongs to their display, not to the look.
          const float peak_nits = shader_injection.peak_white_nits;
          renodx::utils::settings::ResetSettings();
          renodx::utils::settings::UpdateSettings({
              {"ToneMapPeakNits", peak_nits},
              {"ColorGradeHighlights", 70.f},
              {"ColorGradeBlowout", 30.f},
          });
        },
    },
    new renodx::utils::settings::Setting{
        .value_type = renodx::utils::settings::SettingValueType::TEXT,
        .label = "v1.1 TEST BUILD: 16-bit upgrade, Gamut Expansion, Cloud Brightness.",
        .section = "About",
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
      {"ColorGradeGamutExpansion", 0.f},
      {"CloudBrightness", 100.f},
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

// 16-bit upgrade of the game's back-buffer-sized R11G11B10 render targets (scene colour, tonemapper output).
// Same approach as RenoDX Nioh 3, which found it misbehaves on AMD, so NVIDIA only.
void OnInitDevice(reshade::api::device* device) {
  std::vector<renodx::utils::resource::ResourceUpgradeInfo> upgrade_infos = {};
  wide_colour_active = false;

  if (device->get_api() == reshade::api::device_api::d3d12
      && upgrade_setting != nullptr && upgrade_setting->GetValue() == 1.f) {
    uint32_t vendor_id = 0;
    const bool retrieved = device->get_property(reshade::api::device_properties::vendor_id, &vendor_id);
    if (retrieved && vendor_id == 0x10de) {
      upgrade_infos.push_back({
          .old_format = reshade::api::format::r11g11b10_float,
          .new_format = reshade::api::format::r16g16b16a16_float,
          .dimensions = {.width = renodx::utils::resource::ResourceUpgradeInfo::BACK_BUFFER,
                         .height = renodx::utils::resource::ResourceUpgradeInfo::BACK_BUFFER},
          .usage_include = reshade::api::resource_usage::render_target,
      });
      wide_colour_active = true;
    }
  }

  shader_injection.wide_colour = wide_colour_active ? 1.f : 0.f;
  renodx::utils::resource::upgrade::SetUpgradeInfos(device, upgrade_infos);
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
          return device->get_api() == reshade::api::device_api::d3d12 && params.size() == SHADER_ROOT_SIGNATURE_PARAM_COUNT;
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
      renodx::utils::resource::upgrade::Use(fdw_reason);
      reshade::register_event<reshade::addon_event::init_device>(OnInitDevice);
      reshade::register_event<reshade::addon_event::init_swapchain>(OnInitSwapchain);
      break;
    case DLL_PROCESS_DETACH:
      reshade::unregister_event<reshade::addon_event::init_swapchain>(OnInitSwapchain);
      reshade::unregister_event<reshade::addon_event::init_device>(OnInitDevice);
      renodx::utils::resource::upgrade::Use(fdw_reason);
      reshade::unregister_addon(h_module);
      break;
  }

  renodx::utils::settings::Use(fdw_reason, &settings, &OnPresetOff);
  renodx::mods::shader::Use(fdw_reason, custom_shaders, &shader_injection);

  return TRUE;
}
