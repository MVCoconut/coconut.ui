package coconut.ui;

import vdom.Attr;
import vdom.*;

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

class BaseView extends coconut.vdom.Renderable {
  
  public function new<Data>(data:Data, render:Data->VNode) {
    super(tink.state.Observable.auto(function () { 

      var ret = render(data); 

      for (m in __cache) for (stack in m)
        stack.purge();    

      return ret;
    }));
  }

  var __cache = new Map<String, Map<{}, Stack<BaseView>>>();

  function __cachedModelView<M:coconut.data.Model>(m:M, className:String, view:M->BaseView):VNode {
    var perModel = switch __cache.get(className) {
      case null: __cache[className] = new Map();
      case v: v;
    }

    var stack = switch perModel[m] {
      case null: perModel[m] = new Stack(view.bind(m));
      case v: v;
    }

    return stack.poll();
  }
}