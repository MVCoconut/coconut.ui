package views;

class ControlledCounter extends View {
  @:controlled var count:Int = 0;
  @:attribute var id:String;
  function render() '
    <button id=$id onclick=${count++}>$count</button>
  ';
}