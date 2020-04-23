package views;

class Example4 extends View {
  @:attr var value:String;
  static public var redraws(default, null) = 0;
  function render() {
    redraws++;
    return @hxx '
      <div class="example4" data-id={viewId}>{value}</div>
    ';
  }
}
