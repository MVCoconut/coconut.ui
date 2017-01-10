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
      var ret = render(data); 
      if (this.cacheHits != null) {
        this.cachedRepresentations = this.cacheHits;//TODO: consider using a TTL rather than aggressively deleting
      }
      this.cacheHits = new Map();
      return ret;
    }));
  }
  
  function render(data:Data):VNode
    return throw 'abstract';
  
  function CACHED_RENDER<T:{}>(renderer:T->VNode, data:T):VNode {
    return renderer(data);
    var ret = switch cachedRepresentations[data] {
      case null: 
        var ret = renderer(data);
        cachedRepresentations[data] = ret;
        ret;
      case v: v;
    }
    
    if (cacheHits != null)
      cacheHits[data] = ret;

    return ret;
  }
  
  
}