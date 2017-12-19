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
  }

  public function poll(data:In, key:Key) {
    var ret = create(data, stored[counter]);
    if (counter == stored.length)
      stored[counter] = ret;
    counter++;
    return ret;
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

  var __cache = new Map<String, Stack<Dynamic, Dynamic>>();
  
  public function cached<T>(f:Void->T):T {
    if (stack.length > 0 && stack[stack.length - 1] == this) return f();
    var entry = Ref.to(this);//wrapping in entry to allow for reentrancy (no idea if that's needed though)
    stack.push(entry);
    var ret = f();
      // try Success(f())
      // catch (e:Dynamic) Failure(e);
    stack.remove(entry);
    this.purge();
    // return ret.sure();
    return ret;
  }

  inline function purge()
    for (f in __cache) 
      f.purge();

  public function new() {}
  
  inline function getView<Data, View>(cls:String, key:Key, make:Data->?View->View, data:Data) 
    return (switch __cache[cls] {
      case null: __cache[cls] = new Stack(make);
      case v: v;
    }).poll(data, key);

  static public function mk<Data, View>(cls:String, key:Key, make:Data->?View->View, data:Data):View 
    return get().getView(cls, key, make, data);

}

typedef Key = Dynamic;