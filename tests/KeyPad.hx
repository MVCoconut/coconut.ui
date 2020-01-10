class Key extends View {
  @:attribute var value:Int;
  @:controlled var current:Int;
  function render() '
    <button data-value=$value class=${{ selected: value == current }} onclick=${current = value}>$value</button>
  ';
}

class KeyPad extends View {
  @:state var current:Int = 0;
  static var max = 10;
  function render() '
    <div>
      <for ${i in 0...max}>
        <Key value=$i current=${this.current} />
      </for>
    </div>
  ';
}