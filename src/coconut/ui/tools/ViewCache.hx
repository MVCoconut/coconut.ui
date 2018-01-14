package coconut.ui.tools;

import tink.state.*;
using tink.CoreApi;

private class Stack<In, Out> {
  
  var counter = 0;
  var stored:Array<Out> = [];
  var create:In->?Out->Out;

  public function new(create) 
    this.create = create;

  public function purge() {
    stored.splice(counter, stored.length);
    counter = 0;
    return stored.length;
  }

  public function poll(data:In) {
    var ret = create(data, stored[counter]);
    if (counter == stored.length)
      stored[counter] = ret;
    counter++;
    return ret;
  }
}

private class Registry<In, Out> {
  var create:In->?Out->Out;
  var keyless:Stack<In, Out>;
  var byString = new Map<String, Stack<In, Out>>();
  var byObj = new Map<{}, Stack<In, Out>>();

  public function new(create) {
    this.create = create;
    this.keyless = new Stack(create);
  }

  @:extern inline function getStack<K>(m:Map<K, Stack<In, Out>>, key:K) 
    return switch m[key] {
      case null: m[key] = new Stack(create);
      case v: v;
    }

  @:extern inline function purgeMap<K>(m:Map<K, Stack<In, Out>>) {
    var remove = [];
    for (k in m.keys()) {
      var stack = m[k];
      if (stack.purge() == 0)
        remove.push(k);
    }
    for (k in remove)
      m.remove(k);
  }

  public function purge() {
    keyless.purge();
    purgeMap(byString);
    purgeMap(byObj);
  }

  public function poll(data:In, key:Key) {
    var stack = 
      if (key == null) keyless;
      else if (key.isString()) getStack(byString, cast key);
      else getStack(byObj, key);

    return stack.poll(data);    
  }
}

class ViewCache {
  static var stack = new Array<Ref<ViewCache>>();
  static inline function get() 
    return
      switch stack {
        case []:
          new ViewCache();
        case v:
          v[v.length - 1].value;
      }

  var __cache = new Map<String, Registry<Dynamic, Dynamic>>();
  var retainCount = 0;
  public function cached<T>(f:Void->T):T {
    if (stack.length > 0 && stack[stack.length - 1] == this) return f();
    var entry = Ref.to(this);//wrapping in entry to allow for reentrancy (no idea if that's needed though)
    stack.push(entry);
    retainCount++;
    return Error.tryFinally(f, function () {
      stack.remove(entry);
      if (--retainCount == 0) this.purge();
    });
  }

  inline function purge() 
    for (f in __cache) 
      f.purge();

  public function new() {}
  
  inline function getView<Data, View>(cls:String, key:Key, make:Data->?View->View, data:Data) 
    return (switch __cache[cls] {
      case null: __cache[cls] = new Registry(make);
      case v: v;
    }).poll(data, key);

  static public function mk<Data, View>(cls:String, key:Key, make:Data->?View->View, data:Data):View 
    return get().getView(cls, key, make, data);

}

abstract Key(Dynamic) from {} to {} {
  public inline function isString():Bool
    return 
      #if js
        untyped __js__('typeof {0} === "string"', this);
      #else
        Std.is(this, String);
      #end

  @:from static function ofFloat(f:Float):Key
    return Std.string(f);

  @:from static function ofBool(b:Bool):Key
    return if (b == null) null else Std.string(b);

  @:from static function ofAny<O:{}>(o:O):Key
    return (o:{});
}