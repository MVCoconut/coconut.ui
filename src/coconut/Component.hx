package coconut;
import js.html.Element;
import tink.CoreApi.CallbackLink;
import tink.state.Observable;
import vdom.VDom.*;
import vdom.*;


@:autoBuild(coconut.macros.ComponentBuilder.build())
class Component<T, Const> extends Widget {
  var data:Observable<T>;
  var rendered:Observable<VNode>;
  var element:Element;
  var binding:CallbackLink;
  
  static var keyGen = 0;
  
  @:keep var key:Int = keyGen++;  
  
  public function new(data) {
    this.data = data;
    this.rendered = Observable.auto(function () return render(data));
  }
    
  function SIDE_EFFECT<T>(v:T):VNode return null;
  
  function render(state:T):VNode
    return throw 'abstract';
  
  override public function init():Element {
    
    var last = rendered.value;
    
    this.element = create(last);
    
    this.binding = this.rendered.bind(function (next) {
			
			var changes = diff(last, next);
      beforeUpdate();
      this.element = patch(element, changes);
      last = next;
      afterUpdate();
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
