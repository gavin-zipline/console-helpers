// ============================================================================
// SCORM Token Inspector - Browser Console Snippet
// ============================================================================
// Purpose: Inspect JWT token used for SCORM → Zipline communication
// 
// HOW TO USE:
// 1. Open any SCORM lesson in Zipline (in browser)
// 2. Open browser DevTools console (F12 or Cmd+Opt+J on Mac, F12 on Windows)
// 3. Copy and paste this entire snippet into the console
// 4. Hit Enter
//
// WHAT IT SHOWS:
// ✅ Token validity status (valid or expired)
// ⏰ Time remaining until token expiration
// 🎓 SCORM context (file_id, user_id, team_id)
// 📦 Full decoded JWT token payload
//
// USE CASES:
// - Debug "cannot save SCORM data" issues (check if token expired)
// - Verify token has correct user_id and file_id
// - Check how long users have to complete SCORM before token expires
// - Troubleshoot SCORM communication failures
//
// Author: Gavin (CSE Tier-2)
// Last updated: February 13, 2026
// ============================================================================

// Find the iframe
const iframe = document.querySelector('iframe[src*="training"]') || 
               document.querySelector('iframe[src*="secure"]') ||
               document.querySelector('iframe');

if (!iframe) {
  console.error('❌ No iframe found');
} else {
  console.log('✅ Found iframe');
  
  const url = new URL(iframe.src);
  const token = url.searchParams.get('token');
  
  if (token) {
    console.log('🎫 Token found:', token.substring(0, 50) + '...');
    
    // Decode JWT
    const parts = token.split('.');
    const payload = JSON.parse(atob(parts[1]));
    
    console.log('📦 Decoded token:', payload);
    console.log('🕐 Issued at:', new Date(payload.iat * 1000));
    console.log('⏰ Expires at:', new Date(payload.exp * 1000));
    
    const remainingSeconds = Math.round((payload.exp * 1000 - Date.now()) / 1000);
    const remainingMinutes = Math.round(remainingSeconds / 60);
    
    console.log('⏳ Time remaining:', remainingMinutes, 'minutes (', remainingSeconds, 'seconds)');
    
    if (remainingSeconds < 300) {
      console.warn('⚠️ TOKEN EXPIRING SOON!');
    } else if (remainingSeconds < 0) {
      console.error('❌ TOKEN EXPIRED');
    } else {
      console.log('✅ Token is valid');
    }
  } else {
    console.warn('⚠️ No token parameter found in iframe URL');
  }
}
