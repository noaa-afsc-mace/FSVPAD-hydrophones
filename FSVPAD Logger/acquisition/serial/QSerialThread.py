#
#  Should add NMEA parsing:
#       add a parse type of NMEA
#       the parse expression should be a list of NMEA talker+sentence ids to extract
#       The talker and sentence ID should be extracted
#       separate parsing function that accepts the sentence + data and returns dict with fields named for their contents
#         example: GLL {'latitude':12.34, 'ns':'N', 'longitude':123.45, 'ew':'W', 'utc':123456.78, 'status':'A'}
#
#       should include checksum verification:
#
#       from operator import xor
#       data='$GPAAM,A,A,0.10,N,WPTNME*32'
#       nmea = map(ord, data[1:data.index('*')])
#       checksum = reduce(xor, nmea)
#       print hex(checksum)
#

import sys
import re
import serial
#  redefine bin() function since something in PyQt4.QtCore shadows it
#  (do this before importing PyQt4.QtCore)
binb = bin
from PyQt4.QtCore import *

class QSerialThread(QThread):

    def __init__(self, deviceName, deviceParams, pollHz=10,
                 initialState=(False, False), parent=None):

        QThread.__init__(self, parent)

        #  set default values
        self.__running = False
        self.__rxBuffer = ''
        self.__txBuffer = ''
        self.__filtRx = ''
        self.__rts = initialState[0]
        self.__dtr = initialState[1]
        self.__partControl = False

        #  define a list that stores the state of the control lines: order is [CTS, DSR, RI, CD]
        self.__controlLines = [False, False, False, False]

        #  define the maximum line length allowed - no sane input should exceed this
        self.MaxLineLen = 8192

        #  determine pySerial version - the write method in versions prior
        #  to 2.5 (or 2.4 on win32) returns null necessitating different
        #  handling depending on the installed pySerial version.
        try:
            version = serial.VERSION.split('.')
            version = float(version[0] + '.' + version[1])
            if (version >= 2.5):
                self.__writeRetBytes = True
            elif (sys.platform == 'win32') and (version >= 2.4):
                self.__writeRetBytes = True
            else:
                self.__writeRetBytes = False
        except:
            self.__writeRetBytes = False
        if (not self.__writeRetBytes):
            sys.stderr.write('Warning(QSerialThread): It is advised that you upgrade your ' +
                             'pySerial package to version 2.5+\r\n')

        #  connect this thread to the monitor's signals
        self.connect(parent, SIGNAL("txSerialData"), self.__write)
        self.connect(parent, SIGNAL("getControlLines"), self.__getControlLines)
        self.connect(parent, SIGNAL("setSerialRTS"), self.__setRTS)
        self.connect(parent, SIGNAL("setSerialDTR"), self.__setDTR)

        #  set the thread sleep interval in microsecs
        self.__usleepInt = int(1000000. / pollHz)

        #  set the device name
        self.deviceName = deviceName

        #  set the parsing parameters
        if deviceParams[6].upper() == 'REGEX':
            self.parseType = 2
            try:
                #  compile the regular expression
                self.parseExp = re.compile(deviceParams[7])
            except Exception, e:
                raise QSerialError('Invalid regular expression configured for ' + self.deviceName, parent=e)
        elif deviceParams[6].upper() == 'DELIMITED':
            self.parseType = 1
            self.parseExp = deviceParams[7]
        elif deviceParams[6].upper() == 'RFIDFDXB':
            self.parseType = 13
            self.parseExp = ''
            self.MaxLineLen = int(deviceParams[8])
        elif deviceParams[6].upper() == 'HEXENCODE':
            self.parseType = 12
            self.parseExp = ''
            self.MaxLineLen = int(deviceParams[8])
        elif deviceParams[6].upper() == 'FIXEDLEN':
            self.parseType = 11
            self.parseExp = ''
            self.MaxLineLen = int(deviceParams[8])
        elif deviceParams[6].upper() == 'RAMSES':
            self.parseType = 21
            self.parseExp = ''
        else:
            self.parseType = 0
            self.parseExp = ''
        try:
            self.parseIndex = int(deviceParams[8])
        except:
            self.parseIndex = 0

        #  Set the command prompt  - This is required for devices that present a
        #  command prompt that must be responded to.
        self.cmdPrompt = deviceParams[9]
        self.cmdPromptLen = len(self.cmdPrompt)

        #  as of PySerial 3.0, assigning ports by int index is no longer supported. For backwards
        #  compatibility, convert int defined ports to string assuming the int is a 0 based index
        #  into the systems list of COM ports.
        #
        #  THIS IS NOT COMPATIBLE WITH LINUX/MAC but those ports should be defined as strings
        #
        if  isinstance(deviceParams[0], (int, float)):
            deviceParams[0] = 'COM' + str(int(deviceParams[0]) + 1)

        try:
            #  create the serial port (initially set port to none so pySerial doesn't open the port)
            self.__serial = serial.Serial(port=None, baudrate=deviceParams[1], \
                                          bytesize=deviceParams[2], parity=deviceParams[3].upper(), \
                                          stopbits=deviceParams[4])
            self.__serial.port=deviceParams[0]

            #  set flow control
            if deviceParams[5].upper() == 'RTSCTS':
                self.__serial.rtscts = True
            elif deviceParams[5].upper() == 'DSRDTR':
                self.__serial.dsrdtr = True
            elif deviceParams[5].upper() == 'SOFTWARE':
                self.__serial.xonxoff = True


        except Exception, e:
            raise QSerialError('Unable to create serial port for ' + deviceName + '. Invalid port option.', \
                               parent=e)


    def startMonitor(self):
        """
          Open the serial port and start the thread
        """

        if not self.isRunning():
            try:
                #  open the serial port
                self.__serial.open()

                #  set RTS and DTR
                if (self.__serial.rtscts == False):
                    self.__serial.setRTS(self.__rts)
                if (self.__serial.dsrdtr == False):
                    self.__serial.setDTR(self.__dtr)

                #  get the initial control pin states
                self.__controlLines = [self.__serial.getCTS(), self.__serial.getDSR(),
                                       self.__serial.getRI(), self.__serial.getCD()]

                # start the thread
                self.__running = True
                self.start()
            except Exception, e:
                raise QSerialError('Unable to open serial port for device ' + self.deviceName + '.', parent=e)



    def stopMonitor(self):
        """
          Stop the currently running thread which will also close the serial port
        """
        if self.isRunning():
            #  set the "running" state to false
            self.__running = False
            #  wait here until the thread exits the run method
            self.wait()


    def __setRTS(self, deviceName, state):
        """
          Set/Unset the RTS line on this serial port
        """
        if deviceName == self.deviceName:
            self.__serial.setRTS(state)
            self.__rts = state

    def __setDTR(self, deviceName, state):
        """
          Set/Unset the DTR line on this serial port
        """
        if deviceName == self.deviceName:
            self.__serial.setDTR(state)
            self.__dtr = state


    def __getControlLines(self, deviceName):
        """
            Returns the state of the DCE control lines.
        """
        if deviceName == self.deviceName:
            self.emit(SIGNAL("DCEControlState"), self.deviceName, self.__controlLines)


    def __write(self, deviceName, data):
        """
          Write data to the serial port. This method simply appends the data
          to the tx buffer.  Data is written in the "run" method.
        """
        if deviceName == self.deviceName:
            self.__txBuffer = self.__txBuffer + data


    def __filterRAMSESChars(self, data):
        """
            replace control characters in RAMSES sensor data stream
        """

        controlChars = {'@e':'\x23', '@d':'\x40', '@f':'\x11', '@g':'\x13'}
        for i, j in controlChars.iteritems():
            data = data.replace(i, j)

        return data


    def run(self):
        """
          This method monitors the serial port and returns data when the line
          terminator is encountered.

          This method is called automagically by QThread after we call QThread's
          start method. This method is never called directly.
        """
        self.usleep(self.__usleepInt)
        while self.__running:

            #  check the state of the control lines - emit signal if changed
            if (self.__controlLines[0] != self.__serial.getCTS()):
                self.__controlLines[0] = self.__serial.getCTS()
                self.emit(SIGNAL("SerialControlChanged"), self.deviceName, 'CTS', self.__controlLines[0])
            if (self.__controlLines[1] != self.__serial.getDSR()):
                self.__controlLines[1] = self.__serial.getDSR()
                self.emit(SIGNAL("SerialControlChanged"), self.deviceName, 'DSR', self.__controlLines[0])
            if (self.__controlLines[2] != self.__serial.getRI()):
                self.__controlLines[2] = self.__serial.getRI()
                self.emit(SIGNAL("SerialControlChanged"), self.deviceName, 'RI', self.__controlLines[0])
            if (self.__controlLines[3] != self.__serial.getCD()):
                self.__controlLines[3] = self.__serial.getCD()
                self.emit(SIGNAL("SerialControlChanged"), self.deviceName, 'CD', self.__controlLines[0])

            #  check if we have any Rx or Tx buisness
            nBytesTx = len(self.__txBuffer)
            nBytesRx = self.__serial.inWaiting()
            if nBytesRx > 0:
                #  data available - read
                rxData = self.__serial.read(nBytesRx)

                #  check if there is data in the buffer and append if so
                buffLength = len(self.__rxBuffer)
                if buffLength > 0:
                    rxData = self.__rxBuffer + rxData
                    #  reset the buffer
                    self.__rxBuffer = ''

                #  get the new length of our rx buffer
                buffLength = len(rxData)

                #  Parse the received data
                if (self.parseType <= 10):
                    #  Parse types 0-10 are "line based" and are strings of chars
                    #  that are terminated by an EOL (\n or \r\n) characters.

                    #  check if we have to force the buffer to be processed
                    if buffLength > self.MaxLineLen:
                        #  the buffer is too big - force process it
                        rxData = rxData + '\n'

                    #  split lines into a list
                    lines = rxData.splitlines(True)

                    #  loop thru the extracted lines
                    for line in lines:
                        err = None
                        #  check for complete lines
                        if line.endswith('\n') or line.endswith('\r'):
                            #  this line is complete - strip the newline character(s)
                            line = line.rstrip('\r\n')

                            #  process line
                            try:
                                if self.parseType == 2:
                                    #  use regular expression to parse
                                    parts = self.parseExp.findall(line)
                                    data = parts[self.parseIndex]
                                elif self.parseType == 1:
                                    #  use a delimiter to parse
                                    parts = line.split(self.parseExp)
                                    data = parts[self.parseIndex]
                                else:
                                    # do not parse - pass whole line
                                    data = line
                            except Exception, e:
                                data = None
                                err = QSerialError('Error parsing input from ' + self.deviceName + \
                                                   '. Incorrect parsing configuration or malformed data stream.', \
                                                   parent=e)

                            # emit a signal containing data from this line
                            self.emit(SIGNAL("SerialDataReceived"), self.deviceName, data, err)

                        elif (self.cmdPromptLen > 0) and (line[-self.cmdPromptLen:] == self.cmdPrompt):
                            #  this line (or the end of it) matches the command prompt
                            self.emit(SIGNAL("SerialDataReceived"), self.deviceName, line, err)

                        else:
                            #  this line of data is not complete - insert in buffer
                            self.__rxBuffer = line

                elif (self.parseType <= 20):
                    #  Parse types 11-20 are length based. This method of parsing acts on a
                    #  fixed number of characters.

                    #  loop thru the rx buffer extracting our fixed length chunks of data
                    lines = []
                    for i in range(0, (buffLength // self.MaxLineLen)):
                        #  generate the start and end indicies into our chunk
                        si = i * self.MaxLineLen
                        ei = si + self.MaxLineLen
                        #  extract it
                        lines.append(rxData[si:ei])
                        #  remove the chunk from the working rx buffer
                        rxData = rxData[ei:]

                    #  place any partial chunks back in the buffer
                    self.__rxBuffer = self.__rxBuffer + rxData

                    #  loop thru the extracted chunks and process
                    for line in lines:
                        err = None
                        #  process chunk
                        try:

                            if (self.parseType == 12):
                                #  encode the entire chunk as hex
                                data = line.encode('hex')

                            if (self.parseType == 13):
                                #  Process this as a type FDX-B RFID tag

                                #  this parsing is based on a single RFID reader which outputs a fixed 8 byte
                                #  datagram with no newline. It doesn't appear to support the "extra data block"
                                #  so that data is not handled by this parsing routine.

                                bstr = ''
                                for c in line:
                                    #  construct the original binary stream
                                    bstr = binb(ord(c))[2:].zfill(8) + bstr
                                #  decode the binary string into the ID code, Country code, data block status bit, and animal bit
                                data = [str(int(bstr[26:64],2)), str(int(bstr[16:26],2)), bstr[15], bstr[0]]

                            else:
                                # do not do anything - pass whole chunk
                                data = line

                        except Exception, e:
                            data = None
                            err = QSerialError('Error parsing input from ' + self.deviceName + \
                                               '. Incorrect parsing configuration or malformed data stream.', \
                                               parent=e)

                        # emit a signal containing data from this line
                        self.emit(SIGNAL("SerialDataReceived"), self.deviceName, data, err)

                else:
                    if (self.parseType == 21):
                        #  parse data from a the TriOS RAMSES optical sensor family.

                        #  check if we have a split control char on the buffer boundry
                        if self.__partControl:
                            rxData = '\x40' + rxData
                            self.__partControl = False

                        if (rxData[-1] == '\x40'):
                            #  note the partial control character
                            self.__partControl = True
                            #  trim the control char from rxData
                            rxData = rxData[0:-1]

                        #  filter incoming data and place in a filtered Rx buffer
                        self.__filtRx = self.__filtRx + self.__filterRAMSESChars(rxData)
                        lenFiltRx = len(self.__filtRx)

                        nc = 0

                        while (lenFiltRx > 2):

                            nc = nc + 1
                            #  extract the datagram length and calculate frame end index
                            dgLen = (2 ** (ord(self.__filtRx[1]) >> 5)) * 2
                            fEnd = dgLen + 8

                            #  check that we have enough characters to extract a full datagram
                            if (fEnd <= lenFiltRx):
                                #  initialize some variables
                                err = None
                                dgData = []
                                intTime = 0

                                #print 'RAMSES:' + self.__filtRx[0] + ' ' + str(dgLen + 8) + ' ' + str(lenFiltRx) + \
                                #    ' ' + str(len(self.__filtRx))
                                #print ''.join( [ "%02X " % ord( x ) for x in self.__filtRx[0:dgLen+8] ] ).strip()

                                #  determine the datagram frame
                                frame = ord(self.__filtRx[4])

                                if (frame == 7):
                                    #  Frame 7 contains the integration time and 31 pixels of data.

                                    #  parse the integration time
                                    intTime = (2 ** ord(self.__filtRx[7])) * 2

                                    #  parse the rest of the data in the datagram
                                    for i in range(9, fEnd-1, 2):
                                        #  each pixel value is comprised of 2 bytes [low, high]
                                        #  shift the high byte 8 bits left and add the low byte
                                        dgData.append((ord(self.__filtRx[i+1]) << 8) + ord(self.__filtRx[i]))

                                elif (frame < 7):
                                    #  Frames 0-6 contain data from 32 pixels only
                                    for i in range(7, fEnd-1, 2):
                                        #  each pixel value is comprised of 2 bytes [low, high]
                                        #  shift the high byte 8 bits left and add the low byte
                                        dgData.append((ord(self.__filtRx[i+1]) << 8) + ord(self.__filtRx[i]))


                                elif (frame == 254):
                                    #  Frame 254 denotes an error - don't know much about it though
                                    pass

                                elif (frame == 255):
                                    #  Frame 255 denotes a query response

                                    #  append the device ID
                                    dgData.append('SAM_%0x%0x' % (ord(self.__filtRx[8]),ord(self.__filtRx[7])))

                                    #  append the firmware version
                                    dgData.append(ord(self.__filtRx[10]) + (ord(self.__filtRx[9]) / 10.))

                                    #  append the frequency
                                    dgData.append(ord(self.__filtRx[11]))

                                    #  append the last bits I don't know what they are
                                    dgData.append(self.__filtRx[12:15])


                                # emit a signal containing data from this line
                                data = [frame, intTime, dgData]
                                self.emit(SIGNAL("SerialDataReceived"), self.deviceName, data, err)

                                #  remove this datagram from the buffer - add one to get the checkbyte
                                self.__filtRx = self.__filtRx[fEnd:]
                                lenFiltRx = len(self.__filtRx)

                                if nc > 100:
                                    lenFiltRx = 0

                            else:
                                #  there isn't a complete datagram in the buffer - exit processing
                                lenFiltRx = 0

            elif nBytesTx > 0:
                #  write data to the device
                if self.__writeRetBytes:
                    #  for versions 2.5 and greater, pySerial.write returns the number
                    #  of bytes wrtitten so we can use that to manage our write buffer.
                    nBytes = self.__serial.write(self.__txBuffer)
                    self.__txBuffer = self.__txBuffer[nBytes:nBytesTx]
                else:
                    #  for versions prior to 2.5, write returns null so we don't know
                    #  what was actually written. We'll just assume everything but if
                    #  you are writing large chunks of data you might want to break
                    #  them up so they don't exceed the size of the serial port's buffer.
                    self.__serial.write(self.__txBuffer)
                    self.__txBuffer = ''

            else:
                #  nothing to do - so we'll sleep
                self.usleep(self.__usleepInt)


        #  We're not running anymore - close the port
        try:
            #  flush the write buffer and close the serial port
            self.__serial.flush()
            self.__serial.close()
        except:
            raise QSerialError('Unable to close serial port for device ' + self.deviceName +'.', parent=e)



#
#  QSerialMonitor Exception class
#
class QSerialError(Exception):
    def __init__(self, msg, parent=None):
        self.errText = msg
        self.parent = parent

    def __str__(self):
        return repr(self.errText)
