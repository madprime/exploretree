
void mousePressed() {
  float minDist = 30;                                 // don't change position unless at least this close to a node
  int closestNode = node_path[node_path.length - 1];  // default to the latest target base node

  boolean target_found = false;
  // search-for-node node choice by clicking on the displayed name
  
  if (abs(mouseX - depthMinusButtonX) <= (ButtonSize / 2) && abs(mouseY - depthButtonY) <= (ButtonSize / 2)) {
    reduceDepth();
    target_found = true;
  } else if (abs(mouseX - depthPlusButtonX) <= (ButtonSize / 2) && abs(mouseY - depthButtonY) <= ButtonSize / 2) {
    increaseDepth();
    target_found = true;
  }
  
  if (! target_found) {
    for (int i=0; i < search_match_positions.length; i++) {
      float distance = pow( (pow((mouseX - search_match_positions[i][0]),2) + pow((mouseY - search_match_positions[i][1]),2)), 0.5 );
      if (distance < minDist) {
        search_node_ID = search_match_positions[i][2];
        minDist = distance;
        target_found = true;
      }
    }
  }
  if (! target_found) {
    for (int i=0; i<visible_node_positions.length; i++) {
      float distance = pow( (pow((mouseX - visible_node_positions[i][0]),2) + pow((mouseY - visible_node_positions[i][1]),2)), 0.5 );
      if (distance < minDist) {
        closestNode = visible_node_positions[i][2];
        minDist = distance;
      }
    }
    if (closestNode != node_path[0] && closestNode != node_path[node_path.length - 1]) {
      //println("node_path " + closestNode + " length is now " + node_path.length);
      node_path = treeoflife.getNodePath(node_path[0],closestNode);
      //node_path = append(node_path, closestNode);
      //println("Appended to node_path " + closestNode + ". length is now " + node_path.length);
      target_found = true;
    }
  }
  if ( searchBoxX1 <= mouseX && searchBoxX2 >= mouseX && searchBoxY1 <= mouseY && searchBoxY2 >= mouseY) {
    searchBoxFocus = true;
  } else {
    searchBoxFocus = false;
  }
  
}

void keyPressed() {
  if (key == CODED && (keyCode == DOWN || keyCode == LEFT)) { 
    TreeNode curr_node = treeoflife.getNode(node_path[node_path.length - 1]);
    if (curr_node.parent_ID != node_path[node_path.length - 1] && treeoflife.root.node_ID != curr_node.node_ID) {
      node_path = append(node_path, curr_node.parent_ID);
      //println("Appended to node_path " + curr_node.parent_ID + ". length is now " + node_path.length);
    }
  }
  else if (key == CODED && (keyCode == UP || keyCode == RIGHT) && (search_node_ID > 0)) {
    // move forward with search-for-node if already on path to node
    if (treeoflife.isAncestorOf(node_path[node_path.length - 1],search_node_ID)) {
      int next_node = -1;
      for (int i = 0; i < treeoflife.getNode(node_path[node_path.length - 1]).children.length; i++) {
        int child_ID = treeoflife.getNode(node_path[node_path.length - 1]).children[i];
        if (child_ID == search_node_ID || treeoflife.isAncestorOf(child_ID, search_node_ID)) {
          next_node = child_ID;
        }
      }
      if (next_node > 0) {
        node_path = (int[]) append(node_path, next_node);
      }
    }
  } else {
    if (searchBoxFocus) {
      if(key == ENTER)
      {
        matched_IDs = searchNodes(current_search_input);
        search_node_ID = -1;
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
}


