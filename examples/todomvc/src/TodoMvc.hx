package ;

import tink.state.State;
import vdom.VDom.*;

class TodoMvc {
  static function main() {
    var s = new State(5);
  }
}

class TodoItem extends coconut.state.Model<{
  done:Bool,
  description:String,
}> {}

class TodoListView extends coconut.ui.View<Iterable<TodoItem>, '
  <div>
    <input />
    <ul>
      <for {item in __data__}>
        <li>
          <input type="checkbox"  />

        </li>
      </for>
    </ul>
  </div>
'> {


}