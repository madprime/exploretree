// contains:
//  class NodePlotData
//  class TreeGraphInstance
//  class TreePositions
//  class TreeNode
//  class Tree

// NodePlotData is plotting information for a single node
class NodePlotData {
  int node_ID;
  boolean is_visible;
  boolean text_visible;
  float x_coord;
  float y_coord;
  
  NodePlotData(int passed_node_ID, boolean passed_is_visible, float passed_x_coord, float passed_y_coord) {
    node_ID = passed_node_ID;
    is_visible = passed_is_visible;
    text_visible = true;
    x_coord = passed_x_coord;
    y_coord = passed_y_coord;
  }
}

// TreeGraphInstance stores all the NodePlotData for a given tree state
class TreeGraphInstance {
  // node_positions is the HashMap storing all the node data
  // key: node ID, value: NodePlotData object 
  int base_node_ID;
  float depth;
  HashMap node_positions;
  
  TreeGraphInstance(int passed_base_node_ID, float passed_depth) {
    base_node_ID = passed_base_node_ID;
    depth = passed_depth;
    node_positions = new HashMap();
  }
  
  void addPosition(int graphed_node_ID, boolean is_visible, float x_coord, float y_coord) {
    NodePlotData plotdata = new NodePlotData(graphed_node_ID, is_visible, x_coord, y_coord);
    node_positions.put(graphed_node_ID, plotdata);
  }
  
  NodePlotData getPosition(int graphed_node_ID) {
    NodePlotData position = (NodePlotData) node_positions.get(graphed_node_ID);
    return position;
  }   
}

// TreePositions stores all calculated TreeGraphInstances
class TreePositions {
  HashMap treegraph_instances;  // key is base node ID concatenated with depth, 
                                // value is a TreeGraphInstance object
  TreePositions() {
    treegraph_instances = new HashMap();
  }
  
  boolean existsInstance(int base_node_ID, float depth) {
    String key_ID = makeKeyString(base_node_ID, depth);
    if (treegraph_instances.containsKey(key_ID)) {
      return true;
    } else {
      return false;
    }
  }
  
  TreeGraphInstance makeInstance(int base_node_ID, float depth) {
    String key_ID = makeKeyString(base_node_ID, depth);
    TreeGraphInstance treegraph = new TreeGraphInstance(base_node_ID, depth);
    treegraph_instances.put(key_ID, treegraph);
    return treegraph;
  }
    
  TreeGraphInstance getInstance(int base_node_ID, float depth) {
    String key_ID = makeKeyString(base_node_ID, depth);
    return (TreeGraphInstance) treegraph_instances.get(key_ID);
  }
  
  NodePlotData getPosition(int base_node_ID, float depth, int node_ID) {
    String key_ID = makeKeyString(base_node_ID, depth);
    TreeGraphInstance treegraph = (TreeGraphInstance) treegraph_instances.get(key_ID);
    return treegraph.getPosition(node_ID);
  }
  
  private String makeKeyString(int base_node_ID, float depth) {
    String key_ID = Integer.toString(base_node_ID) + "_" + Float.toString(depth);
    return key_ID;
  }
}

// Each TreeNode within a Tree should have a unique non-negative int ID.
class TreeNode {
  int[] children;
  int node_ID;
  int parent_ID;
  String node_name;
  float distance;
  
  TreeNode(int input_node_ID, int input_parent_ID, String input_node_name, float input_distance) {
    node_ID = input_node_ID;
    parent_ID = input_parent_ID;
    node_name = input_node_name;
    children = new int[0];
    distance = input_distance;
  }
}

// Tree is the the main tree data structure.
class Tree {
  TreeNode root;
  HashMap tree_data;
  
  Tree(TreeNode input_root) {
    root = input_root;
    tree_data = new HashMap();
  }
  
