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

  public function purge()
    modify(items = { 
      var ret = items.filter(function (i) return !i.done);
      trace(ret.length);
      ret;
    });
}

class TodoListView extends coconut.ui.View<TodoList, '
  <div class="todos">
    <button onclick=${function () for (i in items) i.done = true}>Complete All</button>
    <form onsubmit=${handleSubmit(add)}>
      <input />
    </form>
    <ol>
      <for ${item in items}>
        <if ${filter.value(item)}>
          <li key=${item} data-done=${item.done} >
            <input type="checkbox" onchange=${updateItem(item)} checked=${item.done} />
            <p>${item.description}</p>
          </li>
        </if>
      </for>
    </ol>
    <menu>
      <span>
        <switch ${items.count(isActive)}>
          <case ${1}>1 item
          <case $v>$v items
        </switch> left
      </span>
      <for ${f in filters}>
        <button onclick=${setFilter(f.value)} data-active=${f.value == filter}> ${f.name}</button>
      </for>
      <if ${items.exists(isCompleted)}>
        <button onclick=$purge>Clear Completed</button>
      </if>
    </menu>
  </div>
'> {

  static function isActive(item:TodoItem) return !item.done;
  static function isCompleted(item:TodoItem) return item.done;

  static var filters = [
    new Named('All', function (item:TodoItem) return true),
    new Named('Active', isActive),
    new Named('Completed', isCompleted),
  ];

  var filter:State<TodoItem->Bool> = new State(filters[0].value);

  function setFilter(f) {
    return function () filter.set(f);
  }

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
