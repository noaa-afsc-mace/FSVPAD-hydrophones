import math
import sys
import time
from datetime import datetime 
import os
import os.path

from ConfigParser import SafeConfigParser
from PyQt4.QtCore import*
from PyQt4.QtGui import*
from acquisition.serial import SerialMonitor
from acquisition.serial.SerialMonitor import QSerialPortError
from ui.ui_GPS_RangeBearing import Ui_MainWindow

'''
Global Constants
'''
# timeout (in ms) before attempting to reconnect to Freewave
SPAR_DATA_TIMEOUT = 5000

'''
Global Functions
'''
def GPS_distance(P1, P2):
        '''
        Calculates the great circle distance
        Latitude and Longitude must be decimal degrees
        W longitude and S latitude are negative values
        the distances is provided in km
        '''
        Lat1, Lon1 = P1                 # Points 1 coordinates 
        Lat2, Lon2 = P2                 # Points 2 coordinates 
        radius = 6371                   # earth radius in km

        dlat = math.radians(Lat2 - Lat1)# latitude differential
        dlon = math.radians(Lon2 - Lon1)# longitude differential

        # d is calculated by the haversine formulate for great circle distances on a sphere
        a = math.sin(dlat/2) **2 + math.cos(math.radians(Lat1)) \
            * math.cos(math.radians(Lat2)) * math.sin(dlon/2) ** 2 
        d = 2 * radius * math.atan2(math.sqrt(a), math.sqrt(1-a))
        return d

def GPS_bearing(pointA, pointB):
        '''
        Calculates the bearing between two points.
        The formula used is the following:
        bearing = atan2(sin(long).cos(lat2),
        cos(lat1).sin(lat2) asin(lat1).cos(lat2).cos(long))
        Parameters:
        - pointA: The tuple representing the latitude/longitude for the
        first point. Latitude and longitude must be in decimal degrees
        - pointB: The tuple representing the latitude/longitude for the
        second point. Latitude and longitude must be in decimal degrees
        Returns:
                The bearing in degrees
        Returns Type:
        float
        '''
        if (type(pointA) != tuple) or (type(pointB) != tuple):
                raise TypeError("Only tuples are supported as arguments")

        lat1 = math.radians(pointA[0])
        lat2 = math.radians(pointB[0])

        diffLong = math.radians(pointB[1] - pointA[1])

        x = math.sin(diffLong) * math.cos(lat2)
        y = math.cos(lat1) * math.sin(lat2) - (math.sin(lat1)
                * math.cos(lat2) * math.cos(diffLong))

        initial_bearing = math.atan2(x, y)

        # Now we have the initial bearing but math.atan2 return values
        # from -180deg to + 180deg which is not what we want for a compass bearing
        # The solution is to normalize the initial bearing as shown below
        initial_bearing = math.degrees(initial_bearing)
        compass_bearing = (initial_bearing + 360) % 360

        return compass_bearing

'''
Main Body 
'''

