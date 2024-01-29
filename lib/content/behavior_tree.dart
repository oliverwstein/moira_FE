import 'package:flame/components.dart';
enum NodeState { success, failure, running }
class BehaviorTree extends Component {
  final BehaviorTreeNode rootNode;

  BehaviorTree(this.rootNode);

  @override
  void update(double dt) {
    super.update(dt);
    if (rootNode.state != NodeState.running) {
      rootNode.state = NodeState.running; // Reset the tree if it finished processing
    }
  }
}

abstract class BehaviorTreeNode extends Component {
  NodeState state = NodeState.running;
  @override
  void onLoad() {
    children.register<BehaviorTreeNode>();
  }
}

class ActionNode extends BehaviorTreeNode {
  final Function action;

  ActionNode(this.action);

  @override
  update(double dt) {
    state = action() ? NodeState.success : NodeState.failure;
  }
}

class ConditionNode extends BehaviorTreeNode {
  final Function condition;

  ConditionNode(this.condition);

  @override
  update(double dt) {
    state = condition() ? NodeState.success : NodeState.failure;
  }
}

class SelectorNode extends BehaviorTreeNode {
  @override
  void update(double dt) {
    super.update(dt);

    // If any child succeeds, the selector succeeds
    for (final child in children.query<BehaviorTreeNode>()) {
      if (child.state == NodeState.success) {
        state = NodeState.success;
        return;
      }
    }

    // If any child is still running, the selector is still running
    if (children.query<BehaviorTreeNode>().any((child) => child.state == NodeState.running)) {
      state = NodeState.running;
    } else {
      // All children have failed
      state = NodeState.failure;
    }
  }
}

class SequenceNode extends BehaviorTreeNode {
  @override
  void update(double dt) {
    super.update(dt);

    // If any child fails, the sequence fails
    for (final child in children.query<BehaviorTreeNode>()) {
      if (child.state == NodeState.failure) {
        state = NodeState.failure;
        return;
      }
    }

    // If any child is still running, the sequence is still running
    if (children.query<BehaviorTreeNode>().any((child) => child.state == NodeState.running)) {
      state = NodeState.running;
    } else {
      // All children have succeeded
      state = NodeState.success;
    }
  }
}
class InverterNode extends BehaviorTreeNode {
  // Assuming only one child is allowed for decorator nodes
  BehaviorTreeNode? get child => children.query<BehaviorTreeNode>().firstOrNull;

  @override
  void update(double dt) {
    super.update(dt);

    final childNode = child;
    if (childNode == null) {
      state = NodeState.failure; // No child to invert
      return;
    }

    // Invert the child's state
    switch (childNode.state) {
      case NodeState.success:
        state = NodeState.failure;
        break;
      case NodeState.failure:
        state = NodeState.success;
        break;
      case NodeState.running:
        state = NodeState.running;
        break;
    }
  }
}

class SucceederNode extends BehaviorTreeNode {
  @override
  void update(double dt) {
    // Regardless of the child's state, Succeeder always reports success
    state = NodeState.success;
  }
}

