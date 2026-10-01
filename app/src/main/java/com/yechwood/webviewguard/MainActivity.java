package com.yechwood.webviewguard;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.graphics.Color;
import android.view.Gravity;
import android.view.ViewGroup;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.Collections;

/** Standalone offline WebView test host; not a system WebView provider. */
public final class MainActivity extends Activity {
    private WebView webView;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        try {
            getWindow().setStatusBarColor(Color.WHITE);
            getWindow().setNavigationBarColor(Color.WHITE);
            if (android.os.Build.VERSION.SDK_INT >= 26) {
                getWindow().getDecorView().setSystemUiVisibility(
                    android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR |
                    android.view.View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR);
            } else {
                getWindow().getDecorView().setSystemUiVisibility(
                    android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
            }

            FrameLayout root = new FrameLayout(this);
            root.setBackgroundColor(Color.WHITE);
            webView = new WebView(this);
            WebSettings settings = webView.getSettings();
            settings.setJavaScriptEnabled(true);
            settings.setDomStorageEnabled(true);
            settings.setAllowFileAccess(true);
            settings.setAllowContentAccess(false);
            settings.setBlockNetworkLoads(true);
            settings.setJavaScriptCanOpenWindowsAutomatically(false);
            settings.setSupportMultipleWindows(false);
            webView.setBackgroundColor(Color.WHITE);
            webView.setWebViewClient(new WebViewClient() {
                @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                    String url = request.getUrl().toString();
                    return !url.startsWith("file:///android_asset/");
                }
                @Override public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                    return blockRemote(request.getUrl().toString());
                }
                @Override public WebResourceResponse shouldInterceptRequest(WebView view, String url) {
                    return blockRemote(url);
                }
            });
            root.addView(webView, new FrameLayout.LayoutParams(-1, -1));
            setContentView(root);
            if (state == null || webView.restoreState(state) == null) {
                webView.loadUrl("file:///android_asset/home.html");
            }
        } catch (Throwable error) {
            if (webView != null) {
                try { webView.destroy(); } catch (Throwable ignored) {}
                webView = null;
            }
            showStartupError(error);
        }
    }

    private WebResourceResponse blockRemote(String url) {
        if (url != null && (url.startsWith("http://") || url.startsWith("https://"))) {
            return new WebResourceResponse("text/plain", "UTF-8", 403, "Blocked by WebView Guard",
                Collections.singletonMap("X-WebView-Guard", "blocked"),
                new ByteArrayInputStream("Remote content blocked".getBytes(StandardCharsets.UTF_8)));
        }
        return null;
    }

    private void showStartupError(Throwable error) {
        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setGravity(Gravity.CENTER_VERTICAL);
        page.setPadding(28, 28, 28, 28);
        page.setBackgroundColor(Color.WHITE);
        TextView title = new TextView(this);
        title.setText("WebView is unavailable");
        title.setTextColor(Color.rgb(32, 33, 36));
        title.setTextSize(24);
        title.setGravity(Gravity.CENTER_VERTICAL);
        TextView detail = new TextView(this);
        detail.setText("Android could not start its installed WebView engine. Check that Android System WebView or the Chrome WebView provider is enabled and updated, then restart this app.\n\nDetails: " +
            error.getClass().getSimpleName() + (error.getMessage() == null ? "" : ": " + error.getMessage()));
        detail.setTextColor(Color.rgb(95, 99, 104));
        detail.setTextSize(16);
        detail.setPadding(0, 16, 0, 0);
        page.addView(title, new LinearLayout.LayoutParams(-1, ViewGroup.LayoutParams.WRAP_CONTENT));
        page.addView(detail, new LinearLayout.LayoutParams(-1, ViewGroup.LayoutParams.WRAP_CONTENT));
        setContentView(page);
    }

    @Override protected void onSaveInstanceState(Bundle outState) {
        if (webView != null) webView.saveState(outState);
        super.onSaveInstanceState(outState);
    }
    @Override public void onBackPressed() {
        if (webView != null && webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }
    @Override protected void onDestroy() {
        if (webView != null) { webView.stopLoading(); webView.destroy(); webView = null; }
        super.onDestroy();
    }
}
