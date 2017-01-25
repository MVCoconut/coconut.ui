package coconut.ui;

import haxe.Timer;
import js.html.Element;
import tink.CoreApi.CallbackLink;
import tink.state.Observable;
import vdom.VDom.*;
import vdom.*;


class Renderable extends Widget {
  
  var rendered:Observable<VNode>;
  var element:Element;
  var binding:CallbackLink;
  var last:VNode;
  
  static var keygen = 0;
  @:keep var key:Any;
  
  public function new(rendered, ?key:Any) {
    this.rendered = rendered;
    if (key == null)
      key = rendered;
      
    this.key = switch (untyped __js__("typeof(key)") : String) {
      case "object":
        var o: { __coconutKey__:Any } = key;
        if (o.__coconutKey__ == null) o.__coconutKey__ = keygen++;
        o.__coconutKey__;
      default:
        key;
    }
  }
      
  function SIDE_EFFECT<T>(v:T):VNode return null;
  
  override public function init():Element {
    trace('init ' + Type.getClassName(Type.getClass(this)));
    last = rendered.value;
    this.element = create(last);
    
    setupBinding();
    
    return this.element;
  }
  
  function setupBinding()
  this.binding = this.rendered.bind(function (next) {
    if (next != last) apply(next);
  });
  
  function apply(next) {
    var changes = diff(last, next);
    beforeUpdate();
    this.element = patch(element, changes);
    last = next;
    afterUpdate();
  }
    
  public function toElement() 
    return switch element {
      case null: init();
      case v: v;
    } 
   
  function beforeUpdate() {}
  function afterUpdate() {}
  
  override public function update(x:{}, y):Element {
    switch Std.instance(x, Type.getClass(this)) {
      case null:
      case v:
        this.element = y;
        this.last = v.last;
        apply(rendered);
        setupBinding();
    }
    
    return toElement();
  }
  
  function get(s:String):Element 
    return this.element.querySelector(s);
  
  override public function destroy():Void {
    this.binding.dissolve();
    super.destroy();
  }  
}
