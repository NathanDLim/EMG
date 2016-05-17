/*
 * Arduino code for communicating with the LSM9DS1 9DOF sensor.
 * It continuously outputs the roll, pitch, and yaw. These euler angles are calculated from gyroscope + accel + magn, and a complemantary filter is used.
 * 
 * Author: Nathan Lim
 */

#include <SparkFunLSM9DS1.h>
#include <Wire.h>
#include <Mouse.h>

#define MAG_ADDR 0x1E
#define AG_ADDR 0x6B
#define PRINT_SPEED 10

#define DECLINATION -13.58 // Declination (degrees) in Ottawa, ON.


LSM9DS1 imu;

float gpitch,groll,gyaw;
float goffX,goffY,goffZ;
float tx,ty,tz;
int16_t mxmin,mxmax,mymin,mymax;
bool calib;

float threshold;

enum TriggerType{
  RISING_EDGE,
  FALLING_EDGE,
  ABOVE_THRESH,
  BELOW_THRESH
};

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
  mxmin = 20000;
  mymin = 20000;
  mxmax = -1;
  mymax = -1;
  calib = false;
  threshold = 1000;
  //the gyroscope offsets must be first taken into account. 1000 is a lot, but the z axis for the gyropscope may drift if this number goes down.
  //if the heading is accurate, this number can go lower
  averageGyro(&goffX,&goffY,&goffZ,1000);

}

String ttToString(TriggerType t){
  if(t == TriggerType::RISING_EDGE)
    return "RISING";
  if(t == TriggerType::FALLING_EDGE)
    return "FALLING";
  if(t == TriggerType::ABOVE_THRESH)
    return "ABOVE";
  if(t == TriggerType::BELOW_THRESH)
    return "BELOW";
  return "";
}

int ttToInt(TriggerType t){
  if(t == TriggerType::RISING_EDGE)
    return 0;
  if(t == TriggerType::FALLING_EDGE)
    return 1;
  if(t == TriggerType::ABOVE_THRESH)
    return 2;
  if(t == TriggerType::BELOW_THRESH)
    return 3;
  return -1;
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
  
  averageGyro(&tx,&ty,&tz,10);

  float m[3];
  fixMagOffsets();
  m[0] = (imu.calcMag(imu.mx)-imu.calcMag((mxmax+mxmin)/2));
  m[1] = (imu.calcMag(imu.my)-imu.calcMag((mymax+mymin)/2));
  m[2] = imu.calcMag(imu.mz);


  float oldYaw = gyaw;


  //integrate gyropscope data to find approx angle. This will have errors over time.
  groll += abs(tx-goffX)<0.05? 0:(tx-goffX)/2000;
  gpitch += abs(ty-goffY)<0.05? 0:(ty-goffY)/2000;
  gyaw += abs(tz-goffZ)<0.025? 0:(tz-goffZ)/2000;
  if(gyaw > PI)
    gyaw -= 2*PI;
  else if (gyaw < -PI)
    gyaw += 2*PI;


  float apitch = atan2(-imu.calcAccel(imu.ax), sqrt(imu.calcAccel(imu.ay) * imu.calcAccel(imu.ay) + imu.calcAccel(imu.az) * imu.calcAccel(imu.az)));
  float aroll = atan2(imu.calcAccel(imu.ay), imu.calcAccel(imu.az));
   /*
   * xh and yh formulas taken from https://www.sparkfun.com/datasheets/Sensors/Magneto/Tilt%20Compensated%20Compass.pdf
   * The Z axis on the magnometer is opposite of that found in the above link.
   */
  float xh = m[0]*cos(gpitch) +m[2]*sin(gpitch);
  float yh = m[0]*sin(groll)*sin(gpitch)+m[1]*cos(groll) + m[2]*sin(groll)*cos(gpitch);
  float myaw =  atan2(yh,xh);

  //Complementary filter. Combined the gyropscope data with the accelerometer data
  gpitch = gpitch*0.98 - 0.02*apitch;
  groll = groll*0.98 - 0.02*aroll;
  gyaw = gyaw*0.98 - 0.02*myaw;

  Serial.print("RAW:" + String(gpitch*180/PI));
  Serial.print(" ");
  Serial.println("ENV:" + String(myaw*180/PI));

  if(tt == TriggerType::RISING_EDGE)
    if(oldYaw*180/PI < threshold && myaw*180/PI > threshold){
      Mouse.click();
    }

  delay(PRINT_SPEED);
}


/*
 * This function reads the magnetometer and finds the highest and lowest values of the x and y axis. It is used to offset the magnetometers.
 * In order to have valid highs and lows, the IMU must be rotated slowly in a full circle.
 */
void fixMagOffsets(){
  imu.readMag();

  int16_t tempmx = imu.mx;
  int16_t tempmy = imu.my;
  int16_t tempmz = imu.mz;

  //some sort of error
  if(abs(tempmx) > 100000 || abs(tempmy) > 10000)
    return;
  
  if(tempmx > mxmax)
    mxmax = tempmx;
  else if(tempmx < mxmin)
    mxmin = tempmx;

  if(tempmy > mymax)
    mymax = tempmy;
  else if(tempmy < mymin)
    mymin = tempmy;
}


