package coconut.ui.internal;

import tink.state.*;
import tink.state.internal.*;

@:forward(value, assign)
abstract Attribute<T>(Impl<T>) {

  public inline function new(compute, ?comparator #if tink_state.debug , toString #end)
    this = new Impl(compute, comparator);
}

private class Impl<T> extends AutoObservable<T> {
  final dFault:()->T;
  final state:State<()->T>;

  public function new(compute:()->T, ?comparator) {
    this.state = new State(this.dFault = compute);
    super(() -> switch state.value {
      case null: dFault();
      case f: switch f() {
        case null: dFault();
        case v: v;
      }
    }, comparator);
  }

  public function assign(c:Null<()->T>)
    state.set(c);

}