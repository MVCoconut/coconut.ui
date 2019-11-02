# Coconut UI Layer

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/MVCoconut/Lobby)

This library provides the means to create views for [your data](https://github.com/MVCoconut/coconut.data#coconut-data). It shares significant similarities with React. One of them is its API, which has increasingly converged with React's for higher familiarity, easier porting and better interoperability with react. Furthermore, just like React requires e.g. react-dom to render to the DOM, coconut also must be accompanied by a rendering backend, of which there are currently two:

- [`coconut.vdom`](https://github.com/MVCoconut/coconut.vdom): a hand crafted virtual dom renderer that trumps React in speed and size.
- [`coconut.react`](https://github.com/MVCoconut/coconut.react): an adapter to render coconut views through React allowing you to leverage React's vast ecosystem.

Coconut views use [HXX](https://github.com/haxetink/tink_hxx#readme) to describe their internal structure, which is primarily driven from their `render` method. This is what a view basically looks like:

```haxe
class Stepper extends coconut.ui.View {

  @:attribute var step:Int = 1;
  @:attribute function onconfirm(value:Int);
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
  @:attribute function onconfirm(value:Int);
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

The promise of `coconut.ui` is: whenever your data updates, your view will update also. This assumes that you [do not defeat coconut's ability to observe changes](https://github.com/MVCoconut/coconut.data#enforced-observability).

Every view has a number of attributes and states, that we'll look at in detail below. If you have a passing familiarity with React, you can roughly think of the attributes being the props and the states being the state.

## Attributes

Attributes represent the data that flows into your view from the outside (usually the model layer or a parent view) and callbacks that allow the view to report changes. The above `Stepper` example has one of each.

You define attributes in one of the two following ways:

- prefix a field with `@:attribute` or `@:attr` and optionally a default value after a `=`.
- define a single `attributes` pseudo-field, where again you have two options of defining defaults:
  - if the type is an anonymous object defined inline, "initialize" the fields
  - otherwise "initialize" the pseudo-field with an object literal.

The following things mean the same:

```haxe
  //as used in the above Stepper:

  @:attribute var step:Int = 1;
  @:attribute function onconfirm(value:Int):Void;

  //is equivalent to:

  var attributes:{
    var step:Int = 1;
    var onconfirm:tink.core.Callback<Int>;
  };

  //is equivalent to:

  var attributes:StepperAttributes = { step: 1 };
  //where
  typedef StepperAttributes = {
    var step:Int;
    var onconfirm:tink.core.Callback<Int>;
  }
```

### Children

Views may also consume children, which are handled very much like attributes in almost every way, except how they're specified in HXX.

The following are all equivalent:

```haxe
class Button extends View {
  @:attribute function onclick():Void;
  @:attribute var children:String;
  function render() '
    <button onclick={onclick}>{children}</button>
  ';
}

class Button extends View {
  @:attribute function onclick():Void;
  @:children var label:String;
  function render() '
    <button onclick={onclick}>{label}</button>
  ';
}

class Button extends View {
  @:attribute function onclick():Void;
  @:child var label:String;
  function render() '
    <button onclick={onclick}>{label}</button>
  ';
}
```

And you would use any of them like so:

```haxe
<Button onclick={trace("World!")}>Hello</Button>
```

## States

States are internal to your view. They allow you to hold data that is only relevant to the view itself, but is still observable from the framework's perspective. In the `Stepper` example, clicking on the `-` button will decrement `value` and this will in turn cause a rerender that is going to update the content of the `span` that shows the current value to the user.

Your views may also hold plain fields for whatever purpose. Note though that updates to those will generally not cause rerendering.

## Laziness, granular invalidation and batched rerendering

Unless the particular renderer diverges from the norm, the following can be said about how views update:

- attributes passed to views are not evaluated unless the view consuming them evaluates them (or passes them to a child that evaluates them). Example:

  ```haxe
  class Foo extends coconut.ui.View {
    @:attribute var foo:Int;
    function render() '<div/>'
  }

  hxx('<Foo foo=${throw "you will never see this"}/>');
  ```

  Because `foo` is never used, it's not evaluated and the exception is never raised.
- Changes to any state or attribute accessed directly or indirectly in a view's render function will invalidate the view. Any other changes have no effect on the view itself.
- Passing states/attributes to child views does not count as access. Consider the following contrived example:

  ```haxe
  class Button extends coconut.ui.View {
    @:attribute var children:coconut.ui.Children;
    @:attribute function onclick():Void;
    function render() '
      <button onclick=${onclick}>${...children}</button>
    ';
  }

  class Container extends coconut.ui.View {
    @:state var a:Int;
    @:state var b:Int;
    var renderCounter = 0;
    function render() '
      <div>
        Rendered ${renderCounter++} times
        <Button onclick=${a++}>${a}</Button>
        <button onclick=${b++}>${b}</button>
      </div>
    ';
  }
  ```

  Note: having side effects such as `renderCounter++` in your render function is bad practice, but here it's meant to illustrate whether or not the component rerenders.

  What's important to note about this example is that clicking on the `Button` will not rerender `Container` (but only the `Button`), while clicking on the plain `button` will. You can use this behavior to contain the effect of state updates. There is a very simple view included in coconut.ui to leverage just that:

  ```haxe
  package coconut.ui;

  class Isolated extends View {
    @:attribute var children:RenderResult;
    function render() return children;
  }
  ```

  You would use it like so:

  ```haxe
  class Container extends View {
    @:state var a:Int;
    @:state var b:Int;
    var renderCounter = 0;
    function render() '
      <div>
        Rendered ${renderCounter++} times
        <Isolated><button onclick=${a++}>${a}</button></Isolated>
        <button onclick=${b++}>${b}</button>
      </div>
    ';
  }
  ```

  Clicking the button wrapped in `Isolated` will not rerender `Container`.

- Changes do not instantly rerender views, but invalidate them, which schedules a batched update with the browser's next animation frame (or frame on NME/OpenFl or short timeout on other platforms). This bares some similarity with React's async rendering.

  It's important to understand though that on one hand invalidation is an event that eagerly cascades through your dependencies, but all computation is batched, *including attributes*. If your view invokes a callback that is likely to change the value of an attribute, the attribute is recomputed only when accessed, either in rendering or other code you write to access it.

### `@:tracked` states and attributes

On occasion, you may wish for a certain state or attribute to cause a rerender, regardless of whether or not it was accessed in the `render` function. The most common case is a revision counter that is bumped when some value that is not (directly) observable has changed (e.g. your view's size on screen). Regardless of the use case, if you mark a state/attribute as `@:tracked` then changes to it will cause invalidation.

You may also specify expressions as parameters, with `_` taking the place of the attribute to track sub-expressions.

Example:

```haxe
@:tracked(_.get('Paris').population)
@:attribute var cities:ObservableMap<String, City>;
```

## Refs

Just like React, coconut supports refs to get access to the elements/views you're creating.

```haxe
'
  <div ref=${div -> if (div != null) console.log(div.innerHTML)}>
    <Stepper ref=${stepper -> trace(stepper.step)} />
  </div>
'
```

It is advised to use methods rather than anonymous functions for performance reasons.

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
    trace(button);//Will log <button>1</button> the first time you click.
  }
}
```

It is in fact possible to pass in any valid left hand value for an assignment, although that will also cause the creation of an anonymous function, which you want to avoid. Using `@:ref` avoids this and also makes the reference read only and thus safer to rely on.

## Life cycle callbacks

Coconut views may declare life cycle callbacks, which are modelled after those in React, adjusted for the naming differences:

What React calls component and props, Coconut calls views and attributes respectively, as those are more specific terms: the term component can mean anything and in ECMAScript terminology, the `state` of a React component is a *property*.

### viewDidMount

```haxe
function viewDidMount():Void;
```

This callback is invoked after the component is mounted into the DOM (or whatever the native view hierarchy might be). It corresponds to [React's `componentDidMount`](https://reactjs.org/docs/react-component.html#componentdidmount)

### shouldViewUpdate

```haxe
function shouldViewUpdate():Bool;
```

This function is invoked to determine if a component should rerender. While it mostly corresponds to [React's `shouldComponentUpdate`](https://reactjs.org/docs/react-component.html#shouldcomponentupdate), in contrast to React, it not pass `nextState` and `nextProps`. Instead, state and attributes changes are always applied *before* this function is invoked.

Caveat: if this function returns `false`, the view will only invalidate if any of the states or attributes that this function depends on changes (or any `@:tracked` attributes or states change).

This function exists only for optimization purposes.

### getDerivedStateFromAttributes

```haxe
static function getDerivedStateFromAttributes(states:States, attributes:Attributes):Partial<States>;
```

This function is called right before rendering and is expected to return an object, that may define a new value for each state. It corresponds to [React's `getDerivedStateFromProps`](https://reactjs.org/docs/react-component.html#static-getderivedstatefromprops).

### getSnapshotBeforeUpdate

```haxe
function getSnapshotBeforeUpdate():Snapshot;
```

This function is called after `render`, before the resulting changes take effect. Note that `Snapshot` is not a particular data type. You may either be explicit about it, otherwise it will be inferred by the compiler. Corresponds to [React's `getSnapshotBeforeUpdate`](https://reactjs.org/docs/react-component.html#getsnapshotbeforeupdate), but note that `prevState` and `prevProps` are not passed. If you need these, you will have to track them yourself.

### viewDidUpdate

```haxe
function viewDidUpdate(snapshot:Snapshot):Void;
```

This callback is invoked after the updates resulting from `render` take effect.

The function has 0 parameters if you don't declare `getSnapshotBeforeUpdate` and 1 if you do. If you don't declare the parameter, a parameter called `snapshot` is created implicitly. If you don't explictly define the type of the one parameter, it will implicitly be inferred to the return type of `getSnapshotBeforeUpdate`.

While `viewDidupdate` mostly corresponds to [React's `componentDidMount`](https://reactjs.org/docs/react-component.html#componentdidmount), `prevState` and `prevProps` are not passed. If you need these, you will have to track them yourself.

### viewDidRender

```haxe
function viewDidRender(firstTime:Bool):Void;
```

This callback is invoked every time after the results of `render` are applied to the physical UI (e.g. DOM), with the passed boolean being `true` for the first call and `false` for all subsequent calls. You can use this as a combination of `viewDidMount` and `viewDidUpdate`.

### viewWillUnmount

```haxe
function viewWillUnmount():Void;
```

This callback is invoked before the view is unmounted and corresponds to
While `viewDidupdate` mostly corresponds to [React's `componentWillUnmount`](https://reactjs.org/docs/react-component.html#componentwillunmount).

Consider using `untilUnmounted`/`beforeUnmounting` instead.

### untilUnmounted or beforeUnmounting

```haxe
function untilUnmounted(cb:Callback<Noise>):Void;
function beforeUnmounting(cb:Callback<Noise>):Void;
```

One possibility (idiomatic in React) for cleaning up a view is to store any allocated resources in instance fields and then access them in `viewWillUnmount`, e.g.:

```haxe
class Example extends View {
  var map:MutationObserver;
  function viewDidMount() {
    observer = new MutationObserver(...);
    observer.connect(...);
  }
  function viewWillUnmount() {
    observer.disconnect();
    observer = null;
  }
}
```

An alternative is to use `untilUnmounted`/`beforeUnmounting` (which are fully equivalent and should be picked depending on what reads more naturally) which take a `Callback<Noise>` that is executed before unmounting. So for example the code above would be written like so:

```haxe
class Example extends View {
  function viewDidMount() {
    var observer = new MutationObserver(...);
    observer.connect(...);
    beforeUnmounting(observer.disconnect);
  }
}
```

That's shorter and avoids having instance fields that clutter completion. Another way to write the same is:

```haxe
class Example extends View {
  function viewDidMount()
    untilUnmounted(() -> {
      var observer = new MutationObserver(...);
      observer.connect(...);
      observer.disconnect;
    });
}
```

This is absolutely equivalent with the previous version. The latter name makes most sense when used a call that returns a `CallbackLink` from `tink_core`. Let's assume we define something like this:

```haxe
class Observe {
  static function mutations(target:Element, cb:Callback<Element>):CallbackLink {
    //... set up mutation observer here
  }
}
```

The we can use it like so:

```haxe
class Example extends View {
  @:ref var root:Element;//Need to populate this in `render` of course
  function viewDidMount()
    untilUnmounted(Observe.mutations(root, () -> {
      //do something
    }));
}
```

### untilNextChange or beforeNextChange

These two are anologous to `untilUnmounted`/`beforeUnmounting`, except that they fire before unmounting and before rerendering. Use these if you need to setup behavior that is cleaned up any time the component changes. Let's consider this rather silly view, that may change it's underlying root element every time it rerenders:

```haxe
class Example extends View {
  @:ref var root:Element;

  function render() '
    <if ${Math.random() > .5}>
      <button ref=${root} />
    <else>
      <textarea ref=${root} />
    </if>
  ';

  function viewDidMount()
    untilNextChange(Observe.mutations(root, () -> {
      //do something
    }));
}
```

### afterUpdating

```haxe
function afterUpdating(cb:Void->Void):Void;
```

If you wish to run a function after the next update, you can schedule it per `afterUpdating`.

### Avoiding typos in life cycle callbacks

To avoid typos when declaring life cycle callbacks, coconut warns if it sees functions that have names similar to the supported callbacks. To make absolutely sure your callback is correctly named, you may add `override` which is de-facto certain to cause an error if you mistype the name.

## Renderer API

Renderers expose the following API.

```haxe
package coconut.ui;

class Renderer {
  /// Mounts a part of vdom into the dom
  static function mount(target:js.html.Node, vdom:RenderResult):Void;
  /// Gets the native view (DOM node) corresponding to a given View (consider using refs instead)
  static function getNative(view:View):Null<js.html.Node>;
  /// Forces the synchronous update of all currently invalidated views
  static function updateAll():Void;
}
```

The above `Renderer.mount` and `Renderer.getNative` are equivalent to `ReactDOM.render` and `ReactDOM.findDOMNode`.