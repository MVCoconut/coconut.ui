package coconut.ui.tools;

abstract Ref<T>({ current:T }) {

  public inline function new()
    this = { current: null };

  public var current(get, never):T;
    @:to inline function get_current():T
      return this.current;

  inline function reset()
    this.current = null;

  @:to function toCallback():tink.core.Callback<T>
    return toFunction();

  @:to function toFunction():T->Void
    return function (value) return this.current = value;

}