# Indoor Positioning System
This is the repository for an indoor positioning system developed during our master thesis project. This master thesis investigated the feasibility of using the relative position between two tags located on the same robot to find the orientation of said robot. The code in the repository are meant to be used for two tags. However it's possible to use the repository as a library for a system with only one tag. In this case only the tag.py file should have to be modified. All other files should be able to be used as is.

Authors: 

Oscar Johansson [@oscjoh95](https://github.com/oscjoh95)

Lucas Wassenius [@lucaswassenius](https://github.com/lucaswassenius)

## Introduction
In the project DW1000 modules from Decawave were used to find the ToF between anchors and tags.
Each anchor had one DW1000 UWB-Module and a Arduino Pro Mini 3.3V. The tag used two UWB-Modules and one Raspberry Pi 3 B+ for processing. The anchor code is based on a DW1000 Library from Thotro, see the library [here](https://github.com/thotro/arduino-dw1000). The tag code is based on a python library from ThingType, see the library [here](https://github.com/ThingType/DW1000_Python_library).

### Two-Way Assymetric Ranging
To find the ToF between tags and anchors Two-Way Assymetric Ranging is used. This means that 3 timestamps in the anchor and 3 timestamps in the tag are recorded. Then these 6 timestamps are used to find the ToF. This do not require any synchronization between
the devices. See the image below to understand the communication flow between the Anchors and the Tags.

<p align="center">
  <img  width="300" height="500" src="/Images/twoWayRanging.png">
</p>

### Filters
There are two filters included in the repository written in python. These can be used in the tag program running on raspberry pi to filter the measurements. To apply the filter just change the constant FILTER in the tag class to correspond to the filter you want to use. 
The filters included are a Kalman filter and a sequential importance resampling particle filter. The filters require tuning to be optimized for different setups and movement patterns of the tags. It should be enough to tweak the parameters under the corresponding filter section at the top of the tag.py file to optimize the filters. 

## Installation Anchor
1. Download the library file "arduino-dw1000-Library.zip" from the Anchor Folder.
2. Unzip the folder and store in Arduino Libraries Folder.
3. Program two Arduinos with Anchor/Tag Calibration files w. device ID(ranging through 0,1,2) in EEPROM address 1.
Note. 5V Arduinos can not supply 3.3V to the DW1000 Chip as the current is limited to approx. 50mA.
4. Find the Antenna delay(in units of 15.65ps) of each DW1000 Chip and store it in EEPROM address 2. 
5. Program the Arduino with the latest version of Anchor Code.

## Installation Tag
1. Download the files from the tag folder to your raspberry pi. 
2. Verify that the constants under the setup section in tag.py are correct.
3. Compile and run

## Project State
In the current version of the project two tags can be positioned using three anchors with an approximate sampling frequency of 4-5 positions/s for each tag. 
