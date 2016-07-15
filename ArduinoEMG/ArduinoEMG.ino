/*
 * Arduino code for communicating with the LSM9DS1 9DOF sensor.
 * It continuously outputs the roll, pitch, and yaw. These euler angles are calculated from gyroscope + accel + magn, and a complemantary filter is used.
 * 
 * Author: Nathan Lim
 */

#include <Wire.h>
#include <Mouse.h>
#include "types.h"

int printSpeed = 5;


boolean sendFlag;
float threshold;

TriggerType tt;
int oldEnv;
int env;


void setup() {

  Mouse.begin();
  tt = TriggerType::RISING_EDGE;
  oldEnv = 0;
  env = 0;
  
  sendFlag = true;
  pinMode(A0, INPUT);   
  pinMode(A1, INPUT);   
  Serial.begin(9600);

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
//      Serial.println("THRSH:" + String(ttToInt(tt)) + ":" + String(threshold));
    }
    else if (s.substring(0,4).equals("PSD:")){
      printSpeed = s.substring(4).toInt();
    }
    else if(s.equals("1")){
      sendFlag = true;
    }else if(s.equals("0")){
      sendFlag = false;
    }
  }
  oldEnv = env;
  env = analogRead(A1);
  

  if(sendFlag){
    Serial.print(String(analogRead(A0)));
    Serial.print(" ");
    Serial.println(String(env));
  }

  if(tt == TriggerType::RISING_EDGE)
    if(oldEnv < threshold && env > threshold)
      Mouse.click();
//  else if(tt == TriggerType::FALLING_EDGE)
//    if(oldYaw*180/PI > threshold && gyaw*180/PI < threshold)
//      Mouse.click();
    
  delay(printSpeed);
}

