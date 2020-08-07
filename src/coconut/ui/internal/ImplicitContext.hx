package coconut.ui.internal;

import tink.state.ObservableMap;

class ImplicitContext {
  final parent:Null<ImplicitContext>;
  final values:ObservableMap<TypeKey<Dynamic>, Dynamic> = new ObservableMap(cast new haxe.ds.ObjectMap());

  public function new(?parent) {
    this.parent = parent;
  }

  public function get<T>(key:TypeKey<T>, getDefault:()->T)
    return switch [values.get(key), parent] {
      case [null, null]: getDefault();
      case [null, p]: p.get(key, getDefault);
      case [v, _]: v;
    }

  public function update(values:ImplicitValues) {
    // TODO: this makes me realize that an atomic update for the whole map content would be nice
    {
      var old = [for (v in this.values.keys()) if (!values.exists(v)) v];
      for (o in old)
        this.values.remove(o);
    }
    for (k => v in values)
      this.values.set(k, v);
  }
}

abstract TypeKey<T>({}) to {} {
  @:from static function ofClass<T>(t:Class<T>):TypeKey<T>
    return cast t;
  @:from static function ofEnum<T>(t:Enum<T>):TypeKey<T>
    return cast t;
}

@:pure
@:forward(exists, keyValueIterator)
abstract ImplicitValues(Map<TypeKey<Dynamic>, Dynamic>) {
  inline function new(v) this = v;
}