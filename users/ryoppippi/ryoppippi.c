// SPDX-License-Identifier: GPL-2.0-or-later

#include "ryoppippi.h"

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
