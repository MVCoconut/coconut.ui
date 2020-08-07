package cases;

@:asserts
class Base {
  public function new() {}

  @:before function setup() {
    document.body.innerHTML = '';
  }

  inline function mount(o) {
    var wrapper = document.createElement('wrapper-element');
    document.body.appendChild(wrapper);
    Renderer.mountInto(wrapper, o);
  }
}