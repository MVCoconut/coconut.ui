# Coconut UI Layer

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/MVCoconut/Lobby)

This library provides the means to create views for [your data](https://github.com/MVCoconut/coconut.data#coconut-data). It cannot do that on its own though, but requires a rendering backend, of which there are currently two: 

- [`coconut.vdom`](https://github.com/MVCoconut/coconut.vdom)
- [`coconut.react`](https://github.com/MVCoconut/coconut.react)

Coconut views use [HXX](https://github.com/haxetink/tink_hxx#readme) to describe their internal structure, which is primarily driven from their `render` method. This is what a view basically looks like:

```haxe
class Stepper extends coconut.ui.View {
  @:attribute var step:Int = 1;
  @:attribute var onconfirm:Callback<Int>;
  @:state var value:Int = 0;
  function render() '
    <div class="counter">
      <button onclick={value -= step}>-</button>
      <span>{value}</span>
      <button onclick={value += step}>+</button>
      <button onclick={onconfirm(value)}>OK</button>
    </div>
  ';
}
```

A function with just a string body is merely a syntactic shortcut for a function with `return hxx('theString')`. So if you want to be more explicit or do something else in your rendering function, you could write:

```haxe
class Stepper extends coconut.ui.View {
  
  @:attribute var step:Int = 1;
  @:attribute var onconfirm:Callback<Int>;
  @:state var value:Int = 0;

  function render() {
    trace("rendering!!!");
    return hxx('
      <div class="counter">
        <button onclick={value -= step}>-</button>
        <span>{value}</span>
        <button onclick={value += step}>+</button>
        <button onclick={onconfirm(value)}>OK</button>
      </div>
    ');
  }
}
```

In general, you should avoid producing side effects in the `render` method.

The promise of `coconut.ui` is: whenever your data updates, your view will update also. This assumes that you [do not defeat coconut's ability to observe changes](https://github.com/MVCoconut/coconut.data#enforced-observability).

Every view has a number of attributes and states. If you have a passing familiarity with React, you can roughly think of the attributes being the props and the states being the state.

## Attributes

Attributes represent the data that flows into your view from the outside (usually the model layer or a parent view) and callbacks that allow the view to report changes. The above `Stepper` example has one of each.

You define attributes in one of the two following ways:

- prefix a field with `@:attribute` or `@:attr` and optionally a default value after a `=`.
- define a single `attributes` pseudo-field, where again you have two options of defining defaults:
  - if the type is an anonymous object defined inline, "initialize" the fields
  - otherwise "initialize" the pseudo-field with an object literal.

The above is equivalent to:

```haxe
  @:attribute var step:Int = 1;
  @:attribute var onconfirm:Callback<Int>;

  //is equivalent to
  
  var attributes:{
    var step:Int = 1;
    var onconfirm:Callback<Int>;
  };
  
  //is equivalent to

  var attributes:StepperAttributes = { step: 1 };
  //where 
  typedef StepperAttributes = {
    var step:Int;
    var onconfirm:Callback<Int>;
  }
```

## States

States are internal to your view. They allow you to hold data that is only relevant to the view itself, but is still observable from the framework's perspective. In the `Stepper` example, clicking on the `-` button will decrement `value` and this will cause a rerender that will update the content of the `span` that shows the current value to the user. You views may also hold plain fields for whatever purpose. Note though that updates to those are not tracked.

### When to go Stateful?

Down the line you will almost always want to move state out of views - except when it's clearly transitory. On the other hand, all software development is a meandering learning process. You may find yourself working on the UI, the application model and the business logic at the same time. It's a system with many moving parts and there's really two important ends to it: how to cleanly model your business logic and how to nicely interface with the user. Any layers inbetween may require *radical* changes as those two ends evolve, which is why coconut gives you the option to put application state directly into the view at first and factor it out as it becomes more obvious along which lines to actually do that. In theory you may even start out with a view that depends solely on its own state.

The main advantage of stateless views is that they are far easier to test. The stateful application logic on the other hand can be tested in isolation from the views too.

## Refs

Just like React, coconut supports refs to get access to the views you're creating.

```haxe
'
  <div ref=${div -> console.log(div.innerHTML)}>
    <Counter ref=${counter -> counter.increment()} />
  </div>
'
```

### `@:ref` syntax

You may also define refs like so:

```haxe
class Counter extends View {
  @:ref var button:ButtonElement;
  @:state var counter:Int = 0;
  function render() '
    <button ref=${button} onclick=${counter++}>${counter}</button>
  ';

  function viewDidUpdate() {
    trace(button.current);//Will log <button>1</button> the first time you click.
  }
}
```

## Life cycle callbacks

Coconut views may declare life cycle callbacks, which are modelled after those in React, adjusted for the naming differences: 

What React calls component and props, Coconut calls views and attributes respectively, as those are more specific terms: the term component can mean anything and in ECMAScript terminology, the `state` of a React component is a *property*.

- `function viewDidMount():Void`: Is called after the component is mounted into the DOM (or whatever the native view hierarchy might be). Corresponds to [React's `componentDidMount`](https://reactjs.org/docs/react-component.html#componentdidmount)

- `function getSnapshotBeforeUpdate():Snapshot`: Is called after `render`, before the resulting changes take effect. Note that `Snapshot` is not a particular data type. You may either be explicit about it, or let the compiler be inferred. Corresponds to [React's `componentDidMount`](https://reactjs.org/docs/react-component.html#getsnapshotbeforeupdate), but note that `prevState` and `prevProps` are not passed. If you need these, you will have to track them yourself.

- `function viewDidUpdate(snapshot:Snapshot):Void`: Is called after the changes resulting from `render` take effect. The function has 0 parameters if you don't declare `getSnapshotBeforeUpdate` and 1 if you do. If you don't declare the parameter, a parameter called `snapshot` is created implicitly. If you don't explictly define the type of the one parameter, it will implicitly be inferred to the return type of `getSnapshotBeforeUpdate`. Corresponds to [React's `componentDidMount`](https://reactjs.org/docs/react-component.html#componentdidmount), but note that `prevState` and `prevProps` are not passed. If you need these, you will have to track them yourself.

- `function viewWillUnmount():Void`: Is called before the component is unmounted. Consider using `untilUnmounted`/`beforeUnmounting` instead.

- `getDerivedStateFromAttributes`: Is called right before rendering and is expected to return an object

Additional life cycle related utilities:

- `untilUnmounted`/`beforeUnmounting`: One possibility for cleaning up a component is to store any allocated resources in instance fields and then access them in `viewWillUnmount`, e.g.:

  ```haxe
  var observer:MutationObserver;
  function viewDidMount() {
    observer = new MutationObserver(...);
    observer.connect(...);
  }
  function viewWillUnmount() {
    observer.disconnect();
    observer = null;
  }
  ```

  An alternative us to use `untilUnmounted`/`beforeUnmounting` (which are fully equivalent and should be picked depending on what reads more naturally) which take a callback of `Void->Void` that is executed before unmounting. So for example the code above would be written like so:

   ```haxe
  function viewDidMount() {
    var observer = new MutationObserver(...);
    observer.connect(...);
    beforeUnmounting(observer.disconnect);
  }
  ``` 

  That's shorter and avoids having instance fields that clutter completion. Another way two write the same is:

  ```haxe
  function viewDidMount() 
    untilUnmounted(() -> {
      var observer = new MutationObserver(...);
      observer.connect(...);
      observer.disconnect;
    });
  ```   

  This is absolutely equivalent with the above. The latter name makes most sense when used a call that returns a `CallbackLink` from `tink_core`. Let's assume we define something like this:

  ```haxe
  class Observe {
    static function mutations(target:Element, cb:Callback<Element>):CallbackLink {
      //... set up mutation observer here
    }
  }
  ```

  The we can use it like so:

  ```haxe
  @:ref var root:Element;//Need to populate this in `render` of course
  function viewDidMount() 
    untilUnmounted(Observe.mutations(root, () -> {
      //do something
    }));
  ```

- `untilNextChange`/`beforeNextChange`: These two are anologous to `untilUnmounted`/`beforeUnmounting`, except that they fire before unmounting and before rerendering. Use these if you need to setup behavior that is cleaned up any time the component changes. Let's consider this rather silly view, that may change it's underlying DOM every time it rerenders:

  ```haxe
  @:ref var root:Element;
  function render() '
    <if ${Math.random() > .5}>
      <button ref=${root} />
    <else>
      <textarea ref=${root} />
    </if>
  ';
  function viewDidMount() 
    untilChanged(Observe.mutations(root, () -> {
      //do something
    }));
  ```