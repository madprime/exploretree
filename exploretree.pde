// ExploreTree is licensed under the GNU GPLv2 or higher, at your choice.
// It uses libnewicktree, which is code from the TreeJuxtaposer project
// and is licensed under the BSD license.
//
// Author:  Madeleine Ball <mad-et@printf.net>

// plot area variables
int sizeX = 800, sizeY = 600; // plot area size
float borderFrac = 0.1;      // fraction of space to leave on border
float treeAreaFrac = 0.6;     // vertical fraction of area to devote to tree drawing

// tree drawing variables
float max_depth = 2;
float depth_max_spread = 0.8;
boolean do_dotted_ends = true; float frac_of_radius = 0.10;
boolean do_dynamicDepth = true; float dynamicAdjust = 0.99; int dynamicMaxNodes = 30; HashMap max_depth_calc = new HashMap();
float min_stroke_weight = 3.5, max_stroke_weight = 5;
color start_color = #0000FF, end_color = #FF0000;
boolean do_nudgeNodes = true; boolean do_hideOverlapNodes = false;
char line_type = 'v'; // 'a' for "arc-and-line-style" and 'v' or anything else for "v-style" 

// font drawing variables
float font_size = 12;
String plot_font_type = "Arial";
PFont plot_font = createFont(plot_font_type,font_size);
float display_font_size = 12;
String display_font_type= "Arial";
PFont display_font = createFont(display_font_type, display_font_size);

// other drawing variables
float searchBoxY1, searchBoxY2, searchBoxX1, searchBoxX2;
float ButtonSize = 15;
float depthMinusButtonX = sizeX-40;
float depthPlusButtonX = sizeX-20;
float depthButtonY = 15;

// graphing constants initialized in setup()
float plotY1, plotY2;    // top and bottom for plot area
float plotX1, plotX2;    // left and right for plot area
float centerX, centerY;  // center coordinates for tree
float maxRadius;         // maximum radius to draw tree
float tree_height;       // total tree height of the tree data loaded (not only that displayed)

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
HashMap calc_distances = new HashMap();   // key is node pair ( node1 + "_" + node2 ), value is the distance (a float). Added because calculating on the fly takes too long.

// Search for node specific variables
int search_node_ID = -1;              // -1 if no search node target, node_ID of target if there is one
boolean searchBoxFocus = false;
String current_search_input = ""; int[] matched_IDs = new int[0]; String search_name = "";
int[][] search_match_positions = new int[0][3];       // array of arrays containing xpos, ypos, and nodeID of displayed matches

void setup() {
  size(sizeX,sizeY);
  frameRate(20);
  textAlign(CENTER, CENTER);
  textFont(plot_font);
  
  // set up plotting global variables
  plotX1 = sizeX * borderFrac;
  plotX2 = sizeX * (1 - borderFrac);
  plotY1 = sizeX * borderFrac;
  plotY2 = plotY1 + (plotX2 - plotX1)/2;
  centerX = (plotX1 + plotX2) / 2;
  centerY = plotY2;
  maxRadius = plotX2 - centerX;  
  searchBoxX1 = sizeX * (borderFrac * 1.5);
  searchBoxX2 = sizeX * (1 - borderFrac * 1.5);
  searchBoxY1 = plotY2;
  searchBoxY2 = sizeY * (1 - (borderFrac/2) );
  
  // set up tree structure global variables
  treeoflife = TreeReadNewick("treeoflife.tree"); //treeoflife.tree"); //itol.tree");
  treeoflife_positions = new TreePositions();
  node_path = append(node_path, treeoflife.root.node_ID);
  tree_height = maxDepth(treeoflife.root.node_ID);

  smooth();
  //noLoop();
}

