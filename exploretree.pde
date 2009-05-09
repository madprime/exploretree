import processing.opengl.*;
import java.lang.Math.*;

// Constants
int maxDepth = 4;
int min_stroke_weight = 4;
int max_stroke_weight = 5;
float inverse_speed = 8; // higher = slower animation
int sizeX = 1000; // width of plot area
int sizeY = 700;  // height of plot area
float borderfrac = 0.06; // fraction of space to leave on border
float controlarea_height = 150;

// Initialized global variables
int[] node_path = { 0 };  // if more than one entry, indicates the node path the tree drawing animation has to take
float node_path_progress = 0;  // fraction of progress between node_path[0] and node_path[1], should be between 0 and 1
int search_node = -1;
String search_name = "";
String current_search_input = "";
PFont type_font = createFont("Courier",12);
PFont plot_font = createFont("Helvetica", 14);

// Uninitialized global variables
Tree treeoflife;
int max_dist;
float step_size;
int[][] node_positions; // array of all nodes, for each node an array containing xpos, ypos, and nodeID
int[][] search_result_positions; // array of search results you can click on to create path to target

// constants initialized in setup()
float plotY1, plotY2; // top and bottom for plot area
float plotX1, plotX2; // left and right for plot area
float centerX, centerY; // center coordinates for tree
float maxRadius; // maximum radius to draw tree
int tree_height; // total tree height of the tree data loaded (not only that displayed)

void setup() {
  size(sizeX,sizeY);
  frameRate(20);

  plotX1 = sizeX * borderfrac;
  plotX2 = sizeX * (1 - borderfrac);
  plotY1 = sizeX * borderfrac;
  plotY2 = sizeY * (1 - borderfrac) - controlarea_height;
  centerX = (plotX1 + plotX2) / 2;
  centerY = plotY2;
  maxRadius = plotX2 - centerX;
  
  parse_tree();                          // Parse tree file
  tree_height = treeoflife.getHeight();  // Get tree height
  
  smooth();
  
  //println(max_dist);
  //noLoop();
}

