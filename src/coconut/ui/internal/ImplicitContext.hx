package coconut.ui.internal;

import tink.state.*;
import coconut.data.Value;
using tink.CoreApi;
#if macro
  using tink.MacroApi;
#end

class ImplicitContext {

  final parent:Lazy<Null<ImplicitContext>>;
  final slots = new Map<TypeKey<Dynamic>, Slot<Dynamic, Value<Dynamic>>>();

  public function new(?parent) {
    this.parent = switch parent {
      case null: ORPHAN;
      case v: v;
    }
  }

  static final ORPHAN:Lazy<Null<ImplicitContext>> = (null:ImplicitContext);
  static final NONE = Observable.const(new ImplicitValues([]));

  public function get<T>(key:TypeKey<T>):Null<T>
    return switch [getSlot(key).value, parent.get()] {
      case [null, null]: null;
      case [null, p]: p.get(key);
      case [v, _]: v;
    }

  function getSlot(key)
    return switch slots[key] {
      case null: slots[key] = new Slot(this);// in theory, creating slots and never destroying them leaks ... in practice, the key set for every context should always be small and well-bound, and typically constant
      case v: v;
    }

  public function update(values:ImplicitValues) {

    for (k => slot in slots)
      if (!values.exists(k)) slot.setData(null);

    for (k => v in values)
      getSlot(k).setData(v);
  }

  static public macro function with(e) {
    var exprs = switch e.expr { case EArrayDecl(a): a; default: [e]; };
    var entries = [for (e in exprs) switch e {
      case macro $k => $v:
        macro @:pos(e.pos) new coconut.ui.internal.ImplicitContext.SingleImplicit($k, $v);
      default: e.reject('expected key => value');
    }];
    return macro new coconut.ui.internal.ImplicitContext.ImplicitValues([$a{entries}]);
  }
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
abstract ImplicitValues(Map<TypeKey<Dynamic>, Value<Dynamic>>) {
  public function new(a:Array<SingleImplicit>) this = [for (o in a) o.key => o.val];
}

class SingleImplicit {
  public final key:TypeKey<Dynamic>;
  public final val:Value<Dynamic>;

  public function new<T>(key:TypeKey<T>, val:Value<T>) {
    this.key = key;
    this.val = val;
  }
}