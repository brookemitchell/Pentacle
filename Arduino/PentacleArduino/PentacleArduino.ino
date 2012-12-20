//Brooke Mitchell 300214807 NZSM 2011
//Pentacle Interface ARDUINO code.
// Thanks to F.Varesio ( DRIVERS!!! VVV FreeIMU code and ADXL345 Freefall detection messages)

#include <ADXL345.h>
#include <HMC58X3.h>
#include <ITG3200.h>

#include "binary_const.h" // with this we can use something B8(01010101) that it will convert to 85 at compile time
// the above cames handy and readable when doing per bit configuration in the ADXL345 registers
#include <SPI.h>
#include "hsv2rgb.h"

const int ShiftPWM_latchPin=9;
const bool ShiftPWM_invertOutputs = 0; // if invertOutputs is 1, outputs will be active low. Usefull for common anode RGB led's.

#include <ShiftPWM.h>   // include ShiftPWM.h after setting the pins!

#include "CommunicationUtils.h"
// FreeIMU.h brings it all together for software IMU'ing.
#include "FreeIMU.h"
#include <Wire.h>

//ADXL345
#define DEVICE (0x53)    //ADXL345 device address (with SDO tied to ground)
#define TO_READ (6)      //num of bytes we are going to read each time (two bytes for each axis)
#define INTERRUPTPIN 2   // Arduino pin which is connected to INT1 from the ADXL345 (SLEEP/FREEFALL/etc)

//SHIFTPWM
unsigned char maxBrightness = 255;
unsigned char pwmFrequency = 75;
int numRegisters = 5;
int numRGBleds = 12;



//ADXL345 stuff
// Register map: see ADXL345 datasheet page 14
const int R_DEVID = 0;
const int R_OFSX = 30;
const int R_OFSY = 31;
const int R_OFSZ = 32;
const int R_THRESH_FF = 40;
const int R_TIME_FF = 41;
const int R_ACT_TAP_STATUS = 43;
const int R_BW_RATE = 44;
const int R_INT_ENABLE = 46;
const int R_INT_MAP = 47;
const int R_INT_SOURCE = 48;
const int R_DATA_FORMAT = 49;
const int R_DATAX0 = 50;
const int R_DATAX1 = 51;
const int R_DATAY0 = 52;
const int R_DATAY1 = 53;
const int R_DATAZ0 = 54;
const int R_DATAZ1 = 55;
const int R_FIFO_CTL = 56;
const int R_FIFO_STATUS = 57;

const int regAddress = 0x32;    //first axis-acceleration-data register on the ADXL345

byte buff[TO_READ];    //6 bytes buffer for saving data read from the device
char str[512];         //string buffer to transform data before sending it to the serial port
boolean inspected = 0;

//Quanterion VALS
float q[4];

//PieZO Matrix 
int piezoMatrix[12];

//LED Blink delay stuff
//long previousMillis = 0;        // will store last time LED was updated
// the follow variables is a long because the time, measured in miliseconds,
// will quickly become a bigger number than can be stored in an int.
long flashDelay = 100;           // interval at which to blink (milliseconds)
long waitUntil = 0; 

// long piezoPressTime[12];

//PIEZO ARRAY STUFF
//Mux control pins
int s0 = 7;
int s1 = 6;
int s2 = 5;
int s3 = 4;

int controlPin[] = {
  s0, s1, s2, s3};


//RGB Matrix
int muxChannel[12][4]={
  {
    0,0,0,0                                          }
  , //channel 0
  {
    1,0,0,0                                          }
  , //channel 1
  {
    0,1,0,0                                          }
  , //channel 2
  {
    1,1,0,0                                          }
  , //channel 3
  {
    0,0,1,0                                          }
  , //channel 4
  {
    1,0,1,0                                          }
  , //channel 5 
  {
    0,1,1,0                                          }
  , //channel 6 
  {
    0,0,1,1                                          }
  , //channel 7 swapped with 4067 pin 12 due to problems  
  {
    0,0,0,1                                          }
  , //channel 8 
  {
    1,0,0,1                                          }
  , //channel 9
  {
    0,1,0,1                                          }
  , //channel 10 
  {
    1,1,0,1                                          }
  , //channel 11
};


//Mux in "SIG" pin
int SIG_pin = 0;
int statePin = LOW;
byte val = 0;
int THRESHOLD = 70;
//DONE

unsigned long currentMillis = millis();


//Assign Multiplexed LED pin numbers to correct faces for easy addressing.
int faces[12] = {
  0, 3, 6, 9, 12, 16, 19, 22, 25, 28, 32, 35};


// Set the FreeIMU object
FreeIMU my3IMU = FreeIMU();

