package coconut.ui;

@:callable
abstract Ref<T>(T->Void) from T->Void to T->Void {
  public inline function new(f)
    this = f;

  public inline function merge(other:Ref<T>) {
    return function(v) {
      this(v);
      other(v);
    }
  }

  @:from static macro function ofExpr(e);
}