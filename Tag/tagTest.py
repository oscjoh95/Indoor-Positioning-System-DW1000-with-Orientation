import DW1000Constants as C
import monotonic
from DW1000TagClass import *
import time

CS1 = 16
IRQ1 = 19
ANTENNA_DELAY1 = 16317
StartupTime = 1
DATA_LEN = 17

module1 = DW1000Tag("module1", CS1, IRQ1, ANTENNA_DELAY1, "82:17:5B:D5:A9:9A:E2:1A", DATA_LEN)

time.sleep(StartupTime)

def loop():
    range = module1.loop()
    
def main():
    try:
        while 1:
            loop()
    except KeyboardInterrupt:
        print('Interrupted by user')

if __name__ == '__main__':
    main()
