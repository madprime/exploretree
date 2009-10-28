// ExploreTree is licensed under the GNU GPLv2 or higher, at your choice.
// It uses libnewicktree, which is code from the TreeJuxtaposer project
// and is licensed under the BSD license.
//
// Authors:  Madeleine Ball <mad-et@printf.net>,
//           Chris Ball <chris-et@printf.net>

// plot area variables
int sizeX = 600, sizeY = 600; // plot area size
float borderFrac = 0.1;      // fraction of space to leave on border
float treeAreaFrac = 0.6;     // vertical fraction of area to devote to tree drawing

// tree drawing variables
float max_depth = 2.4;
boolean do_dynamicDepth = true; float dynamicAdjust = 0.99; int dynamicMaxNodes = 24; HashMap max_depth_calc = new HashMap();
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

// graphing constants initialized in setup()
float plotY1, plotY2;    // top and bottom for plot area
float plotX1, plotX2;    // left and right for plot area
float centerX, centerY;  // center coordinates for tree
float maxRadius;         // maximum radius to draw tree
float tree_height;         // total tree height of the tree data loaded (not only that displayed)

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
int search_node_ID = -1;              // -1 if no search node target, node_ID of target if there is one
boolean searchBoxFocus = false;
String current_search_input = ""; int[] matched_IDs = new int[0]; String search_name = "";
int[][] search_match_positions = new int[0][3];       // array of arrays containing xpos, ypos, and nodeID of displayed matches
HashMap calc_distances = new HashMap();   // key is node pair ( node1 + "_" + node2 ), value is the distance (a float)

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
  searchBoxX1 = sizeX * (borderFrac / 2);
  searchBoxX2 = sizeX * (1 - borderFrac / 2);
  searchBoxY1 = plotY2;
  searchBoxY2 = sizeY * (1 - (borderFrac/2) );
  
  // set up tree structure global variables
  treeoflife = TreeReadNewick("treeoflife.tree");
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
  
  drawSearchArea();
  stroke(0);
  fill(0);

  // dynamic depth determined if needed
  if (do_dynamicDepth == true) {
    String key_string = Integer.toString(node_path[0]) + "_" + Integer.toString(dynamicMaxNodes);
    if (max_depth_calc.containsKey(key_string)) {
      String temp = (String) max_depth_calc.get(key_string);
      max_depth = parseFloat((String) max_depth_calc.get(key_string));
    } else {
      float local_max_depth = maxDepth(node_path[0]);
      while (countNodes(node_path[0], 0, local_max_depth) > dynamicMaxNodes) {
        local_max_depth = local_max_depth * dynamicAdjust;
      }
      max_depth_calc.put(key_string, Float.toString(local_max_depth));
      max_depth = local_max_depth;
    }
  }

  // Not in animation - node path has just one entry.
  if (node_path.length == 1) {
    int basenode_ID = node_path[0];
    if (treeoflife_positions.existsInstance(node_path[0], max_depth)) {
      treegraph_current = treeoflife_positions.getInstance(node_path[0],max_depth);
    }
    else {
      treegraph_current = treeoflife_positions.makeInstance(node_path[0], max_depth);
      int num_ends = countEnds(node_path[0], 0, max_depth);
      calculateTree( treegraph_current, treeoflife.root.node_ID, 'b', 0, num_ends );
      if (do_nudgeNodes == true) {
        while (nudgeNodes( treegraph_current )) {
        };
      } else if (do_hideOverlapNodes == true) {
        hideOverlapNodes( treegraph_current );
      }
    }
    visible_node_positions = new int[0][3];  // Always clear before calling drawTree
    drawTree(treegraph_current, treeoflife.root.node_ID);
    
  } else {
    // In animation - node path has more than one entry
    if (node_path.length > 1) {
      
      // dynamic depth determined if needed
      float max_depth2 = max_depth;
      if (do_dynamicDepth == true) {
        String key_string = Integer.toString(node_path[1]) + "_" + Integer.toString(dynamicMaxNodes);
        if (max_depth_calc.containsKey(key_string)) {
          String temp = (String) max_depth_calc.get(key_string);
          max_depth2 = parseFloat((String) max_depth_calc.get(key_string));
        } else {
          float local_max_depth = maxDepth(node_path[1]);
          while (countNamedNodes(node_path[1], 0, local_max_depth) > dynamicMaxNodes) {
            local_max_depth = local_max_depth * dynamicAdjust;
          }
          max_depth_calc.put(key_string, Float.toString(local_max_depth));
          max_depth2 = local_max_depth;
        }
      }
      
      // current graph
      if (treeoflife_positions.existsInstance(node_path[0], max_depth)) {
        treegraph_current = treeoflife_positions.getInstance(node_path[0],max_depth);
      } else {
        treegraph_current = treeoflife_positions.makeInstance(node_path[0], max_depth);
        int num_ends = countEnds(node_path[0], 0, max_depth);
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
        int num_ends = countEnds(node_path[1], 0, max_depth2);
        calculateTree( treegraph_next, treeoflife.root.node_ID, 'b', 0, num_ends );
        if (do_nudgeNodes == true) {
          while (nudgeNodes( treegraph_next )) {
          };
        } else if (do_hideOverlapNodes == true) {
          hideOverlapNodes( treegraph_next );
        }
      }

      visible_node_positions = new int[0][3];  // clear so clicking during animation doesn't give results
      drawIntermediateTree(treegraph_current, treegraph_next, between_node_progress, treeoflife.root.node_ID);

      // increase progress variable, remove first element of array if progress is complete to next node
      between_node_progress = between_node_progress + ( (node_path.length - 1.0) / steps_between_nodes);
//println("between_node_progress from " + treeoflife.getNode(node_path[0]).node_name + " going to " + treeoflife.getNode(node_path[1]).node_name + " is now " + between_node_progress);
      if (between_node_progress >= 0.9999) {
        // remake array without first element
        int[] new_node_path = { };
        for (int i = 1; i < node_path.length; i++) {
          new_node_path = append(new_node_path,node_path[i]);
        }
        node_path = new_node_path;
        between_node_progress = 0;
      }
    } else {
      println("ERROR");
    }
  }
  
}


