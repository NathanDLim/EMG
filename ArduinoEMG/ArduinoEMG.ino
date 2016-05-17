/*
 * Arduino code for communicating with the LSM9DS1 9DOF sensor.
 * It continuously outputs the roll, pitch, and yaw. These euler angles are calculated from gyroscope + accel + magn, and a complemantary filter is used.
 * 
 * Author: Nathan Lim
 */

#include <SparkFunLSM9DS1.h>
#include <Wire.h>
#include <Mouse.h>
#include "types.h"

#define MAG_ADDR 0x1E
#define AG_ADDR 0x6B
#define PRINT_SPEED 10

LSM9DS1 imu;

float gpitch,groll,gyaw;
float goffX,goffY,goffZ;
float tx,ty,tz;

float threshold;

TriggerType tt;

/*
 * gyroscope data is very unstable, we find the average of a number of samples to smooth the data
 */
void averageGyro(float *gxT, float *gyT, float *gzT, int num){
  double a=0,b=0,c=0;
  for(int i=0; i<num;i++){
    imu.readGyro();
    a += imu.calcGyro(imu.gx);
    b += imu.calcGyro(imu.gy);
    c += imu.calcGyro(imu.gz);
  }

    *gxT = a/num;
    *gyT = b/num;
    *gzT = c/num;

}

void setup() {

  Mouse.begin();
  tt = TriggerType::RISING_EDGE;
  
  Serial.begin(9600);
  
  imu.settings.device.commInterface = IMU_MODE_I2C;
  imu.settings.device.mAddress = MAG_ADDR;
  imu.settings.device.agAddress = AG_ADDR;

  if(!imu.begin()){
    Serial.println("Could not connect");
  }

  gpitch = 0;
  gyaw = 0;
  groll = 0;
  threshold = 1000;
  //the gyroscope offsets must be first taken into account. 1000 is a lot, but the z axis for the gyropscope may drift if this number goes down.
  //if the heading is accurate, this number can go lower
  averageGyro(&goffX,&goffY,&goffZ,1000);

}




void loop() {

  if(Serial.available() > 0){
    String s = Serial.readString();
    if(s.substring(0,6).equals("THRSH:")){
      switch(s.substring(6,7).toInt())
      {
        case 1: tt = TriggerType::FALLING_EDGE; break;
        case 2: tt = TriggerType::ABOVE_THRESH; break;
        case 3: tt = TriggerType::BELOW_THRESH; break;
        default: tt = TriggerType::RISING_EDGE; break;
      };
      threshold = s.substring(8).toFloat();
      Serial.println("THRSH:" + String(ttToInt(tt)) + ":" + String(threshold));
    }
  }

  imu.readAccel();
  imu.readMag();
  
  averageGyro(&tx,&ty,&tz,10);

  float m[3];
  m[0] = imu.calcMag(imu.mx);
  m[1] = imu.calcMag(imu.my);
  m[2] = imu.calcMag(imu.mz);

  float oldYaw = gyaw;


  //integrate gyropscope data to find approx angle. This will have errors over time.
  groll += abs(tx-goffX)<0.05? 0:(tx-goffX)/2000;
  gpitch += abs(ty-goffY)<0.05? 0:(ty-goffY)/2000;
  gyaw += abs(tz-goffZ)<0.025? 0:(tz-goffZ)/2000;
  


  Serial.print("RAW:" + String(gpitch*180/PI));
  Serial.print(" ");
  Serial.println("ENV:" + String(gyaw*180/PI));

  if(tt == TriggerType::RISING_EDGE)
    if(oldYaw*180/PI < threshold && gyaw*180/PI > threshold)
      Mouse.click();
  else if(tt == TriggerType::FALLING_EDGE)
    if(oldYaw*180/PI > threshold && gyaw*180/PI < threshold)
      Mouse.click();
    
//Mouse.move(0,gyaw*180/PI);
  delay(PRINT_SPEED);
}

