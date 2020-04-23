package views;

class Outer extends View {
  @:attribute var children:Children;
  function render() {
    Tests.log('render');
    return @hxx '<div data-id={viewId}>Outer: {...children} <Inner>{...children}</Inner></div>';
  }
  override function viewDidUpdate()
    Tests.log('updated');
}
