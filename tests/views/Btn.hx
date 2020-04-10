package views;

class Btn extends View {
  @:attribute function onclick();
  @:ref var dom:js.html.Element;
  var count = 0;
  function render() '
    <button ref={dom} onclick=${onclick}>Rendered ${count++}</button>
  ';

  function viewDidMount()
    if (dom.nodeName != 'BUTTON') throw 'assert';
}
