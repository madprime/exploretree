// contains:
//  float[] calculateTree
//  float[] drawTree
//  float[] radial_to_xy

// calculateTree recursively calculates the graphing information for all nodes for a given TreeGraphInstance. 
// The function should be called from outside with the following parameters:
// curr_ID as root node of the entire tree, on_side = 'b', end_nodes_filled = 0, 
// total_end_nodes as calculated by count_end_nodes
float[] calculateTree ( TreeGraphInstance treegraph, int curr_ID, char on_side, float end_nodes_filled, float total_end_nodes ) {
  
//println("Running calculateTree on " + curr_ID + ", case " + on_side);
  float[] radial_position = new float[2];
  float[] xy_position = new float[2];
  // defaults
  //radial_position[0] = 0;
  //radial_position[1] = PI / 2.0;
  //xy_position = radial_to_xy(radial_position);

  TreeNode curr_node = treeoflife.getNode(curr_ID);
  
  switch(on_side) {
    case 'b':  // below/before or inside graphed tree
      if (treeoflife.isAncestorOf(curr_ID, treegraph.base_node_ID)) {
//println("...is ancestor of " + treegraph.base_node_ID);
        // This node is ancestor to the base node, we can assume there are children
        char inherit_side = 'r';  // child nodes "before" are on the right because of radial coords
        for (int i = 0; i < curr_node.children.length; i++) {
          if (curr_node.children[i] != curr_ID) { // skip child if it's the same as parent to prevent recursion at root
            radial_position[0] = 0;
            radial_position[1] = PI / 2;
            xy_position = radial_to_xy(radial_position);
            treegraph.addPosition(curr_ID,false,xy_position[0],xy_position[1],radial_position[0],radial_position[1]);
            if (treeoflife.isAncestorOf(curr_node.children[i],treegraph.base_node_ID) || (curr_node.children[i] == treegraph.base_node_ID)) {
              calculateTree( treegraph, curr_node.children[i], 'b', end_nodes_filled, total_end_nodes );
              inherit_side = 'l';
            } else {
              calculateTree( treegraph, curr_node.children[i], inherit_side, end_nodes_filled, total_end_nodes );
            }
          }
        }
      }
      else {
        if (curr_ID == treegraph.base_node_ID) {
//println("Is base!");
          // This is the base node
          radial_position[0] = 0;
          radial_position[1] = PI / 2;
          xy_position = radial_to_xy(radial_position);
          treegraph.addPosition(curr_ID,true,xy_position[0],xy_position[1], radial_position[0], radial_position[1]);
          if (curr_node.children.length > 0) {
            for (int i = 0; i < curr_node.children.length; i++) {
              if (curr_node.children[i] != curr_ID) { // skip child if it's the same as parent to prevent recursion at root
                float[] returned_data = calculateTree( treegraph, curr_node.children[i], 'b', end_nodes_filled, total_end_nodes );
                end_nodes_filled = returned_data[0];
              }
            }
          } else {
            end_nodes_filled++;
          }
        }
        else {
//println("Is drawn...");
          // This is after the base node
          if (treeoflife.isAncestorOf(treegraph.base_node_ID,curr_ID)) { // Should always be true, this is an error check
            float distance = treeoflife.getDist(treegraph.base_node_ID,curr_ID);  
 
            if (distance < treegraph.depth) {
//println("Not max depth... " + maxRadius);
              radial_position[0] = maxRadius * (distance / treegraph.depth);
              if (curr_node.children.length > 0) {
                float sum_radial = 0;
                for (int i = 0; i < curr_node.children.length; i++) {
                  float[] returned_data = calculateTree( treegraph, curr_node.children[i], 'b', end_nodes_filled, total_end_nodes );
                  end_nodes_filled = returned_data[0];
                  sum_radial += returned_data[1];
                }
                float ave_radial = sum_radial / curr_node.children.length;
                radial_position[1] = ave_radial;
                xy_position = radial_to_xy(radial_position);
//println("Radial pos: " + radial_position[0] + ", " + radial_position[1] + "... xy: " + xy_position[0] + ", " + xy_position[1]);
                treegraph.addPosition(curr_ID,true,xy_position[0],xy_position[1],radial_position[0],radial_position[1]);
              } else {
                radial_position[1] = PI * (end_nodes_filled + 0.5) / total_end_nodes;
                end_nodes_filled += 1;
                xy_position = radial_to_xy(radial_position);
                treegraph.addPosition(curr_ID,true,xy_position[0],xy_position[1],radial_position[0],radial_position[1]);
              }
            } else {
              radial_position[0] = maxRadius;
              radial_position[1] = PI * (end_nodes_filled + 0.5) / total_end_nodes;
              end_nodes_filled += 1;
              xy_position = radial_to_xy(radial_position);
              treegraph.addPosition(curr_ID,true,xy_position[0],xy_position[1],radial_position[0],radial_position[1]);
              if (curr_node.children.length > 0) {
                for (int i = 0; i < curr_node.children.length; i++) {
                  calculateTree( treegraph, curr_node.children[i], 'a', end_nodes_filled, total_end_nodes );
                }
              }
            }
            
          }
          else {  // This should be impossible
            println("ERROR");
          }
//println("drawn coord " + xy_position[0] + ", " + xy_position[1]);
        }
      }
      break;
    // Note: cases 'r', 'l', and 'a' are all self-propagating to children.
    case 'r':  // to the right of graphed tree
      radial_position[0] = 0;
      radial_position[1] = 0;
      xy_position = radial_to_xy(radial_position);
      treegraph.addPosition(curr_ID,false,xy_position[0],xy_position[1],radial_position[0],radial_position[1]);
      if (curr_node.children.length > 0) {
        for (int i = 0; i < curr_node.children.length; i++) {
          calculateTree( treegraph, curr_node.children[i], 'r', end_nodes_filled, total_end_nodes );
        }
      }
      break;
    case 'l':  // to the left of the graphed tree
      radial_position[0] = 0;
      radial_position[1] = PI;
      xy_position = radial_to_xy(radial_position);
      treegraph.addPosition(curr_ID,false,xy_position[0],xy_position[1],radial_position[0],radial_position[1]);
      if (curr_node.children.length > 0) {
        for (int i = 0; i < curr_node.children.length; i++) {
          calculateTree( treegraph, curr_node.children[i], 'l', end_nodes_filled, total_end_nodes );
        }
      }
      break;
    case 'a':  // above/after graphed tree
      NodePlotData parent_plot_data = treegraph.getPosition(curr_node.parent_ID);
      xy_position[0] = parent_plot_data.x_coord;  // inherit parent coordinates, but not visible
      xy_position[1] = parent_plot_data.y_coord;
      radial_position = xy_to_radial(xy_position);
      treegraph.addPosition(curr_ID,false,parent_plot_data.x_coord,parent_plot_data.y_coord,parent_plot_data.r,parent_plot_data.theta);
      if (curr_node.children.length > 0) {
        for (int i = 0; i < curr_node.children.length; i++) {
          calculateTree( treegraph, curr_node.children[i], 'a', end_nodes_filled, total_end_nodes );
        }
      }
      break;
  }
  float[] return_data = { end_nodes_filled, radial_position[1] };
  //println("Coordinates for " + curr_ID + " are " + xy_position[0] + ", " + xy_position[1]);
  return return_data;
}

