
void mousePressed() {
  float minDist = 30;                                 // don't change position unless at least this close to a node
  int closestNode = node_path[node_path.length - 1];  // default to the latest target base node

  for (int i=0; i<visible_node_positions.length; i++) {
    float distance = pow( (pow((mouseX - visible_node_positions[i][0]),2) + pow((mouseY - visible_node_positions[i][1]),2)), 0.5 );
    if (distance < minDist) {
      closestNode = visible_node_positions[i][2];
      minDist = distance;
    }
  }
  if (closestNode != node_path[0] && closestNode != node_path[node_path.length - 1]) {
    println("node_path " + closestNode + " length is now " + node_path.length);
    node_path = treeoflife.getNodePath(node_path[0],closestNode);
    //node_path = append(node_path, closestNode);
    println("Appended to node_path " + closestNode + ". length is now " + node_path.length);
  }
  
/*  if (abs(mouseX - (plotX1+170)) <= 200 && abs(mouseY - (plotY2+39)) <= 12) {
    searchBoxFocus = 1;
  } else {
    searchBoxFocus = 0;
  }
  if (abs(mouseX - depthMinusButtonX) <= (ButtonSize / 2) && abs(mouseY - depthButtonY) <= (ButtonSize / 2) && maxDepth > 2) {
    maxDepth--;
  }
  else if (abs(mouseX - depthPlusButtonX) <= (ButtonSize / 2) && abs(mouseY - depthButtonY) <= ButtonSize / 2) {
    maxDepth++;
  }
  else if (abs(mouseX - fontMinusButtonX) <= (ButtonSize / 2) && abs(mouseY - fontButtonY) <= (ButtonSize / 2) && font_size > 1) {
    font_size--;
    plot_font = createFont("Arial",font_size);
  }
  else if (abs(mouseX - fontPlusButtonX) <= (ButtonSize / 2) && abs(mouseY - fontButtonY) <= ButtonSize / 2) {
    font_size++;
    plot_font = createFont("Arial",font_size);
  }
  else if ( (abs(mouseX - navLeftButtonX) <= (ButtonSize / 2) && abs(mouseY - navOutButtonY) <= ButtonSize / 2) || (abs(mouseX - navDownButtonX) <= (ButtonSize / 2) && abs(mouseY - navOutButtonY) <= ButtonSize / 2) ) {
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
  }
  else if ( ((abs(mouseX - navUpButtonX) <= (ButtonSize / 2) && abs(mouseY - navInButtonY) <= ButtonSize / 2) || (abs(mouseX - navRightButtonX) <= (ButtonSize / 2) && abs(mouseY - navInButtonY) <= ButtonSize / 2)) && (search_node > 0)) {
    int[] search_node_to_root_path = nodePath(search_node,0);
    for (int i = 1; i < search_node_to_root_path.length; i++) {
      if (node_path[node_path.length-1] == search_node_to_root_path[i]) {
        node_path = append(node_path,search_node_to_root_path[i-1]);
      }
    }
  }

  
  if (closestNode != node_path[0] && mouseButton == LEFT) {
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
else if (mouseButton == RIGHT) {
      String name = treeoflife.getNodeByKey(closestNode).getName();
      if (name.length() > 0) {
        String url = "http://en.wikipedia.org/wiki/" + name;
        link(url, "_new"); 
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
    //println(new_search_result);
  }
  */
}

void keyPressed() {
  if (key == CODED && (keyCode == DOWN || keyCode == LEFT)) { 
    TreeNode curr_node = treeoflife.getNode(node_path[node_path.length - 1]);
    if (curr_node.parent_ID != node_path[node_path.length - 1] && treeoflife.root.node_ID != curr_node.node_ID) {
      node_path = append(node_path, curr_node.parent_ID);
      //println("Appended to node_path " + curr_node.parent_ID + ". length is now " + node_path.length);
    }
  }
  /* else if (key == CODED && (keyCode == UP || keyCode == RIGHT) && (search_node > 0)) {
    int[] search_node_to_root_path = nodePath(search_node,0);
    for (int i = 1; i < search_node_to_root_path.length; i++) {
      if (node_path[node_path.length-1] == search_node_to_root_path[i]) {
        node_path = append(node_path,search_node_to_root_path[i-1]);
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
  } */
}


