// SPDX-License-Identifier: GPL-2.0-or-later

#include "ryoppippi.h"

// QMK's LAYOUT_split_3x6_3 leaves out the two extra keys on the inner edge of
// the right half (matrix 8,2 and 8,1), so this adds them as the last two keys.
// keymap-drawer finds layers by this macro's name, so the drawing must not
// expand it.
#ifndef KEYMAP_DRAWER
// clang-format off
#define LAYOUT_extra_keys( \
    L00, L01, L02, L03, L04, L05,      R00, R01, R02, R03, R04, R05, \
    L10, L11, L12, L13, L14, L15,      R10, R11, R12, R13, R14, R15, \
    L20, L21, L22, L23, L24, L25,      R20, R21, R22, R23, R24, R25, \
                   L30, L31, L32,      R30, R31, R32,                \
    E0, E1 \
) { \
    { L00, L01, L02, L03, L04, L05 }, \
    { L10, L11, L12, L13, L14, L15 }, \
    { L20, L21, L22, L23, L24, L25 }, \
    { KC_NO, KC_NO, KC_NO, L30, L31, L32 }, \
    { KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO }, \
    { R05, R04, R03, R02, R01, R00 }, \
    { R15, R14, R13, R12, R11, R10 }, \
    { R25, R24, R23, R22, R21, R20 }, \
    { KC_NO, E1, E0, R32, R31, R30 }, \
    { KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO } \
}
// clang-format on
#endif

// clang-format off
const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
    [_BASE] = LAYOUT_extra_keys(
    //,--------+--------+--------+--------+--------+--------.   ,--------+--------+--------+--------+--------+--------.
       KC_F19 , KC_Q   , KC_W   , KC_E   , KC_R   , KC_T   ,     KC_Y   , KC_U   , KC_I   , KC_O   , KC_P   , KC_F19 ,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       C_ESC  , KC_A   , SG_S   , A_D    , G_F    , C_G    ,     C_H    , G_J    , A_K    , SG_L   , HY_SCLN, KC_MINS,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       KC_LEFT, KC_Z   , KC_X   , KC_C   , KC_V   , KC_B   ,     KC_N   , KC_M   , KC_COMM, KC_DOT , KC_SLSH, KC_RGHT,
    //`--------+--------+--------+--------+--------+--------/   \--------+--------+--------+--------+--------+--------'
                                  S_TAB  , NUM_SPC, KC_BSPC,     KC_BSPC, SYM_ENT, RS_TAB ,
    //                           `--------+--------+--------'   `--------+--------+--------'
    //  right-hand extra keys: upper, lower
        G_LNG2 , HY_LNG1
    ),

    [_NUM] = LAYOUT_extra_keys(
    //,--------+--------+--------+--------+--------+--------.   ,--------+--------+--------+--------+--------+--------.
       _______, KC_F1  , KC_F2  , KC_F3  , KC_F4  , KC_F5  ,     KC_SLSH, KC_EQL , KC_ASTR, KC_PLUS, KC_PERC, _______,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       KC_CIRC, KC_1   , KC_2   , KC_3   , KC_4   , KC_5   ,     KC_6   , KC_7   , KC_8   , KC_9   , KC_0   , KC_MINS,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       _______, KC_F6  , KC_F7  , KC_F8  , KC_F9  , KC_F10 ,     KC_F11 , KC_F12 , KC_COMM, KC_DOT , KC_DLR , _______,
    //`--------+--------+--------+--------+--------+--------/   \--------+--------+--------+--------+--------+--------'
                                  _______, _______, _______,     _______, _______, _______,
    //                           `--------+--------+--------'   `--------+--------+--------'
        _______, _______
    ),

    [_SYM] = LAYOUT_extra_keys(
    //,--------+--------+--------+--------+--------+--------.   ,--------+--------+--------+--------+--------+--------.
       _______, KC_QUES, KC_EXLM, KC_AMPR, KC_PIPE, KC_BSLS,     KC_SLSH, KC_EQL , KC_ASTR, KC_PLUS, KC_PERC, _______,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       KC_CIRC, KC_HASH, KC_GRV , KC_DQUO, KC_QUOT, KC_TILD,     KC_LEFT, KC_DOWN, KC_UP  , KC_RGHT, KC_COLN, KC_UNDS,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       _______, KC_AT  , KC_LT  , KC_LCBR, KC_LBRC, KC_LPRN,     KC_RPRN, KC_RBRC, KC_RCBR, KC_GT  , KC_DLR , _______,
    //`--------+--------+--------+--------+--------+--------/   \--------+--------+--------+--------+--------+--------'
                                  KC_DEL , _______, _______,     _______, _______, _______,
    //                           `--------+--------+--------'   `--------+--------+--------'
        _______, _______
    ),

    [_ADJUST] = LAYOUT_extra_keys(
    //,--------+--------+--------+--------+--------+--------.   ,--------+--------+--------+--------+--------+--------.
       KC_PWR , KC_BRID, KC_BRIU, KC_MUTE, KC_VOLD, KC_VOLU,     KC_MRWD, KC_MPLY, KC_MFFD, _______, _______, _______,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       KC_ESC , _______, MS_BTN1, MS_BTN3, MS_BTN2, _______,     MS_LEFT, MS_DOWN, MS_UP  , MS_RGHT, _______, _______,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       _______, M_GMAIL, M_RYO  , M_FAMLY, M_GIVEN, M_HNDL ,     M_LGTM , _______, _______, _______, _______, _______,
    //`--------+--------+--------+--------+--------+--------/   \--------+--------+--------+--------+--------+--------'
                                  _______, _______, _______,     _______, _______, _______,
    //                           `--------+--------+--------'   `--------+--------+--------'
        _______, _______
    ),
};

// The right half has no encoders fitted, but shares the left half's pins, so
// QMK still counts two on each side.
const uint16_t PROGMEM encoder_map[][NUM_ENCODERS][NUM_DIRECTIONS] = {
    [_BASE]   = { ENCODER_CCW_CW(KC_VOLD, KC_VOLU), ENCODER_CCW_CW(MS_WHLU, MS_WHLD), ENCODER_CCW_CW(_______, _______), ENCODER_CCW_CW(_______, _______) },
    [_NUM]    = { ENCODER_CCW_CW(_______, _______), ENCODER_CCW_CW(_______, _______), ENCODER_CCW_CW(_______, _______), ENCODER_CCW_CW(_______, _______) },
    [_SYM]    = { ENCODER_CCW_CW(_______, _______), ENCODER_CCW_CW(_______, _______), ENCODER_CCW_CW(_______, _______), ENCODER_CCW_CW(_______, _______) },
    [_ADJUST] = { ENCODER_CCW_CW(_______, _______), ENCODER_CCW_CW(_______, _______), ENCODER_CCW_CW(_______, _______), ENCODER_CCW_CW(_______, _______) },
};
// clang-format on