float countEnds ( int curr_ID, float depth, float max_depth ) {
  float ends = 0;
  TreeNode curr_node = treeoflife.getNode(curr_ID);
  if (curr_node.children.length > 0 && depth < max_depth) {
    for (int i = 0; i < curr_node.children.length; i++) {
      if (curr_node.children[i] != curr_ID) {            // prevents recursion at base node
        TreeNode child_node = treeoflife.getNode(curr_node.children[i]);
        ends = ends + countEnds(curr_node.children[i], depth + child_node.distance, max_depth);
      }
    }
  } else {
    ends = 1;      
//println("returning an end at " + curr_ID);
  }
//println(ends);
  return ends;
}

int countNodes ( int curr_ID, float depth, float max_depth ) {
  int nodes = 1;
  TreeNode curr_node = treeoflife.getNode(curr_ID);
  if (curr_node.children.length > 0 && depth < max_depth) {
    for (int i = 0; i < curr_node.children.length; i++) {
      if (curr_node.children[i] != curr_ID) {            // prevents recursion at base node
        TreeNode child_node = treeoflife.getNode(curr_node.children[i]);
        nodes = nodes + countNodes(curr_node.children[i], depth + child_node.distance, max_depth);
      }
    }
  } else {
    nodes = 1;
//println("returning an end at " + curr_ID);
  }
  return nodes;
}

