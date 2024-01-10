#!/usr/bin/env python

#  add the UI files directory to the python path
import sys
import os
pyPath = reduce(lambda l,r: l + os.path.sep + r, os.path.dirname(os.path.realpath(__file__)).split(os.path.sep))
sys.path.append(os.path.join(pyPath, 'ui'))

from PyQt4.QtCore import *
from PyQt4.QtGui import *
from ui import ui_SerialFaker
import SerialMonitor
import time


class SerialFaker(QMainWindow, ui_SerialFaker.Ui_SerialFaker):
    def __init__(self, parent=None):
        super(SerialFaker, self).__init__(parent)
        self.setupUi(self)

        #  create the device dictionary
        devices = dict()

        #  DEVICE CONFIGURATION - THIS IS WHERE YOU DEFINE THE PORT SETTINGS
        #
        #  Since we're only transmitting from these ports we only need to
        #  set the port and baud rates. We don't need to worry about parsing
        #  since no data will be received.
        #
        #  When specifying COM ports as integers, you start at 0. Thus 'COM1'
        #  is 0, 'COM5' is 4, etc.
        #
        #  The configuration dictionary is keyed by label. The value is a list
        #  in the form [COM port, Baud, Parse Type, Parse Expression, Parse Index]

        #  Device 1 - Lengthboard
        devices['Lengthboard'] = [16, 9600, 'None', '', '']
        #  Device 2 - Small Scale
        devices['SmallScale'] = [18, 2400, 'None', '', '']
        #  Device 3 - Large Scale
        devices['LargeScale'] = [15, 2400, 'None', '', '']
        #  Device 4 - Bar Code Reader
        devices['BarCode'] = [14, 9600, 'None', '', '']

        #  create an instance of the serial monitor
        self.smonitor = SerialMonitor.SerialMonitor()

        #  add the devices to the serial monitor
        for device in devices.iteritems():
            self.smonitor.addDevice(device[0], device[1][0],device[1][1],device[1][2],device[1][3], device[1][4])

        #  start the serial monifor
        self.smonitor.startMonitoring()

        #  connect the button signals
        self.connect(self.sendBtn1, SIGNAL("clicked()"), self.sendLength)
        self.connect(self.sendBtn2, SIGNAL("clicked()"), self.sendSmScale)
        self.connect(self.sendBtn3, SIGNAL("clicked()"), self.sendLgScale)
        self.connect(self.sendBtn4, SIGNAL("clicked()"), self.sendBarcode)
        self.connect(self.fileBtn1, SIGNAL("clicked()"), self.sendAutoLength)


    def sendLength(self):
        #  send the lengthboard value
        self.smonitor.txData('Lengthboard', self.lengthText.text() + '\r\n')


    def sendAutoLength(self):
        #  this method sends a bunch of lengths that are contained in a text file

        #  get the file to send
        fname = QFileDialog.getOpenFileName(self,"SerialFaker - Choose input file")

        #  set the cursor to the "busy" pointer
        self.setCursor(QCursor(Qt.BusyCursor))

        #  open up the file
        file = open(str(fname))

        #  iterate over contents
        for line in file:
            time.sleep(0.5)
            self.smonitor.txData('Lengthboard', line)

        #  close the file and set the cursor back to the regular pointer
        file.close()
        self.setCursor(QCursor())


    def sendSmScale(self):
        #  send the small scale text

        #  first ensure that we have a decimal in our text
        text = self.smallScaleText.text()
        if (not text.contains('.')):
            text = text + '.0'

        #  We decorate the value so it mimics the output of the small scale
        text = 'P01 FISH             0.000kg    0.000kg    ' + text + 'kg\r\n'
        self.smonitor.txData('SmallScale', text)


    def sendLgScale(self):
        #  send the large scale text

        #  first ensure that we have a decimal in our text
        #  first we convert to a python string so we ca
        text = self.largeScaleText.text()
        if (not text.contains('.')):
            text = text + '.0'

        #  We decorate the value so it mimics the output of the large scale
        text = 'P01                   0.00kg     0.00kg    '+ text + 'kg 10.02.13 01:22\r\n'
        self.smonitor.txData('LargeScale', text)


    def sendBarcode(self):
        #  send the bar code text
        self.smonitor.txData('BarCode', self.barCodeText.text() + '\r\n')


    #def goExit(self):
    #    self.close()


    def closeEvent(self, event):

        self.smonitor.stopMonitoring()




if __name__ == "__main__":

    app = QApplication(sys.argv)
    form = SerialFaker()
    form.show()
    app.exec_()
