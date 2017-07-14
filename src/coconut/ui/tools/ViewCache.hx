package coconut.ui.tools;

using tink.CoreApi;

#if macro
import haxe.macro.Expr;
using tink.MacroApi;
#end
private class Stack<T> {
  
  var counter = 0;
  var stored:Array<T> = [];
  var create:Void->T;

  public function new(create) 
    this.create = create;

  public function purge() {
    stored.splice(counter, stored.length);
    counter = 0;
  }

  public function poll() {
    return switch stored[counter++] {
      case null:
        var ret = create();
        stored.push(ret);
        ret;
      case v: v;
    }
  }
}

private class Factory<Data:{}, View> {
  
  var render:Data->View;
  var stackByData:Map<Data, Stack<View>> = new Map();

  var dataByKey:Map<{}, Any> = new Map();

  public function new(render)
    this.render = render;

  public function forKey<A>(key:{}, f:Void->A):A 
    return switch dataByKey[key] {
      case null: dataByKey[key] = f();
      case v: v;
    }

  public function purge() 
    for (s in stackByData) 
      s.purge();

  public function make(data:Data):View {
    var stack = switch stackByData[data] {
      case null: stackByData[data] = new Stack(render.bind(data));
      case v: v;
    }

    return stack.poll();
  }
}

#if js
@:native('WeakMap')
extern private class WeakMap<K:{}, V> {
  
  function new() {}
  function get(key:K):Null<V>;
  function set(key:K, value:V):Void;

  static function __init__():Void {
    //this whole madness is really here just for pre ES2015 versions of phantomjs
    if (untyped __js__("typeof WeakMap") != 'undefined') return;
    var counter = 0;
    inline function key(o:Dynamic) {
      if (o == null) return 0;
      if (o.__hx_key__ == null)
        return o.__hx_key__ = ++counter;
      return o.__hx_key__;
    }

    var cls:Dynamic = function () {};
    cls.prototype = {
      get: function (k:Dynamic) {
        return js.Lib.nativeThis[key(k)];
      },
      set: function (k:Dynamic, v:Dynamic) {
        js.Lib.nativeThis[key(k)] = v;
      }
    }
    
    untyped js.Browser.window.WeakMap = cls;
  }
}
#elseif macro
private class WeakMap<K:{}, V> {
  public function new() throw "Something is rotten in the state of Denmark!";
  public function get(key:K) return null;
  public function set(key:K, value:V) {}
}
#else
  typedef WeakMap<K:{}, V> = haxe.ds.WeakMap<K, V>;//No idea if this works well enough
#end

class ViewCache {
  #if !macro
  static var stack = new Array<Ref<ViewCache>>();
  static public function get() 
    return
      switch stack {
        case []:
          new ViewCache();
        case v:
          v[v.length - 1].value;
      }

  var __cache = new Map<String, Factory<Dynamic, Dynamic>>();
  
  public function cached<T>(f:Void->T):T {
    if (stack.length > 0 && stack[stack.length - 1] == this) return f();
    var entry = Ref.to(this);
    stack.push(entry);
    var ret = 
      try Success(f())
      catch (e:Dynamic) Failure(e);
    stack.remove(entry);
    this.purge();
    return ret.sure();
  }

  @:noCompletion function purge()
    for (f in __cache) 
      f.purge();

  public function new() {}

  private function getFactory<Data:{}, View>(cls:String, make:Data->View):Factory<Data, View> 
    return cast switch __cache[cls] {
      case null: __cache[cls] = new Factory<Dynamic, Dynamic>(make);
      case v: v;
    }
  #else
  static function with(e:Expr, cb:TypePath->Expr->Expr) 
    return switch e.expr {
      case ENew(cl, [arg]): cb(cl, arg);
      default: e.reject();
    }
  #end
  macro static public function create(view) {
    return with(
      view, 
      coconut.ui.macros.Caching.createView.bind(macro coconut.ui.tools.ViewCache.get())
    );
  }

}