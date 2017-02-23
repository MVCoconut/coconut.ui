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

## Stateful Views

Views consume the data they are to represent through the constructor. They may however define internal state, in which case we consider them "stateful".

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

Any change to `@:state` fields results in the view being scheduled for a redraw. As shown in the example above, if you do not give the `render` method a parameter, then the data is simply decomposed into the current scope as is the case with `onsave`.

## Property Based Views

The `Counter` we created is a **stateful** view. It is also what we'll call **property based** as opposed to **model based** views. The former renders "a bunch of properties" of an anonymous object, while the latter is underpinned by a coconut model (i.e. an object implementing `coconut.data.Model`). 

### Keys

On occasion, views need to be recreated by their parent and because anonymous objects are, well, anonymous, coconut requires a bit of help to identify them to be able to associate the right anonymous object with the right property based view. This is done with keys:

```haxe
class CounterList extends coconut.ui.View<{ title:String }> {
  @:state var total:Int = 1;
  function render() '
    <div class="counter-list">
      <h1>{title}</h1>
      <for {i in 0...total}>
        <Counter key={i} onsave={function (count) total = count} />
      </for>
    </div>
  ';
}
```

In this (rather pointless) example, we create a whole range of counters. Once we click "save" on one of them, the view's `total` gets updated and the `CounterList` must re-render - with a different amount of children. Notice that the only data a `Counter` gets is a callback, which in this case is even an anonymous function that gets created when the `Counter` is created, which means the only actual data given to the view changes *every time* the view must be updated from the parent component. This is where the `key` comes in. 

Notice that the above version is quite inefficient, because it means that on every redraw, we create a new event handler, that happens to do the same thing, but ultimately it does mean that on the rendering layer the old handler needs to be deregistered and the new one must be attached. Instead we can optimize it like so:

```haxe
class CounterList extends coconut.ui.View<{ title:String }> {
  @:state var total:Int = 1;
  function render() '
    <div class="counter-list">
      <h1>{title}</h1>
      <for {i in 0...total}>
        <Counter key={i} onsave={saveTotal} />
      </for>
    </div>
  ';
  function saveTotal(v)
    this.total = v;
}
```

### Observability

In the example above you may wish for the title to change over time and for the UI to reflect that change. To look at how this is possible, let's take a closer look at the code `coconut.ui` generates:

```haxe
class CounterList extends coconut.ui.ViewBase {

  //Here is what `@:state var total` becomes:

    var total(get, set):Int;
    var __coco_total = new tink.state.State(1);
    function total_get() 
      return __coco_total.value;

    function total_set(param) {
      __coco_total.set(param);
      return param;
    }

  //The generated constructor. Notice the type of `data.title`

    public function new(data:{ key:Key, title:tink.state.Observable<String> });

  //And this is the full render function:

    public function render(__data__:{ title:String }) {
      var title = __data__.title;
      return hxx('
        <div class="counter-list">
          <h1>{title}</h1>
          <for {i in 0...total}>
            <Counter key={i} onsave={saveTotal} />
          </for>
        </div>    
      ');
    }
}
```

The code above is still a quite simplified version of what is actually being generated, but it's enough to illustrate a few things. The data being rendered and the data being consumed in the constructor are not quite the same. The former is lifted to become observable.

That allows us to do this (with `-lib coconut.vdom`):

```haxe
import js.Browser.*;

var title = new tink.state.State("Useless Example");
document.appendChild(new CounterList({ key: "whatever", title: title }).toElement());
title.set("Useless Example Indeed");
tink.state.Observable.updateAll();//Ordinarily we'd have to wait for one frame for the changes to be applied, but let's just force them
alert(document.querySelector(".counter-list>h1").innerHTML);//Will display "Useless Example Indeed"
```

### Rendering Models through Property Based Views

If you wish to render a model (or multiple ones) through a property based view, it can be a bit arduous, but in HXX you can rely on the spread operator.

```haxe
class TodoItemView extends coconut.ui.View<{ completed:Bool, description:String, important:Bool }> {
  function render() '
    <div class="todo-item">
      <! -- exercise for the reader -->
    </div>
  ';
}

class TodoItem implements coconut.data.Model {
  @:editable var completed:Bool;
  @:editable var description:String;
  @:editable var important:Bool;
}

var item = new TodoItem({ description: 'Shop groceries' });
hxx('<TodoItemView {...item} />');
```

Here we're rendering a `TodoItem` through a slightly diverging property based view. We use the model itself as key, the spread operator to assign properties automatically and finally we deal with the discrepancy in naming between `completed` and `done` by assigning that field manually.

If the structure of the model completely matches

# Virtual DOM Based Rendering

Currently the only renderer for `coconut.ui` is based on `virtual-dom`. Other VDOM libraries are being investigated.



