package coconut.ui;

class Isolated extends View {
  @:attribute var children:RenderResult;
  function render() return children;
}