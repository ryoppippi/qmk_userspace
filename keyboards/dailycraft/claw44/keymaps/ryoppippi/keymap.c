// SPDX-License-Identifier: GPL-2.0-or-later

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

// clang-format off
const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
    [_BASE] = LAYOUT(
    //,--------+--------+--------+--------+--------+--------.   ,--------+--------+--------+--------+--------+--------.
       KC_F19 , KC_Q   , KC_W   , KC_E   , KC_R   , KC_T   ,     KC_Y   , KC_U   , KC_I   , KC_O   , KC_P   , KC_F19 ,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       C_ESC  , KC_A   , SG_S   , A_D    , G_F    , C_G    ,     C_H    , G_J    , A_K    , SG_L   , HY_SCLN, KC_MINS,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       KC_LEFT, KC_Z   , KC_X   , KC_C   , KC_V   , KC_B   ,     KC_N   , KC_M   , KC_COMM, KC_DOT , KC_SLSH, KC_RGHT,
    //`--------+--------+--------+--------+--------+--------/   \--------+--------+--------+--------+--------+--------'
                         G_LNG2 , S_TAB  , NUM_SPC, KC_BSPC,     KC_BSPC, SYM_ENT, RS_TAB , HY_LNG1
    //                  `--------+--------+--------+--------'   `--------+--------+--------+--------'
    ),

    [_NUM] = LAYOUT(
    //,--------+--------+--------+--------+--------+--------.   ,--------+--------+--------+--------+--------+--------.
       _______, KC_F1  , KC_F2  , KC_F3  , KC_F4  , KC_F5  ,     KC_SLSH, KC_EQL , KC_ASTR, KC_PLUS, KC_PERC, _______,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       KC_CIRC, KC_1   , KC_2   , KC_3   , KC_4   , KC_5   ,     KC_6   , KC_7   , KC_8   , KC_9   , KC_0   , KC_MINS,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       _______, KC_F6  , KC_F7  , KC_F8  , KC_F9  , KC_F10 ,     KC_F11 , KC_F12 , KC_COMM, KC_DOT , KC_DLR , _______,
    //`--------+--------+--------+--------+--------+--------/   \--------+--------+--------+--------+--------+--------'
                         _______, _______, _______, _______,     _______, _______, _______, _______
    //                  `--------+--------+--------+--------'   `--------+--------+--------+--------'
    ),

    [_SYM] = LAYOUT(
    //,--------+--------+--------+--------+--------+--------.   ,--------+--------+--------+--------+--------+--------.
       _______, KC_QUES, KC_EXLM, KC_AMPR, KC_PIPE, KC_BSLS,     KC_SLSH, KC_EQL , KC_ASTR, KC_PLUS, KC_PERC, _______,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       KC_CIRC, KC_HASH, KC_GRV , KC_DQUO, KC_QUOT, KC_TILD,     KC_LEFT, KC_DOWN, KC_UP  , KC_RGHT, KC_COLN, KC_UNDS,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       _______, KC_AT  , KC_LT  , KC_LCBR, KC_LBRC, KC_LPRN,     KC_RPRN, KC_RBRC, KC_RCBR, KC_GT  , KC_DLR , _______,
    //`--------+--------+--------+--------+--------+--------/   \--------+--------+--------+--------+--------+--------'
                         _______, KC_DEL , _______, _______,     _______, _______, _______, _______
    //                  `--------+--------+--------+--------'   `--------+--------+--------+--------'
    ),

    [_ADJUST] = LAYOUT(
    //,--------+--------+--------+--------+--------+--------.   ,--------+--------+--------+--------+--------+--------.
       KC_PWR , KC_BRID, KC_BRIU, KC_MUTE, KC_VOLD, KC_VOLU,     KC_MRWD, KC_MPLY, KC_MFFD, _______, _______, _______,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       KC_ESC , _______, MS_BTN1, MS_BTN3, MS_BTN2, _______,     MS_LEFT, MS_DOWN, MS_UP  , MS_RGHT, _______, _______,
    //|--------+--------+--------+--------+--------+--------|   |--------+--------+--------+--------+--------+--------|
       _______, M_GMAIL, M_RYO  , M_FAMLY, M_GIVEN, M_HNDL ,     M_LGTM , _______, _______, _______, _______, _______,
    //`--------+--------+--------+--------+--------+--------/   \--------+--------+--------+--------+--------+--------'
                         _______, _______, _______, _______,     _______, _______, _______, _______
    //                  `--------+--------+--------+--------'   `--------+--------+--------+--------'
    ),
};
// clang-format on

uint16_t get_tapping_term(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
        case SG_S:
        case SG_L:
        case A_D:
        case A_K:
            return TAPPING_LAYER_TERM;
        default:
            return TAPPING_TERM;
    }
}

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
    if (!record->event.pressed) {
        return true;
    }
    switch (keycode) {
        case M_HNDL:
            SEND_STRING("ryoppippi");
            return false;
        case M_GIVEN:
            SEND_STRING("ryotaro");
            return false;
        case M_FAMLY:
            SEND_STRING("kimura");
            return false;
        case M_RYO:
            SEND_STRING("ryo");
            return false;
        case M_GMAIL:
            SEND_STRING("m.ryoppippi@gmail.com");
            return false;
        case M_LGTM:
            SEND_STRING("lgtm");
            return false;
    }
    return true;
}

layer_state_t layer_state_set_user(layer_state_t state) {
    return update_tri_layer_state(state, _NUM, _SYM, _ADJUST);
}

// Retro tapping only fires when no other key was pressed in between, so the
// most recent press is always the tap-hold key that is being released.
static uint16_t last_press_time;

bool pre_process_record_user(uint16_t keycode, keyrecord_t *record) {
    if (record->event.pressed) {
        last_press_time = record->event.time;
    }
    return true;
}

bool get_retro_tapping(uint16_t keycode, keyrecord_t *record) {
    return TIMER_DIFF_16(record->event.time, last_press_time) < RETRO_TAPPING_TERM;
}
