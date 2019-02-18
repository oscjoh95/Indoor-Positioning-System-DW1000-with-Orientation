"""
Main file for the tags that are controlled by a raspberry pi. It alternates sampling between the two
tags to keep the distances up to date.
"""
import DW1000Constants as C
from DW1000TagClass import *
import time
import RPi.GPIO as GPIO

CS1 = 12
CS2 = 5
IRQ1 = 6
IRQ2 = 26
ANTENNA_DELAY1 = 16317
ANTENNA_DELAY2 = 16317
startupTime = 1
DATA_LEN = 17
data = [0] * 5


time.sleep(startupTime)

#module1 = DWM1000_ranging("module1", "82:17:5B:D5:A9:9A:E2:1A", CS1, IRQ1, ANTENNA_DELAY1)
module1 = DW1000Tag("module1", CS1, IRQ1, ANTENNA_DELAY1, "82:17:5B:D5:A9:9A:E2:1A", DATA_LEN)
module1.idle()
print("\n")

time.sleep(startupTime)

#module2 = DWM1000_ranging("module2", "82:17:5B:D5:A9:9A:E2:1B", CS2, IRQ2, ANTENNA_DELAY2)
module2 = DW1000Tag("module2", CS2, IRQ2, ANTENNA_DELAY2, "82:17:5B:D5:A9:9A:E2:1B", DATA_LEN)
module2.idle()
time.sleep(startupTime)

def loop():
    print("-----Module 1-----")
    range = None
    i = 0
    while((range == None)):#& (i < 5000)):
        i += 1
        range = module1.loop()
    print(range)
    module1.idle()
    print("\n")
    time.sleep(1)

    print("-----Module 2-----")
    range = None
    i = 0
    while((range == None)):# & (i < 5000)):
        i += 1
        range = module2.loop()
    print(range)
    module2.idle()
    print("\n")
    time.sleep(1)
    
def main():
    try:
        while 1:
            loop()
    except KeyboardInterrupt:
        print('Interrupted by user')
if __name__ == '__main__':
    main()
