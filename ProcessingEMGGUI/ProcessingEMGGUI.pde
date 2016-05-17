/**********************************************************************************************************************************
 * ProcessingEMGGUI
 * Author: Nathan Lim
 *
 * Receives raw and enveloped data from EMG and graphs them both
 *********************************************************************************************************************************/

import processing.serial.*;
import static javax.swing.JOptionPane.*;


float bar;
float line;
BarGraph bg;
LineGraph lg;
Serial myPort;

void setup(){
  size(1000,500); 
  
  //initialize the graphs
  bg = new BarGraph(600,height-40, 200, 300,350,TriggerType.RISING_EDGE);
  lg = new LineGraph(20,height-20,500,400,200,-90,90);
  
  //open the serial port
  println(myPort.list());
  myPort = new Serial(this, myPort.list()[2], 9600); 
  myPort.bufferUntil('\n'); 
  
}

void draw(){
  background(0);
  bg.draw();
  

  if(mousePressed){
    if(bg.insideGraph(mouseX,mouseY))
      bg.setThreshold(mouseY);
  }
  
  lg.draw();
}

//void keyPressed() {
//  if(key == 'w')
//    x = bg.getVal() + 10;
//  if(key == 's')
//    x = bg.getVal()-10;
//}

void serialEvent (Serial myPort) {
  String inString = myPort.readStringUntil('\n');
  if(inString.substring(0,4).equals("RAW:")){
   String[] split = split(inString, ' ');
   //println(split.length);
   if(split.length == 2){
     if(split[0].substring(0,4).equals("RAW:"))
       line = float(split[0].substring(4));
     if(split[1].substring(0,4).equals("ENV:"))
       bar = float(split[1].substring(4));
   }
  }else if(inString.substring(0,6).equals("THRSH:")){
   int tt = int(inString.substring(6,7));
   float tmpThrsh = float(inString.substring(7));
   if(abs(tmpThrsh - bg.getThreshold()) < 0.001){
     println("THRESHOLD SET CORRECTLY TO " + tmpThrsh);
   }
  }

  
  lg.update(line);
  bg.update(bar);
  //Deal with triggers
  if(bg.foundTrigger())
    println("TRIGGERED");
}

void mouseReleased(){
  if(bg.insideGraph(mouseX,mouseY)){
    myPort.write("THRSH:" + str(bg.getTT()) + ":" + str(bg.getThreshold()));
    println("THRSH:" + str(bg.getTT()) + ":" + str(bg.getThreshold()));
  }
}