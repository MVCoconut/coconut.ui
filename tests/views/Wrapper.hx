package views;

class Wrapper {
  static var container = {
    var e = document.createElement('wrapper-element');
    document.body.appendChild(e);
    e;
  }
  static public function clear()
    mount(null);

  static public function mount(o)
    coconut.ui.Renderer.mount(container, o);
}