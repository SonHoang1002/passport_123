import 'package:flutter/material.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/widgets/w_instruction_item.dart';
import 'package:passport_photo_2/widgets/w_text.dart';

class Instructions extends StatelessWidget {
  const Instructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(
              top: 40,
              bottom: 60,
            ),
            child: WTextContent(
              value: "Instructions",
              textSize: 32,
              textLineHeight: 38,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.vertical,
              child: Column(
                  children: LIST_INSTRUCTION_MODEL.map((e) {
                final index = LIST_INSTRUCTION_MODEL.indexWhere(
                  (element) => element.id == e.id,
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: 35),
                  child: InstructionItem(
                    index: index,
                    model: e,
                  ),
                );
              }).toList()),
            ),
          )
        ],
      ),
    );
  }
}
