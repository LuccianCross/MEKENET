# Amharic Translation Fix Instructions

**For:** Teammate fixing Amharic translations in `mekenet_mobile/lib/l10n/app_localizations.dart`
**File:** Line 144-272 in the `'am'` map

This document lists EVERY problem in the Amharic translations, what the word currently says, and the exact replacement text. Copy-paste the corrected values directly.

---

## CRITICAL: Gibberish / Wrong Script (4 keys)

These contain Korean, Hebrew, or mixed-script characters. Fix immediately.

| Line | Key | Current (BROKEN) | Corrected |
|------|-----|-------------------|-----------|
| ~148 | `debts` | `뽐ዓን` | `ዕዳዎች` |
| ~186 | `copyReport` | `ሪፖርት ቅרון` | `ሪፖርት ቅጂ` |
| ~183 | `syncData` | `መረጃ ማ_sync` | `መረጃ ማመሳከል` |
| ~165 | `noTransactionsYet` | `ገብይቶች አልተፈተጡም` | `ገና ግብይቶች የሉም` |

---

## IMPORTANT: Wrong Meaning (12 keys)

These are real Amharic words but mean the wrong thing.

| Key | Current | What it means | Corrected |
|-----|---------|---------------|-----------|
| `income` | `ግቢ` | "compound/campus" | `ገቢ` |
| `category` | `ምድር` | "earth/ground/world" | `ምድብ` |
| `manageCategories` | `ምድሮችን ማስተካከል` | "adjust the earths" | `ምድቦችን ማስተካከል` |
| `incomeByCategory` | `ገቢ በምድር መሰረት` | "income by earth" | `ገቢ በምድብ መሰረት` |
| `todayProfit` | `የዛሬ ቀሪ` | "today's leftover" | `የዛሬ ትርፍ` |
| `thisWeekProfit` | `የዚህ ሳምንት ቀሪ` | "this week's leftover" | `የዚህ ሳምንት ትርፍ` |
| `thisMonthProfit` | `የዚህ ወር ቀሪ` | "this month's leftover" | `የዚહ ወር ትርፍ` |
| `last7Days` | `ለ7 ቀናት` | "for 7 days" (duration) | `ያለፉት 7 ቀናት` |
| `openDebts` | `ተከፍተው የሚገኙ ፖሞዎች` | "ፖሞ" is gibberish | `ክፍት ዕዳዎች` |
| `addDebt` | `ፖሞ መጨመር` | "ፖሞ" is gibberish | `ዕዳ መጨመር` |
| `noOpenDebts` | `ተከፍተው የሚገኙ ፖሞዎች የሉም` | "ፖሞ" is gibberish | `ክፍት ዕዳዎች የሉም` |
| `reportGenerated` | `ሪፖርት ተዘርግቷል` | "stretched" (scrambled letters) | `ሪፖርት ተዘጋጅቷል` |

---

## NEEDS FIX: Questionable Translations (2 keys)

| Key | Current | Problem | Corrected |
|-----|---------|---------|-----------|
| `owed` | `የተበደለ` | Describes the borrower, not the amount | `ዕዳ` |
| `markPaid` | `ከፍለዋል ምልክት` | Awkward word order | `እንደተከፈለ ምልክት አድርግ` |

---

## UNTRANSLATED: Still English (74 keys)

These keys in the `'am'` map still contain English text. Replace each one with the Amharic below.

### Navigation & General

| Key | Corrected |
|-----|-----------|
| `skip` | `ዝለል` |
| `next` | `ቀጣይ` |
| `neverShare` | `መረጃዎን ገር አንጋራም` |
| `ok` | `እሺ` |
| `confirm` | `ማረጋገጫ` |
| `chooseLanguage` | `ቋንቋ ምረጥ` |
| `chooseLanguageDesc` | `የምትመርጠውን ቋንቋ ምረጥ` |

### Onboarding Screen

| Key | Corrected |
|-----|-----------|
| `getStarted` | `ጀምር` |
| `allowSmsAccess` | `ለSMS ፈቃድ ይስጡ?` |
| `allowSmsAccessDesc` | `ሽያጭዎንና የንግድ ወጪዎን በራስ-ሰር ለመመዝገብ የባንክ ክፍያ መልእክቶችን ብቻ እናነባለን። የግል ውይይቶችን አናስተውልም።` |
| `dataStaysOnDevice` | `መረጃዎ በስልክዎ ላይ ብቻ ይቀራል` |
| `dataStaysOnDeviceDesc` | `የፋይናንስ መዝገቦችዎ በ100% የግል ናቸው። ሁሉም የSMS ስራ ዝርዝሮችን ወደ ማንኛውም ሰርቨር ሳይላክ በስልክዎ ላይ በደህና ሁኔታ ይከናወናል።` |

### Settings Screen

| Key | Corrected |
|-----|-----------|
| `syncToCloud` | `ወደ ክላውድ ማመሳከል` |
| `syncOn` | `ግብይቶች መጠባበቂያ ይደረግላቸዋል` |
| `syncOff` | `በዚህ መሣሪያ ላይ ብቻ ይቀመጣሉ` |
| `allowAccess` | `ፈቃድ ስጥ` |
| `notNow` | `አሁን አይደለም` |
| `sendReportToBank` | `ሪፖርት ወደ ባንክ ላክ` |
| `addOrRemoveCategories` | `የወጪ ምድቦችን ጨምር ወይም አንስ` |
| `changePIN` | `PIN ቀይር` |
| `updatePINSubtitle` | `የደህንነት PINዎን ያዘምኑ` |
| `debugSMS` | `SMS ፍተሻ` |
| `debugSMSSubtitle` | `የSMS ሂደቱን ደረጃ በደረጃ ይሞክሩ` |
| `language` | `ቋንቋ` |
| `selectLanguage` | `ቋንቋ ምረጥ` |
| `english` | `እንግሊዝኛ` |
| `amharic` | `አማርኛ` |

