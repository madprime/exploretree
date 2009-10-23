// ExploreTree is licensed under the GNU GPLv2 or higher, at your choice.
// It uses libnewicktree, which is code from the TreeJuxtaposer project
// and is licensed under the BSD license.
//
// Authors:  Madeleine Ball <mad-et@printf.net>,
//           Chris Ball <chris-et@printf.net>

// plot area variables
int sizeX = 600, sizeY = 400; // plot area size
float borderFrac = 0.05;      // fraction of space to leave on border
float treeAreaFrac = 0.6;     // vertical fraction of area to devote to tree drawing

// tree drawing variables
float maxDepth = 2.4;
float min_stroke_weight = 3.5, max_stroke_weight = 5;
color start_color = #0000FF, end_color = #FF0000;

// font drawing variables
int font_size = 12;
PFont plot_font = createFont("Arial",font_size);

// graphing constants initialized in setup()
float plotY1, plotY2;    // top and bottom for plot area
float plotX1, plotX2;    // left and right for plot area
float centerX, centerY;  // center coordinates for tree
float maxRadius;         // maximum radius to draw tree
int tree_height;         // total tree height of the tree data loaded (not only that displayed)

// tree variables
Tree treeoflife;
TreePositions treeoflife_positions;
TreeGraphInstance treegraph_current;
TreeGraphInstance treegraph_next;

// interaction & animation
int[][] visible_node_positions;       // array of arrays containing xpos, ypos, and nodeID of visible nodes
int[] node_path = new int[0];
int steps_between_nodes = 10;         // number of steps to take when animating movement between nodes
float between_node_progress = 0.0;    // 0 to 1, for animation: how far between two graph states you are

void setup() {
  size(sizeX,sizeY);
  frameRate(20);
  
  // set up plotting global variables
  plotX1 = sizeX * borderFrac;
  plotX2 = sizeX * (1 - borderFrac);
  plotY1 = sizeX * borderFrac;
  plotY2 = sizeY * (1 - borderFrac);
  centerX = (plotX1 + plotX2) / 2;
  centerY = plotY2;
  maxRadius = plotX2 - centerX;
  
  // set up tree structure global variables
  treeoflife = TreeReadNewick("temp2");
  treeoflife_positions = new TreePositions();
  node_path = append(node_path, treeoflife.root.node_ID);
  
  smooth();
  //noLoop();
}

void draw() {
  background(255);
  strokeWeight(3);
  stroke(0,255,255);
  fill(0);
  
  if (node_path.length == 1) {
    //println("stable base node: " + node_path[0]);
    int basenode_ID = node_path[0];
    if (treeoflife_positions.existsInstance(node_path[0], maxDepth)) {
      treegraph_current = treeoflife_positions.getInstance(node_path[0],maxDepth);
    }
    else {
      treegraph_current = treeoflife_positions.makeInstance(node_path[0], maxDepth);
      int num_ends = countEnds(node_path[0], 0);
println("Number of ends for base node " + node_path[0] + " is " + num_ends);
      calculateTree( treegraph_current, treeoflife.root.node_ID, 'b', 0, num_ends );
    }
//println("treegraph_current base node : " + treegraph_current.base_node_ID);
    visible_node_positions = new int[0][3];  // Always clear before calling drawTree
    drawTree(treegraph_current, treeoflife.root.node_ID);
  } else {
    if (node_path.length > 1) {
//println("Moving between nodes " + node_path[0] + " and " + node_path[1]);
      // current graph
      if (treeoflife_positions.existsInstance(node_path[0], maxDepth)) {
        treegraph_current = treeoflife_positions.getInstance(node_path[0],maxDepth);
      } else {
        treegraph_current = treeoflife_positions.makeInstance(node_path[0], maxDepth);
        int num_ends = countEnds(node_path[0], 0);
println("Number of ends for base node " + node_path[0] + " is " + num_ends);
        calculateTree( treegraph_current, treeoflife.root.node_ID, 'b', 0, num_ends );
      }
      // next graph
      if (treeoflife_positions.existsInstance(node_path[1], maxDepth)) {
        treegraph_next = treeoflife_positions.getInstance(node_path[1], maxDepth);
      } else {
        treegraph_next = treeoflife_positions.makeInstance(node_path[1], maxDepth);
        int num_ends = countEnds(node_path[1], 0);
println("Number of ends for base node " + node_path[0] + " is " + num_ends);
        calculateTree( treegraph_next, treeoflife.root.node_ID, 'b', 0, num_ends );
      }
      //NodePlotData curr_data_to = treegraph_next.getPosition(3);

      drawIntermediateTree(treegraph_current, treegraph_next, between_node_progress, treeoflife.root.node_ID);
      between_node_progress = between_node_progress + (1.0 / steps_between_nodes);
      if (between_node_progress >= 0.9999) {
        // remake array without first element
        int[] new_node_path = { };
        for (int i = 1; i < node_path.length; i++) {
          new_node_path = append(new_node_path,node_path[i]);
        }
        node_path = new_node_path;
        between_node_progress = 0;
      }

      //println(between_node_progress);
    } else {
      println("ERROR");
    }
  }
  
}