int countNamedNodes ( int curr_ID, float depth, float max_depth ) {
  int nodes = 0;
  TreeNode curr_node = treeoflife.getNode(curr_ID);
  if (curr_node.node_name.length() > 1) {
    nodes = 1;
    //println(curr_node.node_name + " has length larger than 1 and children " + curr_node.children.length);
  }
  if (curr_node.children.length > 0 && depth < max_depth) {
    for (int i = 0; i < curr_node.children.length; i++) {
      if (curr_node.children[i] != curr_ID) {            // prevents recursion at base node
        TreeNode child_node = treeoflife.getNode(curr_node.children[i]);
        nodes = nodes + countNamedNodes(curr_node.children[i], depth + child_node.distance, max_depth);
      }
    }
  }
//println("returning an end at " + curr_ID);
  return nodes;
}

float maxDepth ( int curr_ID ) {
//println("maxDepth: getting depth for " + curr_ID);
  float depth = 0;
  TreeNode curr_node = treeoflife.getNode(curr_ID);
  if (curr_node.children.length > 0) {
    float max_child_depth = 0;
    for (int i = 0; i < curr_node.children.length; i++) {
      float child_depth = 0;
      if (curr_node.children[i] != curr_ID) { // avoid recursion
        child_depth = (treeoflife.getNode(curr_node.children[i]).distance) + maxDepth(curr_node.children[i]);
      }
      if (max_child_depth < child_depth) {
        max_child_depth = child_depth;
      }
    }
    depth = max_child_depth;
  }
  return(depth);
}

boolean nudgeNodes (TreeGraphInstance treegraph) {
  boolean overlap_found = false;
  Object[] keys = treegraph.node_positions.keySet().toArray();
  for (int i = 0; i < keys.length - 1; i++) {
    Integer key_i = (Integer) keys[i];
    NodePlotData node1 = treegraph.getPosition(parseInt(key_i));
    if (node1.is_visible == true && node1.text_visible == true && treeoflife.getNode(node1.node_ID).node_name.length() > 0) {
      for (int j = i+1; j < keys.length; j++) {
        Integer key_j = (Integer) keys[j];
        NodePlotData node2 = treegraph.getPosition(parseInt(key_j));
        if (node2.is_visible == true && node2.text_visible == true && treeoflife.getNode(node2.node_ID).node_name.length() > 0) {
          NodePlotData high_node = node1;
          NodePlotData low_node = node2;
          if (node1.y_coord > node2.y_coord) {
            high_node = node2;
            low_node = node1;            
          }
          boolean vert_overlap = (high_node.y_coord + (font_size / 2)) >= (low_node.y_coord - (font_size / 2));
          if (vert_overlap) {
            NodePlotData left_node = node1;
            NodePlotData right_node = node2;
            if (node1.x_coord > node2.x_coord) {
              left_node = node2;
              right_node = node1;
            }
            float left_node_width = textWidth(treeoflife.getNode(left_node.node_ID).node_name);
            float right_node_width = textWidth(treeoflife.getNode(right_node.node_ID).node_name);
            boolean horiz_overlap = (left_node.x_coord + left_node_width / 2) > (right_node.x_coord - right_node_width / 2);
            if (horiz_overlap) {
              overlap_found = true;
              while (vert_overlap) {
                high_node.y_coord = high_node.y_coord - 1;
                vert_overlap = (high_node.y_coord + (font_size / 2)) >= (low_node.y_coord - (font_size / 2));
              }
              float[] temp_xy = { high_node.x_coord, high_node.y_coord };
              float[] temp_radial = xy_to_radial(temp_xy);
              high_node.r = temp_radial[0];
              high_node.theta = temp_radial[1];
            }
          }
        }
      }
    }
  }
  return(overlap_found);
}

