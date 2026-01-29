import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;

  const ExpandableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 2,
    this.textAlign,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style.merge(widget.style);

    return LayoutBuilder(builder: (context, constraints) {
      final span = TextSpan(text: widget.text, style: defaultStyle);
      final tp = TextPainter(
        text: span,
        maxLines: widget.maxLines,
        textDirection: Directionality.of(context),
        ellipsis: '...',
      );
      tp.layout(maxWidth: constraints.maxWidth);
      final didOverflow = tp.didExceedMaxLines;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            style: widget.style,
            maxLines: _expanded ? null : widget.maxLines,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            textAlign: widget.textAlign,
          ),
          if (didOverflow)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24)),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Багасгах' : 'Дэлгэрэнгүй', style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
        ],
      );
    });
  }
}
