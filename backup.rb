require 'git_clone_url'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: ruby backup.rb [options]'

  opts.on('-r', '--root PATH', 'Root directory to store backups') do |root|
    options[:root] = root
  end
end.parse!

ROOT_DIR = options[:root] || '.'
TIME = Time.now.to_i

class Backup
  attr_reader :clone_url, :root_dir
  def initialize(clone_url, root_dir)
    @clone_url = clone_url
    @root_dir = root_dir
  end

  def run(timestamp)
    make_repo_directory
    last_backup_time = Dir.entries(full_path(clone_url)).reject { |f| f =~ /^\.+$/ }.sort.last
    mirror_repo(timestamp)
    cleanup_duplicate(timestamp) if no_change?(last_backup_time, timestamp)
  end

  private

  def full_path(clone_url, *parts)
    uri = GitCloneUrl.parse(clone_url)
    repo_path = File.join(uri.host, uri.path)
    File.join(root_dir, repo_path, *parts.map(&:to_s))
  end

  def make_repo_directory
    system "mkdir -p #{full_path(clone_url)}"
  end

  def mirror_repo(timestamp)
    system "git clone --mirror #{clone_url} #{full_path(clone_url, timestamp)}"
  end

  def no_change?(last_backup_time, timestamp)
    return false unless last_backup_time
    system "diff #{full_path(clone_url, last_backup_time)} #{full_path(clone_url, timestamp)}"
  end

  def cleanup_duplicate(timestamp)
    puts "No change, cleaning up duplicate #{timestamp}"
    system "rm -rf #{full_path(clone_url, timestamp)}"
  end
end

while repo = gets&.strip
  Backup.new(repo, ROOT_DIR).run(TIME)
end
