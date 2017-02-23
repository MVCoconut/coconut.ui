package ;

import js.Browser.*;

class Test {
  static function main() {
    var state = new tink.state.State('Useless Example');
    // var t = new haxe.Timer(1000);
    // t.run = function () state.set('T = '+haxe.Timer.stamp());
    document.body.appendChild(new Counters({ key: 100, title: state }).init());
  }
}

class Counter extends coconut.ui.View<{ onsave:Int->Void }> {
  @:state var count:Int = 10;
  function render() '
    <div class="counter">
      <button onclick={count--}>-1</button>
      <span>{count}</span>
      <button onclick={count++}>+1</button>
      <button onclick={onsave(count)}>Save</button>
    </div>
  ';
}

class Counters extends coconut.ui.View<{ title:String }> {
  @:state var total:Int = 1;
  function render() '
    <div>
      <h1>{title}</h1>
      <for {i in 0...total}>
        <Counter key={i} onsave={saveCount} />
      </for>
    </div>
  ';
  function saveCount(count)
    this.total = count;
}