package coconut.ui.internal;

import tink.state.*;
using tink.CoreApi;
#if macro
  using tink.MacroApi;
#end

class ImplicitContext {

  final parent:Lazy<Null<ImplicitContext>>;
  final slots = new Map<TypeKey<Dynamic>, Attribute<Dynamic>>();

  public function new(?parent) {
    this.parent = switch parent {
      case null: ORPHAN;
      case v: v;
    }
  }

  static final ORPHAN:Lazy<Null<ImplicitContext>> = (null:ImplicitContext);

  public function get<T>(key:TypeKey<T>):Null<T>
    return switch getSlot(key).value {
      case null:
        switch parent.get() {
          case null: null;
          case ctx: ctx.get(key);
        }
      case v: v;
    }

  function getSlot(key)
    return switch slots[key] {
      case null: slots[key] = new Attribute(() -> Noise);// in theory, creating slots and never destroying them leaks ... in practice, the key set for every context should always be small and well-bound, and typically constant
      case v: v;
    }

  public function update(values:ImplicitValues) {

    for (k => slot in slots)
      if (!values.exists(k)) slot.assign(null);

    for (k => v in values)
      getSlot(k).assign(v);
  }

  static public macro function with(e);
}

abstract TypeKey<T>({}) to {} {
  @:from static function ofClass<T>(t:Class<T>):TypeKey<T>
    return cast t;
  @:from static function ofEnum<T>(t:Enum<T>):TypeKey<T>
    return cast t;
}

@:pure
@:forward(exists, get, keyValueIterator)
@:fromHxx(
  transform = coconut.ui.internal.ImplicitContext.with(_)
)
abstract ImplicitValues(Map<TypeKey<Dynamic>, tink.hxx.Expression<Dynamic>>) {
  public function new(a:Array<SingleImplicit>) this = [for (o in a) o.key => o.val];
}

class SingleImplicit {
  public final key:TypeKey<Dynamic>;
  public final val:tink.hxx.Expression<Dynamic>;

  public function new<T>(key:TypeKey<T>, val:tink.hxx.Expression<T>) {
    this.key = key;
    this.val = val;
  }
}