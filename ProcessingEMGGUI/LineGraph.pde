
/*
 * This class displays data in a line graph
 */
class LineGraph{
  int x,y;
  int xLength, yLength;
  float[] yData;
  float yMin, yMax;
  int currX; // the next data to be updated
  
  LineGraph(int x,int y, int xLen, int yLen, int size, float yMin, float yMax){
    this.x = x;
    this.y = y;
    xLength = xLen;
    yLength = yLen;
    yData =  new float[size];
    this.yMin = yMin;
    this.yMax = yMax;
  }
  
  void update(float newY){
   if(newY < yMin) newY = yMin;
   else if(newY > yMax) newY = yMax;
   yData[currX++] = newY;
   if(currX >= yData.length) currX = 0;
  }
  
  void draw(){
    //axes
    line(x,y,x,y-yLength);
    //float xAxis = (yMin<0)? y+map(yMin,y,y+yLength,yMin,yMax):y;
    //line(x,xAxis,x+xLength,xAxis);
    //println(str(y) + " " + str(y+map(yMin,y,y+yLength,yMin,yMax)));
    
    for(int i=0; i< yData.length-1; ++i){
      line(x+(xLength/yData.length)*i,y - map(yData[i],yMin,yMax,0,yLength), x+(xLength/yData.length)*(i+1),y - map(yData[i+1],yMin,yMax,0,yLength));
    }
  }
}