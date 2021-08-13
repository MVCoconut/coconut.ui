package coconut.ui.internal;

import tink.state.*;
import tink.state.internal.*;

@:forward(value, assign)
abstract Controlled<T>(Impl<T>) {

  public inline function new(compute, ?comparator)
    this = new Impl(compute, comparator);
}

private class Impl<T> implements ObservableObject<T> extends Dispatcher {

  final fallback:tink.core.Lazy<State<T>>;
  var cur:Null<State<T>>;
  final comparator:Comparator<T>;

  public var value(get, set):T;
    inline function get_value():T
      return state().value;

    inline function set_value(param):T
      return state().value = param;

  inline function state()
    return switch cur {
      case null: fallback.get();
      case v: v;
    }

  public function new(fallback, ?comparator) {
    super();
    this.comparator = comparator;
    this.fallback = fallback;
  }

  public function assign(c:Null<State<T>>)
    if (c != cur) {
      cur = c;
      fire(this);
    }

  public function getValue():T
    return state().value;

  public function isValid():Bool
    return false;//TODO: implement

  public function getComparator():Comparator<T>
    return comparator;
}