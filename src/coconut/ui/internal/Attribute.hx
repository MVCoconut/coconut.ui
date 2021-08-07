package coconut.ui.internal;

import tink.state.internal.*;

@:forward(value)
abstract Attribute<T>(AutoObservable<T>) {

  public inline function new(compute, ?comparator)
    this = new AutoObservable(compute, comparator);

  public inline function assign(compute)
    this.swapComputation(compute);
}