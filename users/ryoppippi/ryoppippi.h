// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include QMK_KEYBOARD_H

enum layer_number {
    _BASE = 0,
    _NUM,
    _SYM,
    _ADJUST,
};

enum custom_keycodes {
    M_HNDL = SAFE_RANGE,
    M_GIVEN,
    M_FAMLY,
    M_RYO,
    M_GMAIL,
    M_LGTM,
};

#define RHYPR_T(kc) MT(MOD_RCTL | MOD_RSFT | MOD_RALT | MOD_RGUI, kc)

#define C_ESC LCTL_T(KC_ESC)
#define SG_S LSG_T(KC_S)
#define A_D LALT_T(KC_D)
#define G_F LGUI_T(KC_F)
#define C_G LCTL_T(KC_G)
#define C_H RCTL_T(KC_H)
#define G_J RGUI_T(KC_J)
#define A_K RALT_T(KC_K)
#define SG_L RSG_T(KC_L)
#define HY_SCLN RHYPR_T(KC_SCLN)

#define G_LNG2 LGUI_T(KC_LNG2)
#define S_TAB LSFT_T(KC_TAB)
#define NUM_SPC LT(_NUM, KC_SPC)
#define SYM_ENT LT(_SYM, KC_ENT)
#define RS_TAB RSFT_T(KC_TAB)
#define HY_LNG1 RHYPR_T(KC_LNG1)
