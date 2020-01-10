package issues;

using tink.CoreApi;

class Issue44 extends coconut.ui.View {
  @:attr var item:ItemData;
  function render() '
    <div>
      <div>
        <div>
          <div>
            <switch ${item.data}>
              <case ${Loading}>
              <case ${Done(data)}>
                <div>
                  <div>
                    <div>
                      <div>
                        <a>${data.user.name}</a>
                      </div>
                    </div>
                  </div>
                </div>
              <case ${Failed(e)}>
            </switch>
          </div>
        </div>
      </div>
    </div>
  ';
  public static function main() {}
}

typedef ItemResponse = {
  final user:SimpleUserResponse;
}

typedef SimpleUserResponse = {
  final id:String;
  final name:String;
}

class ItemData implements coconut.data.Model {
  @:loaded var data:ItemResponse = null;
}