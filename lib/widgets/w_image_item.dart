// import 'dart:io'; 
// import 'package:flutter/material.dart';
// import 'package:passport_photo_2/commons/colors.dart';
// import 'package:passport_photo_2/models/image_item_model.dart';
// import 'package:passport_photo_2/widgets/w_text.dart';

// class WImageItem extends StatelessWidget {
//   final ItemImage item;
//   final List<ItemImage> listSelectedImage;
//   final Function(ItemImage item)? onTap;

//   const WImageItem(
//       {super.key,
//       required this.item,
//       required this.listSelectedImage,
//       this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     final _size = MediaQuery.sizeOf(context);
//     int indexOfSelectedImageList =
//         listSelectedImage.indexWhere((element) => element.id == item.id);

//     return GestureDetector(
//       onTap: () {
//         onTap != null ? onTap!(item) : null;
//       },
//       child: Container(
//           height: _size.width * 0.3,
//           width: _size.width * 0.3,
//           margin: const EdgeInsets.all(5),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.file(
//                   File(item.path),
//                   fit: BoxFit.cover,
//                   height: _size.width * 0.3,
//                   width: _size.width * 0.3,
//                   // cacheHeight: (imageHeight ?? _size.width).toInt(),
//                   // cacheWidth: (imageWidth ?? _size.width).toInt(),
//                 ),
//               ),
//               if (indexOfSelectedImageList != -1)
//                 Positioned.fill(
//                     child: Container(
//                   decoration: BoxDecoration(
//                     color: const Color.fromRGBO(0, 0, 0, 0.2),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 )),
//               // Center(
//               //   child: WTextContent(
//               //     value: item.id,
//               //     textColor: red,
//               //   ),
//               // ),
//               Align(
//                 alignment: Alignment.bottomRight,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: const Color.fromRGBO(0, 0, 0, 0.3),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   margin: const EdgeInsets.only(bottom: 5, right: 5),
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
//                   child: WTextContent(
//                     value: item.path.split(".").last.toUpperCase(),
//                     textColor: white,
//                     textSize: 10,
//                     textLineHeight: 16,
//                   ),
//                 ),
//               ),
//               if (indexOfSelectedImageList != -1)
//                 Container(
//                   height: 32,
//                   width: 32,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(19),
//                     color: blue,
//                   ),
//                   alignment: Alignment.center,
//                   child: WTextContent(
//                     value: (indexOfSelectedImageList + 1).toString(),
//                     textColor: white,
//                     textSize: 13,
//                     textLineHeight: 16.25,
//                   ),
//                 )
//             ],
//           )),
//     );
//   }
// }
