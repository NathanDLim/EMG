int x;
BarGraph bg;
LineGraph lg;
void setup(){
  size(1000,500); 
  bg = new BarGraph(600,height-40, 200, 300,350,TriggerType.RISING_EDGE);
  
  
  lg = new LineGraph(20,height-20,500,400,20,0,300);
  
  x=100;
}

void draw(){
  background(0);
  bg.update(x);
  bg.draw();
  if(bg.foundTrigger())
    println("TRIGGERED");
  if(mousePressed){
    if(bg.insideGraph(mouseX,mouseY))
      bg.setThreshold(mouseY);
  }
  
  lg.update(x);
  lg.draw();
}

void keyPressed() {
  if(key == 'w')
    x = bg.getVal() + 10;
  if(key == 's')
    x = bg.getVal()-10;
}