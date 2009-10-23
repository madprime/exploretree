// contains:
//  float[] calculateTree
//  float[] drawTree
//  float[] radial_to_xy

// calculateTree recursively calculates the graphing information for all nodes for a given TreeGraphInstance. 
// The function should be called from outside with the following parameters:
// curr_ID as root node of the entire tree, on_side = 'b', end_nodes_filled = 0, 
// total_end_nodes as calculated by count_end_nodes  ****** NEED TO WRITE THIS ******
float[] calculateTree ( TreeGraphInstance treegraph, int curr_ID, char on_side, float end_nodes_filled, int total_end_nodes ) {
  
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
        for (int i = 0; i < curr_node.children.length; i++) {
          if (curr_node.children[i] != curr_ID) { // skip child if it's the same as parent to prevent recursion at root
            radial_position[0] = 0;
            radial_position[1] = PI / 2;
            xy_position = radial_to_xy(radial_position);
            treegraph.addPosition(curr_ID,false,xy_position[0],xy_position[1]);
            char inherit_side = 'r';  // child nodes "before" are on the right because of radial coords
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
          treegraph.addPosition(curr_ID,true,xy_position[0],xy_position[1]);
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
                treegraph.addPosition(curr_ID,true,xy_position[0],xy_position[1]);
              } else {
                radial_position[1] = PI * (end_nodes_filled + 0.5) / total_end_nodes;
                end_nodes_filled += 1;
                xy_position = radial_to_xy(radial_position);
                treegraph.addPosition(curr_ID,true,xy_position[0],xy_position[1]);
              }
            } else {
              radial_position[0] = maxRadius;
              radial_position[1] = PI * (end_nodes_filled + 0.5) / total_end_nodes;
              end_nodes_filled += 1;
              xy_position = radial_to_xy(radial_position);
              treegraph.addPosition(curr_ID,true,xy_position[0],xy_position[1]);
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
      treegraph.addPosition(curr_ID,false,xy_position[0],xy_position[1]);
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
      treegraph.addPosition(curr_ID,false,xy_position[0],xy_position[1]);
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
      treegraph.addPosition(curr_ID,false,parent_plot_data.x_coord,parent_plot_data.y_coord);
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

int countEnds ( int curr_ID, float depth ) {
  int ends = 0;
  TreeNode curr_node = treeoflife.getNode(curr_ID);
  if (curr_node.children.length > 0 && depth < maxDepth) {
    for (int i = 0; i < curr_node.children.length; i++) {
      if (curr_node.children[i] != curr_ID) {            // prevents recursion at base node
        TreeNode child_node = treeoflife.getNode(curr_node.children[i]);
        ends = ends + countEnds(curr_node.children[i], depth + child_node.distance);
      }
    }
  } else {
    ends = 1;
println("returning an end at " + curr_ID);
  }
  return ends;
}

void drawTree(TreeGraphInstance treegraph, int curr_ID) {
  //println("Printing tree at " + curr_ID);
  TreeNode curr_node = treeoflife.getNode(curr_ID);
  NodePlotData curr_data = treegraph.getPosition(curr_ID);
    
  if (curr_node.children.length > 0) {
    for (int i = 0; i < curr_node.children.length; i++) {
      if (curr_node.children[i] != curr_ID) {   // prevent infinite recursion at root
        NodePlotData child_data = treegraph.getPosition(curr_node.children[i]);
        if (child_data.is_visible) {
          line(curr_data.x_coord,curr_data.y_coord,child_data.x_coord, child_data.y_coord);
        } else {
        //  println("Child node not visible: " + curr_node.children[i]);
        }
        drawTree(treegraph, curr_node.children[i]);
      }
    }
  }
  if (curr_data.is_visible) {
    String name = curr_node.node_name;
    textAlign(CENTER,BOTTOM);
    name = name.replace("_"," ");
    textFont(plot_font);
    text(name,curr_data.x_coord,curr_data.y_coord);  
    int[] posarraydata = { (int) (curr_data.x_coord + 0.5), (int) (curr_data.y_coord + 0.5), curr_ID };
    visible_node_positions = (int[][]) append(visible_node_positions, posarraydata);
  }
}

void drawIntermediateTree(TreeGraphInstance treegraph_from, TreeGraphInstance treegraph_to, float how_far, int curr_ID)  {
  TreeNode curr_node = treeoflife.getNode(curr_ID);
  NodePlotData curr_data_from = treegraph_from.getPosition(curr_ID);
  NodePlotData curr_data_to = treegraph_to.getPosition(curr_ID);
//println(curr_data_from.x_coord);
//println(curr_data_to.x_coord);
  float curr_x = (curr_data_from.x_coord) * (1 - how_far) + curr_data_to.x_coord * (how_far);
  float curr_y = (curr_data_from.y_coord) * (1 - how_far) + curr_data_to.y_coord * (how_far);
  float visibility = 0;
  if ( curr_data_from.is_visible ) {
    visibility = visibility + (1 - how_far);
  }
  if ( curr_data_to.is_visible ) {
    visibility = visibility + (how_far);
  }  
  if (curr_node.children.length > 0) {
    for (int i = 0; i < curr_node.children.length; i++) {
      if (curr_node.children[i] != curr_ID) {   // prevent infinite recursion at root
        NodePlotData child_data_from = treegraph_from.getPosition(curr_node.children[i]);
        NodePlotData child_data_to = treegraph_to.getPosition(curr_node.children[i]);
        float child_x = (child_data_from.x_coord) * (1 - how_far) + (child_data_to.x_coord) * (how_far);
        float child_y = (child_data_from.y_coord) * (1 - how_far) + (child_data_to.y_coord) * (how_far);
        float child_visibility = 0;
        if (child_data_from.is_visible) {
          child_visibility = child_visibility + (1 - how_far);
        }
        if (child_data_to.is_visible) {
          child_visibility = child_visibility + (how_far);
        }
        if ( child_visibility > 0.001) {
          line(curr_x,curr_y,child_x, child_y);
        }
        drawIntermediateTree(treegraph_from, treegraph_to, how_far, curr_node.children[i]);
      }
    } 
  }
  fill(0,255 * visibility);
  String name = curr_node.node_name;
  textAlign(CENTER,BOTTOM);
  name = name.replace("_"," ");
  textFont(plot_font);
  //println(name);
  text(name,curr_x,curr_y);
  
  int[] posarraydata = { (int) (curr_x + 0.5), (int) (curr_y + 0.5), curr_ID };
  visible_node_positions = (int[][]) append(visible_node_positions, posarraydata);  
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
  float r = pow(pow(x-centerX,2) + pow(centerY-y,2),0.5);
  float theta = atan((centerY-y)/(x-centerX));
  float[] returndata = {r, theta};
  return returndata;
}