void drawSearchArea() {
  search_match_positions = new int[0][3];
  // line to display search text input
  strokeWeight(1);
  if (searchBoxFocus == false) {
    stroke(120);
    fill(120);
  } else {
    stroke(0);
    fill(0);
  }
  textAlign(RIGHT,BOTTOM);
  textFont(display_font);
  String searchlinelabel = "Type to search for an organism:";
  text(searchlinelabel,searchBoxX1+170,searchBoxY1+45);
  textAlign(LEFT,BOTTOM);
  line(searchBoxX1+180,searchBoxY1+45,searchBoxX1+380,searchBoxY1+45);
  text(current_search_input,searchBoxX1+190,searchBoxY1+45);
  
  fill(200);
  noStroke();
  rect(searchBoxX1, searchBoxY1+60, (searchBoxX2 - searchBoxX1), searchBoxY2 - (searchBoxY1+60));
  
  boolean too_many_matches = false;
  float x_position = searchBoxX1;
  float y_position = searchBoxY1 + 60 + display_font_size + 5;
  textAlign(CENTER,CENTER);
  for (int i = 0; i < matched_IDs.length; i++) {
    float name_width = textWidth(treeoflife.getNode(matched_IDs[i]).node_name);
    x_position = x_position + name_width + 30;
    if (x_position > searchBoxX2) {
      x_position = searchBoxX1 + name_width + 30;
      y_position = y_position + display_font_size + 15;
    }
    if (y_position < searchBoxY2 - (display_font_size / 2)) {
      int[] position_data = { (int) (x_position - (20 + name_width)/2 + 0.5), (int) (y_position + 0.5), matched_IDs[i] };
      search_match_positions = (int[][]) append(search_match_positions, position_data);
    } else {
      // Too many matches!
      search_match_positions = new int[0][3];
      too_many_matches = true;
    }
  }
  
  stroke(0);
  fill(0);
  if (too_many_matches) {
    textAlign(LEFT, CENTER);
    String too_many_match_text = "Too many matches!  Try searching with a longer string.";
    text(too_many_match_text, searchBoxX1 + 10, searchBoxY1 + 60 + (display_font_size / 2) + 5);
  } else {
    if (matched_IDs.length > 0) {
      textAlign(CENTER,CENTER);
      for (int i = 0; i < matched_IDs.length; i++) {
        int[] position_data = search_match_positions[i];
        if (position_data[2] == search_node_ID) {
          fill(255);
          noStroke();
          float text_width = textWidth(treeoflife.getNode(position_data[2]).node_name);
          ellipse(position_data[0],position_data[1]+1,text_width+display_font_size,display_font_size*2);
          fill(0);
          stroke(0);
        }
        String curr_name = treeoflife.getNode(position_data[2]).node_name;
        curr_name = curr_name.replace("_"," ");
        text(curr_name,position_data[0],position_data[1]);
      }
    }
  }
}

int[] searchNodes(String searched_name) {
  int[] matched_IDs = new int[0];
  Object[] keys = treeoflife.tree_data.keySet().toArray();
  if (searched_name.length() > 0) {
    for (int i = 0; i < keys.length - 1; i++) {
      Integer key_i = (Integer) keys[i];
      TreeNode curr_node = treeoflife.getNode(key_i);
      String curr_name = treeoflife.getNode(key_i).node_name;
      if (curr_name.length() > 0) {
        String[] matched_IDs_temp1 = match(searched_name.toLowerCase(), curr_name.toLowerCase());
        String[] matched_IDs_temp2 = match(curr_name.toLowerCase(), searched_name.toLowerCase());
        if (matched_IDs_temp1 != null || matched_IDs_temp2 != null) {
        matched_IDs = append(matched_IDs, (int) key_i);
        }
      }
    }
  }
  return matched_IDs;
}
