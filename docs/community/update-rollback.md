# Update and rollback

Back up first, review release notes, then run `scripts/community/update.sh --version 0.1.1`. Images are pulled before containers are recreated. For rollback, restore `.env.pre-update`, pull the previous pinned images, run Compose, and restore the compatible data backup if migrations occurred. Preview releases do not guarantee downgrade-compatible state.
