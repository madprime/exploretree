import processing.opengl.*;
import java.lang.Math.*;

// CHANGEME -- use your local path here
String fileName = "/Users/mad/treeoflife/treeoflife.tree";

String search_name = "Human";
int search_node = -1;
int max_dist = 1;

Tree treeoflife;

int maxDepth = 4;
int curr_node_key = 0;
int min_stroke_weight = 4;
int max_stroke_weight = 5;

int[] node_path = { 0 };  // if more than one entry, indicates the node path the tree drawing animation has to take
float node_path_progress = 0;  // fraction of progress between node_path[0] and node_path[1], should be between 0 and 1
float step_size = 0.05;
float inverse_speed = 40;

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
  borderfrac = 0.06; 
  plotX1 = sizeX * borderfrac;
  plotX2 = sizeX * (1 - borderfrac);
  plotY1 = sizeX * borderfrac;
  plotY2 = sizeY * (1 - borderfrac);
  centerX = (plotX1 + plotX2) / 2;
  centerY = plotY2;
  maxRadius = plotX2 - centerX;
  
  plotFont = createFont("Helvetica", 14);
  textFont(plotFont);
  
  parse_tree();                          // Parse tree file
  tree_height = treeoflife.getHeight();  // Get tree height
  
  smooth();
  
  searchNode(search_name,0);
  max_dist = getDist(0);
  //println(max_dist);
  //noLoop();
}

void draw() {
  strokeWeight(4);
  background(255);
  fill(0);
  
  //drawTree(node_path[0], 0, 0, total_num_ends[0]);
  //drawTreeIntermediate(node_path[0], 0, num_ends_covered, total_num_ends, 0, node_path[1]);
  
  //float[] drawTreeIntermediate(int node_key, int currDepth, int[] num_ends_covered, int[] total_num_ends, int in_child) {
  node_positions = new int[0][3];
  
  if (node_path.length > 1) {
    step_size = (node_path.length - 1) / inverse_speed;
    int node_ahead_key = -1;
    int node_behind_key = -1;
    float local_progress = node_path_progress;
    
    int[] path_old_to_root = nodePath(node_path[0],0);
    int[] path_new_to_root = nodePath(node_path[1],0);
    if (path_new_to_root.length > path_old_to_root.length) {
      // moving forward into tree
      node_ahead_key = node_path[1];
      node_behind_key = node_path[0];
    } else {
      node_ahead_key = node_path[0];
      node_behind_key = node_path[1];
      local_progress = 1 - node_path_progress;
      // moving backward in tree
    }
    
    int[] node_counts_before = { 0, 0 };
    node_counts_before = countTreeNodes(node_behind_key, 0, node_counts_before);
    int[] node_counts_after = { 0, 0 };
    node_counts_after = countTreeNodes(node_ahead_key, 0, node_counts_after);
    int[] total_num_ends = { node_counts_before[1], node_counts_after[1] };
  
    int[] num_ends_covered = { 0, 0 };

    drawTreeIntermediate(node_behind_key, 0, num_ends_covered, total_num_ends, 0, node_ahead_key, local_progress);

    node_path_progress = node_path_progress + step_size;
    if (node_path_progress >= 1) {
      int[] new_node_path = { };
      for (int i = 1; i < node_path.length; i++) {
        new_node_path = append(new_node_path,node_path[i]);
      }
      node_path = new_node_path;
      node_path_progress = node_path_progress - 1;
      if (node_path_progress < 0) {
        node_path_progress = 0;
      }
    }

  } else 
  {
    int[] node_counts = { 0, 0 };
    node_counts = countTreeNodes(node_path[0], 0, node_counts);
    drawTree(node_path[0], 0, 0, node_counts[1]);
  }
  
}

