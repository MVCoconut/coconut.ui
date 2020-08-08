package issues;

@:asserts
class Issue63 {
  public function new() {}
  public function test() {
    var h:Hidable = null;
    Renderer.mount(document.createDivElement(), '<Hidable ref=$h />');
    asserts.assert(h.hidden == false);
    return asserts.done();
  }
}

private class Hidable extends View {
  @:attribute var hidden:Bool;

  function render()
    return if (hidden) null else 'now you see mee';
}