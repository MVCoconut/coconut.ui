package views;

typedef TodoItemData = {
  description:String,
  completed:Bool,
  ontoggle:Bool->Void,
  onedit:String->Void,
}
class TodoItemView extends View {
  var attributes:TodoItemData;
  function render() '
    <div class="todo-item">
      <input type="checkbox" checked={completed} onchange={ontoggle(event.src.checked)} />
      <input type="text" value={description} onchange={onedit(event.src.value)} />
    </div>
  ';
}