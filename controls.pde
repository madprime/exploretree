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

void drawDepthControls() {
  
  // Depth adjustment buttons
  fill(100);
  noStroke();
  textFont(display_font);
  textAlign(RIGHT,CENTER);
  String depthLabel = "Depth:";
  text(depthLabel,depthMinusButtonX - 12, depthButtonY - 2);
  rect(depthMinusButtonX-0.5*ButtonSize,depthButtonY-0.5*ButtonSize,ButtonSize,ButtonSize);
  rect(depthPlusButtonX-0.5*ButtonSize,depthButtonY-0.5*ButtonSize,ButtonSize,ButtonSize);
  fill(255);
  textAlign(CENTER,CENTER);
  String minus_sign = "-";
  String plus_sign = "+";
  text(minus_sign,depthMinusButtonX,depthButtonY-2);
  text(plus_sign,depthPlusButtonX,depthButtonY-2);
}

void reduceDepth() {
  if (node_path.length == 1) {  // Only adjust depth if we're not in animation
    if (do_dynamicDepth) {
      float local_max_depth = max_depth;
      int current_number_nodes = countNodes(node_path[0], 0, local_max_depth);
      while (countNodes(node_path[0], 0, local_max_depth) >= current_number_nodes) {
        // Adjust local_max_depth down until it displays no more than the limit set to number of nodes
        local_max_depth = local_max_depth * dynamicAdjust;
      }
      dynamicMaxNodes = countNodes(node_path[0], 0, local_max_depth);
    } else {
      float local_max_depth = maxDepth(node_path[0]);
      int current_number_nodes = countNodes(node_path[0], 0, max_depth);
      while (countNodes(node_path[0], 0, local_max_depth) >= current_number_nodes) {
        local_max_depth = local_max_depth * dynamicAdjust;
      }
      max_depth = local_max_depth;
    }
  }
}

void increaseDepth() {
  if (node_path.length == 1) {  // Only adjust depth if we're not in animation
    if (do_dynamicDepth) {
      float local_max_depth = max_depth;
      int current_number_nodes = countNodes(node_path[0], 0, local_max_depth);
      while (countNodes(node_path[0], 0, local_max_depth) <= current_number_nodes) {
        // Adjust local_max_depth down until it displays no more than the limit set to number of nodes
        local_max_depth = local_max_depth / dynamicAdjust;
      }
      dynamicMaxNodes = countNodes(node_path[0], 0, local_max_depth);
    } else {
      float local_max_depth = max_depth;
      int current_number_nodes = countNodes(node_path[0],0,max_depth);
      while (countNodes(node_path[0], 0, local_max_depth) <= current_number_nodes) {
        local_max_depth = local_max_depth / dynamicAdjust;
      }
      int new_number_of_nodes = countNodes(node_path[0], 0, local_max_depth);
      while (countNodes(node_path[0], 0, local_max_depth) <= new_number_of_nodes) {
        local_max_depth = local_max_depth / dynamicAdjust;
      }
      local_max_depth = local_max_depth * dynamicAdjust;  // overstepped by one, step back now
      max_depth = local_max_depth;
    }
  }
}