### Report & Export

| Key | Corrected |
|-----|-----------|
| `type` | `ዓይነት` |
| `all` | `ሁሉም` |
| `incomeShort` | `ገቢ` |
| `expenseShort` | `ወጪ` |
| `getReport` | `ሪፖርት አግኝ` |
| `share` | `አጋራ` |
| `from` | `ከ` |
| `to` | `እስከ` |
| `viewAll` | `ሁሉንም ተመልከት` |
| `transactionHistory` | `የግብይት ታሪክ` |
| `allTransactions` | `ሁሉም ግብይቶች` |
| `incomeByCategory` | `ገቢ በምድብ መሰረት` |

### Debts Screen

| Key | Corrected |
|-----|-----------|
| `openDebts` | `ክፍት ዕዳዎች` |
| `addDebt` | `ዕዳ መጨመር` |
| `noOpenDebts` | `ክፍት ዕዳዎች የሉም` |
| `deleteDebt` | `ዕዳው ይሰረዝ?` |
| `addDebtTitle` | `ዕዳ ጨምር` |
| `oweToMe` | `የሚገባኝ` |
| `iOwe` | `የምከፍለው` |
| `daysAgo` | `ቀናት በፊት` |
| `yesterday` | `ትናንት` |
| `todayLabel` | `ዛሬ` |
| `noOpenDebtsYet` | `ክፍት ዕዳዎች የሉም` |
| `owedToMe` | `ለእኔ የሚገባ` |
| `markAsPaid` | `እንደተከፈለ ምልክት አድርግ` |
| `owesMe` | `የሚያከፍለኝ` |
| `noOneOwesYouYet` | `እስካሁን ማንም ለእርስዎ ዕዳ የለውም` |
| `youDontOweAnyone` | `ለማንም ዕዳ የለብዎትም` |
| `tapPlusToAdd` | `ዕዳ ለመጨመር + ይንኩ` |
| `paid` | `ተከፍሏል` |
| `addedToday` | `ዛሬ ታክሏል` |
| `addedYesterday` | `ትናንት ታክሏል` |
| `addedDaysAgo` | `ቀናት በፊት` |
| `pleaseFillAllFields` | `እባክዎ ሁሉንም መስኮች ይሙሉ` |

### Quick Add Screen

| Key | Corrected |
|-----|-----------|
| `amountBr` | `መጠን (ብር)` |
| `note` | `ማስታወሻ (አማራጭ)` |
| `noteHint` | `ለምሳሌ፦ የሳምንቱ የዕቃ መሙላት` |
| `clearAndStartOver` | `አጽዳና እንደገና ጀምር` |
| `pleaseEnterAmount` | `እባክዎ መጠን ያስገቡ` |
| `pleaseEnterValidAmount` | `እባክዎ ትክክለኛ መጠን ያስገቡ` |
| `saved` | `ተቀምጧል` |
| `noCategory` | `ያልተመደበ` |

### PIN Screen

| Key | Corrected |
|-----|-----------|
| `pinMismatch` | `PINዎቹ አልተመሳሰሉም። እንደገና ይሞክሩ።` |
| `incorrectPIN` | `ትክክለኛ ያልሆነ PIN` |
| `tooManyAttempts` | `በጣም ብዙ ሙከራ። ለ30 ሰከንድ ተዘግቷል።` |
| `tryAgainIn` | `እንደገና ለመሞክር፦` |
| `seconds` | `ሰከንዶች` |
| `attempts` | `ሙከራዎች` |
| `setPIN` | `PIN አዘጋጅ` |
| `confirmPIN` | `PIN አረጋግጥ` |
| `enterPIN` | `PIN አስገባ` |
| `confirmYourPIN` | `PINዎን ያረጋግጡ` |
| `createYourPIN` | `PINዎን ይፍጠሩ` |
| `enterExistingPIN` | `ነባሩን PIN ያስገቡ` |
| `lockedFor` | `ተዘግቷል` |
| `lockoutSeconds` | `ሰከንድ።` |

### Other

| Key | Corrected |
|-----|-----------|
| `date` | `ቀን` |
| `delete` | `ሰርዝ` |
| `cancel` | `ሰርዝ` |
| `retry` | `ድጋሚ ሞክር` |

---

## Why These Words Were Wrong

Here's what happened, so your teammate understands the patterns:

1. **Korean/Hebrew characters** — Likely copy-paste from a translation tool or keyboard glitch. Always preview Amharic in a real app/emulator before committing.

2. **`ምድር` vs `ምድብ`** — One vowel difference. `ምድር` = earth/ground. `ምድብ` = category. Easy to confuse in Amharic typing.

3. **`ግቢ` vs `ገቢ`** — One vowel difference. `ግቢ` = compound/premises. `ገቢ` = income.

4. **`ቀሪ` vs `ትርፍ`** — `ቀሪ` means "leftover/remaining". `ትርፍ` means "profit". Both relate to money but have different meanings.

5. **`ፖሞ`** — Not a real Amharic word. Likely auto-complete or transliteration error. The correct word for "debt" is `ዕዳ`.

6. **`ተዘርግቷል` vs `ተዘጋጅቷል`** — Scrambled letters. `ተዘርግቷል` = "has been stretched". `ተዘጋጅቷል` = "has been prepared/generated".

7. **74 untranslated keys** — These were never translated. The `'am'` section was copied from `'en'` and only some values were changed.

---

## Testing

After fixing, run:
```bash
cd mekenet_mobile
flutter test
flutter build apk --debug
```

Then switch the app language to Amharic and verify every screen shows proper Ge'ez script.
