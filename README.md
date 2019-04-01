# Indoor Positioning System
Master Thesis

Authors: 

Oscar Johansson @orjn01

Lucas Wassenius @lucaswassenius

## Introduction
The thesis project's aim is to find evaluate a dual tag setup of UWB-modules, in a indoor positioning system, 
to find the orientation in addition to the position. DW1000 modules from Decawave is used to find the ToF between anchors and tags.
Each anchor has one DW1000 UWB-Module and a Arduino Pro Mini 3.3V. A tag uses two UWB-Modules and one Raspberry Pi 3 B+ for processing.
The code is based on the DW1000 Library from Thotro, see the library [here](https://github.com/thotro/arduino-dw1000).

### Two-Way Assymetric Ranging
To find the ToF between tags and anchors Two-Way Assymetric Ranging is used. This means that 3 timestamps in the anchor is recorded 
and 3 timestamps in the tag is recorded. Then these 6 timestamps are used to find the ToF. This do not require any synchronization between
the devices. See image below to understand the communication flow between Anchors and Tags.

<p align="center">
  <img  width="300" height="500" src="/Images/twoWayRanging.png">
</p>

### Trilateration

### Particle Filter

## Installation Anchor
1. Download the library file "arduino-dw1000-Library.zip" from the Anchor Folder.
2. Unzip the folder and store in Arduino Libraries Folder.
3. Program two Arduinos with Anchor/Tag Calibration files w. device ID(ranging through 0,1,2) in EEPROM address 1.
Note. 5V Arduinos can not supply 3.3V to the DW1000 Chip as the current is limited to approx. 50mA.
4. Find the Antenna delay(in units of 15.65ps) of each DW1000 Chip and store it in EEPROM address 2. 
5. Program the Arduino with the latest version of Anchor Code.

## Installation Tag


## Project State
In the current version of the project two tags can be positioned with an approximate sampling frequency of 4-5 positions/s for each tag. 
