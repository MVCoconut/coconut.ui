import coconut.data.*;

class TodoList implements Model {
  @:observable var items:List<TodoItem> = @byDefault new List();
}

class TodoListView extends View {
  @:attribute var todos:TodoList;
  function render() '
    <div class="todo-list">
      <for {todo in items}>
        <TodoItemView key={todo} completed={todo.completed} description={todo.description} ontoggle={todo.completed = event} onedit={todo.description = event} />
      </for>
    </div>
  ';
}