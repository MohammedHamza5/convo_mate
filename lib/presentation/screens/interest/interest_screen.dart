import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart'; // لدعم ملفات SVG
import '../../../logic/cubits/interest_cubit.dart';
import '../../../logic/cubits/interest_state.dart';

class InterestSelectionScreen extends StatelessWidget {
  final String userId;

  const InterestSelectionScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InterestCubit()..loadInterests(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("اختر اهتماماتك"),
          automaticallyImplyLeading: false,
        ),
        body: BlocConsumer<InterestCubit, InterestState>(
          listener: (context, state) {
            if (state is InterestSaved) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (state is InterestError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error)));
            }
          },
          builder: (context, state) {
            if (state is InterestLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is InterestLoaded) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'اختر من 3 إلى 5 اهتمامات (${state.selectedInterests.length}/5)',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.5,
                          ),
                      itemCount: state.interests.length,
                      itemBuilder: (context, index) {
                        final interest = state.interests[index];
                        final isSelected = state.selectedInterests.contains(
                          interest.id,
                        );
                        return GestureDetector(
                          onTap:
                              () => context
                                  .read<InterestCubit>()
                                  .toggleInterest(interest.id),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.blueAccent
                                      : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                interest.icon != null
                                    ? SvgPicture.asset(
                                      interest.icon!,
                                      height: 40,
                                      width: 40,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.black,
                                    )
                                    : const Icon(Icons.interests, size: 40),
                                const SizedBox(height: 10),
                                Text(
                                  interest.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed:
                          state.selectedInterests.length >= 3
                              ? () => context
                                  .read<InterestCubit>()
                                  .saveInterests(userId)
                              : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          state is InterestSaving
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                "التالي",
                                style: TextStyle(fontSize: 18),
                              ),
                    ),
                  ),
                ],
              );
            } else if (state is InterestError) {
              return Center(child: Text("خطأ: ${state.error}"));
            }
            return const Center(child: Text("لا توجد بيانات لعرضها"));
          },
        ),
      ),
    );
  }
}
