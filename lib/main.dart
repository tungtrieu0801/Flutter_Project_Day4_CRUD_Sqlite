import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

//khoi tao co so du lieu Sqlite
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //tạo cơ sở dữ liệu lưu trong tập tin task_database
  final database = openDatabase(
    join (await getDatabasesPath(), 'task_database.db'),   //join nối đường dẫn với cơ sở dữ liệu
    //callback được gọi khi cơ sở dữ liệu mới được tạo.
    onCreate: (db,version){
      return db.execute(
        'CREATE TABLE tasks(id INTEGER PRIMARY KEY, title TEXT, desc TEXT)',
      );
    },
    //phiên bản của cơ sở dữ liệu
    version: 1,
  );
  //truyền biến database vào Myapp để sử dụng trong toànứng dụng
  runApp(MyApp(database: database));
}
//có thể cấu hình toàn cục cho ứng dụng như color,...
class MyApp extends StatelessWidget {
  final Future<Database> database;  //.là 1 biến thành viên của database của class myapp, là 1 future của kiểu dữ liệu Database.Biến này được sử dụng để chuyển cơ sở dữ liệu đã mở từ hàm main vào lớp MyApp
  const MyApp({super.key, required this.database}); //constructor, cho phép truyền giá trị cho biến thành viên database

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "CRUD APP",
      color: Colors.brown,
      home: HomeScreen(database: database,), //truyền giá trị cơ sở dữ liệu vào trong homescreen thông qua biến database
    );
  }
}
//là một StatefulWidget, có nghĩa là nó có khả năng thay đổi trạng thái và giao diện người dùng của nó.
class HomeScreen extends StatefulWidget {
  final Future<Database> database; //: Đây là một biến thành viên (database) của lớp HomeScreen, là một tương lai (future) của kiểu dữ liệu Database. Biến này được sử dụng để truyền cơ sở dữ liệu đã mở từ lớp MyApp vào lớp HomeScreen.
  const HomeScreen({super.key, required this.database});


  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
//HomeScreenState, là một lớp con (State) của widget HomeScreen.
// Lớp _HomeScreenState được sử dụng để quản lý trạng thái và giao diện người dùng cho màn hình chính của ứng dụng.

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _titleController = TextEditingController(); //kiểm soát và quản lý dữ liệu nhập vào từ một trường văn bản
  TextEditingController _desController = TextEditingController();
  List<Map<String, dynamic>> _task =[];
//_task là một danh sách (list) các đối tượng Map<String, dynamic>\
// Mỗi mục trong danh sách là một Map với các cặp khóa - giá trị,
// trong đó khóa là tên thuộc tính (ví dụ: "id", "title", "desc"), và giá trị là dữ liệu tương ứng của thuộc tính.
  @override
  //được ghi đè từ lớp cha State. Phương thức này được gọi khi đối tượng State đang được khởi tạo.
  // Trong trường hợp này, nó gọi phương thức refresTaskList() để cập nhật danh sách công việc khi màn hình chính được khởi tạo.
  void initState() {
    super.initState();
    refresTaskList();
  }
  //hàm insert với hai tham số đầu vào là title và desc, đều là chuỗi (String).
  // Hàm này trả về một tương lai (future) có kiểu dữ liệu là void, nghĩa là nó không trả về giá trị.
  Future<void>insertTask(String title, String desc) async {
    final Database db = await widget.database; // Đây là cách để lấy cơ sở dữ liệu từ biến database đã được truyền từ widget cha (MyApp) vào widget con (HomeScreen). Biến db là một đối tượng của lớp Database.
    await db.insert(
      'tasks',  //Đây là tên của bảng trong cơ sở dữ liệu mà bạn muốn thêm dữ liệu vào.
      {
        //Đây là một Map chứa cặp khóa-giá trị,
        // trong đó khóa là tên các cột trong bảng tasks ("title" và "desc"), và giá trị là dữ liệu tương ứng bạn muốn thêm vào bảng.
      'title': title,
      'desc':desc,
      },
    conflictAlgorithm: ConflictAlgorithm.replace,//: Đây là cách xử lý khi có sự xung đột dữ liệu (nếu đã tồn tại bản ghi có cùng khóa chính).
                                                   // Trong trường hợp này, ConflictAlgorithm.replace có nghĩa là nếu có xung đột, bản ghi cũ sẽ bị thay thế bằng bản ghi mới.
    );
  }

