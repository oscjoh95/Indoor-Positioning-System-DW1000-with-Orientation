import DW1000Constants as C
import monotonic
from DW1000TagClass import *
import time

CS = 16
IRQ = 19
ANTENNA_DELAY = 16317
StartupTime = 1
DATA_LEN = 17

DW1000_module = DW1000Tag("module1", CS, IRQ, ANTENNA_DELAY, "82:17:5B:D5:A9:9A:E2:1A", DATA_LEN)
time.sleep(StartupTime)

def loop():
    range = DW1000_module.loop()
    
def main():
    try:
        while 1:
            loop()
    except KeyboardInterrupt:
        print('Interrupted by user')

if __name__ == '__main__':
    main()
