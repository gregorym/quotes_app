# No Excuses — App Store Release

## Listing

- Name: `No Excuses`
- Subtitle: `Direct accountability. Daily.`
- Primary category: `Productivity`
- Secondary category: `Health & Fitness`
- Age rating: `4+`
- Copyright: `© 2026 Koroworld, Inc`
- Privacy policy: `https://github.com/gregorym/quotes_app/blob/main/PRIVACY.md`
- Support: `https://github.com/gregorym/quotes_app/issues`
- Keywords: `discipline,focus,goals,motivation,habits,productivity,accountability,quotes,reminders`

## Promotional text

Stop negotiating with the work you already chose. Build a personal pressure protocol and let direct reminders pull your attention back to what matters.

## Description

No Excuses is a direct accountability system for ambitious people who are tired of drifting.

Build your protocol around one concrete goal. Choose the areas you are raising, name the friction that keeps winning, and decide how hard the app should push. Then set the exact days, hours, and number of reminders that fit your life.

No Excuses gives you:

- Direct prompts shaped around your goal and pressure level
- Complete control over reminder days, frequency, and time window
- A focused quote feed with local favorites
- Small and wide Home Screen widgets with a fresh quote every day
- Offline access to the bundled quote library

The tone is firm and honest, never degrading. You control the pressure and can change or disable reminders at any time.

No account is required. Profile answers, schedules, and favorites remain on your device.

Payment is charged to your Apple Account when you confirm purchase. Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. You can manage or cancel your subscription in App Store settings.

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

Privacy Policy: https://github.com/gregorym/quotes_app/blob/main/PRIVACY.md

## Subscriptions

Subscription group: `No Excuses Premium`

| Reference name | Product ID | Duration | US price |
| --- | --- | --- | --- |
| No Excuses Premium Weekly | `com.mars6.noexcuse.premium.weekly` | 1 week | $9.99 |
| No Excuses Premium Annual | `com.mars6.noexcuse.premium.annual` | 1 year | $99.00 |

Both products unlock the same premium access. Weekly includes a three-day free trial; annual has no introductory offer. Annual is the better effective rate.

## App Review notes

No account or reviewer credentials are required.

1. Complete the onboarding to reach the subscription screen.
2. Notification permission is requested only on its dedicated onboarding step and can be skipped.
3. Use Restore on the subscription screen to restore an existing entitlement.
4. The app verifies active StoreKit entitlements natively before unlocking premium content.
5. To test widgets, add No Excuses from the Home Screen widget gallery. Small and medium families are supported and update at the next local midnight.
6. Reminder scheduling is local to the device. The user selects weekdays, a start/end window, and one to six prompts per selected day.

Export compliance: the app uses only exempt encryption supplied by the operating system for HTTPS and StoreKit (`ITSAppUsesNonExemptEncryption = false`).

## Release prerequisites

- Create the App Store Connect app for bundle ID `com.mars6.noexcuse`.
- Create both subscriptions in one subscription group with the identifiers and prices above.
- Add subscription display names and descriptions for every storefront being released.
- Publish `PRIVACY.md` before adding the privacy-policy URL.
- Select the Koroworld distribution team and enable automatic signing for both Runner and NoExcusesWidgetExtension.
- Archive, validate, upload, complete App Privacy answers, attach the subscriptions to version 1.0, and submit for review.
