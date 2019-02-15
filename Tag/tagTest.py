"""
Main file for the tags that are controlled by a raspberry pi. It alternates sampling between the two
tags to keep the distances up to date.
"""
import DW1000Constants as C
import monotonic
from DW1000TagClass import *
import time
import RPi.GPIO as GPIO

CS1 = 25
CS2 = 16
IRQ1 = 13
IRQ2 = 26
ANTENNA_DELAY1 = 16317
ANTENNA_DELAY2 = 16317
startupTime = 1
DATA_LEN = 17
data = [0] * 5
time.sleep(startupTime)

module1 = DW1000Tag("module1", CS1, IRQ1, ANTENNA_DELAY1, "82:17:5B:D5:A9:9A:E2:1A", DATA_LEN, 0)
print("\n")

time.sleep(startupTime)


module2 = DW1000Tag("module2", CS2, IRQ2, ANTENNA_DELAY2, "82:17:5B:D5:A9:9A:E2:1B", DATA_LEN, 1)

time.sleep(startupTime)

def loop():
    print("-----Module 2-----")
    range = None
    while(range == None):
        range = module2.loop()
    print(range)
    print("\n")
    time.sleep(1)
    print("-----Module 1-----")
    range = None
    while(range == None):
        range = module1.loop()
    print(range)
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
