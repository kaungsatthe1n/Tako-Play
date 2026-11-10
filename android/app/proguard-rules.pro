# Room generated database implementations (e.g. WorkManager's
# WorkDatabase_Impl) are instantiated reflectively by androidx.room.Room.
# Keep their constructors so R8 does not strip them in release builds.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
-keep class androidx.work.impl.WorkDatabase_Impl {
    <init>();
}
