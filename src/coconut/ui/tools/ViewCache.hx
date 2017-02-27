package coconut.ui.tools;

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
  var byData:Map<Data, Stack<View>> = new Map();

  public function new(render)
    this.render = render;

  public function adhoc<T:(Data, { var key(default, null):{}; })>(v:T):View {
    return null;
  }

  public function purge() 
    for (s in byData) 
      s.purge();

  public function make(data:Data):View {
    var stack = switch byData[data] {
      case null: byData[data] = new Stack(render.bind(data));
      case v: v;
    }

    return stack.poll();
  }
}

class ViewCache {
  
  var __cache = new Map<String, Factory<Dynamic, Dynamic>>();

  @:noCompletion public function purge()
    for (f in __cache) 
      f.purge();

  public function new() {}

  private function getFactory<Data:{}, View>(cls:String, make:Data->View):Factory<Data, View> 
    return cast switch __cache[cls] {
      case null: __cache[cls] = new Factory<Dynamic, Dynamic>(make);
      case v: v;
    }
  
  macro public function createView(ethis, view)
    return coconut.ui.macros.Caching.createView(ethis, view);

}