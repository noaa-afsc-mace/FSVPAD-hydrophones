# FSVPAD

FSVPAD is a free-drifting hydrophone spar buoy designed for measurement of vessel-radiated noise designed for NOAA Fisheries noise-reduced research vessels.

This repository provides processing software, technical information, and example data output from an instrument deployment as described in a NOAA Technical memorandum:

Bassett, C., De Robertis, A., and Gallagher, M. 2024. A passive acoustic drifter for radiated noise measurements of NOAA Fisheries survey vessels. 
U.S. Department of Commerce, NOAA Technical Memorandum NMFS-AFSC-490, 116 p. https://repository.library.noaa.gov/view/noaa/65794

## Primary directories
**Matlab** - contains processing scripts to estimate vessel radiated noise from FSVPAD measurements

**FSVPAD Logger** - python application run on ship-based laptop to collect GPS data and compute the range and bearing between the FSVPAD and the test vessel.

**Technical documentation** - contains technical documentation related to construction and configuration of the FSVPAD system

**Example results** - contains example output of the processing scripts from a 2023 measurement of NOAA ship Oscar Dyson.

# Prerequisites
The analysis scripts require Matlab and the signal processing and statistics toolboxes.


## Authors

* **Chris Bassett** - _Applied Physics Laboratory, University of Washington_ 
* **Alex De Robertis** - _Alaska Fisheries Secience Center, NOAA Fisheries_  


## License

This software is licensed under the GNU License - see the
[LICENSE](LICENSE) file for details


## Acknowledgments

* This work was funded by the National Marine Fisheries Service Office of Science and Technology.
 

