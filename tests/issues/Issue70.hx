package issues;

class Issue70 extends View {
  @:state var value = 'initial';
  function render() '<div>$value</div>';
  override function viewDidMount() value = 'updated';
}