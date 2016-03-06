# Git Backup

## Setup

* Ruby 2.3
* bundle

## Usage

Backup a newline-separated list of repo clone URLs:

```bash
cat repos.txt | ruby backup.rb --root [PATH]
```

Backup all GitHub repos for authenticated user:

```bash
$ ruby github_repos.rb [TOKEN] | ruby backup.rb --root [PATH]
```

Backup all GitHub repos for organization:

```bash
$ ruby github_repos.rb [TOKEN] --org philosophie | ruby backup.rb --root [PATH]
```
