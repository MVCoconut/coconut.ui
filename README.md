# Coconut UI Layer

This library provides the means to create views for [your data](https://github.com/MVCoconut/coconut.data#coconut-data). It cannot do that on its own though, but requires a rendering backend, of which there's currently exactly one: [`coconut.vdom`](https://github.com/MVCoconut/coconut.vdom).

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

The promise of `coconut.ui` is: whenever your data updates, your view will update also. This assumes that you [do not defeat coconut's ability to observe changes](https://github.com/MVCoconut/coconut.data#enforced-observability). In addition to that `coconut.ui` has a (probably overly complex) caching layer that reduces those updates to a minimum.

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