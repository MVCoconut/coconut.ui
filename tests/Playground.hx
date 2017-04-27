package ;

import coconut.ui.*;
import tink.state.*;

// typedef Foo<T> = Props<{ foo:T }>;

// typedef WindowConfig = { 
//   var className(default, never):String;
//   var title(default, never):RenderResult;
//   var content(default, never):RenderResult;
//   var parts(default, never):Iterable<Int>;
// }

// class Window<C:WindowConfig> extends View<C> {
//   @:signal var closed;
//   function render() '
//     <div class={className}>
//       <for {p in parts}>
//       </for>
//     </div>
//   ';
// }

class Example extends View<{ foo: Iterable<String> }> {
  override function render(data:{ foo: Iterable<String> }) '
    <div>{data.foo}</div>
  ';
}

// class Sub extends Window<WindowConfig> {
//   function foo()
//     _closed.trigger(Noise);
// }

// class SubSub extends Sub {
//   override function render() '
//     <div class={"test"}></div>
//   ';
// }

class Playground {
  static function main() {
    
    // var x:Foo<Int> = { foo: 5 };
    // var x:Foo<String> = { foo: 'hoho' };

    // var cache = {
    //   states: {
    //     foo: new State(4),
    //     bar: new State(5.0),
    //   }
    // };

    // var p:Props<{
    //   foo:Int,
    //   bar:Float,
    // }> = cache.states;
    
  }
}