boolean hideOverlapNodes (TreeGraphInstance treegraph) {
  boolean overlap_found = false;
  Object[] keys = treegraph.node_positions.keySet().toArray();
  for (int i = 0; i < keys.length - 1; i++) {
    Integer key_i = (Integer) keys[i];
    NodePlotData node1 = treegraph.getPosition(parseInt(key_i));
    if (node1.is_visible == true && treeoflife.getNode(node1.node_ID).node_name.length() > 0) {
      for (int j = i+1; j < keys.length; j++) {
        Integer key_j = (Integer) keys[j];
        NodePlotData node2 = treegraph.getPosition(parseInt(key_j));
        if (node2.is_visible == true && treeoflife.getNode(node2.node_ID).node_name.length() > 0) {
          NodePlotData high_node = node1;
          NodePlotData low_node = node2;
          if (node1.y_coord > node2.y_coord) {
            high_node = node2;
            low_node = node1;            
          }
          boolean vert_overlap = (high_node.y_coord + (font_size / 2)) >= (low_node.y_coord - (font_size / 2));
          if (vert_overlap) {
            NodePlotData left_node = node1;
            NodePlotData right_node = node2;
            if (node1.x_coord > node2.x_coord) {
              left_node = node2;
              right_node = node1;
            }
            float left_node_width = textWidth(treeoflife.getNode(left_node.node_ID).node_name);
            float right_node_width = textWidth(treeoflife.getNode(right_node.node_ID).node_name);
            boolean horiz_overlap = (left_node.x_coord + left_node_width / 2) > (right_node.x_coord - right_node_width / 2);
            if (horiz_overlap) {
              // hide farthest node
              overlap_found = true;
              float high_node_dist = treeoflife.getDist(treegraph.base_node_ID, high_node.node_ID);
              float low_node_dist = treeoflife.getDist(treegraph.base_node_ID, low_node.node_ID);
              if (low_node_dist < high_node_dist) {
                high_node.text_visible = false;
              } else {
                low_node.text_visible = false;
              }
            }
          }
        }
      }
    }
  }
  return overlap_found;
}

void drawTree(TreeGraphInstance treegraph, int curr_ID) {
  // Recursively plot tree from each node, then call this function for visible child nodes
  TreeNode curr_node = treeoflife.getNode(curr_ID);
  NodePlotData curr_data = treegraph.getPosition(curr_ID);
      
  if (curr_node.children.length > 0) {
    for (int i = 0; i < curr_node.children.length; i++) {
      
      boolean should_draw_to_child = (curr_node.children[i] != curr_ID)   // avoid infinite recursion at the root
                                        && (curr_data.is_visible             // current node is visible
                                          || treeoflife.isAncestorOf(curr_ID, treegraph.base_node_ID));   // or it descends from the base node 
      if (should_draw_to_child) {
        NodePlotData child_data = treegraph.getPosition(curr_node.children[i]);
        
        // if the child is visible, draw a line to it
        if (child_data.is_visible) {
          setColor(curr_ID, curr_node.children[i]);
          if (line_type == 'a') {
            noFill();
            drawArcLine(curr_data.x_coord, curr_data.y_coord, child_data.x_coord, child_data.y_coord);
          } else { 
            line(curr_data.x_coord,curr_data.y_coord,child_data.x_coord, child_data.y_coord);
          }
        } else {
          if (do_dotted_ends == true && curr_data.is_visible) {
            NodePlotData from_node_data;
            if (line_type == 'a') {
              from_node_data = treegraph.getPosition(treegraph.base_node_ID);
            } else {
              from_node_data = treegraph.getPosition(curr_node.parent_ID);
            }
            // Get slope of dotted line. Then get coords, using length of frac_of_radius * maxRadius.
            float slope = (curr_data.y_coord - from_node_data.y_coord) / (curr_data.x_coord - from_node_data.x_coord);
            float x_change = -1 * frac_of_radius * sqrt( pow(maxRadius,2) / (1 + pow(slope,2))) * (curr_data.x_coord - from_node_data.x_coord) / abs(curr_data.x_coord - from_node_data.x_coord);
            float y_change = slope * x_change;
            float x_end = curr_data.x_coord - x_change;
            float y_end = curr_data.y_coord - y_change;
            // Draw dotted line.
            int fragments = 3;
            for(int dot_step=2; dot_step<= fragments * 3; dot_step = dot_step + 3) {
              float x1 = lerp(curr_data.x_coord, x_end, dot_step/(3.0 * fragments));
              float y1 = lerp(curr_data.y_coord, y_end, dot_step/(3.0 * fragments));
              float x2 = lerp(curr_data.x_coord, x_end, (dot_step+1)/(3.0 * fragments));
              float y2 = lerp(curr_data.y_coord, y_end, (dot_step+1)/(3.0 * fragments));
              setColor(curr_ID, curr_node.children[i]);
              line(x1, y1, x2, y2);
              setColor(curr_ID, curr_node.children[i]);
              stroke(255, (dot_step) * (255 / (4 * fragments)));
              line(x1, y1, x2, y2);
            }
          }
        }
        drawTree(treegraph, curr_node.children[i]);
      }
    }
  }
  if (curr_data.is_visible && curr_data.text_visible) {
    String name = curr_node.node_name;
    textAlign(CENTER,BOTTOM);
    name = name.replace("_"," ");
    text(name,curr_data.x_coord,curr_data.y_coord);  
    int[] posarraydata = { (int) (curr_data.x_coord + 0.5), (int) (curr_data.y_coord + 0.5), curr_ID };
    visible_node_positions = (int[][]) append(visible_node_positions, posarraydata);
  }
}