  Future<void>updateTask(int id,String title, String desc) async {
    final Database db = await widget.database;
    await db.update(
      'tasks',
      {
        'title': title,
        'desc':desc,
      },
      where: 'id = ?', // Đây là điều kiện để chỉ định bản ghi cần cập nhật.
                      // Trong trường hợp này, chúng ta chỉ định rằng bản ghi cần cập nhật có cột id bằng với tham số id mà bạn đã truyền vào hàm.
      whereArgs: [id],
    );
  }

  Future<void>deleteTask(int id) async {
    final Database db = await widget.database;
    await db.delete(
      'tasks',
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<void>refresTaskList() async {
    final Database db = await widget.database;
    //sử dụng phương thức query để truy vấn tất cả các bản ghi trong bảng tasks của cơ sở dữ liệu.
    // Kết quả trả về là một danh sách các Map (dictionary) chứa thông tin về các công việc.
    final List<Map<String,dynamic>> maps = await db.query('tasks');
    //sử dụng phương thức setState để cập nhật trạng thái của widget _HomeScreenState.
    // Bạn gán danh sách maps (các công việc từ cơ sở dữ liệu) vào biến _task, từ đó cập nhật giao diện người dùng với thông tin công việc mới nhất.
    setState(() {
      _task = maps;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CRUD APP", style: TextStyle(color: Colors.black),),),
      body: Column(
        children: [
          const SizedBox(height: 20,),
          Padding(padding: const EdgeInsets.all(10),
            //kết nối TextField với TextEditingController có tên _titleController.
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "Task title",
                //: Đây là cách định nghĩa viền xung quanh trường văn bản. OutlineInputBorder() tạo ra viền dạng khung xung quanh trường văn bản.
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _desController,
              decoration: const InputDecoration(
                hintText: "Task Description",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          //tạo ra một nút "Add task" có phông nền, và khi được nhấn, nó sẽ thực hiện việc thêm công việc mới vào cơ sở dữ liệu,
          // xóa nội dung trong trường văn bản và cập nhật danh sách công việc.
          ElevatedButton(
              onPressed: () async{
                await insertTask(
                    _titleController.text, _desController.text);
                    _titleController.text = "";
                    _desController.text = "";
                refresTaskList();
              },
              child: const Text("Add task"),
          ),
          Expanded(
              child: ListView.builder(
              itemCount: _task.length,
              itemBuilder: (context, index){
                final task = _task[index];
                TextEditingController _titleController1 = TextEditingController(text: task['title']);
                TextEditingController _descController1 = TextEditingController(text: task['desc']);

                return ListTile(
                  title: Text(task['title']),
                  subtitle: Text(task['desc']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          onPressed: (){
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                          title: const Text("Edit task"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _titleController1,
                                decoration: const InputDecoration(
                                  hintText:"Task title",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              TextField(
                                controller: _descController1,
                                decoration: const InputDecoration(
                                  hintText:"Task Description",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () async {
                                  await updateTask(
                                      task['id'],
                                      _titleController1.text,
                                      _descController1.text,
                                  );
                              Navigator.pop(context);
                              refresTaskList();
                            },
                                child: const Text("Update"))
                          ],
                        ));
                      }, icon: const Icon(Icons.edit)),
                      TextButton(
                          onPressed: () async{
                            await deleteTask(task['id']);
                            refresTaskList();
                          }, child: const Icon(Icons.delete))
                    ],
                  ),
                );
              },
          )),
        ],
      ),
    );
  }
}