  void addNode(TreeNode input_node) {
    //println("In addNode");
    // Check if this node exists; update or add as needed
    if (tree_data.containsKey(input_node.node_ID)) {
      
    } else {
      tree_data.put(input_node.node_ID,input_node);
    }
    // Check if parent exists; update or add as needed
    if (tree_data.containsKey(input_node.parent_ID)) {
      //println("Tree.addNode: Adding " + input_node.node_ID + " to children of " + input_node.parent_ID);
      TreeNode parent_node = (TreeNode) tree_data.get(input_node.parent_ID);
      parent_node.children = (int[]) append(parent_node.children, input_node.node_ID);
      //for (int i = 0; i < parent_node.children.length; i++) { println(parent_node.children[i]); };
      tree_data.put(input_node.parent_ID,parent_node);
    } else {
      TreeNode parent_node = new TreeNode(input_node.parent_ID,-1,"",1.0);
      //println("Tree.addNode: Making new parent node " + parent_node.node_ID + " with child " + input_node.node_ID);
      parent_node.children = (int[]) append(parent_node.children,input_node.node_ID);
      tree_data.put(input_node.parent_ID,parent_node);
    }
  }
  
  TreeNode getNode(int node_ID) {
    TreeNode node = (TreeNode) tree_data.get(node_ID);
    return node;
  }
  
  boolean isParentOf(int potential_parent_ID, int potential_child_ID) {
    boolean is_parent = false;
    TreeNode parent_node = treeoflife.getNode(potential_parent_ID);
    if (parent_node.children.length > 0) {
      for (int i = 0; i < parent_node.children.length; i++) {
        if (parent_node.children[i] != potential_parent_ID) {
          if (parent_node.children[i] == potential_child_ID) {
            is_parent = true;
          }
        }
      }
    }
    return is_parent;
  }
  
  boolean isAncestorOf(int potential_ancestor_ID, int potential_child_ID) {
    boolean is_ancestor = false;
    TreeNode ancestor_node = treeoflife.getNode(potential_ancestor_ID);
    if (ancestor_node.children.length > 0) {
      for (int i = 0; i < ancestor_node.children.length; i++) {
        if (ancestor_node.children[i] != potential_ancestor_ID) {
          if (ancestor_node.children[i] == potential_child_ID) {
            is_ancestor = true;
          } else {
            if (isAncestorOf(ancestor_node.children[i],potential_child_ID)) {
              is_ancestor = true;
            }
          }
        }
      }
    }
    return is_ancestor;
  }
  
  float getDist(int node1_ID, int node2_ID) {
    float distance;
    if (node1_ID == node2_ID) {
      distance = 0;
    } else {
      if (isAncestorOf(node1_ID, node2_ID)) {
        TreeNode node2 = treeoflife.getNode(node2_ID);
        distance = node2.distance + getDist(node1_ID,node2.parent_ID);
      } else {
        if (isAncestorOf(node2_ID, node1_ID)) {
          distance = getDist(node2_ID, node1_ID);
        } else {
          // need to find common ancestor
          TreeNode node1 = treeoflife.getNode(node1_ID);
          TreeNode node2 = treeoflife.getNode(node2_ID);
          while(node1.parent_ID != treeoflife.root.node_ID && node1.parent_ID != node2.parent_ID) {
            node2 = treeoflife.getNode(node2_ID);
            while (node2.parent_ID != treeoflife.root.node_ID && node1.parent_ID != node2.parent_ID) {
              node2 = treeoflife.getNode(node2.parent_ID);
            }
            if (node1.parent_ID != node2.parent_ID) {
              node1 = treeoflife.getNode(node1.parent_ID);
            }
          }
          distance = getDist(node1_ID,node1.parent_ID) + getDist(node2_ID,node1.parent_ID);
          //println("common parent to " + node1_ID + " and " + node2_ID + " is " + node1.parent_ID);
        }
      }
    }
    //println("distance between " + node1_ID + " and " + node2_ID + " is " + distance);
    return distance;
  }
  
  int[] getNodePath(int node_ID1, int node_ID2) {
    TreeNode Node1 = treeoflife.getNode(node_ID1);
    TreeNode Node2 = treeoflife.getNode(node_ID2);
  
    // first find paths to root node (key=0)
    int[] pathtoroot1 = {node_ID1};
    int[] pathtoroot2 = {node_ID2};
    while (pathtoroot1[pathtoroot1.length-1] != treeoflife.root.node_ID) {
      pathtoroot1 = append(pathtoroot1,Node1.parent_ID);
      Node1 = treeoflife.getNode(Node1.parent_ID);
    }
    while (pathtoroot2[pathtoroot2.length-1] != 0) {
      pathtoroot2 = append(pathtoroot2,Node2.parent_ID);
      Node2 = treeoflife.getNode(Node2.parent_ID);
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
}