void draw() {
  strokeWeight(4);
  background(255);
  fill(0);
  
  // line to display search text input
  textFont(type_font);
  stroke(0);
  strokeWeight(1);
  line(plotX1,plotY2 + 40,plotX1+200,plotY2+40);
  textAlign(BOTTOM,LEFT);
  text(current_search_input,plotX1+15,plotY2+35);
  
  
  int[] match_keys = {};
  search_result_positions = new int[0][3];
  match_keys = searchNodes(search_name,0,match_keys);
  if (match_keys.length == 1) {
    search_node = match_keys[0];
  }
  if (match_keys.length > 0 && match_keys.length < 50) {
    textFont(plot_font);
    int left_to_post = match_keys.length;
    int xmod = 0;
    int ymod = left_to_post / 7;
    for (int i=0; i<match_keys.length;i++){
      if (ymod != left_to_post / 7) {
        xmod = 0;
      }
      ymod = left_to_post / 7;
      //println(ymod);
      String potential_match_name = treeoflife.getNodeByKey(match_keys[i]).getName();
      //println(match_keys[i]);
      textAlign(CENTER,BOTTOM);
      potential_match_name = potential_match_name.replace("_"," ");
      float plot_xcoord = plotX1 + (plotX2-plotX1)*((xmod + 0.5)/7);
      float plot_ycoord = plotY2 + controlarea_height - ymod * 20.0;
      text(potential_match_name,plot_xcoord, plot_ycoord);
      left_to_post--;
      xmod++;
      int[] temp = {(int) plot_xcoord, (int) plot_ycoord, match_keys[i]};
      search_result_positions = (int[][]) append(search_result_positions,temp);
    }
  }
  if (search_node >= 0) {
    max_dist = getDist(0);
  }
  
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
  textFont(plot_font);

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
    float fraction_dist = currNode.height * 1.0 / tree_height;
    color levelColor = lerpColor(#0000FF,#FF0000,fraction_dist,HSB);
    stroke(levelColor,100);
    strokeWeight(min_stroke_weight);
        
    // Draw lines from here to each of the child nodes
    for (int i = 0; i < numChildren; i++) {
      if (search_node >= 0) {
        fraction_dist = (1.0 * max_dist - getDist(currNode.getChild(i).key)) / max_dist;
        levelColor = lerpColor(#0000FF,#FF0000,fraction_dist,HSB);
        stroke(levelColor,80);
        if (getDist(currNode.getChild(i).key) < getDist(currNode.key)) {
          strokeWeight(max_stroke_weight);
          stroke(levelColor,160);
        }
      }
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
  textFont(plot_font);
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
    float fraction_dist = currNode.height * 1.0 / tree_height;
    color levelColor = lerpColor(#0000FF,#FF0000,fraction_dist,HSB);
    stroke(levelColor,100);
    strokeWeight(min_stroke_weight);
        
    // Draw lines from here to each of the child nodes
    for (int i = 0; i < numChildren; i++) {
      if (search_node >= 0) {
        fraction_dist = (1.0 * max_dist - getDist(currNode.getChild(i).key)) / max_dist;
        levelColor = lerpColor(#0000FF,#FF0000,fraction_dist,HSB);
        stroke(levelColor,80);
        if (getDist(currNode.getChild(i).key) < getDist(currNode.key)) {
          strokeWeight(max_stroke_weight);
          stroke(levelColor,160);
        }
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
  int closestNode = node_path[0];
  //println(node_positions.length);
  for (int i=0; i<node_positions.length; i++) {
    float distance = pow( (pow((mouseX - node_positions[i][0]),2) + pow((mouseY - node_positions[i][1]),2)), 0.5 );
    if (distance < minDist) {
      closestNode = node_positions[i][2];
      minDist = distance;
    }
  }
  
  if (closestNode != node_path[0]) {
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
  
  // or search for clicks to name search results
  int new_search_result = search_node;
  for (int i=0; i<search_result_positions.length; i++) {
    float distance = pow( (pow((mouseX - search_result_positions[i][0]),2) + pow((mouseY - search_result_positions[i][1]),2)), 0.5 );
    if (distance < minDist) {
      new_search_result = search_result_positions[i][2];
      minDist = distance;
    }
  }
  if (new_search_result != search_node) {
    search_node = new_search_result;
    println(new_search_result);
  }
}

// If a key is pressed, go back by one node
void keyPressed() {
  if (key == CODED && (keyCode == DOWN || keyCode == LEFT)) { 
    if (node_path[node_path.length-1] > 0) {    // don't back up if already at the bottom
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
    }
  } else {
    if(key == ENTER)
    {
      search_name = current_search_input;
      current_search_input = "";
    }
    else if(key == BACKSPACE && current_search_input.length() > 0)
    {
      current_search_input = current_search_input.substring(0, current_search_input.length() - 1);
    }
    else if (key != CODED) {
      current_search_input = current_search_input + key;
    }
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
  if (connectnode1_index == 0 && connectnode2_index == 0) {
    return(0);
  } else {
    return (connectnode1_index);
  }
  
}

// recursively search for node with name matching search_name
int[] searchNodes (String search_name, int curr_node, int[] match_keys) {
  TreeNode currNode = treeoflife.getNodeByKey(curr_node);
  
  String currName = currNode.getName();
  
  search_name = search_name.replace(" ","_");
  String[] matches = null;
  String[] more_matches = null;
  if (search_name.length() == 0) {
    search_node = -1;
  }
  else if (currName.length() > 1 && search_name.length() > 1) {
    matches = match(currName.toLowerCase(), search_name.toLowerCase());
    more_matches = match(search_name.toLowerCase(), currName.toLowerCase());
  }
 
  int numChildren = currNode.numberChildren();
  if ( (matches != null || more_matches != null) && search_name.length() > 2) {
    //search_node = currNode.key;
    match_keys = append(match_keys, currNode.key);
  }
  if (numChildren > 0) {
    for (int i = 0; i < numChildren; i++) {
      match_keys = searchNodes(search_name, currNode.getChild(i).key,match_keys);
    }
  }

  return(match_keys);
}

// Chris wrote this tree parser function.
void parse_tree() {
  try {
    BufferedReader r = createReader("treeoflife.tree");
    TreeParser tp = new TreeParser(r);
    // The first arg should be a file length, but it's only used to draw
    // a progress bar, and we don't know the length of the file yet.
    treeoflife = tp.tokenize(1, "treeoflife", null);
  }
  catch (Exception e) {
    System.out.println("Couldn't find data file");
  }
}
