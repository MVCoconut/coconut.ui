class Snapshotter extends View {
  @:ref var ref:js.html.Element;
  @:attribute var value:Int;

  override function getSnapshotBeforeUpdate() {
    return Std.parseInt(ref.innerHTML);
  }
  function render() '
    <div ref=$ref>$value</div>
  ';

  function viewDidUpdate(snapshot:Int)
    Tests.log('$snapshot');
}