void draw() {
  background(255);
  strokeWeight(3);
  stroke(0,255,255);
  fill(0);
  
  // create interactive controls
  drawSearchArea();
  drawDepthControls();

  stroke(0);
  fill(0);

  if (do_dynamicDepth == true) {
    // dynamic depth determined if needed
    String key_string = Integer.toString(node_path[0]) + "_" + Integer.toString(dynamicMaxNodes);
    if (max_depth_calc.containsKey(key_string)) {
      String temp = (String) max_depth_calc.get(key_string);  // get stored value
      max_depth = parseFloat((String) max_depth_calc.get(key_string));  // reset global variable
    } else {
      float local_max_depth = maxDepth(node_path[0]);  // start with the largest depth for this node
      while (countNodes(node_path[0], 0, local_max_depth) > dynamicMaxNodes) {
        // Adjust local_max_depth down until it displays no more than the limit set to number of nodes
        local_max_depth = local_max_depth * dynamicAdjust;
      }
      max_depth_calc.put(key_string, Float.toString(local_max_depth));  // store value
      max_depth = local_max_depth;  // reset global variable
    }
  }

  // Not in animation - node path has just one entry.
  if (node_path.length == 1) {
    int basenode_ID = node_path[0];
    if (treeoflife_positions.existsInstance(node_path[0], max_depth)) {
      // get stored tree
      treegraph_current = treeoflife_positions.getInstance(node_path[0],max_depth);
    }
    else {
      treegraph_current = treeoflife_positions.makeInstance(node_path[0], max_depth); // make tree object
      float num_ends = countEnds(node_path[0], 0, max_depth);                           // number of ends that will be visible
      calculateTree( treegraph_current, treeoflife.root.node_ID, 'b', 0, num_ends );  // calculate graphed positions
      if (do_nudgeNodes == true) {
        // nudge node positions so that no labels overlap
        while (nudgeNodes( treegraph_current )) {
        };
      } else if (do_hideOverlapNodes == true) {
        // hide nodes (child hidden before parent) so no labels overlap
        hideOverlapNodes( treegraph_current );
      }
    }
    
    visible_node_positions = new int[0][3];  // Always clear before calling drawTree
    drawTree(treegraph_current, treeoflife.root.node_ID);  // do the graphics
  } 
  
  else {
  // In animation through a series of nodes
    if (!(node_path.length > 1)) {
      // confirm that path is longer than one (not empty)
      println("ERROR");
    } 
    else {
      float max_depth2 = max_depth;  // depth of "next tree" defaults to same as "current tree"
      // get dynamic depth for next tree if needed
      if (do_dynamicDepth == true) {
        // dynamic depth determined for next tree if needed
        String key_string = Integer.toString(node_path[1]) + "_" + Integer.toString(dynamicMaxNodes);
        if (max_depth_calc.containsKey(key_string)) {
          String temp = (String) max_depth_calc.get(key_string);  // get stored value
          max_depth2 = parseFloat((String) max_depth_calc.get(key_string)); // set main variable
        } else {
          float local_max_depth = maxDepth(node_path[1]);   // default to maximum depth
          while (countNamedNodes(node_path[1], 0, local_max_depth) > dynamicMaxNodes) {
            // trim depth down until it displays no more than the limit set to number of nodes
            local_max_depth = local_max_depth * dynamicAdjust;
          }
          max_depth_calc.put(key_string, Float.toString(local_max_depth));
          max_depth2 = local_max_depth; // set main variable
        }
      }
      
      // current graph
      if (treeoflife_positions.existsInstance(node_path[0], max_depth)) {
        treegraph_current = treeoflife_positions.getInstance(node_path[0],max_depth);
      } else {
        treegraph_current = treeoflife_positions.makeInstance(node_path[0], max_depth);
        float num_ends = countEnds(node_path[0], 0, max_depth);
        calculateTree( treegraph_current, treeoflife.root.node_ID, 'b', 0, num_ends );
        if (do_nudgeNodes == true) {
          while (nudgeNodes( treegraph_current )) {
          };
        } else if (do_hideOverlapNodes == true) {
          hideOverlapNodes( treegraph_current );
        }
      }
      // next graph
      if (treeoflife_positions.existsInstance(node_path[1], max_depth2)) {
        treegraph_next = treeoflife_positions.getInstance(node_path[1], max_depth2);
      } else {
        treegraph_next = treeoflife_positions.makeInstance(node_path[1], max_depth2);
        float num_ends = countEnds(node_path[1], 0, max_depth2);
        calculateTree( treegraph_next, treeoflife.root.node_ID, 'b', 0, num_ends );
        if (do_nudgeNodes == true) {
          while (nudgeNodes( treegraph_next )) {
          };
        } else if (do_hideOverlapNodes == true) {
          hideOverlapNodes( treegraph_next );
        }
      }
      
      // Draw intermediate tree
      visible_node_positions = new int[0][3];  // clear so clicking during animation doesn't give results
      drawIntermediateTree(treegraph_current, treegraph_next, between_node_progress, treeoflife.root.node_ID);

      // increase progress variable, remove first element of array if progress is complete to next node
      between_node_progress = between_node_progress + ( (node_path.length - 1.0) / steps_between_nodes);
      if (between_node_progress >= 0.9999) {
        // remake array without first element
        int[] new_node_path = { };
        for (int i = 1; i < node_path.length; i++) {
          new_node_path = append(new_node_path,node_path[i]);
        }
        node_path = new_node_path;
        between_node_progress = 0;
      }
    }
  }
  
}


