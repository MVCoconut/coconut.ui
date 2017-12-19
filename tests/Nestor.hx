class Nestor extends View {
  var attributes:{ plain:String, inner: Observable<String>, foo:Void->Void, bar:Void->Void };
  static public var redraws(default, null):Int = 0;

  function render() {
    redraws++;
    return @hxx '
      <div class="nestor">
        <span class="plain">{plain}</span>
        <Example4 key={this} value={inner} />
      </div>
    ';
  }

}