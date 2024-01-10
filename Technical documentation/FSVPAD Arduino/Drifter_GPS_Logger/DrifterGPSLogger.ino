// Ladyada's logger modified by Chris Bassett
// for logging spar buoy GPS data

#include <SD.h>
#include "GPSconfig.h"
#include <SoftwareSerial.h>


// power saving modes
#define TURNOFFGPS 0    /* set to 1 to enable powerdown of arduino and GPS. Ignored if SLEEPDELAY == 0 */
#define LOG_RMC_FIXONLY 0  /* set to 1 to only log to SD when GPD has a fix */

// what to log
#define LOG_RMC 1 // RMC-Recommended Minimum Specific GNSS Data, message 103,04
//#define LOG_GGA 0 // GGA-Global Positioning System Fixed Data, message 103,00
//#define LOG_GLL 0 // GLL-Geographic Position-Latitude/Longitude, message 103,01
//#define LOG_GSA 0 // GSA-GNSS DOP and Active Satellites, message 103,02
//#define LOG_GSV 0 // GSV-GNSS Satellites in View, message 103,03
//#define LOG_VTG 0 // VTG-Course Over Ground and Ground Speed, message 103,05

// Use pins 2 and 3 to talk to the GPS. 2 is the TX pin, 3 is the RX pin
 SoftwareSerial gpsSerial =  SoftwareSerial(2, 3);
// Set the GPSRATE to the baud rate of the GPS module. Most are 4800
// but some are 38400 or other. Check the datasheet!
#define GPSRATE 4800

// Set the pins used 
//#define powerPin 4
#define ledPin1 6
#define ledPin2 5
#define chipSelect 10


#define BUFFSIZE 90
char buffer[BUFFSIZE];
uint8_t bufferidx = 0;
bool fix = false; // current fix data
bool gotGPRMC;    //true if current data is a GPRMC strinng
uint8_t i;
int pinState2 = HIGH;

//SdFat SD;

File logfile;

// read a Hex value and return the decimal equivalent
uint8_t parseHex(char c) {
  if (c < '0')
    return 0;
  if (c <= '9')
    return c - '0';
  if (c < 'A')
    return 0;
  if (c <= 'F')
    return (c - 'A')+10;
}

// blink out an error code


void setup() {
  WDTCSR |= (1 << WDCE) | (1 << WDE);
  WDTCSR = 0;
  //Serial.begin(9600);
  //Serial.println("\r\nGPSlogger");
  pinMode(ledPin1, OUTPUT);
  pinMode(ledPin2, OUTPUT);

  // make sure that the default chip select pin is set to
  // output, even if you don't use it:
  pinMode(chipSelect, OUTPUT);
  strcpy(buffer, "DGPS000.TXT");

  //pinMode(powerPin, OUTPUT);
  //digitalWrite(powerPin, LOW);

  
  // see if the card is present and can be initialized:
  if (!SD.begin(chipSelect)) {
      //Serial.println("Card init. failed!");
        for (i=0; i<120; i++) {
         digitalWrite(ledPin1, HIGH);
         digitalWrite(ledPin2, LOW);
         delay(250);
         digitalWrite(ledPin1, LOW);
         digitalWrite(ledPin2, LOW);
         delay(250);  
      };
  }

    for (i = 0; i < 1000; i++) {
      buffer[4] = '0' + i/100;
      buffer[5] = '0' + i/10;
      buffer[6] = '0' + i%10;      
        // create if does not exist, do not open existing, write, sync after write
      if (! SD.exists(buffer)) {
        break;
    }
    }

  logfile = SD.open(buffer, FILE_WRITE);
  if( ! logfile ) {
    //Serial.print("Couldnt create "); Serial.println(buffer);
          for (uint8_t i = 0; i < 15; i++) {
          // Red slow blinking
          digitalWrite(ledPin1, HIGH);
          digitalWrite(ledPin2, LOW);
          delay(3000);
          digitalWrite(ledPin1, LOW);
          digitalWrite(ledPin2, LOW);
          delay(1000);  
       };
  }
  //Serial.print("Writing to "); Serial.println(buffer);
  
  // connect to the GPS at the desired rate
  gpsSerial.begin(GPSRATE);
  
  //Serial.println("Ready!");
  
  gpsSerial.print(SERIAL_SET);

#if (LOG_RMC == 1)
    gpsSerial.print(RMC_ON);
#else
    gpsSerial.print(RMC_OFF);
#endif

}

void loop() {
  //Serial.println(Serial.available(), DEC);
  char c;
  uint8_t sum;

  // read one 'line'
  if (gpsSerial.available()) {
    c = gpsSerial.read();

    if (bufferidx == 0) {
      while (c != '$')
        c = gpsSerial.read(); // wait till we get a $
    }
    buffer[bufferidx] = c;


    //Serial.print(c, BYTE);

    if (c == '\n') {
      //putstring_nl("EOL");
      //Serial.print(buffer);
      buffer[bufferidx+1] = 0; // terminate it

      if (buffer[bufferidx-4] != '*') {
        // no checksum?
        //Serial.print('*');
        bufferidx = 0;
        return;
      }
      // get checksum
      sum = parseHex(buffer[bufferidx-3]) * 16;
      sum += parseHex(buffer[bufferidx-2]);

      // check checksum
      for (i=1; i < (bufferidx-4); i++) {
        sum ^= buffer[i];
      }
      if (sum != 0) {
        //putstring_nl("Cxsum mismatch");
        //Serial.print('~');
        bufferidx = 0;
        return;
      }
      // got good data!

      gotGPRMC = strstr(buffer, "GPRMC");
//      if (gotGPRMC) {
//        // find out if we got a fix
//        char *p = buffer;
//        p = strchr(p, ',')+1;
//        p = strchr(p, ',')+1;       // skip to 3rd item
//        
//        if (p[0] == 'V') {
//          digitalWrite(ledPin2, LOW);
//          fix = false;
//        } else {
//          digitalWrite(ledPin2, HIGH);
//          fix = true;
//        }
//      }
//      if (LOG_RMC_FIXONLY) {
//        if (!fix) {
//          //Serial.print('_');
//          bufferidx = 0;
//          return;
//        }
//      }
      // rad. lets log it!
      
      
      if (gotGPRMC)      //If we have a GPRMC string
      {
        // Bill Greiman - need to write bufferidx + 1 bytes to getCR/LF
        bufferidx++;
      //Serial.print(buffer);    //first, write it to the serial monitor

      if (pinState2 == LOW){
          pinState2 = HIGH;
      }
      else{  
            pinState2 = LOW;
      }
       digitalWrite(ledPin2, pinState2);


        logfile.write((uint8_t *) buffer, bufferidx);    //write the string to the SD file
        logfile.flush();
        /*
        if( != bufferidx) {
           putstring_nl("can't write!");
           error(4);
        }
        */


        bufferidx = 0;    //reset buffer pointer

        
        return;
      }
      
    }
    bufferidx++;
    if (bufferidx == BUFFSIZE-1) {
       //Serial.print('!');
       bufferidx = 0;
    }
  } 

}



/* End code */