void drawIntermediateTree(TreeGraphInstance treegraph_from, TreeGraphInstance treegraph_to, float how_far, int curr_ID)  {
  // Recursively plot intermediate tree between "treegraph_from" and "treegraph_to", 
  // nodes are interpolations between their locations weighted according to "how_far"
  // "curr_ID" is the current node being drawn
  TreeNode curr_node = treeoflife.getNode(curr_ID);
  NodePlotData curr_data_from = treegraph_from.getPosition(curr_ID);  // current node in "from"
  NodePlotData curr_data_to = treegraph_to.getPosition(curr_ID);      // current node in "to"
  
  // get interpolation using radial coordinates, then convert to xy
  float[] curr_radial = new float[2];
  curr_radial[0] = (curr_data_from.r) * (1 - how_far) + curr_data_to.r * (how_far);
  curr_radial[1] = (curr_data_from.theta) * (1 - how_far) + curr_data_to.theta * (how_far);
  float[] curr_xy = radial_to_xy(curr_radial);
  
  // set visibility & text visibility as interpolation as well
  float visibility = 0;
  float text_visibility = 0;
  if ( curr_data_from.is_visible ) {
    visibility = visibility + (1 - how_far);
    if (curr_data_from.text_visible) {
      text_visibility = text_visibility + (1 - how_far);
    }
  }
  if ( curr_data_to.is_visible ) {
    visibility = visibility + (how_far);
    if (curr_data_to.text_visible) {
      text_visibility = text_visibility + how_far;
    }
  }
  
  // If there are children, need to recursively call this drawing function
  if (curr_node.children.length > 0) {
    for (int i = 0; i < curr_node.children.length; i++) {
      boolean should_draw_to_child = (curr_node.children[i] != curr_ID)   // avoid infinite recursion at the root
                                        && (curr_data_from.is_visible || curr_data_to.is_visible             // current node is visible in "from" or "to"
                                          || treeoflife.isAncestorOf(curr_ID, treegraph_from.base_node_ID)   // or it descends from the "from" base node 
                                          || treeoflife.isAncestorOf(curr_ID, treegraph_to.base_node_ID) );  // or it descends from the "to" base node
      if ( should_draw_to_child ) {
        // get child's interpolated position
        NodePlotData child_data_from = treegraph_from.getPosition(curr_node.children[i]);
        NodePlotData child_data_to = treegraph_to.getPosition(curr_node.children[i]);
        float[] child_radial = new float[2];
        child_radial[0] = (child_data_from.r) * (1 - how_far) + child_data_to.r * (how_far);
        child_radial[1] = (child_data_from.theta) * (1 - how_far) + child_data_to.theta * (how_far);
        float[] child_xy = radial_to_xy(child_radial);
        
        // get child's interpolated visibility
        float child_visibility = 0;
        if (child_data_from.is_visible) {
          child_visibility = child_visibility + (1 - how_far);
        }
        if (child_data_to.is_visible) {
          child_visibility = child_visibility + (how_far);
        }
        
        // if the child is at all visible...
        if ( child_visibility > 0.001) {
          // call setColor to color tree according to setColor's parameters
          setColor(curr_ID, curr_node.children[i]);
          // draw arc-type tree if "line_type" is "a"
          if (line_type == 'a') {
            noFill();
            drawArcLine(curr_xy[0], curr_xy[1], child_xy[0], child_xy[1]);
          }
          // otherwise draw v-branching tree
          else { 
            line(curr_xy[0],curr_xy[1],child_xy[0], child_xy[1]);
          }
        }
        // call drawIntermediateTree for the child node
        drawIntermediateTree(treegraph_from, treegraph_to, how_far, curr_node.children[i]);
      }
    } 
  }
  
  // Draw node nome  (after calling children so those lines are behind this)
  fill(0,255 * text_visibility);
  String name = curr_node.node_name;
  textAlign(CENTER,BOTTOM);
  name = name.replace("_"," ");
  text(name,curr_xy[0],curr_xy[1]);
  
  // Record position for later mouse click interaction
  int[] posarraydata = { (int) (curr_xy[0] + 0.5), (int) (curr_xy[1] + 0.5), curr_ID };
  visible_node_positions = (int[][]) append(visible_node_positions, posarraydata);  
}

