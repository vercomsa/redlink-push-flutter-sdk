package pl.redlink.redlink_flutter_sdk

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context
import android.os.Process

fun Context.isApplicationInForeground(): Boolean {
    (getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager)?.apply {
        if (isKeyguardLocked) {
            return false
        }
    }

    (getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager)?.apply {
        val myPid = Process.myPid()
        runningAppProcesses.orEmpty().filterNotNull().forEach { runningAppProcessInfo ->
            if (runningAppProcessInfo.pid == myPid) {
                return runningAppProcessInfo.importance ==
                        ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
            }
        }
    }

    return false
}