//drawTree draws a tree recursively, from the endpoints inwards
float[] drawTree(int node_key, int currDepth, int num_ends_covered, int total_num_ends) {

  TreeNode currNode = treeoflife.getNodeByKey(node_key);
  int numChildren = currNode.numberChildren();
  
  // If there are children and we haven't hit maxDepth, descend recursively
  if (numChildren > 0 && currDepth < maxDepth) {
    
    float sumtheta = 0;  // these will be used to find average theta of children
    int numtheta = 0;
    float[][] child_data_list = new float[numChildren][3]; // for storing child coordinates & num_ends_covered
    
    // call each of the child nodes with drawTree
    for (int i = 0; i < numChildren; i++) {
      float[] child_data = drawTree(currNode.getChild(i).key, currDepth+1, num_ends_covered, total_num_ends);
      child_data_list[i] = child_data;  // store child data
      num_ends_covered = (int) child_data[2];  // update num ends covered
      sumtheta += child_data[1];               // add to theta sum
      numtheta++;
    }
    float theta = sumtheta / numtheta; // get average theta
    
    float radius = (maxRadius * currDepth) / maxDepth;   // radius based on current depth
    float[] radialpos = {radius, theta};
    float[] xypos = radial_to_xy(radialpos);
    
    // Color this line in the tree based on overall (not local) depth
    //float fraction_depth = currNode.height * 1.0 / tree_height;
    //color levelColor = lerpColor(#0000FF,#FF0000,fraction_depth,HSB);
    //color levelColor = lerpColor(#0000FF,#FF0000,fraction_dist,HSB);
    //stroke(levelColor,100);
        
    // Draw lines from here to each of the child nodes
    for (int i = 0; i < numChildren; i++) {
      float fraction_dist = (1.0 * max_dist - getDist(currNode.getChild(i).key)) / max_dist;
      color levelColor = lerpColor(#0000FF,#FF0000,fraction_dist,HSB);
      stroke(levelColor,80);
      if (getDist(currNode.getChild(i).key) < getDist(currNode.key)) {
        strokeWeight(max_stroke_weight);
        stroke(levelColor,160);
      } else {
        strokeWeight(min_stroke_weight);
      }
      //strokeWeight(min_stroke_weight + (max_stroke_weight - min_stroke_weight) * fraction_dist);
      float[] child_data = child_data_list[i];
      float[] childradialcoord = { child_data[0], child_data[1] };
      float[] childxycoord = radial_to_xy(childradialcoord);
      line(xypos[0],xypos[1],childxycoord[0],childxycoord[1]);
    }
    
    // Place the name text above this node
    textAlign(CENTER,BOTTOM);
    String name = currNode.getName();
    name = name.replace("_"," ");
    text(name,xypos[0],xypos[1]-5);
    
    // Keep track of node positions for interpreting mouse clicks
    int[] posarraydata = { (int) xypos[0], (int) xypos[1], currNode.key };
    node_positions = (int[][]) append(node_positions, posarraydata);

    float[] returndata = { radialpos[0], radialpos[1], (float) num_ends_covered };
    // return radial position
    return(returndata);
  }
  else {            // if no child nodes, this is an "end node"  
  
    // end nodes should have equally spaced thetas
    float theta = (PI * (num_ends_covered + 0.5)) / total_num_ends;
    float radius = (maxRadius * currDepth) / maxDepth;
    float[] radialpos = { radius, theta };
    float[] xypos = radial_to_xy(radialpos);
    
    // Increment the global variable keeping track of the number of end nodes covered
    num_ends_covered++;
    
    // Keep track of node positions for interpreting mouse clicks
    int[] posarraydata = { (int) xypos[0], (int) xypos[1], currNode.key };
    node_positions = (int[][]) append(node_positions, posarraydata);
    
    // Write name above node
    textAlign(CENTER,BOTTOM);
    String name = currNode.getName();
    name = name.replace("_"," ");
    text(name,xypos[0],xypos[1]-5);
    
    float[] returndata = { radialpos[0], radialpos[1], (float) num_ends_covered };
    // return radial position
    return(returndata);
  }
}

//drawTreeIntermediate draws a tree recursively, from the endpoints inwards
//this tree is an intermediate between trees of two neighboring nodes
//
//to keep track of whether we've moved into the target child or not,
//in_child = 1 if in children, 0 if on the right and -1 if on the left.
float[] drawTreeIntermediate(int node_key, int currDepth, int[] num_ends_covered, int[] total_num_ends, int in_child, int target_child_node_key, float local_progress) {

  TreeNode currNode = treeoflife.getNodeByKey(node_key);
  int numChildren = currNode.numberChildren();
  
  // If there are children and we haven't hit maxDepth + 1, descend recursively
  if (numChildren > 0 && (currDepth < maxDepth || (currDepth < maxDepth + 1 && in_child == 1))) {
    
    float sumtheta = 0;  // these will be used to find average theta of children
    int numtheta = 0;
    float[][] child_data_list = new float[numChildren][4]; // for storing child coordinates & num_ends_covered
    
    // call each of the child nodes with drawTree
    for (int i = 0; i < numChildren; i++) {
      float[] child_data;
      if (in_child == 0 && currNode.getChild(i).key == target_child_node_key) {
        child_data = drawTreeIntermediate(currNode.getChild(i).key, currDepth+1, num_ends_covered, total_num_ends, 1, target_child_node_key, local_progress);
        in_child = -1;
      } else {      
        child_data = drawTreeIntermediate(currNode.getChild(i).key, currDepth+1, num_ends_covered, total_num_ends, in_child, target_child_node_key, local_progress);
      }
      child_data_list[i] = child_data;  // store child data
      num_ends_covered[0] = (int) child_data[2];  // update num ends covered
      num_ends_covered[1] = (int) child_data[3];
      sumtheta += child_data[1];               // add to theta sum
      numtheta++;
    }
    float theta = sumtheta / numtheta; // get average theta
    
    float radius = (maxRadius * (currDepth - local_progress)) / (maxDepth);   // radius based on current depth
    if (radius < 0) {
      radius = 0;
    }
    if (in_child < 1) {
      radius = radius * (1 - local_progress);
    }
    float[] radialpos = {radius, theta};
    float[] xypos = radial_to_xy(radialpos);
    
    // Color this line in the tree based on overall (not local) depth
    //float fraction_depth = currNode.height * 1.0 / tree_height;
    //color levelColor = lerpColor(#0000FF,#FF0000,fraction_depth,HSB);
    //stroke(levelColor,100);
        
    // Draw lines from here to each of the child nodes
    for (int i = 0; i < numChildren; i++) {
      float fraction_dist = (1.0 * max_dist - getDist(currNode.getChild(i).key)) / max_dist;
      color levelColor = lerpColor(#0000FF,#FF0000,fraction_dist,HSB);
      stroke(levelColor,80);
      if (getDist(currNode.getChild(i).key) < getDist(currNode.key)) {
        strokeWeight(max_stroke_weight);
        stroke(levelColor,160);
      } else {
        strokeWeight(min_stroke_weight);
      }
      float[] child_data = child_data_list[i];
      float[] childradialcoord = { child_data[0], child_data[1] };
      float[] childxycoord = radial_to_xy(childradialcoord);
      line(xypos[0],xypos[1],childxycoord[0],childxycoord[1]);
    }
    
    if (currDepth == maxDepth) {
      num_ends_covered[0]++;
      //println("incrementing old end nodes covered at " + currNode.getName() + ", " + num_ends_covered[0]);
    }
    
    // Place the name text above this node
    textAlign(CENTER,BOTTOM);
    String name = currNode.getName();
    name = name.replace("_"," ");
    
    if ( in_child == 1) {
      fill(0);
    } else {
      fill(0,255 * (1 - local_progress));
    }
    text(name,xypos[0],xypos[1]-5);
    
    // Keep track of node positions for interpreting mouse clicks
    int[] posarraydata = { (int) xypos[0], (int) xypos[1], currNode.key };
    node_positions = (int[][]) append(node_positions, posarraydata);

    float[] returndata = { radialpos[0], radialpos[1], (float) num_ends_covered[0], (float) num_ends_covered[1] };
    // return radial position
    return(returndata);
  }
  else {            // if no child nodes, this is an "end node"  
  
    // end nodes should have equally spaced thetas
    float theta_new = (PI * (num_ends_covered[1] + 0.5)) / total_num_ends[1];
    //println ("total num ends new is " + total_num_ends[1]);
    if (in_child == 0) {
      theta_new = 0;
    }
    if (in_child == -1 ) {
      theta_new = PI;
    }
    float theta_old = (PI * (num_ends_covered[0] + 0.5)) / total_num_ends[0];
    float theta_ave = (theta_new * local_progress) + (theta_old * (1 - local_progress));
    //println("theta for " + currNode.getName() + " is " + theta_ave + " from old " + theta_old + " and new " + theta_new);
    float radius = (maxRadius * (currDepth - local_progress)) / (maxDepth);   // radius based on current depth
    if (radius < 0) {
      radius = 0;
    }
    if (currDepth == maxDepth + 1) {
      radius = maxRadius;
    }
    if (in_child < 1) {
      radius = radius * (1 - local_progress);
    }
    float[] radialpos = { radius, theta_ave };
    float[] xypos = radial_to_xy(radialpos);
    
    // Increment the global variable keeping track of the number of end nodes covered
    if (in_child == 1) {
      num_ends_covered[1]++;
      //println("incrementing new end nodes covered at " + currNode.getName() + ", " + num_ends_covered[1]);
    }
    if (currDepth < maxDepth + 1) {
      num_ends_covered[0]++;
      //println("incrementing old end nodes covered at " + currNode.getName() + ", " + num_ends_covered[0]);
    }
   // println("incrementing new end nodes covered at " + currNode.getName());
    
    // Keep track of node positions for interpreting mouse clicks
    int[] posarraydata = { (int) xypos[0], (int) xypos[1], currNode.key };
    node_positions = (int[][]) append(node_positions, posarraydata);
    
    // Write name above node
    textAlign(CENTER,BOTTOM);
    String name = currNode.getName();
    name = name.replace("_"," ");
    if (currDepth == maxDepth + 1) {
      fill(0,local_progress * 255);
    } else {
      if (in_child < 1) {
        fill(0,(1 - local_progress) * 255);
      } else {
        fill(0);
      }
    }
    text(name,xypos[0],xypos[1]-5);
    
    float[] returndata = { radialpos[0], radialpos[1], (float) num_ends_covered[0], (float) num_ends_covered[1] };
    // return radial position
    return(returndata);
  }
}


// Recursives descend in the tree to maxDepth to count
// total number of total nodes and end nodes.
int[] countTreeNodes(int node_key, int currDepth, int[] node_tally) {
  
  TreeNode currNode = treeoflife.getNodeByKey(node_key);
  
  int numChildren = currNode.numberChildren();
  if (numChildren > 0 && currDepth < maxDepth) {
    node_tally[0]++;
    for (int i = 0; i < numChildren; i++) {
      node_tally = countTreeNodes(currNode.getChild(i).key,currDepth + 1, node_tally);
    }
  }
  else {
    node_tally[0]++;
    node_tally[1]++;
  }
  return(node_tally);
}

// Convert xy coordinates to radial coordinates.
// I made this and then never used it. Go figure.
float[] xy_to_radial(float[] xypos) {
  float x = xypos[0];
  float y = xypos[1];
  float radius = pow(pow(x - centerX,2) + pow(y - centerY,2),0.5);
  float theta = asin((centerY - y)/radius);
  if ( (x - centerX) < 0) {
    theta = theta + PI;
  }
  float[] returndata = { radius, theta };
  return returndata;
}

// Convert radial coordinates to xy coordinates.
float[] radial_to_xy(float[] radialpos) {
  float r = radialpos[0];
  float theta = radialpos[1];
  float x = (r * cos(theta)) + centerX;
  float y = centerY - (r * sin(theta));
  float[] returndata = {x, y};
  return returndata;
}

// If the mouse is clicked, change the node we are drawing
// to the node closest to the click, if any are within 50px
void mousePressed() {
  float minDist = 50;   // don't change position unless at least this close to a node
  int closestNode = curr_node_key;
  //println(node_positions.length);
  for (int i=0; i<node_positions.length; i++) {
    float distance = pow( (pow((mouseX - node_positions[i][0]),2) + pow((mouseY - node_positions[i][1]),2)), 0.5 );
    if (distance < minDist) {
      closestNode = node_positions[i][2];
      minDist = distance;
    }
  }
  
  if (closestNode != curr_node_key) {
    // find new node path
    if (node_path.length == 1) {
      node_path = nodePath(node_path[0],closestNode);
    }
    else {
      int[] tempnodepath1 = nodePath(node_path[0],closestNode);
      int[] tempnodepath2 = nodePath(node_path[1],closestNode);
      if (tempnodepath1.length > tempnodepath2.length) {  // full steam ahead!
        node_path = tempnodepath1;
      } else {                                            // reverse course!
        node_path = tempnodepath2;
        node_path_progress = 1 - node_path_progress;
      }
    }
  }
  
  curr_node_key = closestNode;  // should be able to remove this once animation works
}

// If a key is pressed, go back by one node
void keyPressed() {
  if (curr_node_key > 0) {    // don't back up if already at the bottom
    TreeNode Node = treeoflife.getNodeByKey(node_path[node_path.length-1]);
    int parent_node_key = Node.parent().key;
        
    // find new node path
    if (node_path.length == 1) {
      node_path = nodePath(node_path[0],parent_node_key);
    } else {
      int[] tempnodepath1 = nodePath(node_path[0],parent_node_key);
      int[] tempnodepath2 = nodePath(node_path[1],parent_node_key);
      if (tempnodepath1.length > tempnodepath2.length) {    // we were already backing up
        node_path = tempnodepath1;
      } else {
        node_path = tempnodepath2;
        node_path_progress = 1 - node_path_progress;        // reverse course!
      }
    }
    
    TreeNode Node_old = treeoflife.getNodeByKey(curr_node_key);   // can delete once animation implemented
    int parent_node_key_old = Node.parent().key;                  //
    curr_node_key = parent_node_key_old;                          //
    
  }
}

// find the list of node keys connecting one node to another
int[] nodePath(int nodekey1, int nodekey2) {
  TreeNode Node1 = treeoflife.getNodeByKey(nodekey1);
  TreeNode Node2 = treeoflife.getNodeByKey(nodekey2);
  
  // first find paths to root node (key=0)
  int[] pathtoroot1 = {nodekey1};
  int[] pathtoroot2 = {nodekey2};
  while (pathtoroot1[pathtoroot1.length-1] != 0) {
    pathtoroot1 = append(pathtoroot1,Node1.parent().key);
    Node1 = Node1.parent();
  }
  while (pathtoroot2[pathtoroot2.length-1] != 0) {
    pathtoroot2 = append(pathtoroot2,Node2.parent().key);
    Node2 = Node2.parent();
  }
  // Find the first node these paths-to-root overlap
  int connectnode1_index = -1;
  int connectnode2_index = -1;
  for (int i = 0; i<pathtoroot1.length; i++) {
    for (int j = 0; j<pathtoroot2.length;j++) {
      if (connectnode1_index < 0 && (pathtoroot1[i] == pathtoroot2[j])) {
        connectnode1_index = i;
        connectnode2_index = j;
      }
    }
  }
  // Create a path from node1 to connectnode to node2
  int[] path = {};
  for (int i = 0; i < connectnode1_index; i++) {
    path = append(path, pathtoroot1[i]);
  }
  for (int j = connectnode2_index; j >= 0; j--) {
    path = append(path, pathtoroot2[j]);
  }

  return(path);
}

int getDist (int node_key) {
  TreeNode Node1 = treeoflife.getNodeByKey(search_node);
  TreeNode Node2 = treeoflife.getNodeByKey(node_key);
  
  // first find paths to root node (key=0)
  int[] pathtoroot1 = {search_node};
  int[] pathtoroot2 = {node_key};
  while (pathtoroot1[pathtoroot1.length-1] != 0) {
    pathtoroot1 = append(pathtoroot1,Node1.parent().key);
    Node1 = Node1.parent();
  }
  while (pathtoroot2[pathtoroot2.length-1] != 0) {
    pathtoroot2 = append(pathtoroot2,Node2.parent().key);
    Node2 = Node2.parent();
  }
  // Find the first node these paths-to-root overlap
  int connectnode1_index = -1;
  int connectnode2_index = -1;
  for (int i = 0; i<pathtoroot1.length; i++) {
    for (int j = 0; j<pathtoroot2.length;j++) {
      if (connectnode1_index < 0 && (pathtoroot1[i] == pathtoroot2[j])) {
        connectnode1_index = i;
        connectnode2_index = j;
      }
    }
  }
  if (connectnode1_index > connectnode2_index) {
    return(connectnode1_index+1);
  } else {
    return(connectnode2_index+1);
  }
  
}

// recursively search for node with name matching search_name
void searchNode (String search_name, int curr_node) {
  TreeNode currNode = treeoflife.getNodeByKey(curr_node);
  int numChildren = currNode.numberChildren();
  if (numChildren > 0) {
    for (int i = 0; i < numChildren; i++) {
      searchNode(search_name, currNode.getChild(i).key);
    }
  }
  String currName = currNode.getName();
  String[] matches = match(currName, search_name);
  if (matches != null) {
    search_node = currNode.key;
  }
}


// Chris wrote this tree parser function.
void parse_tree() {
  File f = new File(fileName);
  try {
    BufferedReader r = new BufferedReader(new FileReader(f));
    TreeParser tp = new TreeParser(r);
    treeoflife = tp.tokenize(f.length(), f.getName(), null);
  }
  catch (FileNotFoundException e)
  {
    System.out.println("Couldn't find file: " + fileName);
  }
}
