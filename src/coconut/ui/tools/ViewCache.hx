package coconut.ui.tools;

import tink.state.*;
using tink.CoreApi;

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

  var dataByString = new Map<String, Dynamic>();
  var dataByObject = new Map<{}, Dynamic>();

  public function new(render)
    this.render = render;

  public function forKey<A>(key:{}, f:Void->A):A 
    return
      if (Std.is(key, String)) {
        var key:String = cast key,
            cache = dataByString;
        switch cache[key] {
          case null: cache[key] = f();
          case v: v;
        }    
      }
      else {
        var cache = dataByObject;
        switch cache[key] {
          case null: cache[key] = f();
          case v: v;
        } 
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
    if (untyped __js__("typeof WeakMap") == 'undefined') {
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
}
#else
typedef WeakMap<K:{}, V> = haxe.ds.WeakMap<K, V>;//No idea if this works well enough
#end

class ViewCache {
  static var stack = new Array<Ref<ViewCache>>();
  static function get() 
    return
      switch stack {
        case []:
          new ViewCache();
        case v:
          v[v.length - 1].value;
      }

  static function modelView<T:coconut.data.Model, V>(className:String, model:T, create:T->V):V 
    return get().getFactory(className, create).make(model);
  
  static function propView<T:{}, V>(key:{}, className:String, data:Observable<T>, create:Observable<T>->V):V {
    var factory = get().getFactory(className, create);
    
    var alreadyCreated = true;
    
    var link = factory.forKey(key, function () {
      alreadyCreated = false;
      var state = new tink.state.State(data);
      return new tink.core.Pair(state, coconut.ui.tools.ViewCache.stable(state));
    });
    
    if (alreadyCreated) {
      @:privateAccess tink.state.Observable.stack.push(null);//TODO: this is horrible
      link.a.set(data);
      @:privateAccess tink.state.Observable.stack.pop();
    }

    return factory.make(link.b);
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
  
  static function stable<T:{}>(s:State<Observable<T>>) {
    return Compare.stabilize(s.observe().flatten(), Compare.shallow.bind(false));
  }
  private function getFactory<Data:{}, View>(cls:String, make:Data->View):Factory<Data, View> 
    return cast switch __cache[cls] {
      case null: __cache[cls] = new Factory<Dynamic, Dynamic>(make);
      case v: v;
    }


}