import coconut.data.*;

class TodoList implements Model {
  @:observable var items:List<TodoItem> = @byDefault new List();
}

class TodoListView extends coconut.ui.View<TodoList> {
  function render() '
    <div class="todo-list">
      <for {todo in items}>
        <TodoItemView key={@reusingFunctions todo} {...todo} ontoggle={todo.completed = event} onedit={todo.description = event} />
      </for>
    </div>
  ';
}