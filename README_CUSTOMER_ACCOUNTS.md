# GOOD BREW — Customer Accounts & Order History

## Included changes
- Customer self-registration with name, WhatsApp, email, and password.
- Email verification flow (when Supabase email confirmation is enabled).
- Login, logout, forgot-password email, and password reset.
- Checkout requires a signed-in customer.
- Every new order is linked to `auth.uid()` on the database side.
- Customer order history shows only that customer's own orders and items.
- Existing admin dashboard and admin policies remain in place.

## IMPORTANT: preserve your live config.js
The package intentionally does not contain your real Supabase URL/key. Keep the current `config.js` from your GitHub repository. Never put a service_role/secret key in browser code.

## Deployment steps
1. Download/extract this package.
2. In GitHub repository `Larev1/good-brew`, replace `index.html`, `app.js`, and `style.css` with the files in this package. Upload `schema_customer_accounts.sql` too. Do not replace `config.js` or your existing `admin.html` / `admin.js`.
3. In Supabase Dashboard → SQL Editor, run the complete `schema_customer_accounts.sql` migration once.
4. In Supabase Dashboard → Authentication → URL Configuration:
   - Site URL: `https://larev1.github.io/good-brew/`
   - Add `https://larev1.github.io/good-brew/` to Redirect URLs (also add `https://larev1.github.io/good-brew/index.html` if the dashboard requires the exact page path).
5. In Authentication → Providers → Email, keep Email enabled. For proper account ownership, keep email confirmation enabled. Configure SMTP if you need reliable branded email delivery; Supabase's default email service has sending limits.
6. Commit the updated files and wait for GitHub Pages deployment.
7. Test with a new customer email: register → verify email → login → place one test order → check that it appears in customer history and in the admin dashboard.

## Existing orders
Orders created before this upgrade have `user_id = NULL`. They remain visible to admins but are not automatically assigned to a new account. This avoids exposing or incorrectly claiming a guest order. New orders will be linked to the signed-in account.

## Security notes
- The browser uses only the Supabase publishable/anon key.
- The customer ID is never accepted from the browser; the SQL function sets it from `auth.uid()`.
- RLS lets a customer read only their own order header and line items.
- Customers cannot update order/payment status.
- Admin read/update policies from the original schema remain active.
