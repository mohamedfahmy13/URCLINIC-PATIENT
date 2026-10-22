# Sign in with Apple: backend requirements

| | |
|---|---|
| Endpoint | `POST https://urclinic.findosystem.com/api/social-login` |
| Client | UrClinic patient app, iOS (bundle ID `com.urclinic.patient`) |
| Firebase project | `urclinic-72a3e` |
| Date | 2026-10-17 |

Sign in with Apple is back in the iOS app. On the phone, Apple and Firebase sign-in succeed, and the request below carries the email they returned. The last step, `POST /api/social-login`, fails with **HTTP 500 and an HTML error page**. The user can't log in, and the app can only show "Internal Server Error".

## 1. Fix the 500 (blocking)

The exact request that failed:

```http
POST /api/social-login
Content-Type: application/json; charset=utf-8
global-localization: en
```

```json
{
  "contact_number": "",
  "email": "mof4943@gmail.com",
  "first_name": "mohamed",
  "last_name": "mohamed",
  "username": "mohamed mohamed",
  "profile_image": "",
  "user_type": "user",
  "login_type": "apple"
}
```

The exception is in the server log (`storage/logs/laravel.log`, if this is Laravel, which the HTML error page suggests). The mobile team can't see the server, so these are guesses, ordered by likelihood:

| Suspect | Why it would fail |
|---|---|
| The email already exists | If this email was registered with a password or Google, a plain `INSERT` hits the unique index on `email`. |
| `contact_number` is `""` | Apple never provides a phone number. If `mobile` is unique, the second user saved with `""` collides with the first. Store `NULL` instead. |
| `username` collides | `"mohamed mohamed"` is not unique. If `username` has a unique index, the insert fails. |
| `login_type = "apple"` isn't handled | An enum column, validation rule or `switch` that only knows `google`. |
| A required column has no value | For example, `password` is `NOT NULL` when a social user is created. |

## 2. What the app sends

`POST /api/social-login`, JSON body, no `Authorization` header.

| Field | Value for Apple | Notes |
|---|---|---|
| `email` | Always present | May be an Apple relay address (`…@privaterelay.appleid.com`) if the user chose "Hide My Email". It stays the same for this user and this app, so treat it like any other email. |
| `first_name`, `last_name` | See notes | Apple sends the name **only the first time** a user authorizes the app. On later sign-ins the app sends a fallback: the Firebase display name, or the part of the email before `@`. |
| `username` | `"first last"` | Not unique. |
| `contact_number` | `""` | Apple never provides a phone number. |
| `profile_image` | `""` | Apple never provides a photo. |
| `user_type` | `"user"` | Always `user` (patient). |
| `login_type` | `"apple"` | `"google"` uses the same contract if Google sign-in comes back. |

The `global-localization` header is `en` or `ar`. Use it for the language of `message`.

## 3. Expected behavior

1. Validate: `email` is required and valid, and `login_type` is `google` or `apple`.
2. Look up the user by `email`.
3. **Not found:** create a patient with role `user`, `login_type` from the request, names from the request, `mobile = NULL`, a random hashed password (or a nullable password column), and the email marked as verified. Return a token.
4. **Found, and a patient:** log them in and return a token. Don't overwrite a non-empty `first_name` or `last_name` with what the app sends on later logins (see the name note in section 2).
5. **Found, but not a patient** (doctor, receptionist, admin): don't issue a token. Return a JSON error.
6. **Found, but deleted or banned:** return `status: false` with a message. For deleted accounts, add `"is_deleted": true`; the app clears its local data when it sees it.
7. Never respond with HTML (see section 5).

Pick one policy for an email that is already registered with a password, and tell the mobile team. Either log the user in (link the accounts), or return a JSON error such as "This email is registered with a password. Please sign in with your password." Either is fine; a 500 is not.

## 4. Response the app expects

On success, return HTTP 200 with the same shape as `POST /api/login`:

