# Coconut UI Layer

This library provides the means to create views for [your data](https://github.com/MVCoconut/coconut.data#coconut-data). It cannot do that on its own though, but requires a rendering backend, of which there's currently exactly one: [`coconut.vdom`](https://github.com/MVCoconut/coconut.vdom).

Coconut views use [HXX](https://github.com/haxetink/tink_hxx#readme) to describe their internal structure, which is primarily driven from their `render` method. This is what a view basically looks like:

```haxe
class SomeView extends coconut.ui.View<SomeData> {
  function render(data:SomeData) '
    <div>
      <!-- render the actual data -->
    </div>
  ';
}
```

A function with just a string body is merely a syntactic shortcut for a function with `return hxx('<theString>')`. So if you want to be more explicit or do something else in your rendering function, you could write:

```haxe
class SomeView extends coconut.ui.View<SomeData> {
  function render(data:SomeData) {
    trace('rendering!!!');
    return hxx('
      <div>
        <!-- render the actual data -->
      </div>
    ');
  }
}
```

Generally speaking, you should avoid producing side effects in the `render` method.

The promise of `coconut.ui` is: whenever your data updates, your view will update also. This assumes that you [do not defeat coconut's ability to observe changes](https://github.com/MVCoconut/coconut.data#enforced-observability). In addition to that `coconut.ui` has a (probably overly complex) caching layer that reduces those updates to a minimum.

Depending on what data they consume, views fall into one of two categories

- **model based views**: a view is written against a coconut model. This makes it very easy for coconut to observe changes properly.
- **property based views**: a view that just consumes a bunch of properties. It turns out that this is a lot trickier for coconut to handle in a way that is convenient to use.

## Property Based Views

Let's define a property based view (using `-lib coconut.vdom`):

```haxe
class TodoItemView extends View<{ description:String, completed:Bool, onedit:String->Void, ontoggle:Bool->Void }> {
  function render() '
    <div class="todo-item">
      <input type="checkbox" checked={completed} onchange={ontoggle(event.target.checked)} />
      <input type="text" value={description} onchange={onedit(event.target.value)} />
    </div>
  ';
}
```

The above is basically unfolded into the following:

```haxe
private typedef TodoItemViewData = { 
  var description(default, never):String;
  var completed(default, never):Bool;
  function onedit(param:String):Void;
  function ontoggle(param:Bool):Void;
}

class TodoItemView extends coconut.ui.BaseView {
  public function new(o:tink.state.Observable<TodoItemViewData>) { /* some magic happens here */}
  private function render(data:TodoItemViewData) {

    var description = data.description,
        completed = data.completed,
        onedit = data.onedit,
        ontoggle = data.ontoggle;

    return hxx('
      <div class="todo-item">
        <input type="checkbox" checked={completed} onchange={ontoggle(event.target.checked)} />
        <input type="text" value={description} onchange={onedit(event.target.value)} />
      </div>
    ');
  }
}
```

Notice how instead of just consuming the properties, an observable of those properties is taken in. This is what brings the view to life. You can still just instantiate the view with an anonymous object:

```haxe
new TodoItemView({ description: 'foo', completed: true, onedit: function (_) {}, ontoggle(_) {}})
```

This way the view's data will be a constant though: an anonymous object who's description is immutable. Here's an example of how we could make it come to life:

```haxe
import js.Browser.*;
import tink.state.State;
import coconut.Ui.hxx;

class Main {
  static function main() {
    var desc = new State('test'),
        done = new State(false);

    document.body.appendChild(
      hxx('<TodoItemView completed={done} description={desc} onedit={desc.set} ontoggle={done.set} />').toElement()
    );
  }
}
```

Using `hxx` the data flow is properly wired up under the hood. That doesn't imply that you need to create your own states and observables though. We can modify the example above and feed true model into the view instead:

```haxe
import js.Browser.*;
import tink.state.State;
import coconut.Ui.hxx;

class TodoItem implements coconut.data.Model {
  @:editable var completed:Bool = false;
  @:editable var description:String;
}

class Main {
  static function main() {
    var todo = new TodoItem({ description: 'test' });

    document.body.appendChild(
      hxx('<TodoItemView ontoggle={todo.completed = event} onedit={todo.description = event} {...todo} />').toElement()
    );
  }
}
```

Here we let the data flow into the view using the spread operator (`...`) while the events are explititly handled by modifying model properties.

### When to use Property Based Views

The most accurate answer to that is "it depends". It's also the least useful one.

At the bottom line, property based views pose a couple of problems:

1. There's quite a bit of heavy lifting to be done by the coconut macros to wire up the data flow in such a way that it works as expected.
2. They may have to redraw even when their data did not effectively change. Because their data is always composed on the fly, it's not always easy to determine whether the recomposed data is equal to the last composed version. The renderer will still do its part to minimize effective updates, but 
3. Because of the above and other subtleties, they may not always work entirely as expected.

The advantage is that they are more easily fed with arbitrary data, which increases flexibility for whoever uses them.

## Stateful Views

Views consume the data they are to represent through the constructor. They may however define internal state, in which case we consider them "stateful". Example:

```haxe
class TodoItemView extends View<{ description:String, completed:Bool, onedit:String->Void, ontoggle:Bool->Void }> {
  @:state var isEditing:Bool = false;
  function render() '
    <div class="todo-item" data-editing={isEditing}>
      <input type="checkbox" checked={completed} onchange={ontoggle(event.target.checked)} />
      <input type="text" value={description} onchange={onedit(event.target.value)} onfocus={isEditing = true} onblur={isEditing = false}/>
    </div>
  ';
}
```

Any change to `@:state` fields results in the view being scheduled for a redraw. 

Just to dwell on nuances: in fact even the "stateless" version of `TodoItemView` was inherently stateful, because the input elements it contains are stateful by their very nature.

### When to go Stateful?

Down the line you will always want to move state out of views. On the other hand, all software development is a meandering learning process. You may find yourself working on the UI, the application model and the business logic at the same time. It's a system with many moving parts and there's really two important ends to it: how to cleanly model your business logic and how to nicely interface with the user. Any layers inbetween may require *radical* changes as those two ends evolve, which is why coconut gives you the option to put application state directly into the view at first and factor it out as it becomes more obvious along which lines to actually do that. In theory you may even start out with a view that depends solely on its own state.

The main advantage of stateless views is that they are far easier to test. The stateful application logic on the other hand can be tested without the views. 

## View Nesting and Keys

Expanding on the todos, here is how we might define a todo list view:

```haxe
import coconut.data.*;

class TodoList implements Model {
  @:observable var items:List<TodoItem> = @byDefault new List();
}

class TodoListView extends coconut.ui.View<TodoList> {
  function render() '
    <div class="todo-list">
      <for {todo in items}>
        <TodoItemView key={todo} {...todo} ontoggle={todo.completed = event} onedit={todo.description = event} />
      </for>
    </div>
  ';
}
```

Everything except the `key` property should be clear from the things explained above. Let's ignore the `key` for the moment and consider how this view would rerender:

Whenever the underlying model changes, the view needs to construct `TodoItemView` children. Of course we don't want them to be created every time we rerender. Adding an item to a list with 1000 items would be potentially very expensive (in fact the cost is mitigated by the renderer, at least if it is `coconut.vdom`). We actually want to be able to reuse the same view again and again. The issue is though that while the children that should be renderered may change, the data that they should render can change at the same time. This is where the `key` comes into play: it allows coconut to understand which data belongs to which view. Upon rerendering, coconut will check if it already has a view of the required type for a given key and will reuse it, if it exists - potentially assigning new data to it. In this case, such an assignment occurs: `ontoggle={todo.completed = event}` is a shorthand for `ontoggle={function (event) todo.completed = event}`, meaning that every time the view is reused, it is assigned a new anonymous function.

One way to not have the problem of reassigning handlers is to make sure they are the same. In this particular case you could define them as methods on the model itself and then use them like so:

```
<TodoItemView key={todo} {...todo} ontoggle={todo.toggleCompleted} onedit={todo.editDescription} />
```

Another one is to simply have model based views in such heavy loops. Those do not require a `key` at all, because the model itself is a self-contained object with identity, that makes the mapping trivial.

# Virtual DOM Based Rendering

Currently the only renderer for `coconut.ui` is based on `virtual-dom`. Other VDOM libraries are being investigated.