void setup() {
  Serial.begin(57600);
  Wire.begin();

  delay(5);
  my3IMU.init();
  delay(5);

  //MORE PIEZO ARRAY STUFF
  pinMode(s0, OUTPUT);
  pinMode(s1, OUTPUT);
  pinMode(s2, OUTPUT);
  pinMode(s3, OUTPUT); 

  digitalWrite(s0, LOW);
  digitalWrite(s1, LOW);
  digitalWrite(s2, LOW);
  digitalWrite(s3, LOW);

  pinMode(INTERRUPTPIN, INPUT); 


  // interrupts setup
  writeTo(DEVICE, R_INT_MAP, 0); // send all interrupts to ADXL345's INT1 pin
  writeTo(DEVICE, R_INT_ENABLE, B8(1111100)); // enable signle and double tap, activity, inactivity and free fall detection

  // free fall configuration
  writeTo(DEVICE, R_TIME_FF, 0x14); // set free fall time
  writeTo(DEVICE, R_THRESH_FF, 0x05); // set free fall threshold



  //SHIFTPWM Setup STuff
  pinMode(ShiftPWM_latchPin, OUTPUT);
  SPI.setBitOrder(LSBFIRST); // The least significant bit shoult be sent out by the SPI port first.
  // Here you can set the clock speed of the SPI port. Default is DIV4, which is 4MHz with a 16Mhz system clock.
  // If you encounter problems due to long wires or capacitive loads, try lowering the SPI clock.
  SPI.setClockDivider(SPI_CLOCK_DIV4); 
  SPI.begin(); 

  ShiftPWM.SetAmountOfRegisters(numRegisters);  
  ShiftPWM.Start(pwmFrequency,maxBrightness);  

  ShiftPWM.SetAll(0);

  // Fade in all outputs
  for(int j=0;j<maxBrightness;j++){
    ShiftPWM.SetAll(j);  
    delay(5);
  }
  // Fade out all outputs
  for(int j=maxBrightness;j>=0;j--){
    ShiftPWM.SetAll(j);  
    delay(5);
  }
}



void loop() { 
  //  unsigned long currentMillis = millis();

  ShiftPWM.SetAll(0);


  // READ FREEIMU DATA
  my3IMU.getQ(q);
  serialPrintFloatArr(q, 4);
  Serial.println("");
  //delay(5);

  // use a digitalRead instead of attachInterrupt so we can use delay()
  if(digitalRead(INTERRUPTPIN)) {
    int interruptSource = readByte(DEVICE, R_INT_SOURCE);

    if(interruptSource & B8(100)) {
      Serial.println("### FREE_FALL");

    }
  }
  readFrom(DEVICE, regAddress, TO_READ, buff); //read the acceleration data from the ADXL345


  //Loop through and read all 12 PIEZO values
  for(int j = 0; j < 12; j++){
    
    readMux(j);

  }


}






//---------------- Functions-------------------//


void readMux(int channel){

  //loop through the 4 Piezo signal channels
  for(int i = 0; i < 4; i++){
    digitalWrite(controlPin[i], muxChannel[channel][i]);
  }

  //read the value at the piezoSIG pin
  int piezoVal = analogRead(SIG_pin);


  //each iteration sets back to base
  if   (piezoVal >= THRESHOLD) {
    Serial.print(channel);
    Serial.print(",");

    piezoMatrix[channel] = piezoVal;

    Serial.print(piezoMatrix[channel]);
    Serial.println(", ");

    //   ledFlash(faces[channel], flashDelay, val);

  }
}



//Writes val to address register on device
void writeTo(int device, byte address, byte val) {
  Wire.beginTransmission(device); //start transmission to device 
  Wire.write(address);        // send register address
  Wire.write(val);        // send value to write
  Wire.endTransmission(); //end transmission
}


//reads num bytes starting from address register on device in to buff array
void readFrom(int device, byte address, int num, byte buff[]) {
  Wire.beginTransmission(device); //start transmission to device 
  Wire.write(address);        //sends address to read from
  Wire.endTransmission(); //end transmission

    Wire.beginTransmission(device); //start transmission to device
  Wire.requestFrom(device, num);    // request 6 bytes from device

  int i = 0;

  while(Wire.available())    //device may send less than requested (abnormal)
  { 
    buff[i] = Wire.read(); // receive a byte
    i++;
  }
  Wire.endTransmission(); //end transmission
}

// read a single bite and returns the readed value
byte readByte(int device, byte address) {
  Wire.beginTransmission(device); //start transmission to device 
  Wire.write(address);        //sends address to read from
  Wire.endTransmission(); //end transmission

    Wire.beginTransmission(device); //start transmission to device
  Wire.requestFrom(device, 1);    // request 1 byte from device

  int readed = 0;
  if(Wire.available())
  { 
    readed = Wire.read(); // receive a byte
  }
  Wire.endTransmission(); //end transmission
  return readed;
}








