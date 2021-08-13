package coconut.ui.internal;

import tink.state.*;

@:fromHxx(
  transform = coconut.ui.internal.Variable.make(_)
)
@:forward
abstract Variable<T>(State<T>) from State<T> to State<T> {
  public inline function new(init)
    this = new State<T>(init);

  static public macro function make(e);
}