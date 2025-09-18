package com.example.mindtrainer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.mindtrainer.app.BillingMethodCallHandler

class MainActivity : FlutterActivity() {
    private lateinit var billingHandler: BillingMethodCallHandler
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register billing method channel
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mindtrainer/billing")
        billingHandler = BillingMethodCallHandler(this, this, channel)
        channel.setMethodCallHandler(billingHandler)
    }
}
