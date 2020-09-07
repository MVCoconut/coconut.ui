package issues;

class Issue48 extends cases.Base {
  public function test() {
    var data = new Data();
    mount(
      hxx('
        <Isolated>
          <div>
            <for {item in data.rows}>
              <RowView row={item} />
            </for>
          </div>
        </Isolated>
      ')
    );

    asserts.assert(RowView.count == data.rows.length);
    data.rows.splice(1, 1);
    Renderer.updateAll();
    asserts.assert(RowView.count == data.rows.length);

    return asserts.done();
  }
}

class RowView extends coconut.ui.View {
  static public var count(default, null) = 0;
  @:attribute var row:Row;
  function render() '
    <div>{row.i}</div>
  ';
  function viewDidMount() count++;
  function viewWillUnmount() count--;
}

class Data implements coconut.data.Model {
  var rows:tink.state.ObservableArray<Row> = new tink.state.ObservableArray(
      [for(i in 0...10) new Row({ i: i })]
  );
}

class Row implements coconut.data.Model {
  @:editable var i:Int;
}