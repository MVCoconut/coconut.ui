package coconut.ui.internal;

import tink.state.*;
import tink.state.internal.*;

@:forward(value, assign)
abstract Attribute<T>(Impl<T>) {

  public inline function new(compute, ?comparator #if tink_state.debug , toString #end)
    this = new Impl(compute, comparator);
}

private class Impl<T> implements ObservableObject<T> extends Dispatcher {

  final dFault:()->T;
  var cur:Null<()->T>;
  final comparator:Comparator<T>;

  public var value(get, never):T;
    inline function get_value():T
      return (this:Observable<T>).value;

  public function new(compute:()->T, ?comparator) {
    super();
    this.comparator = comparator;
    this.dFault = compute;
  }

  public function assign(c:Null<()->T>)
    if (c != cur) {
      cur = c;
      fire(this);
    }

  public function getValue():T
    return switch cur {
      case null: dFault();
      case f: switch f() {
        case null: dFault();
        case v: v;
      }
    }

  public function isValid():Bool
    return false;//TODO: implement

  public function getComparator():Comparator<T>
    return comparator;
}