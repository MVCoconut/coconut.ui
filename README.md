# Coconut UI Layer

This library provides the means to create views for [your data](https://github.com/MVCoconut/coconut.data#coconut-data). It cannot do that on its own though, but requires a rendering backend, of which there's currently exactly one: [`coconut.vdom`](https://github.com/MVCoconut/coconut.vdom).

Coconut views use [HXX](https://github.com/haxetink/tink_hxx#readme) to describe their internal structure, which is primarily driven from their `render` method. This is what a view basically looks like:

```haxe
class SomeView extends coconut.ui.View<SomeData> {
  function render(data:SomeData) '
    <div>
      <!-- render the actual data -->
    </div>
  '
}
```

Views consume the data they are to represent through the constructor. They may however define internal state, in which case we consider them *stateful*.

Example:

```haxe
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
```

Any change to `@:state` fields results in the view being scheduled for a redraw. As show in the example above, if you do not give the `render` method a parameter, then the data is simply decomposed into the current scope as is the case with `onsave`.

As said before, the above view is *stateful*. It is also what we'll call **property based** as opposed to **model based** views. The former renders "a bunch of properties" of an anonymous object, while the latter is underpinned by a coconut model (i.e. an object implementing `coconut.data.Model`). On occasion, views need to be recreated and because anonymous objects are, well, anonymous, coconut requires a bit of help to identify them to be able to associate the right anonymous object with the right property based view. This is done with keys:

```haxe
class Counters extends coconut.ui.View<{}> {
  @:state var total:Int = 1;
  function render() '
    <div>
      <for {i in 0...total}>
        <Counter key={i} onsave={total = event} />
      </for>
    </div>
  ';
}
```

In this (rather pointless) example, we create a whole range of counters. Once we click "save" on one of them, the view's `total` gets updated and the component must re-render - with a different amount of children. Notice that the only data a `Counter` gets is a callback, which in this case is even an anonymous function that gets created when the view is created, which means the only actual data given to the view changes *every time* the view must be updated from the parent component. This is where the `key` comes in.