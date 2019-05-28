# PreCommitPHPHook

Pre-commit PHP checks hook for git repositories, using the most known libraries for PHP checks.

If the score is lower than 80%, it will refuse the commit.

The script creates log files.

## Installation and usage

Just copy this script inside your `.git/hooks` project directory **and rename** it as `pre-commit` (without extension).

```
git clone https://github.com/flavienbwk/PreCommitPHPHook
cd PreCommitPHPHook
cp ./code-coverage.sh <path_to_git_project>/.git/hooks/pre-commit
```

All dependencies are automatically installed.

## Logs

You will find all the logs related to this checking script under `.pre-commit` in your project root directory.

## Libraries used

- shellcheck : https://github.com/koalaman/shellcheck (script is self checking)
- php lint : (php -l) https://github.com/overtrue/phplint
- phpcpd : https://github.com/sebastianbergmann/phpcpd
- phpcs : https://github.com/squizlabs/PHP_CodeSniffer
- phpmd : https://github.com/phpmd/phpmd