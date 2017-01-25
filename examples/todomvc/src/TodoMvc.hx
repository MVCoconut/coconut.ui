package ;

import tink.state.*;
import tink.pure.List;
import js.html.*;
import js.Browser.*;
import vdom.VDom.*;

using tink.CoreApi;

class TodoMvc {
  static function main() {
    
    var data = new TodoList({ items: [] });
    var view = new TodoListView(data);
    document.body.appendChild(view.toElement());
  }
}

@:writable
class TodoItem extends coconut.state.Model<{
  var done(default, null):Bool;
  var description(default, null):String;
}> {
  static public function create(description:String) {
    return new TodoItem({ done: false, description: description });
  }
}

class TodoList extends coconut.state.Model<{
  var items(default, null):List<TodoItem>;
  
}> {
  public function add(description:String):Void
    modify(items = items.prepend(TodoItem.create(description)));
    // modify(items = items.concat([TodoItem.create(description)]));
}

class TodoListView extends coconut.ui.View<TodoList, '
  <div class="todos">
    <form onsubmit=${handleSubmit(add)}>
      <input />
    </form>
    <ol>
      <for ${item in items}>
        <if ${filter.value(item)}>
          <li key=${item} data-done=${item.done} >
            <input type="checkbox" onchange=${updateItem(item)} />
            <p>${item.description}</p>
          </li>
        </if>
      </for>
    </ol>
    <menu>
      
    </menu>
  </div>
'> {


  static var options = [
    new Named('All', function (item:TodoItem) return true),
    new Named('Active', function (item:TodoItem) return !item.done),
    new Named('Completed', function (item:TodoItem) return item.done),
  ];

  var filter:State<TodoItem->Bool> = new State(options[0].value);

  function handleSubmit(add:String->Void) {
    return function (e:Event) {
      var input:InputElement = cast get('form input');
      add(input.value);
      input.value = '';
      e.preventDefault();
    }
  }
  static function updateItem(item:TodoItem)
    return function (e:Event) {
      item.done = (cast e.target : InputElement).checked;
      
    }

}
