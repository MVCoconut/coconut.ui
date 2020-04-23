package views;

class Inner extends View {
  @:children var content:Children;
  function render() {
    Tests.log('render');
    return @hxx '<div data-id={viewId}>Inner: {...content}</div>';
  }

  override function viewDidUpdate()
    Tests.log('updated');
}