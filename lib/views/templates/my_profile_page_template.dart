import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

import '../themes/colors.dart';
import '../themes/typography.dart';
import '../widgets/snackbar.dart';

class MyProfile extends StatelessWidget {
  const MyProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.background,
        toolbarHeight: 66,
        title: Text(
          "My Profile",
          style: MyTypography.h3,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MyColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Image(
                    height: 64,
                    width: 64,
                    image: AssetImage('assets/images/avatar.png'),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kris Watson',
                        style: MyTypography.body1
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Ad ullamco',
                        style: MyTypography.body2,
                      ),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => showSnackbar(
                      context,
                      'Profile editing needs account storage.',
                    ),
                    child: const Image(
                      height: 32,
                      width: 32,
                      image: AssetImage('assets/images/pencil.png'),
                    ),
                  ),
                ],
              ),
            ),

            // button
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => showSnackbar(
                    context,
                    'Delete account needs account backend.',
                  ),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: MyColors.pink,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Delete Account',
                          style:
                              MyTypography.body2.copyWith(color: MyColors.pink),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => showSnackbar(
                    context,
                    'Sign out needs auth integration.',
                  ),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: MyColors.selected,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout,
                          size: 16,
                          color: MyColors.pink,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sign Out',
                          style:
                              MyTypography.body2.copyWith(color: MyColors.pink),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Appearance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance'.toUpperCase(),
                  style: MyTypography.caption1,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Image(image: AssetImage('assets/images/sabit.png')),
                    const SizedBox(width: 16),
                    Text(
                      'Night mode',
                      style: MyTypography.body2,
                    ),
                    const Spacer(),
                    GFToggle(
                      onChanged: (val) => showSnackbar(
                        context,
                        'Night mode needs theme persistence.',
                      ),
                      value: true,
                      type: GFToggleType.ios,
                      boxShape: BoxShape.circle,
                      enabledThumbColor: Colors.white,
                      enabledTrackColor: MyColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(
                  color: MyColors.disabled,
                  height: 0.2,
                  endIndent: 0,
                  thickness: 1,
                ),
                const SizedBox(height: 24),

                // other setting
                Text(
                  'Other Settings'.toUpperCase(),
                  style: MyTypography.caption1,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => showSnackbar(
                    context,
                    'Help support needs a support URL or contact channel.',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Image(image: AssetImage('assets/images/ask.png')),
                      const SizedBox(width: 16),
                      Text(
                        'Help & Support',
                        style: MyTypography.body2,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => showSnackbar(
                    context,
                    'Feedback needs a destination URL or mail channel.',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Image(
                          image: AssetImage('assets/images/feedback.png')),
                      const SizedBox(width: 16),
                      Text(
                        'Feedback',
                        style: MyTypography.body2,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
