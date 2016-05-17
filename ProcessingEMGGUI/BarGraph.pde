
/*
 * This class creates a bar graph of a given size which can trigger upon certain events (Rising/Falling edge, etc.)
 */
class BarGraph{
  int x,y; //base x and y coordinates of the graph
  int barWidth;
  int size; //size of bar graph
  //Expecting a value between 0 and valMax;
  int val,valMax; //current value and the max value
  int threshold; //the value at which the trigger event takes place
  TriggerType tt; 
  boolean triggered; //bool to check if a trigger has happened
  
  /*
   * 
   */
  BarGraph(int x, int y, int thresh,int valMax, int gsize,TriggerType tt){
    this.x = x;
    this.y = y;
    this.valMax = valMax;
    if(gsize < 200)
      gsize = 200;
    size = gsize;
    barWidth = size/3;
    threshold = thresh;
    this.tt = tt;
  }
  
  //Default size is 200, default trigger type is rising edge, 
  BarGraph(int x, int y, int thresh, int valMax){
    this.x = x;
    this.y = y;
    this.valMax = valMax;
    size = 200;
    barWidth = size/3;
    threshold = thresh;
    this.tt = TriggerType.RISING_EDGE;
  }
  
  void update(int v){
    
    //determine the state of the trigger
    if(tt == TriggerType.RISING_EDGE){
      if(val < threshold && v >= threshold)
        triggered = true;
    }else if(tt == TriggerType.FALLING_EDGE){
      if(val > threshold && v <= threshold)
        triggered = true;
    }else if(tt == TriggerType.ABOVE_THRESH){
      if(v > threshold)
        triggered = true;
    }else if(tt == TriggerType.BELOW_THRESH){
      if(v < threshold)
        triggered = true;
    }
    
    //update the current val
    val = v;
    if(val>valMax) val = valMax;
    else if(val<0) val =0;
  }
  
  void draw(){
    stroke(0xff);
    //draw the bar graph axes
    line(x+30,y,x+30,y-size-5);
    line(x+25,y,x+size,y);
    
    //draw y axis ticks
    text(valMax,x+2,y-size+4);
    line(x+25,y-size,x+35,y-size);
    text(valMax*3/4,x+2,y-size*3/4+4);
    line(x+25,y-size*3/4,x+35,y-size*3/4);
    text(valMax/2,x+2,y-size/2+4);
    line(x+25,y-size/2,x+35,y-size/2);
    text(valMax*1/4,x+2,y-size*1/4+4);
    line(x+25,y-size*1/4,x+35,y-size*1/4);
    
    //draw the threshold line
    int normThresh = int(map(threshold,0,valMax,0,size));
    line(x+25,y-normThresh,x+size,y-normThresh);
    text(threshold,x+size-10,y-normThresh-10);
    
    //draw the bar
    int normVal = int(map(val,0,valMax,0,size));
    rect(x+size/3,y,barWidth,-normVal);
    text(val,x+size/3+20,y-normVal-10);
  }
  
  int getVal(){
    return val;
  }
  
  boolean insideGraph(int x1,int y1){
    return (x1>x && x1 < x+size && y1<y && y1 > y-size);
  }
  
  //newT should be the y value of the desired point of threshold on the GUI (absolute y value, not relative)
  void setThreshold(int newT){
     threshold = int(map(y-newT,0,size,0,valMax));
  }
  
  boolean foundTrigger(){
    boolean t = triggered;
    triggered = false;
    return t;
  }
  
}