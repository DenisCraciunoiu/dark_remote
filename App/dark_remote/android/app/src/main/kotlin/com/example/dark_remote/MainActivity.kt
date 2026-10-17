package com.example.dark_remote

import android.content.Context
import android.net.wifi.WifiManager
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.dark_remote/multicast"
    private var lock: WifiManager.MulticastLock? = null
    private var nsdDiscovery: NsdManager.DiscoveryListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "acquire" -> {
                    val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                    lock = wifi.createMulticastLock("mDnsLock").apply {
                        setReferenceCounted(true)
                        acquire()
                    }
                    result.success(true)
                }
                "release" -> {
                    lock?.let { if (it.isHeld) it.release() }
                    result.success(true)
                }
                "discoverService" -> discoverService(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun discoverService(result: MethodChannel.Result) {
        val nsdManager = getSystemService(Context.NSD_SERVICE) as NsdManager
        val listener = object : NsdManager.DiscoveryListener {
            private var completed = false

            private fun finish(value: Any?) {
                if (completed) return
                completed = true
                nsdManager.stopServiceDiscovery(this)
                nsdDiscovery = null
                result.success(value)
            }

            override fun onDiscoveryStarted(serviceType: String) = Unit

            override fun onServiceFound(serviceInfo: NsdServiceInfo) {
                if (serviceInfo.serviceType != "_darkremote._tcp.") return
                nsdManager.resolveService(
                    serviceInfo,
                    object : NsdManager.ResolveListener {
                        override fun onServiceResolved(resolved: NsdServiceInfo) {
                            val host = resolved.host ?: return
                            finish(
                                mapOf(
                                    "address" to host.hostAddress,
                                    "port" to resolved.port,
                                ),
                            )
                        }

                        override fun onResolveFailed(
                            serviceInfo: NsdServiceInfo,
                            errorCode: Int,
                        ) = Unit
                    },
                )
            }

            override fun onServiceLost(serviceInfo: NsdServiceInfo) = Unit

            override fun onDiscoveryStopped(serviceType: String) = Unit

            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                finish(null)
            }

            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
                nsdDiscovery = null
            }
        }

        nsdDiscovery = listener
        nsdManager.discoverServices("_darkremote._tcp.", NsdManager.PROTOCOL_DNS_SD, listener)
    }
}