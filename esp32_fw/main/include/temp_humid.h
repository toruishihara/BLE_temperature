#ifndef TEMP_HUMID_H
#define TEMP_HUMID_H

/* Includes */
/* ESP APIs */

/* Defines */

/* Public function declarations */
float get_temperature(void);
void update_temperature(float temperature);

uint8_t get_humid(void);
void update_humid(void);

#endif // TEMP_HUMID_H
