import processing.opengl.*;
import java.lang.Math.*;

// CHANGEME -- use your local path here
String fileName = "/Users/mad/treeoflife/treeoflife.tree";

Tree t;

int num_ends_covered = 0;
int num_nodes_covered = 0;
int total_num_ends = 0;
int total_num_nodes = 0;
int maxdepth = 5;
int curr_node_key = 0;
int last_node = 0;

int sizeX, sizeY; // width and height of plot area
float plotY1, plotY2; // top and bottom for plot area
float plotX1, plotX2; // left and right for plot area
float borderfrac; // fraction of space to leave on border
float centerX, centerY; // center coordinates for tree
float maxRadius; // maximum radius to draw tree
int tree_height; // total tree height of the tree data loaded (not only that displayed)

int[][] node_positions; // array of all nodes, for each node an array containing xpos, ypos, and nodeID

PFont plotFont;

void setup() {
  sizeX = 1000;
  sizeY = 600;
  size(sizeX,sizeY);
  borderfrac = 0.02; 
  plotX1 = sizeX * borderfrac;
  plotX2 = sizeX * (1 - borderfrac);
  plotY1 = sizeX * borderfrac;
  plotY2 = sizeY * (1 - borderfrac);
  centerX = (plotX1 + plotX2) / 2;
  centerY = plotY2;
  maxRadius = plotX2 - centerX;
  
  plotFont = createFont("Helvetica", 14);
  textFont(plotFont);
  
  parse_tree();
  smooth();
}

void draw() {
  stroke(0,0,0,30);
  strokeWeight(4);
  background(255);
  fill(0);
  //float[] radialpos = { (maxRadius * 2)/3, (PI/6) };
  //float[] radialpos2 = { (maxRadius * 2)/3, (PI * 2)/6 };
  //float[] xypos = radial_to_xy(radialpos);
  //float[] xypos2  = radial_to_xy(radialpos2);
  //point(xypos[0], xypos[1]);
  //point(xypos2[0], xypos2[1]);
  //line(centerX, centerY, xypos[0], xypos[1]);
  //drawpoint();
 
  TreeNode rootNode = t.getNodeByKey(curr_node_key);
  //System.out.println("numleaves: " + t.getLeafCount());
  
  tree_height = t.getHeight();
  
  total_num_ends = 0;
  total_num_nodes = 0;
  countTreeNodes(rootNode, maxdepth, 0);
  node_positions = new int[total_num_nodes][3];
  //println(total_num_ends);
  num_nodes_covered = 0;
  num_ends_covered = 0;
  drawTree(rootNode, maxdepth, 0);
}

