package coconut.ui.internal;

import tink.state.internal.*;

abstract Attribute<T>(AutoObservable<T>) {

  public var value(get, never):T;
    inline function get_value()
      return AutoObservable.track(this);

  public inline function new(compute, ?comparator)
    this = new AutoObservable(compute, comparator);

  public inline function assign(compute)
    this.swapComputation(compute);
}