```json
{
  "status": true,
  "message": "Login successfully",
  "data": {
    "id": 123,
    "first_name": "Ahmed",
    "last_name": "Ali",
    "user_name": "Ahmed Ali",
    "email": "user@example.com",
    "mobile": "",
    "profile_image": "",
    "login_type": "apple",
    "user_type": "user",
    "user_role": ["user"],
    "api_token": "<token>"
  }
}
```

- `data.user_role` **must contain `"user"`**. If it doesn't, the app refuses the login and shows `message`.
- The app sends `data.api_token` as `Authorization: Bearer <api_token>` on every later request.

For errors, return JSON: `{"status": false, "message": "..."}`. Whether the user sees your `message` depends on the HTTP status:

| HTTP status | What the user sees |
|---|---|
| 200 with `"status": false` | Your `message` |
| 401, 409 or 422 with a JSON body | Your `message` |
| 400, 403, 404 or 500 | A generic text; your `message` is ignored |

Use 200 with `"status": false`, 409 or 422 for anything the user should read.

## 5. Always return JSON on `/api/*`

The app sends `Content-Type: application/json` but not `Accept: application/json`, so a Laravel exception renders the HTML error page. Force JSON for API routes on the server.

Laravel 11 and later, in `bootstrap/app.php`:

```php
->withExceptions(function (Exceptions $exceptions) {
    $exceptions->shouldRenderJsonWhen(fn (Request $request) => $request->is('api/*'));
})
```

Older Laravel: add a middleware to the `api` group that runs `$request->headers->set('Accept', 'application/json');`.

## 6. Security: verify who the user is (high priority)

Right now `social-login` trusts the `email` in the request body. Anyone who knows a patient's email can send `{"email": "...", "login_type": "apple", ...}` and receive that patient's `api_token`, which gives full access to their medical records. The same is true for `login_type: "google"`.

The fix is to verify a token issued by Apple or Firebase and take the email from that token, never from the body.

- **Recommended: Firebase ID token.** The app already signs in to Firebase (project `urclinic-72a3e`) before it calls the API, so it can send a `firebase_id_token` field. Verify it with the Firebase Admin SDK (in PHP, `kreait/firebase-php`: `$auth->verifyIdToken($token)`). Check that `firebase.sign_in_provider` is `apple.com` or `google.com`, then use the token's `email` and `uid`. One check covers both Apple and Google.
- **Alternative: Apple identity token.** Verify the JWT signature against Apple's public keys (`https://appleid.apple.com/auth/keys`), check `iss = https://appleid.apple.com` and `aud = com.urclinic.patient`, and use its `sub` and `email` claims.

Store the provider's stable user ID (`uid` or `sub`) and match on it before the email, since emails can change.

This needs both sides. Agree on the field name with the mobile team, then the app starts sending it. Make it required only after that app version is live; otherwise older versions lose social login.

## 7. Account deletion (App Store requirement)

App Store Review Guideline 5.1.1(v) requires apps that offer Sign in with Apple to revoke the user's Apple tokens when the user deletes their account (`POST /api/delete-account`). This can happen on the server, through Apple's `https://appleid.apple.com/auth/revoke` endpoint (it needs a Sign in with Apple key from the Apple Developer account and the authorization code the app receives at sign-in), or in the app through Firebase. Agree with the mobile team on which side does it. It isn't needed to fix the login.

## 8. Test checklist

- [ ] New email: 200, `"status": true`, `user_role` contains `user`, and `api_token` works on an authenticated endpoint.
- [ ] Same email again: 200, same user `id`, names unchanged.
- [ ] Two different Apple users, both with `contact_number: ""`: both succeed.
- [ ] Relay email (`abc123@privaterelay.appleid.com`): succeeds.
- [ ] Email already registered with a password: the agreed behavior, as JSON, not a 500.
- [ ] Email that belongs to a doctor or admin: JSON error, no token.
- [ ] Any exception on `/api/*`: JSON body, not HTML.
- [ ] After section 6: a missing or invalid token returns 401 JSON, and when the body's email differs from the token's, the token wins.
