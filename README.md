#  Examples how to use uFR Series readers Fast Read command

Software example written for Lazarus/FPC. 
Example of Fast card reading feature of uFR devices with usage of "LinRowRead_" API command, by using default card keys.

Tested on Windows and Linux-RPI.


## Getting Started

Download project, open source in Lazarus RAD, compile and run. Optionally you can use precompiled binary at first.
Appropriate ufr-lib dynamic library (ufCoder-...) is mandatory for this project, choose it depending on platform and architecture.

### Prerequisites

uFR series reader, Lazarus/FPC.

NOTE: Please be sure that you are using Strings in appropriate manner, if String type is multi byte, please use Ansistring with safe conversion method in that case. 

### Installing

No installation needed. 


## Usage

Example provides basic funcionality with usage of "LinRowRead_" API command, by using default card keys.
It will read and dump card content. Optionally it can be saved in binary and text format.
 

## License

This project is licensed under the ..... License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Purpose of this software demo is to provide additional info about usage of uFR Series API specific features.
* It is specific to mentioned hardware ONLY and some other hardware might have different approach, please bear in mind that.  


