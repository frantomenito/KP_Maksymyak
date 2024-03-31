import 'package:all_gallery_images/model/StorageImages.dart';
import 'package:flutter/material.dart';
import 'package:all_gallery_images/all_gallery_images.dart';
import 'package:botovod/AuthManager.dart';
import 'dart:io';
import 'package:http/http.dart' as http;


class SourceManager {
  Future<List<Item>?> getItemsForSource(ImageSource source) async {
    switch (source) {
      case ImageSource.device:
        try {
          StorageImages? rawImages = await GalleryImages().getStorageImages();
          
          if (rawImages == null) {
            return null;
          } else {
            List<Item> result = [];
            
            rawImages.images!.forEach((image) {

              Item itemToAdd = Item();
              itemToAdd.image = Image.file(File(image.imagePath ?? ""));
              result.add(itemToAdd);
            });
            
            return result;
          }
        } catch (error) {
          return null;
        }
      case ImageSource.dropbox:
        var url = Uri.parse('http://baristop-27964.portmap.io:27964/api/Images/GetAll');
        var response = await http.get(url);

        // Check the status code of the response
        if (response.statusCode == 200) {
          // If the server returns a 200 OK response, print the response body
          print('Response body: ${response.body}');
        } else {
          // If the server returns an error response, print the error message
          print('Request failed with status: ${response.statusCode}.');
        }


    // TODO: Handle this case.
    }
  }
}

class Item {
  Image image = Image.asset("assets/Folder.png");
  String? name;
  bool isImage = false;
}

class DrawingImage {
  Image image;
  ImageSource source;

  DrawingImage(this.image, this.source);
}

enum ImageSource {
  device(icon: Icons.phone_iphone, name: 'Device'),
  dropbox(icon: Icons.add_box_rounded, name: "Dropbox");

  const ImageSource({
    required this.icon,
    required this.name
  });

  final IconData icon;
  final String name;
}
