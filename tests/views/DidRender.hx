package views;

class DidRender extends View {
  @:attribute var counter:Int;
  function render() '
    <div>${counter}</div>
  ';

  override function viewDidRender(firstTime:Bool) {
    Tests.log('$firstTime');
  }

}