void setColor(int node_ID, int child_ID) {
  int pointA = node_ID;
  int pointB = search_node_ID;
  if (search_node_ID == -1) {
    pointB = treeoflife.root.node_ID;
  }
  if (search_node_ID == -1) {
    // Default coloring
    String dist_key = Integer.toString(pointA) + "_" + Integer.toString(pointB);
    float distance;
    if (calc_distances.containsKey(dist_key)) {
      distance = (Float) calc_distances.get(dist_key);
    } else {
      distance = 1.0 * treeoflife.getDist(pointA, pointB);
      calc_distances.put(dist_key, (Float) distance);
    }
    float fraction_dist = distance / tree_height;
    color levelColor = lerpColor(start_color,end_color,fraction_dist,HSB);
    stroke(levelColor,100);
    strokeWeight(min_stroke_weight);
  } else {
    // The rest is search-for-node based coloring
    while ( treeoflife.isAncestorOf(pointA,search_node_ID) == false && pointA != treeoflife.root.node_ID) {
      pointA = treeoflife.getNode(pointA).parent_ID;
    }
    String dist_key = Integer.toString(pointA) + "_" + Integer.toString(pointB);
    float distance;
    if (calc_distances.containsKey(dist_key)) {
      distance = (Float) calc_distances.get(dist_key);
    } else {
      distance = 1.0 * treeoflife.getDist(pointA, pointB);
      calc_distances.put(dist_key, (Float) distance);
    }
    String dist2_key = Integer.toString(pointB) + "_" + Integer.toString(treeoflife.root.node_ID);
    float distance2;
    if (calc_distances.containsKey(dist2_key)) {
      distance2 = (Float) calc_distances.get(dist2_key);
    } else {
      distance2 = treeoflife.getDist(pointB, treeoflife.root.node_ID);
      calc_distances.put(dist2_key, (Float) distance2);
    }
    strokeWeight(max_stroke_weight);
    float fraction_dist = 1.0 - distance / distance2;
    if (fraction_dist < 0) {
      fraction_dist = 0;
    } else if (fraction_dist > 1) {
      fraction_dist = 1;
    }
    color levelColor = lerpColor(start_color,end_color,fraction_dist,HSB);
    if (treeoflife.isAncestorOf(child_ID,search_node_ID) || child_ID == search_node_ID) {
      stroke(levelColor,150);
      strokeWeight(max_stroke_weight);
    } else {
      stroke(levelColor,70);
      strokeWeight(min_stroke_weight);
    }
  }
}

void drawArcLine(float parent_x, float parent_y, float child_x, float child_y) {
  float[] coords_parent_xy = { parent_x, parent_y };
  float[] coords_child_xy = { child_x, child_y };
  float[] coords_parent_radial = xy_to_radial(coords_parent_xy);
  float[] coords_child_radial = xy_to_radial(coords_child_xy);
  if (coords_child_radial[1] < coords_parent_radial[1]) {
    arc(centerX, centerY, 2*coords_parent_radial[0], 2*coords_parent_radial[0], -1 * coords_parent_radial[1], -1 * coords_child_radial[1]);
  } else {
    arc(centerX, centerY, 2*coords_parent_radial[0], 2*coords_parent_radial[0], -1 * coords_child_radial[1], -1 * coords_parent_radial[1]);
  }
  float[] line_start_radial = {coords_parent_radial[0], coords_child_radial[1]};
  float[] line_start_xy = radial_to_xy(line_start_radial);
  float[] line_end_xy = radial_to_xy(coords_child_radial);
  line(line_start_xy[0], line_start_xy[1], line_end_xy[0], line_end_xy[1]);
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

// Convert xy coordinates to radial coordinates.
float[] xy_to_radial(float[] xypos) {
  float x = xypos[0];
  float y = xypos[1];
  float relative_X = x - centerX;
  float relative_Y = centerY - y;
  float r = pow(pow(x-centerX,2) + pow(centerY-y,2),0.5);
  float theta;
  // Assumption is that y >= 0
  if (relative_X > 0) {
    theta = atan(relative_Y/relative_X);
  }
  else {
    if (relative_X < 0) {
      theta = atan(relative_Y/relative_X) + PI;
    } else {
      theta = PI / 2;
    }
  }
  float[] returndata = {r, theta};
  return returndata;
}
