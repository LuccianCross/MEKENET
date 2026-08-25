# Mekenet ProGuard rules

# Keep flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep another_telephony (real package: com.shounakmulay.telephony)
-keep class com.shounakmulay.telephony.** { *; }
-keepattributes Signature

# Keep sqflite_sqlcipher
-keep class com.sqlcipher.** { *; }
