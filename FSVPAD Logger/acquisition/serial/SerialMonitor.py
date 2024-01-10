
from PyQt4.QtCore import *
import QSerialThread


class SerialMonitor(QObject):
    """A class for acquiring data from multiple serial port devices.

    SerialMonitor watches a collection of serial ports and emits a signal when
    data is received by any of the monitored ports. SerialMonitor does this by
    spawning a thread for each port that is monitored that periodically
    polls the serial port, buffering data until a complete line is received. (A
    complete line is defined as a line terminated by LF, CR+LF, or CR.) The line
    can optionally be parsed and the resulting output is passed from the
    monitoring thread to SerialMonitor via Qt's signal/Slot mechanism which
    then re-emits these signals which are then handled by the application's
    serial event handling method. SerialMonitor handles both sending and receiving
    of data and thus can be used for polled sensors and for general serial I/O.

    **Public Methods**

    **addDevice** -- add a serial device to the list of devices that
    SerialMonitor watches.

    **removeDevice** -- Remove a device from the list of devices that
    SerialMonitor watches. If the device is currently being monitored,
    the acquisition thread is stopped and the serial port is closed.

    **startMonitoring** -- Start monitoring all (or optionally some) of the
    devices that have been registered by calls to addDevice. Calling
    startMonitoring will open the serial ports and start the acquisition
    threads for the specified devices.

    **stopMonitoring** -- Stop monitoring all (or optionally some) of the
    devices that have been registered by calls to addDevice. The acquisition
    threads are stopped and the serial ports closed for the specified devices.

    **Signals**

    **SerialDataReceived** -- This signal is emitted when a complete line of
    data is received by one of the monitored serial ports. If the line is
    parsed, the signal is only emitted if the parsing method returns data.

    Applications wishing to receive data from SerialMonitor must connect
    this signal to a method that accepts the following parameters:

        @rtype: String
        @returns: The device name string, as defined in the call to addDevice.
        @rtype: String
        @returns: The data received by the port identified by the device name.
        @rtype: Exception
        @returns: If there is an error parsing the data,

    """

    def __init__(self, parent=None):
        """Initialize this SerialMonitor instance."""
        QObject.__init__(self, parent)
        self.__devices = dict()


    def __del__(self):
        """Clean up any active QserialThread objects before deleting the SerialMonitor instance."""
        devices = self.__devices.keys()
        for device in devices:
            self.removeDevice(device)


    def addDevice(self, deviceName, port, baud, parseType, parseExp, parseIndex, cmdPrompt='', \
                  byteSize=8, parity='N', stopBits=1, flowControl='NONE', pollRate=100,
                  initialState = (True, True)):
        """Add a serial device to the list of devices that SerialMonitor watches.

        *deviceName* is a string that serves as a unique identfier for the serial port.
        This name will be included in the emitted signals to associate data with a device.

        *port* is a string containing the platform specific serial port identifier. For
        example, on windows systems it would be ``'COM1'`` or ``'COM12'``. On Linux systems it
        would be ``'/dev/ttyS0'`` or similar.

        *baud* is the serial port baud rate such as 9600 or 115200 etc.

        *parseType* specifies how the incoming data is parsed before the data is emitted
        via the *SerialDataReceived* signal. Valid values are:

            ``None`` -- No parsing is performed but newline characters are stripped.

            ``Delimited`` -- The incoming line is parsed using a delimiter. The delimiter
            is specified in the *parseExp* argument and the *parseIndex* argument specifies
            which field is returned.

            ``RegEx`` -- The incoming line is parsed using a regular expression. The regex
            is passed via the *parseExp* argument and and the *parseIndex* argument specifies
            which field is returned.

            ``RFIDFDXB`` -- This is a fixed length parser that assumes the data conforms to
            the FDX-B RFID tag specification. The *parseIndex* argument specifies the length
            in bytes of the datagram which for now should be specified as 8.

            ``HexEncode`` -- This is a fixed length parser that assumes the data is hex encoded.
            The *parseIndex* argument specifies the length in bytes of the datagram.

            ``FixedLen`` -- This is a generic fixed length parser that simply returns data in
            chunks of bytes the size of which is specified in the *parseIndex* argument.

            ``RAMSES`` -- This is a specialized fixed length parser for the RAMSES-ACC series of
            hyperspectral radiometers. Set *parseExp* and *parseIndex* to NONE.

        *parseExp* is a string defining either the parsing delimiter if *parseType* is 1
        or the regular expression if *parseType* is set to 2. If `parseType` is 0, specify
        an empty string ``''``.

        *parseIndex* is a number that is the index into the list returned by the parsing
        method of the data element of interest. This parameter must be specified even if
        only 1 element is returned from the parsing method (in which case *parseIndex*
        would be set to ``0``. For the fixed length parsers this argument specified the length
        of the message that should be returned.

        *cmdPrompt* (optional) is a string that specifies the command prompt for instruments
        that require user interaction. Text based UI's that require user interaction may
        output a command prompt which lacks a newline character. Setting *cmdPrompt* to
        the text of this command prompt will result in the command prompt line being
        handled like a regular line where the text of the command prompt is emitted via
        the *SerialDataReceived* signal. This allows the method handling the
        *SerialDataReceived* signal to "respond" to the command prompt.

        *byteSize* (optional) a number specifying the number of data bits. Possible values
        are ``5``, ``6``, ``7``, and ``8``. Default is ``8``.

        *parity* (optional) a string specifying the serial port parity checking method.
        Possible values are ``N`` for None, ``E`` for Even, ``O`` for Odd, ``M`` for Mark,
        and ``S`` for Space. Default is ``N``.

        *stopBits* (optional) a number specifying the number of stop bits. Possible values
        are ``1``, ``1.5``, and ``2``. Default is ``1``.

        *flowControl* (optional) a string specifying the flow control method. Possible
        values are ``RTSCTS`` for RTS/CTS hardware flow control, ``DSRDTR`` for DSR/DTR
        hardware flow control, ``SOFTWARE`` for XON/XOFF software flow control and
        ``NONE`` for no flow control. Default is ``NONE``.

        *pollRate* (optional) a number specifying the rate (in Hz) that the serial port
        is polled. During polling both the input and output buffers are checked for data
        and if data is present the buffer is read from or written to the port. When working
        at high baud rates it may be necessary to increase this value. Valid values are in
        the range of 1-999999 Hz. The default value is 100 Hz.

        *initialState* (optional) a 2-tuple of booleans containing the initial state of the
        control lines RTS and DTR (in that order) for the serial port when added to the
        monitor
        """

        if deviceName in self.__devices:
            #  device name is already in use - issue error
            raise QSerialError('Device name ' + deviceName + ' is already in use. Specify a unique name.')

        #  create the monitor thread and add to the device dictionary
        self.__devices[deviceName] = QSerialThread.QSerialThread(deviceName, [port, baud, byteSize, parity, stopBits,
                                                   flowControl, parseType, parseExp, parseIndex, cmdPrompt],
                                                   pollHz=pollRate, initialState=initialState, parent=self)
        #  connect us to the monitor thread's signals
        self.connect(self.__devices[deviceName], SIGNAL("SerialDataReceived"), self.__rxData)
        self.connect(self.__devices[deviceName], SIGNAL("SerialControlChanged"), self.__controlData)
        self.connect(self.__devices[deviceName], SIGNAL("DCEControlState"), self.__controlDataState)


    def removeDevice(self, deviceName):
        """
          Removes a device from the list of devices that are monitored stopping the thread
          that monitors said device if needed.
        """

        if deviceName in self.__devices:
            if self.__devices[deviceName].isRunning():
                #  stop the serial monitor thread associated with this device
                self.__devices[deviceName].stopMonitor()

            #  remove the device from device list
            self.__devices.pop(deviceName)

        else:
           raise QSerialError('Unable to remove unknown device: ' + deviceName + '.')


    def startMonitoring(self, devices=None):
        """
          Start monitoring. Serial ports are opened and the monitoring threads are
          started.  As data is received from the individual ports that are being
          monitored it is sent via the ``SerialDataReceived`` signal.

          You can start specific devices by setting the `devices` keyword to a list
          of device(s) you want to start.
        """

        deviceErrors = {}

        if devices == None:
            #  no devices specified - get a list of all devices
            devices = self.__devices.keys()

        for device in devices:
            #  try to start each device in the list
            if not self.__devices[device].isRunning():
                try:
                    self.__devices[device].startMonitor()
                except Exception, e:
                    deviceErrors[device] = e

        if (len(deviceErrors) > 0):
            #  pass the error up the stack
            raise QSerialPortError(deviceErrors)


    def stopMonitoring(self, devices=None):
        """
          Stop monitoring. The serial ports are closed and the monitoring threads
          are stopped.

          You can stop specific devices by setting the `devices` keyword to a list
          of device(s) you want to stop.
        """

        deviceErrors = {}

        if devices == None:
            #  no devices specified - get a list of all devices
            devices = self.__devices.keys()

        for device in devices:
            #  try to stop each device in the list
            if self.__devices[device].isRunning():
                try:
                    self.__devices[device].stopMonitor()
                except Exception, e:
                    deviceErrors[device] = e

        if (len(deviceErrors) > 0):
            #  pass the error up the stack
            raise QSerialPortError(deviceErrors)


    def whosMonitoring(self):
        """Returns a list of currently running serial acquisition threads"""
        runningDevices = []
        for device in self.__devices.iteritems():
            if device[1].isRunning():
                runningDevices.append(device[0])

        return runningDevices


    def setDTR(self, deviceName, state):
        """Set the DTR line on the specified serial port

        """
        if deviceName in self.__devices:
            self.emit(SIGNAL("setSerialDTR"), deviceName, state)


    def setRTS(self, deviceName, state):
        """Set the RTS line on the specified serial port

        """
        if deviceName in self.__devices:
            self.emit(SIGNAL("setSerialRTS"), deviceName, state)


    def txData(self, deviceName, data):
        """Transmit data to the specified device

        `deviceName` must be set to the name of a configured
        """

        #  send the txSerialData signal to the monitoring threads
        if deviceName in self.__devices:
            self.emit(SIGNAL("txSerialData"), deviceName, data)


    def getControlLines(self, deviceName):
        """
            Request the status of the DCE control lines. The data is returned as a
            list of booleans ordered as [CTS, DSR, RI, CD].
        """
        self.emit(SIGNAL("getControlLines"), deviceName)


    def __rxData(self, deviceName, data, err):
        # consolodates the signals from the individual monitoring threads and re-emit
        self.emit(SIGNAL("SerialDataReceived"), deviceName, data, err)


    def __controlData(self, deviceName, line, state):
        # consolodates the signals from the individual monitoring threads and re-emit
        self.emit(SIGNAL("SerialControlChanged"), deviceName, line, state)


    def __controlDataState(self, deviceName, state):
        # consolodates the signals from the individual monitoring threads and re-emit
        self.emit(SIGNAL("SerialControlState"), deviceName, state)

#
#  SerialMonitor Exception class
#
class QSerialError(Exception):
    def __init__(self, msg, parent=None):
        self.errText = msg
        self.parent = parent

    def __str__(self):
        return repr(self.errText)


class QSerialPortError(Exception):
    def __init__(self, devices, parent=None):
        self.devices = devices
        self.devNames = devices.keys()
        if (len(devices) == 1):
            self.errText = 'Error opening device ' + str(self.devNames[0])
        else:
            self.errText = 'Error opening devices ' + ','.join(self.devNames)

    def __str__(self):
        return repr(self.errText)
