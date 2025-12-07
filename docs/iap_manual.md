# IAP OAuth Brand & Client Manual Guide

This guide provides step-by-step instructions to manually configure the OAuth Consent Screen and OAuth Client required for Identity-Aware Proxy (IAP).

## Prerequisites

- **Permission**: You need `Project Editor` or `OAuth Config Editor` roles.
- **Audience Decision**:
  - **Internal (Recommended)**: Choose this if your project belongs to the `intelligenceforgood.org` Google Cloud Organization. This allows you to control access via IAM groups (like `i4g-analyst@intelligenceforgood.org`) without managing individual "Test Users".
  - **External**: Choose this only if you do not have a Google Workspace Organization. You will be limited to a list of specific "Test Users" unless you go through a verification process.

---

## Step 1: Configure OAuth Consent Screen

1.  Log in to the **Google Cloud Console** and select your project (e.g., `i4g-dev`).
2.  Navigate to **APIs & Services** > **OAuth consent screen**.
3.  **User Type Selection**:
    *   Select **Internal** (if available and you are in an Org).
    *   Select **External** (if Internal is disabled).
    *   Click **Create**.

### Tab 1: App Information
4.  **App Information**:
    *   **App name**: Enter `Intelligence for Good Analyst Platform`.
    *   **User support email**: Select your email address.
    *   **App logo**: (Optional) Skip for now.
5.  **App Domain**:
    *   **Application home page**: `https://app.intelligenceforgood.org`
    *   **Application privacy policy link**: (Optional)
    *   **Application terms of service link**: (Optional)
    *   **Authorized domains**: Click **Add Domain** and enter `intelligenceforgood.org`.
6.  **Developer Contact Information**:
    *   Enter your email address (e.g., `jerry@intelligenceforgood.org`).
7.  Click **Save and Continue**.

### Tab 2: Scopes
8.  Click **Add or Remove Scopes**.
9.  In the filter list, select the checkboxes for:
    *   `.../auth/userinfo.email`
    *   `.../auth/userinfo.profile`
    *   `openid`
10. Click **Update**.
11. Click **Save and Continue**.

### Tab 3: Test Users (External Only)
*Note: If you selected "Internal", this step is skipped.*
12. If you selected **External**, click **Add Users**.
13. Enter the specific email addresses of users who need access (e.g., yourself).
    *   *Warning*: You cannot add Google Groups (like `i4g-analyst@...`) here. You must add individual emails.
14. Click **Save and Continue**.

### Tab 4: Summary
15. Review your settings and click **Back to Dashboard**.

---

## Step 2: Create OAuth Client ID

1.  Navigate to **APIs & Services** > **Credentials**.
2.  Click **+ Create Credentials** at the top and select **OAuth client ID**.
3.  **Application type**: Select **Web application**.
4.  **Name**: Enter `IAP Client - Console`.
5.  **Authorized JavaScript origins**:
    *   Click **Add URI**.
    *   Enter: `https://app.intelligenceforgood.org`
6.  **Authorized redirect URIs**:
    *   Click **Add URI**.
    *   Enter: `https://app.intelligenceforgood.org/api/auth/callback/google` (Standard for NextAuth.js/Auth.js if used).
    *   Click **Add URI**.
    *   Enter: `https://iap.googleapis.com/v1/oauth/clientIds/YOUR_CLIENT_ID_HERE:handleRedirect`
        *   *Note*: You won't know the Client ID until you create it. You can come back and edit this later, or skip it if you are only using IAP's built-in flow (which auto-handles this).
7.  Click **Create**.
8.  **Important**: A popup will show "OAuth client created".
    *   Copy the **Client ID**.
    *   Copy the **Client Secret**.
    *   Store these temporarily in a secure note.

---

## Step 3: Store Secrets in Secret Manager

You need to store the Client Secret in Google Secret Manager so Terraform and the application can access it.

1.  Open the **Cloud Shell** (icon in top right) or use your local terminal.
2.  Run the following command (replace placeholders):

```bash
# Set your variables
export PROJECT_ID="i4g-dev"  # or i4g-prod
export SECRET_ID="iap-client-console"
export CLIENT_SECRET="YOUR_COPIED_CLIENT_SECRET"

# Create the secret (if it doesn't exist)
gcloud secrets create $SECRET_ID --replication-policy="automatic" --project=$PROJECT_ID || true

# Add the secret version
printf "$CLIENT_SECRET" | gcloud secrets versions add $SECRET_ID --data-file=- --project=$PROJECT_ID
```

3.  Repeat this process if you have a separate client for the API (e.g., `iap-client-fastapi`).

---

## Step 4: Important Architecture Note

**Critical**: Identity-Aware Proxy (IAP) **requires** an HTTP(S) Load Balancer.
Currently, your infrastructure uses **Cloud Run Domain Mapping** (`google_cloud_run_domain_mapping`), which maps the domain directly to Cloud Run.

**IAP will NOT work with Domain Mapping.**

To enforce IAP:
1.  You must switch from Domain Mapping to a **Global External Application Load Balancer**.
2.  The Load Balancer will have IAP enabled on its Backend Service.
3.  The DNS for `app.intelligenceforgood.org` must point to the Load Balancer IP, not the Cloud Run domain mapping.

If you proceed with the current setup, users will access the app directly, bypassing IAP.
