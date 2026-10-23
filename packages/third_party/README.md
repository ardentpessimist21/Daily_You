# Third-party packages kept in the repo

These packages are each looked after by a single person, so a copy lives
here to make sure the app can always be built, even if a package is ever
removed from pub.dev or GitHub. `pubspec.yaml` points at these folders
instead of downloading them.

Each folder is the exact version the app was already using, unchanged
apart from leaving out examples, tests and docs. Every package keeps its
own `LICENSE`.

| Package | Version | Original source |
| --- | --- | --- |
| easy_debounce | 2.0.3 | pub.dev |
| fc_native_video_thumbnail | 3.0.1 | pub.dev |
| flutter_colorpicker | 1.1.0 | pub.dev |
| html2md | 1.3.2 | pub.dev |
| shamsi_date | 1.1.1 | pub.dev |
| shared_storage | 0.8.0 | github.com/Demizo/shared-storage (`release`, 4b04f71) |
| statsfl | 2.3.0 | pub.dev |
| v_video_compressor | 2.2.3 | pub.dev |
| word_count | 1.0.4 | pub.dev |

To update one, replace its folder with the new version and note it here.
