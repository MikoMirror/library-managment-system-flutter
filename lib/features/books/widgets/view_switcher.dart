import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/book_view_type.dart';
import '../cubit/view/view_cubit.dart';
import '../cubit/view/view_state.dart';


class ViewSwitcher extends StatelessWidget {
  const ViewSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewCubit, ViewState>(
      builder: (context, state) {
        if (state is! ViewLoaded) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BookViewType>(
              value: state.viewType,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 20,
              items: BookViewType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type.icon, size: 20),
                      const SizedBox(width: 8),
                      Text(type.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (type) {
                if (type != null) {
                  context.read<ViewCubit>().setViewType(type);
                }
              },
            ),
          ),
        );
      },
    );
  }
} 