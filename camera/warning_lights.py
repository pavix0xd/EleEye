# include all necessary packages to get LEDs to work with 
# the Raspberry Pi board
import time
import board
import neopixel

# LED Strip configuration variables:
LED_COUNT = 30 # Number of LED pixels expected on the LED strip
LED_PIN = board.D18 # GPIO pin connected to the pixels
LED_BRIGHTNESS = 40 # Brightness of the LED strip. A float between 0 and 1

# converting the brightness to a value between 0 and 1
brightness = LED_BRIGHTNESS / 255

# Initializing the LED strip
LED_STRIP = neopixel.NeoPixel(LED_PIN, LED_COUNT, brightness=brightness)

# Toggle the LED strip on and off every second for a period of 10 seconds. 
# The below logic will largely remain the same. The final change will involve 
# a network request to turn the warning lights on and off. 

for duration in range(5):

    LED_STRIP.fill((255,0,0))
    time.sleep(1)

    LED_STRIP.fill((0,0,0))
    time.sleep(1)