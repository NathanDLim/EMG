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
float[] floatArray;
BarGraph bg;
LineGraph lg;
Serial myPort;
String s;

void setup(){
  size(1000,500); 
  
  s = "";
  
  //initialize the graphs
  bg = new BarGraph(600,height-40, 200, 1000,350,TriggerType.RISING_EDGE);
  lg = new LineGraph(20,height-20,500,400,400,-90,600);
  
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
  
  
  //frameRate(10);
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

void serialEvent (Serial myPort) {
 String inString = myPort.readStringUntil('\n');
 if (inString != null) {
   // Removes whitespace before and after string
   inString = trim(inString);
   // Parses the data on spaces, converts to floats, and puts each number into the array
   floatArray = float(split(inString, " "));
   // Make sure the array is at least 2 strings long.   
   if (floatArray.length >= 2) {
     // Assign the two numbers to variables so they can be drawn
     line = floatArray[0];
     bar = floatArray[1];
     println(bar);
     // You could do the drawing down here in the serialEvent, but it would be choppy
   }
 } 
 
 bg.update(bar);
 lg.update(line);
}

void mouseReleased(){
  if(bg.insideGraph(mouseX,mouseY)){
   myPort.write("THRSH:" + str(bg.getTT()) + ":" + str(bg.getThreshold()));
   println("THRSH:" + str(bg.getTT()) + ":" + str(bg.getThreshold()));
  }
}