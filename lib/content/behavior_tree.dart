import 'package:flame/components.dart';

abstract class BehaviorTreeNode extends Component {
    BehaviorTreeState state = BehaviorTreeState.running;

    BehaviorTreeState tick(double dt);

    void reset() {
        state = BehaviorTreeState.running;
    }
}

enum BehaviorTreeState { success, failure, running }