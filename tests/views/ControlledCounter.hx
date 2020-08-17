package views;

class ControlledCounter extends View {
  @:controlled var count:Int = 0;
  @:attribute var id:String;
  function render() '
    <button id=$id onclick=${count++}>$count</button>
  ';
  static function main() {
    Renderer.mount(document.body, '<ControlledCounter id="123" />');
    document.getElementById('123').click();
  }
}