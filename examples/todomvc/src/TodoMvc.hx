package ;

import js.Browser.*;
import vdom.VDom.*;
import todomvc.data.*;

class TodoMvc {
  static function main() {

    document.body.appendChild(
      hxx('
        <todomvc.ui.TodoListView filter={new TodoFilter()} todos={new TodoList()}/>
      ').toElement()
    );
  }
}