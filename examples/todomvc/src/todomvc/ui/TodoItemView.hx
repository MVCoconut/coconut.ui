package todomvc.ui;

import todomvc.data.TodoItem;
import coconut.ui.View;
import vdom.VDom.*;

class TodoItemView extends View<{ item: TodoItem, ondeleted: Void->Void }> {
  
  @:state var isEditing:Bool = false;

  function render() '
    <div class="todo-item" data-completed={item.completed} data-editing={isEditing}>
      <input type="checkbox" checked={item.completed} onchange={e => item.completed = e.target.checked} />
      <if {isEditing}>
        <input type="text" value={item.description} onchange={e => item.description = e.target.value} onblur={_ => isEditing = false} />
      <else>
        <span ondblclick={_ => this.isEditing = true}>{item.description}</span>
        <button onclick={ondeleted}>Delete</button>
      </if>
    </div>
  ';

  override function afterUpdate() 
    if (isEditing)
      get('input[type="text"]').focus();
  
}