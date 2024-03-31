import 'package:flutter/material.dart';
import 'package:botovod/SourceManager.dart';
import 'package:botovod/AuthManager.dart';

var credits = "";

class SelectorView extends StatefulWidget {
  const SelectorView({super.key});

  @override
  State<SelectorView> createState() => _SelectorViewState();
}

class _SelectorViewState extends State<SelectorView> {
  int selectedIndex = 0;
  ImageSource currentImageSource = ImageSource.device;
  List<Item>? itemList = [];

  @override
  void initState() {
    super.initState();

    _loadItemsForSource();
  }

  void updateCredits() {
    setState(() {
      credits = credits;
    });
  }

  void _loadItemsForSource() async {
    print("loading items");
    itemList = await SourceManager().getItemsForSource(currentImageSource);


    // Ensure the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        // Update the state with the loaded items
      });
    }
  }

  void selectSource(int index) async {
    selectedIndex = index;

    setState(() {
      credits = "";
      currentImageSource = ImageSource.values[selectedIndex];
    });

    List<Item>? items =
        await SourceManager().getItemsForSource(currentImageSource);

    setState(() {
      itemList = items;
    });
  }

  List<Widget> accoutActions() {
    if (credits == "") {
      return [SizedBox()];
    } else {
      return [
        Text(credits),

        IconButton(onPressed: AuthManager.instance.logout,
              icon: Text("logout", style: TextStyle(color: Colors.red[300]),))
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentImageSource.name),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent[100],
        actions: accoutActions(),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            SizedBox(
              height: 65,
              child: DrawerHeader(
                child: Text("Sources"),
                decoration: BoxDecoration(color: Colors.lightBlueAccent),
              ),
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(ImageSource.device.icon),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                  Text(ImageSource.device.name)
                ],
              ),
              onTap: () {
                selectSource(0);
              },
              selected: currentImageSource == ImageSource.device,
            ),
            ListTile(
              title: Row(
                children: [
                  Icon(ImageSource.dropbox.icon),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                  Text(ImageSource.dropbox.name)
                ],
              ),
              onTap: () {
                selectSource(1);
              },
              selected: currentImageSource == ImageSource.dropbox,
            ),
          ],
        ),
      ),
      body: ItemPicker(itemSource: currentImageSource, itemList: itemList, onUpdateCredits: updateCredits, // Pass the callback function here
      ),
    );
  }
}

class ItemPicker extends StatefulWidget {
  final ImageSource itemSource;
  final List<Item>? itemList;
  final VoidCallback onUpdateCredits; // Add this line

  ItemPicker({
    required this.itemSource,
    this.itemList,
    required this.onUpdateCredits, // Add this line
  });

  @override
  State<ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends State<ItemPicker> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return itemList();
  }

  Widget tryItems() {
    return widget.itemList == null
        ? Text("No photos to show")
        : itemList();
  }

  Widget itemList() {
    return (widget.itemList?.length ?? 0) != 0
        ? Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: GridView.builder(
          itemCount: widget.itemList!.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/canvas',
                    arguments: DrawingImage(
                        widget.itemList![index].image,
                        widget.itemSource));
              },
              child: Padding(
                padding: EdgeInsets.all(0.5),
                child: Image(
                  image: widget.itemList![index].image.image,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }),
    )
        : Text("No images to show");
  }
}
