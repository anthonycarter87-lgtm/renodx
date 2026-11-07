/*
 * Copyright (C) 2026 Anthony Carter
 * SPDX-License-Identifier: MIT
 */

#define ImTextureID ImU64

#define DEBUG_LEVEL_0

#include <deps/imgui/imgui.h>
#include <include/reshade.hpp>

#include <embed/shaders.h>

#include "../../mods/shader.hpp"
#include "../../utils/date.hpp"
#include "../../utils/settings.hpp"
#include "../../utils/swapchain.hpp"
#include "./shared.h"

namespace {

renodx::mods::shader::CustomShaders custom_shaders = {__ALL_CUSTOM_SHADERS};

ShaderInjectData shader_injection;

renodx::utils::settings::Settings settings = {
    new renodx::utils::settings::Setting{
        .key = "ToneMapType",
        .binding = &shader_injection.tone_map_type,
        .value_type = renodx::utils::settings::SettingValueType::INTEGER,
        .default_value = 1.f,
        .label = "Tone Mapper",
        .section = "Tone Mapping",
        .tooltip = "Vanilla is the untouched game output. RenoDX keeps the game's grading, removes the per-channel "
                   "oversaturation, lets highlights reach the display peak and uses the brightness sliders below.",
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
        .is_enabled = []() { return shader_injection.tone_map_type != 0; },
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
        .is_enabled = []() { return shader_injection.tone_map_type != 0; },
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
        .is_enabled = []() { return shader_injection.tone_map_type != 0; },
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeExposure",
        .binding = &shader_injection.tone_map_exposure,
        .default_value = 1.f,
        .label = "Exposure",
        .section = "Color Grading",
        .max = 2.f,
        .format = "%.2f",
        .is_enabled = []() { return shader_injection.tone_map_type != 0; },
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeHighlights",
        .binding = &shader_injection.tone_map_highlights,
        .default_value = 50.f,
        .label = "Highlights",
        .section = "Color Grading",
        .max = 100.f,
        .is_enabled = []() { return shader_injection.tone_map_type != 0; },
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeShadows",
        .binding = &shader_injection.tone_map_shadows,
        .default_value = 50.f,
        .label = "Shadows",
        .section = "Color Grading",
        .max = 100.f,
        .is_enabled = []() { return shader_injection.tone_map_type != 0; },
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeContrast",
        .binding = &shader_injection.tone_map_contrast,
        .default_value = 50.f,
        .label = "Contrast",
        .section = "Color Grading",
        .max = 100.f,
        .is_enabled = []() { return shader_injection.tone_map_type != 0; },
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeSaturation",
        .binding = &shader_injection.tone_map_saturation,
        .default_value = 50.f,
        .label = "Saturation",
        .section = "Color Grading",
        .max = 100.f,
        .is_enabled = []() { return shader_injection.tone_map_type != 0; },
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
        .is_enabled = []() { return shader_injection.tone_map_type != 0; },
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
        .is_enabled = []() { return shader_injection.tone_map_type != 0; },
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .key = "ColorGradeScene",
        .binding = &shader_injection.color_grade_strength,
        .default_value = 100.f,
        .label = "Scene Grading",
        .section = "Color Grading",
        .tooltip = "Strength of the game's own colour grading",
        .max = 100.f,
        .is_enabled = []() { return shader_injection.tone_map_type != 0; },
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .key = "FxAOStrength",
        .binding = &shader_injection.custom_ao_strength,
        .default_value = 100.f,
        .label = "Ambient Occlusion",
        .section = "Effects",
        .tooltip = "Strength of the game's ambient occlusion (contact shadows in corners and under objects). "
                   "100 is the game's own, 0 turns it off. Requires Ambient Occlusion enabled in FS25.",
        .max = 300.f,
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .key = "FxAORadius",
        .binding = &shader_injection.custom_ao_radius,
        .default_value = 100.f,
        .label = "Ambient Occlusion Radius",
        .section = "Effects",
        .tooltip = "How far ambient occlusion reaches. Higher darkens covered areas like barns, sheds and the space "
                   "under machinery and trees. 100 is the game's own. Higher values cost a little performance.",
        .min = 50.f,
        .max = 400.f,
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .key = "FxAOQuality",
        .binding = &shader_injection.custom_ao_quality,
        .value_type = renodx::utils::settings::SettingValueType::INTEGER,
        .default_value = 0.f,
        .label = "Ambient Occlusion Quality",
        .section = "Effects",
        .tooltip = "Samples per pixel: Game 3x3, High 4x4, Ultra 6x6. Raise it with a large radius to remove noise. "
                   "Higher costs more GPU time.",
        .labels = {"Game", "High", "Ultra"},
    },
    new renodx::utils::settings::Setting{
        .key = "CloudDensity",
        .binding = &shader_injection.custom_cloud_density,
        .default_value = 100.f,
        .label = "Cloud Density",
        .section = "Clouds",
        .tooltip = "How thick and opaque clouds are. 100 is the game's own.",
        .min = 25.f,
        .max = 300.f,
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .key = "CloudCoverage",
        .binding = &shader_injection.custom_cloud_coverage,
        .default_value = 100.f,
        .label = "Cloud Coverage",
        .section = "Clouds",
        .tooltip = "How much of the sky clouds cover, for any weather. 100 is the game's own.",
        .min = 0.f,
        .max = 200.f,
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .key = "CloudDetail",
        .binding = &shader_injection.custom_cloud_detail,
        .default_value = 100.f,
        .label = "Cloud Detail",
        .section = "Clouds",
        .tooltip = "Erosion of cloud edges: higher gives wispier, more detailed edges. 100 is the game's own.",
        .min = 0.f,
        .max = 300.f,
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .key = "CloudSilverLining",
        .binding = &shader_injection.custom_cloud_silver_lining,
        .default_value = 0.f,
        .label = "Silver Lining",
        .section = "Clouds",
        .tooltip = "Brightens cloud edges facing the sun. 0 is the game's own.",
        .min = 0.f,
        .max = 100.f,
        .parse = [](float value) { return value * 0.01f; },
    },
    new renodx::utils::settings::Setting{
        .key = "CloudUpscaling",
        .binding = &shader_injection.custom_cloud_upscaling,
        .value_type = renodx::utils::settings::SettingValueType::INTEGER,
        .default_value = 0.f,
        .label = "Cloud Reconstruction",
        .section = "Clouds",
        .tooltip = "Clouds are rendered at a quarter of 1080p and built up over 4 frames. Improved clamps old frames to "
                   "new detail (less grid pattern when clouds move) and upscales with bicubic filtering.",
        .labels = {"Game", "Improved"},
    },
    new renodx::utils::settings::Setting{
        .key = "CloudSharpness",
        .binding = &shader_injection.custom_cloud_sharpness,
        .default_value = 0.f,
        .label = "Cloud Sharpness",
        .section = "Clouds",
        .tooltip = "Sharpens clouds, which the game renders at reduced resolution. 0 is the game's own.",
        .max = 100.f,
        .parse = [](float value) { return value * 0.02f; },
    },
    new renodx::utils::settings::Setting{
        .key = "CloudQuality",
        .binding = &shader_injection.custom_cloud_quality,
        .value_type = renodx::utils::settings::SettingValueType::INTEGER,
        .default_value = 0.f,
        .label = "Cloud Quality",
        .section = "Clouds",
        .tooltip = "Raymarching steps: Game, High (1.5x) or Ultra (2x). Smoother, less noisy clouds at a GPU cost.",
        .labels = {"Game", "High", "Ultra"},
        .parse = [](float value) { return 1.f + value * 0.5f; },
    },
    new renodx::utils::settings::Setting{
        .value_type = renodx::utils::settings::SettingValueType::BUTTON,
        .label = "Reset All",
        .section = "Options",
        .group = "button-line-0",
        .tooltip = "HDR fix only: the game's own look with correct brightness, colour and highlights.",
        .on_change = []() { renodx::utils::settings::ResetSettings(); },
    },
    new renodx::utils::settings::Setting{
        .value_type = renodx::utils::settings::SettingValueType::BUTTON,
        .label = "Recommended",
        .section = "Options",
        .group = "button-line-0",
        .tooltip = "HDR fix plus a little extra depth: softer highlights, deeper shadows, more contrast, "
                   "slightly less saturation, stronger and wider ambient occlusion, and denser, sharper clouds.",
        .on_change = []() {
          renodx::utils::settings::ResetSettings();
          renodx::utils::settings::UpdateSettings({
              {"ColorGradeHighlights", 45.f},
              {"ColorGradeShadows", 45.f},
              {"ColorGradeContrast", 60.f},
              {"ColorGradeSaturation", 47.f},
              {"ColorGradeHighlightSaturation", 45.f},
              {"FxAOStrength", 120.f},
              {"FxAORadius", 400.f},
              {"FxAOQuality", 2.f},
              {"CloudDensity", 168.f},
              {"CloudCoverage", 85.f},
              {"CloudDetail", 125.f},
              {"CloudSharpness", 50.f},
              {"CloudUpscaling", 1.f},
              {"CloudQuality", 2.f},
          });
        },
    },
    new renodx::utils::settings::Setting{
        .value_type = renodx::utils::settings::SettingValueType::TEXT,
        .label = "Requires HDR enabled in FS25. RenoDX replaces FS25's HDR Calibration settings "
                 "(3D Brightness, Overlay Brightness and HDR Contrast) with its own sliders.",
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
      {"ColorGradeScene", 100.f},
      {"FxAOStrength", 100.f},
      {"FxAORadius", 100.f},
      {"FxAOQuality", 0.f},
      {"CloudDensity", 100.f},
      {"CloudCoverage", 100.f},
      {"CloudDetail", 100.f},
      {"CloudSilverLining", 0.f},
      {"CloudQuality", 0.f},
      {"CloudSharpness", 0.f},
      {"CloudUpscaling", 0.f},
  });
}

