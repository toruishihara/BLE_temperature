/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */
/* Includes */
#include "common.h"
#include "temp_humid.h"

/* Private variables */
static float s_temperature;
static float s_humid;

/* Public functions */
float get_temperature(void) { return s_temperature; }
uint8_t get_humid(void) { return s_humid; }

void update_temperature(float temperature) { s_temperature=temperature; }
void update_humid(void) { s_humid=50; }