class Drifter(QMainWindow, Ui_MainWindow):

        def __init__(self,parent=None):
            super(Drifter,self).__init__(parent)
            # Set up the GUI
            self.setupUi(self)
            self.rangebox.setText(str(format(9999,'.0f')))
            self.bearingbox.setText(str(format(999,'.0f')))
            self.sogbox.setText(str(format(99.9,'.1f')))
            self.coordsbox.setText('99 99.99 N, 999 99.99 W')
            self.statusbox.setText('Inactive')
            self.running = False
            self.fn = None
            self.fn_drift = None
            self.fn_ship = None

            #  create an instance of the serial monitor
            self.smonitor = SerialMonitor.SerialMonitor()
            #  connect to the serial monitor's "SerialDataReceived" signal
            self.connect(self.smonitor, SIGNAL("SerialDataReceived"), self.dataReceived)
            
            #  set the application icon
            baseDir = reduce(lambda l,r: l + os.path.sep + r,
            os.path.dirname(os.path.realpath(__file__)).split(os.path.sep))
            try:
                self.setWindowIcon(QIcon(baseDir + os.sep +'resources/FSVPAD_icon.png'))
            except:
                pass

            # if start button then begin running code
            self.connect(self.startbutton, SIGNAL("clicked()"), self.GPSsetup)
            # if stop button, then stop updating code
            self.connect(self.stopbutton, SIGNAL("clicked()"), self.endGPScalc)
            self.stopbutton.setEnabled(False)

            # create a timeout time for the spar buoy data stream
            self.sparDataTimer = QTimer(self)
            self.sparDataTimer.timeout.connect(self.sparDataTimeout)
            self.sparDataTimer.setInterval(SPAR_DATA_TIMEOUT)
            self.sparDataTimer.setSingleShot(True)
            

        def GPSsetup(self):
            
            #  read the config file
            parser = SafeConfigParser()
            parser.read(r".\GUI_Configuration.txt")
            try:
                driftercom = parser.get('drifter','com_port')
                drifterbaud = parser.get('drifter','com_baud')
            except Exception, e:
                QMessageBox.critical(self, "Error", "Error parsing [drifter] section of 'GUI_Configuration.txt'. " +
                        str(e))
                return
            try:
                shipcom = parser.get('ship','com_port')
                shipbaud = parser.get('ship','com_baud')
            except Exception, e:
                QMessageBox.critical(self, "Error", "Error parsing [ship] section of 'GUI_Configuration.txt'. " +
                        str(e))
                return
            try:
                logdir = parser.get('logging','directory')
            except Exception, e:
                QMessageBox.critical(self, "Error", "Error parsing data directory section of 'GUI_Configuration.txt'. " +
                        str(e))
                return
            #  normalize the path to clean up any user mumbo jumbo
            logdir = os.path.normpath(logdir)
            
            # where are the files going to go as they are written
            dirname = logdir + os.sep + "GPS_Files_YMD_"
            dirname2 = dirname + datetime.utcnow().strftime("%Y%m%d") + "\Distance"
            dirname = dirname + datetime.utcnow().strftime("%Y%m%d") + "\RawGPS"
            if not os.path.exists(dirname):
                    os.makedirs(dirname)
            if not os.path.exists(dirname2):
                    os.makedirs(dirname2)

            # set up serial connections
            devices = {}
            devices['spar'] = ['COM'+str(driftercom), drifterbaud, 'None', '', '']
            devices['ship'] = ['COM'+str(shipcom), shipbaud, 'None', '', '']
            
            #  add the devices to the serial monitor
            for device in devices.iteritems():
                self.smonitor.addDevice(device[0], device[1][0],device[1][1],device[1][2],device[1][3], device[1][4])

            #  try to open serial ports and start monitoring
            try:
                self.smonitor.startMonitoring()
            except QSerialPortError, e:
                #  there was a problem with the serial port
                QMessageBox.critical(self, "Error", "Error opening COM port. " + e.errText)
                return
            except Exception, e:
                #  other problem
                    raise e
                    
            #  set the "running" flag and enable the stop button
            self.running = True
            self.stopbutton.setEnabled(True)
            
            # set non-loop based windows (GPS status and file directory)
            self.statusbox.setText('Active')
            self.dirbox.setText(dirname)
            
            #  initialize time old
            self.told = 0

            # Loop for writing GPS calculations
            for i in range(9999):# Limits the total number of GPS files to 9999
                dt = datetime.utcnow().strftime("%y%m%d")
                timestart = datetime.utcnow()

                outfile_calc = dirname2 + "\GPS_Cals" + dt + "_" + str(i).zfill(3) + ".txt" #print(outfile_drift)

                if os.path.isfile(outfile_calc) and os.access(outfile_calc, os.R_OK):
                    i += 1
                else:
                    self.fn = open(outfile_calc,'w')
                    break
                    
            for i in range(9999):# Limits the total number of GPS files to 9999
                outfile_drift = dirname + "\DrifterGPS_20" + dt + "_" + str(i).zfill(3) + ".txt" #print(outfile_drift)
                outfile_ship = dirname + "\ShipGPS_20" + dt + "_" + str(i).zfill(3) + ".txt"
                
                if os.path.isfile(outfile_drift) and os.access(outfile_drift, os.R_OK):
                    i += 1
                else:
                    print("Files created")
                    self.fn_drift = open(outfile_drift,'w')
                    self.fn_ship = open(outfile_ship,'w')
                    break


        def dataReceived(self, device, data, err):

            receiveTime = datetime.utcnow()
            
            if (device == 'ship'):
                data_ship = data
                line_ship = data_ship.decode("ascii").split(',')

                if line_ship[0] == '$GPRMC':
                    line_ship2 = (data_ship)
                    self.fn_ship.write(datetime.utcnow().strftime("%y%m%d%H%M%S ")+line_ship2+"\n")
                    self.fn_ship.flush()
                    print("ship data: %s"%data_ship)
                    t2tmp = line_ship[1]
                    self.t2 = float(t2tmp[0:2])*3600 + float(t2tmp[2:4])*60 + float(t2tmp[4:6])
                    latstr2 = line_ship[3]
                    lonstr2 = line_ship[5]
                    self.lat2 = abs(float(latstr2[:2])+(float(latstr2[2:])/60))
                    self.lon2 = abs(float(lonstr2[:3])+(float(lonstr2[3:])/60))

                    if line_ship[4] == 'S':
                            self.lat2 = -1 * self.lat2

                    if line_ship[6] == 'W':
                            self.lon2 = -1 * self.lon2

                    self.LatLon2 = (self.lat2, self.lon2)
                    self.LatLon2str = latstr2[:2] + ' ' + latstr2[2:] + ' ' + line_ship[4] + ' ,' + lonstr2[3:] + ' ' + lonstr2[:3] + ' ' + line_ship[6] 

                    if line_ship[7] == '':
                            self.sog2 = 99.9
                    else:
                            self.sog2 = float(line_ship[7])                     

            elif (device == 'spar'):

                # reset spar buoy timeout timer
                self.sparDataTimer.start()

                line = data.decode("ascii").split(',')

                if line[0] == '$GPRMC':
                    line_drift = data
                    self.fn_drift.write(datetime.utcnow().strftime("%y%m%d%H%M%S ")+line_drift+"\n")
                    self.fn_drift.flush()
                    print("spar data: %s"%data)
                    t1tmp = line[1]
                    self.t1 = float(t1tmp[0:2])*3600 + float(t1tmp[2:4])*60 + float(t1tmp[4:6])
                    latstr = line[3]
                    lonstr = line[5]
                    self.lat1 = abs(float(latstr[:2])+(float(latstr[2:])/60))
                    self.lon1 = abs(float(lonstr[:3])+(float(lonstr[3:])/60))

                    if line[4] == 'S':
                            self.lat1 = -1 * self.lat1

                    if line[6] == 'W':
                            self.lon1 = -1 * self.lon1

                    self.LatLon1 = (self.lat1, self.lon1)
                    self.LatLon1str = latstr[:2] + ' ' + latstr[2:] + ' ' + line[4] + ', ' + lonstr[:3] + ' ' + lonstr[3:] + ' ' + line[6] 
                    if line[7] == '':
                            self.sog1 = 99.9
                    else:
                            self.sog1 = float(line[7])
                    self.GPScalc() 


        def sparDataTimeout(self):
            
            #sparDataTimeout is called when the spar data timeout timer expires.
            #IT is assumed that at this point we have lost contact with the
            #buoy and need to re-initiate contact
            
            # assuming close and opening is what needs to happen
                try:
                        # close the spar COM port
                        self.smonitor.stopMonitoring(devices=['spar'])
                        # open the spar COM port
                        self.smonitor.startMonitoring(devices=['spar'])

                except QSerialPortError, e:
                        # there was a problem with the serial port
                        print('ERROR: Unable to open spar buoy COM Port: ' + e.errText)

                except Exception, e:
                         # other problem
                        raise e

                # resetart spar buoy timeout timer even if there was an except
                # keep doing it until it works
                self.sparDataTimer.start()

                   
        def GPScalc(self):                        
            self.difftime = abs(self.t2-self.t1)
            self.dis = GPS_distance(self.LatLon1,self.LatLon2)*1000
            self.bearing = GPS_bearing(self.LatLon2,self.LatLon1)
            self.GPSwrite()
            if self.t1 -1 > self.told:
                    self.GPSwriteGUI()
                    self.told = self.t1

                
        def GPSwriteGUI(self):
            disstr = "%.0f" % self.dis
            bearingstr = "%.0f" % self.bearing
            sogstr = "%.1f" % self.sog1

            self.rangebox.setText(disstr)
            self.bearingbox.setText(bearingstr)
            
            if self.difftime < 15:
                    self.sogbox.setText(sogstr)
            else:
                    self.sogbox.setText('Asynchronous - ' + sogstr)

            self.coordsbox.setText(self.LatLon1str)
            #print("GUI Updated %f"%self.t1)
            app.processEvents()


        def GPSwrite(self):
            dataout = "%.1f,%0.1f,%.0f,%s"  % (self.dis, self.bearing,self.difftime,self.LatLon1str)
            self.fn.write(datetime.utcnow().strftime("%y%m%d%H%M%S,")+dataout+"\n")
            self.fn.flush()                


        def endGPScalc(self): 
            if (self.running):
                self.smonitor.stopMonitoring()
                self.statusbox.setText('INACTIVE')
                self.fn.close()
                self.fn_drift.close()
                self.fn_ship.close()
                self.running = False
                self.stopbutton.setEnabled(False)


        def closeEvent(self, event):
            self.smonitor.stopMonitoring()
            if (self.fn):
                self.fn.close()
            if (self.fn_drift):
                self.fn_drift.close()
            if (self.fn_ship):
                self.fn_ship.close()


if __name__ == "__main__":
        app = QApplication(sys.argv)
        form = Drifter()
        form.show()
        sys.exit(app.exec_())
