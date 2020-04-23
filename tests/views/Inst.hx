package views;

class Inst extends View {

  @:state public var count:Int = 0;

  var elt =
    #if react
      null;
    #else {
      var div = document.createDivElement();
      div.className = 'native-element';
      div.innerHTML = 'I am native!';
      div;
    }
    #end

  function render() '
    <div class="inst">
      Inst: ${elt}
      <button onclick=${count++}>$count</button>
    </div>
  ';

  override function viewDidMount()
    Tests.log('mounted');

  override function viewWillUnmount()
    Tests.log('unmounting');

}
