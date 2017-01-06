package coconut;
import haxe.Timer;
import js.html.Element;
import tink.CoreApi.CallbackLink;
import tink.state.Observable;
import vdom.VDom.*;
import vdom.*;


@:autoBuild(coconut.macros.ComponentBuilder.build())
class Component<T, Const> extends Widget {
  
  var cachedRepresentations:Map<{}, VNode> = new Map();
  var cacheHits:Map<{}, VNode>;
  var data:Observable<T>;
  var rendered:Observable<VNode>;
  var element:Element;
  var binding:CallbackLink;
  
  static var keyGen = 0;
  
  @:keep var key:Int = keyGen++;  
  
  public function new(data) {
    this.data = data;
    this.rendered = Observable.auto(function () { 
      
      var ret = render(data); 
      if (this.cacheHits != null) {
        this.cachedRepresentations = this.cacheHits;//TODO: consider using a TTL rather than aggressively deleting
      }
      this.cacheHits = new Map();
      return ret;
    });
  }
  
  function CACHED_RENDER<T:{}>(data:T, renderer:T->VNode) {
        
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
    
  function SIDE_EFFECT<T>(v:T):VNode return null;
  
  function render(state:T):VNode
    return throw 'abstract';
  
  override public function init():Element {
    
    var last = rendered.value;
    
    this.element = create(last);
    
    this.binding = this.rendered.bind(function (next) {
      
      var start = Timer.stamp();
      var changes = diff(last, next);
      beforeUpdate();
      this.element = patch(element, changes);
      last = next;
      afterUpdate();
      trace('updating $this took ${Timer.stamp() - start}s');
    });
    
    return this.element;
  }
  
  public function toElement() 
    return switch element {
      case null: init();
      case v: v;
    } 
   
  function beforeUpdate() {}
  function afterUpdate() {}
  
  override public function update(x, y):Element 
    return toElement();
  
  function get(s:String):Element 
    return this.element.querySelector(s);
  
  override public function destroy():Void {
    this.binding.dissolve();
    super.destroy();
  }  
}
