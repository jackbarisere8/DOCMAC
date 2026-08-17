package com.jack.docmac

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Bundle
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // This AVD exposes a Wi-Fi network with a non-functional IPv6 route.
        // Firebase Auth can select an IPv6 Google endpoint before Flutter starts,
        // so bind emulator traffic to its IPv4-capable virtual cellular network.
        // The cellular network is still routed through the host computer's Wi-Fi.
        bindEmulatorToIpv4Network()
        super.onCreate(savedInstanceState)
    }

    private fun bindEmulatorToIpv4Network() {
        if (!isRunningOnEmulator()) return

        val connectivityManager =
            getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val cellularNetwork = connectivityManager.allNetworks.firstOrNull { network ->
            connectivityManager.getNetworkCapabilities(network)
                ?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true
        } ?: return

        connectivityManager.bindProcessToNetwork(cellularNetwork)
    }

    private fun isRunningOnEmulator(): Boolean =
        Build.FINGERPRINT.startsWith("generic") ||
            Build.FINGERPRINT.startsWith("unknown") ||
            Build.MODEL.contains("Emulator", ignoreCase = true) ||
            Build.MODEL.contains("Android SDK built for", ignoreCase = true) ||
            Build.MANUFACTURER.contains("Genymotion", ignoreCase = true) ||
            Build.HARDWARE.contains("ranchu", ignoreCase = true) ||
            Build.HARDWARE.contains("goldfish", ignoreCase = true) ||
            Build.PRODUCT.startsWith("sdk_")
}