//global vars:
//total_end_nodes
//num_ends_covered
//depth
float[] drawTree(TreeNode currNode, int maxDepth, int currDepth) {
  //println("drawtree node id is " + currNode.key);
  //println(num_nodes_covered);
  //println(num_ends_covered);

  //System.out.println("in drawtree, node " + currNode.getName());
  int numChildren = currNode.numberChildren();
  //System.out.println("num children " + numChildren);
  //System.out.println("depth " + currNode.height);
  if (numChildren > 0 && currDepth < maxDepth) {
 
    // - if so, descend recursively
    float sumtheta = 0;
    float numtheta = 0;
    float[][] childcoordlist = new float[numChildren][2];
    for (int i = 0; i < numChildren; i++) {
      float[] childradialcoord = drawTree(currNode.getChild(i), maxDepth, currDepth+1);
      childcoordlist[i] = childradialcoord;
      sumtheta += childradialcoord[1];
      numtheta++;
    }
    float theta = sumtheta / numtheta;
    float radius = (maxRadius * currDepth) / maxDepth;
    float[] radialpos = {radius, theta};
    float[] xypos = radial_to_xy(radialpos);
    
    float fraction_depth = currNode.height * 1.0 / tree_height;
    color levelColor = lerpColor(#0000FF,#FF0000,fraction_depth,HSB);
    //println(fraction_depth);
    stroke(levelColor,100);
    point(xypos[0],xypos[1]);
    for (int i = 0; i < numChildren; i++) {
      float[] childradialcoord = childcoordlist[i];
      float[] childxycoord = radial_to_xy(childradialcoord);
      line(xypos[0],xypos[1],childxycoord[0],childxycoord[1]);
    }
    textAlign(CENTER,BOTTOM);
    String name = currNode.getName();
    name = name.replace("_"," ");
    text(name,xypos[0],xypos[1]-5);
    
    int[] posarraydata = { (int) xypos[0], (int) xypos[1], currNode.key };
    node_positions[num_nodes_covered] = posarraydata;
    num_nodes_covered++;

    return(radialpos);
  }
  else {
    float radius = (maxRadius * currDepth) / maxDepth;
    float theta = (PI * (num_ends_covered + 0.5)) / total_num_ends;
    float[] radialpos = { radius, theta };
    float[] xypos = radial_to_xy(radialpos);
    
    float fraction_depth = currNode.height * 1.0 / tree_height;
    color levelColor = lerpColor(#0000FF,#FF0000,fraction_depth,HSB);
    //println(fraction_depth);
    stroke(levelColor,100);
    point(xypos[0],xypos[1]);
    
    num_ends_covered++;
    int[] posarraydata = { (int) xypos[0], (int) xypos[1], currNode.key };
    node_positions[num_nodes_covered] = posarraydata;
    num_nodes_covered++;
    
    //println("in drawtree, node " + currNode.getName());
    textAlign(CENTER,BOTTOM);
    String name = currNode.getName();
    name = name.replace("_"," ");
    text(name,xypos[0],xypos[1]-5);
    return(radialpos);
    // calculate position
    // increment num_ends_covered
    // return coords
  }
  
   // drawTree for each child: pass depth++, return radialpos for each;
   // calculate position based on children positions,
   // draw lines from self to each child position,
   // return self position
}

void countTreeNodes(TreeNode currNode, int maxDepth, int currDepth) {
  //System.out.println("in drawtree, node " + currNode.getName());
  int numChildren = currNode.numberChildren();
  //System.out.println("num children " + numChildren);
  //System.out.println("depth " + currNode.height);
  if (numChildren > 0 && currDepth < maxDepth) {
    total_num_nodes++;
    // - if so, descend recursively
    for (int i = 0; i < numChildren; i++) {
      countTreeNodes(currNode.getChild(i),maxDepth,currDepth + 1);
    }
  }
  else {
    total_num_ends++;
    total_num_nodes++;
    // calculate position
    // increment num_ends_covered
    // return coords
  }
  
   // drawTree for each child: pass depth++, return radialpos for each;
   // calculate position based on children positions,
   // draw lines from self to each child position,
   // return self position
}


float[] xy_to_radial(float[] xypos) {
  float x = xypos[0];
  float y = xypos[1];
  float radius = pow(pow(x - centerX,2) + pow(y - centerY,2),0.5);
  //println(radius);
  float theta = asin((centerY - y)/radius);
  if ( (x - centerX) < 0) {
    theta = theta + PI;
  }
  //println(theta);
  float[] returndata = { radius, theta };
  return returndata;
}

float[] radial_to_xy(float[] radialpos) {
  float r = radialpos[0];
  float theta = radialpos[1];
  float x = (r * cos(theta)) + centerX;
  float y = centerY - (r * sin(theta));
  float[] returndata = {x, y};
  return returndata;
}

void mousePressed() {  
  for (int i=0; i<total_num_nodes; i++) {
    if (abs(mouseX - node_positions[i][0]) <= 10) {
      if (abs(mouseY - node_positions[i][1]) <= 10) {
        background(255);
        last_node = curr_node_key;
        curr_node_key = node_positions[i][2];
      }
    }
  }
}

void keyPressed() {
  if (curr_node_key > 0) {
    TreeNode Node = t.getNodeByKey(curr_node_key);
    int parent_node_key = Node.parent().key;
    curr_node_key = parent_node_key;
  }
}

void parse_tree() {
  File f = new File(fileName);
  try {
    BufferedReader r = new BufferedReader(new FileReader(f));
    TreeParser tp = new TreeParser(r);
    t = tp.tokenize(f.length(), f.getName(), null);
  }
  catch (FileNotFoundException e)
  {
    System.out.println("Couldn't find file: " + fileName);
  }
}
