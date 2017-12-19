typedef TodoItemData = { 
  description:String, 
  completed:Bool, 
  ontoggle:Bool->Void, 
  onedit:String->Void,
}
class TodoItemView extends coconut.ui.View {
  var attributes:TodoItemData;
  function render() '
    <div class="todo-item">
      <input type="checkbox" checked={completed} onchange={ontoggle(event.target.checked)} />
      <input type="text" value={description} onchange={onedit(event.target.value)} />
    </div>
  ';
}