bool fired_on_init_swapchain = false;

void OnInitSwapchain(reshade::api::swapchain* swapchain, bool resize) {
  if (fired_on_init_swapchain) return;
  fired_on_init_swapchain = true;
  auto peak = renodx::utils::swapchain::GetPeakNits(swapchain);
  if (peak.has_value()) {
    auto* peak_setting = settings[1];
    const bool is_untouched = (peak_setting->GetValue() == peak_setting->default_value);
    peak_setting->default_value = peak.value();
    peak_setting->can_reset = true;
    // Follow the display's reported peak until the user picks their own value.
    if (is_untouched) {
      renodx::utils::settings::UpdateSetting(peak_setting->key, peak.value());
    }
  }
}

bool initialized = false;

}  // namespace

extern "C" __declspec(dllexport) constexpr const char* NAME = "RenoDX";
extern "C" __declspec(dllexport) constexpr const char* DESCRIPTION = "RenoDX for Farming Simulator 25";

BOOL APIENTRY DllMain(HMODULE h_module, DWORD fdw_reason, LPVOID lpv_reserved) {
  switch (fdw_reason) {
    case DLL_PROCESS_ATTACH:
      if (!reshade::register_addon(h_module)) return FALSE;

      if (!initialized) {
        renodx::mods::shader::force_pipeline_cloning = true;
        renodx::mods::shader::allow_multiple_push_constants = true;
        renodx::mods::shader::expected_constant_buffer_space = 50;
        renodx::mods::shader::expected_constant_buffer_index = 13;

        initialized = true;
      }
      reshade::register_event<reshade::addon_event::init_swapchain>(OnInitSwapchain);

      break;
    case DLL_PROCESS_DETACH:
      reshade::unregister_event<reshade::addon_event::init_swapchain>(OnInitSwapchain);

      reshade::unregister_addon(h_module);
      break;
  }

  renodx::utils::settings::Use(fdw_reason, &settings, &OnPresetOff);
  renodx::mods::shader::Use(fdw_reason, custom_shaders, &shader_injection);

  return TRUE;
}
