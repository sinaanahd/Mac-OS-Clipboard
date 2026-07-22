# Privacy

Pasteboard is designed for local processing. It has no account, analytics, advertising, telemetry, or cloud-sync component. Clipboard metadata and owned image files will live under the app's Application Support directory and remain subject to user-configured limits and deletion.

The application must never log complete clipboard contents, transmit captured data, retain data after a successful clear operation, or request Accessibility or Screen Recording permission before the related feature is used. Passwords, tokens, certificates, provisioning profiles, runtime databases, clipboard history, and captured screenshots must never enter source control.

Accessibility access is used only after the user selects automatic paste and solely to synthesize Command-V for the previously active application. Pasteboard explains the purpose before invoking the macOS permission prompt and does not inspect other applications' interface content.

File history stores local file paths as references. Pasteboard does not copy, upload, modify, or delete the referenced user files; removing a history entry removes only Pasteboard metadata.
