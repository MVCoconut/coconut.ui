package coconut.ui.tools;

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

class ViewCache {
  
  static var stack = new Array<{ cache: ViewCache }>();
  static public var current(get, never):ViewCache;

  static inline function get_current()
    return stack[stack.length - 1].cache;

  var __cache = new Map<String, Factory<Dynamic, Dynamic>>();

  public function cached<T>(f:Void->T):T {
    var o = { cache: this };
    stack.push(o);
    var ret = f();
    stack.remove(o);
    this.purge();
    return ret;
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
  #if macro
  static function with(e:Expr, cb:TypePath->Expr->Expr) 
    return switch e.expr {
      case ENew(cl, [arg]): cb(cl, arg);
      default: e.reject();
    }
  #end
  macro static public function create(view) {
    return with(view, function (cl, arg) return
      switch (macro (__coco__cache:coconut.ui.tools.ViewCache)).typeof() {
        case Success(_): coconut.ui.macros.Caching.createView(macro __coco__cache, cl, arg);
        default: macro new $cl(coconut.ui.macros.HXX.liftIfNeedBe($arg));
      }
    );
  }
  
  // macro public function createView(ethis, view)
    // return coconut.ui.macros.Caching.createView(ethis, view);

}