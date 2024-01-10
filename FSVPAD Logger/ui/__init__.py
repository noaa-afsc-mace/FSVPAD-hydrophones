#!/usr/bin/env python
"""A PyQt based package for data acquisition.

acquisition is a data acquisition package written in Python using the Qt
application framework. The package provides a high level interface to
sampling devices and sensors and integrates seamlessly into PyQt based
applications using Qt's signals/slots mechanism. The package also aims
to provide supporting functions that make it easier to work with
common instrument and sensor data formats.

================
Package Overview
================

Currently the acquisition package contains a single sub-package serial
which contains the SerialMonitor class for acquiring data from serial
based devices.

The package will be extended soon with classes for interfacing with NOAA
Scientific Computing System (SCS) servers.


"""

__docformat__ = 'restructuredtext en'

__version__ = '0.4.0'

__author__ = 'Rick Towler <rick.towler@noaa.gov>'
