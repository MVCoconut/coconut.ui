package coconut.ui;

import vdom.VDom.hxx;
import tink.state.Observable;
import vdom.VNode;

@:autoBuild(coconut.macros.ViewBuilder.build())
class View<Data, @:const Template> extends Renderable { 
  var cachedRepresentations:Map<{}, VNode> = new Map();
  var cacheHits:Map<{}, VNode>;

  public function new(data:Observable<Data>) {
    super(Observable.auto(function () { 
      return render(data); 
    }), data);//for some weird reason render.bind(data) will not work here
  }
  
  function render(data:Data):VNode
    return throw 'abstract';
}