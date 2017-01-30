package todomvc.ui;

import js.html.KeyboardEvent;
import vdom.VDom.*;
import todomvc.data.*;
import coconut.ui.*;

class TodoListView extends View<{todos:TodoList, filter:TodoFilter}> {
  function render() '
    <div class="todo-list">
      <input type="text" onkeypress={e => if (e.keyCode == KeyboardEvent.DOM_VK_RETURN) { todos.add(e.target.value); e.target.value = ""; }} />
      <ol>
        <for {item in todos.items}>
          <if {filter.matches(item)}>
            <TodoItemView {...item} />
          </if>
        </for>
      </ol>
      <menu>
        <span>
          <switch {todos.items.count(TodoItem.isActive)}>
            <case {1}>1 item
            <case $v>$v items
          </switch> left
        </span>
        <for {f in filter.options}>
          <button onclick={[] => filter.toggle(f.value)} data-active={filter.isActive(f.value)}>{f.name}</button>
        </for>
        <if {todos.items.exists(TodoItem.isCompleted)}>
          <button onclick={todos.clearCompleted}>Clear Completed</button>
        </if>
      </menu>
    </div>
  ';
}