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
  bg = new BarGraph(600,height-40, 200, 600,350,TriggerType.RISING_EDGE);
  lg = new LineGraph(20,height-20,500,400,200,-90,600);
  
    //Choose the PORT
  String COMlist="",COMx = "";
  try {
    int i = Serial.list().length;
    if (i != 0) {
      if (i >= 2) {
        for (int j = 0; j < i;) {
          COMlist += char(j+'a') + " = " + Serial.list()[j];
          if (++j < i) COMlist += ",  ";
        }
        COMx = showInputDialog("Which COM port is correct? (a,b,..):\n"+COMlist);
        if (COMx == null) exit();
        if (COMx.isEmpty()) exit();
        i = int(COMx.toLowerCase().charAt(0) - 'a') + 1;
      }
      String portName = Serial.list()[i-1];
      myPort = new Serial(this, portName, 9600); 
      myPort.bufferUntil('\n'); 
    }
    else {
      showMessageDialog(frame,"Device is not connected to the PC");
      exit();
    }
  }
  catch (Exception e)
  { //Print the type of error
    showMessageDialog(frame,"COM port is not available (may\nbe in use by another program)");
    println("Error:", e);
    exit();
  }
  
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
   float tmpThrsh = float(inString.substring(8));
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