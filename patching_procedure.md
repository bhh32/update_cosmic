# How to Patch
1. Clone package's src repo
2. Run `git checkout <current commit hash>`
3. Use the patch in pkg directory in the repo for the following command:
  ```bash
  git am pkg_dir_patch.patch
  ```
4. Run `git rebase -i <updated commit hash>`
5. Manually edit any conflicts
6. `git add .`
7. `git rebase --continue`
8. git format-patch -1 --no-signature
9. `mv new_patch.patch /path/to/package/pkg/old_patch_name.patch`
10. Build the patched package.
