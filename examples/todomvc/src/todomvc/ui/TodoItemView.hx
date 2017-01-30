package todomvc.ui;

import todomvc.data.TodoItem;
import coconut.ui.View;
import vdom.VDom.*;

class TodoItemView extends View<TodoItem> {
  function render(item:TodoItem) '
    <div class="todo-item" data-completed={item.completed}>
      <input type="checkbox" checked={item.completed} onchange={e => item.completed = e.target.checked} />
      <input type="name" value={item.description} onchange={e => item.description = e.target.value} />
    </div>
  ';
}