# Privacy

Pasteboard is designed for local processing. It has no account, analytics, advertising, telemetry, or cloud-sync component. Clipboard metadata and owned image files will live under the app's Application Support directory and remain subject to user-configured limits and deletion.

Items marked by their source as concealed, transient, or auto-generated are excluded from history. This uses the pasteboard privacy signals exposed by the source application; applications that publish sensitive content without such a signal cannot be identified reliably by Pasteboard.

The application must never log complete clipboard contents, transmit captured data, retain data after a successful clear operation, or request Accessibility or Screen Recording permission before the related feature is used. Passwords, tokens, certificates, provisioning profiles, runtime databases, clipboard history, and captured screenshots must never enter source control.

Accessibility access is used only after the user selects automatic paste and solely to synthesize Command-V for the previously active application. Pasteboard explains the purpose before invoking the macOS permission prompt and does not inspect other applications' interface content.

File history stores local file paths as references. Pasteboard does not copy, upload, modify, or delete the referenced user files; removing a history entry removes only Pasteboard metadata.

Screen Recording access is requested only after the user invokes region capture and accepts Pasteboard's explanation. The native macOS selector determines the captured region. Pasteboard imports the resulting PNG locally, removes its own temporary file, and never transmits the image.

Clear History requires confirmation. It removes history metadata and image copies owned by Pasteboard, then removes unreferenced files from Pasteboard's image-storage directory. It never deletes original files referenced by file-history entries. The configured expiration policy applies the same owned-data cleanup to expired entries.
