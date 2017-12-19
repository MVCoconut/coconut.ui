class TodoItemView extends coconut.ui.View {
  var attributes:{ description:String, completed:Bool, ontoggle:Bool->Void, onedit:String->Void };
  function render() '
    <div class="todo-item">
      <input type="checkbox" checked={completed} onchange={ontoggle(event.target.checked)} />
      <input type="text" value={description} onchange={onedit(event.target.value)} />
    </div>
  ';
}