package coconut.ui;

#if !macro
import js.html.Element;
import tink.CoreApi;
import tink.state.Observable;
import vdom.Attr.Key;
import vdom.VDom.*;
import vdom.*;

class Renderable extends Widget {
  
  var rendered:Observable<VNode>;
  var element:Element;
  var binding:CallbackLink;
  var last:VNode;
  
  static var keygen = 0;
  @:keep var key:Key;
  
  public function new(rendered, ?key:Key) {
    this.rendered = rendered;
    if (key == null)
      key = rendered;
      
    this.key = key;
  }
      
  function SIDE_EFFECT<T>(v:T):VNode return null;
  
  override public function init():Element {
    //trace('init ' + Type.getClassName(Type.getClass(this)));
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
  
  macro function get(_, e);

  override public function destroy():Void {
    this.binding.dissolve();
    super.destroy();
  }  
}
#else
import haxe.macro.Expr;
using tink.MacroApi;

class Renderable {
  static var tags = [
    'a' => macro : js.html.AnchorElement,
    'input' => macro : js.html.InputElement,
    'iframe' => macro : js.html.IFrameElement,    
    'img' => macro : js.html.ImageElement,    
    'button' => macro : js.html.ButtonElement,    
  ];
 
  macro function get(_, e:Expr) {
    var type = 
      switch tink.csss.Parser.parse(e.getString().sure(), e.pos).sure() {
        case [tags[_[_.length - 1].tag] => v] if (v != null): v;
        default: macro : js.html.Element;
      }
    return macro (cast this.element.querySelector($e) : $type);
  }    
}
#end